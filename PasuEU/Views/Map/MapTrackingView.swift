import SwiftUI
import MapKit

private struct TrackedPoint: Equatable {
    let latitude: Double
    let longitude: Double

    init(_ coordinate: CLLocationCoordinate2D) {
        latitude = coordinate.latitude
        longitude = coordinate.longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func distance(to other: TrackedPoint) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }
}

private struct PinPair: Equatable {
    var buddy: TrackedPoint?
    var client: TrackedPoint?
}

struct MapTrackingView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @StateObject private var locationManager = LocationManager.shared

    let request: ServiceRequest

    @State private var cameraPosition: MapCameraPosition = .region(CampusArea.region)
    @State private var status: RequestStatus
    @State private var otherPoint: TrackedPoint?
    @State private var otherName: String?
    @State private var locationSubscription: DataSubscription?
    @State private var requestSubscription: DataSubscription?
    @State private var route: MKRoute?
    @State private var routeFailed = false
    @State private var routeTask: Task<Void, Never>?
    @State private var routedBuddy: TrackedPoint?
    @State private var routedClient: TrackedPoint?
    @State private var lastRouteRequest = Date.distantPast
    @State private var fittedPinCount = 0

    private let routeRefreshDistance: CLLocationDistance = 30
    private let routeMinInterval: TimeInterval = 10
    private let walkingSpeed: Double = 1.4

    init(request: ServiceRequest) {
        self.request = request
        _status = State(initialValue: request.status)
    }

    private var isBuddy: Bool { supabase.currentUser?.role == .buddy }
    private var isActive: Bool { status == .accepted || status == .inProgress }

    private var myPoint: TrackedPoint? {
        locationManager.currentLocation.map(TrackedPoint.init)
    }

    private var pins: PinPair {
        PinPair(buddy: isBuddy ? myPoint : otherPoint,
                client: isBuddy ? otherPoint : myPoint)
    }

    private var straightDistance: CLLocationDistance? {
        guard let buddy = pins.buddy, let client = pins.client else { return nil }
        return buddy.distance(to: client)
    }

    private var displayDistance: CLLocationDistance? {
        route?.distance ?? straightDistance
    }

    private var displayTravelTime: TimeInterval? {
        route?.expectedTravelTime ?? straightDistance.map { $0 / walkingSpeed }
    }

    private var otherDisplayName: String {
        otherName ?? (isBuddy ? "Client" : "Buddy")
    }

    var body: some View {
        Map(position: $cameraPosition) {
            MapPolygon(coordinates: CampusArea.boundary)
                .stroke(Theme.brand, lineWidth: 2)
                .foregroundStyle(Theme.brand.opacity(0.12))

            if let route {
                MapPolyline(route.polyline)
                    .stroke(Theme.brand, lineWidth: 5)
            } else if routeFailed, let buddy = pins.buddy, let client = pins.client {
                MapPolyline(coordinates: [buddy.coordinate, client.coordinate])
                    .stroke(Theme.brand, style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [8, 8]))
            }

            if let buddy = pins.buddy {
                Annotation(isBuddy ? "You" : otherDisplayName, coordinate: buddy.coordinate) {
                    pin(icon: "figure.walk", color: Theme.brand)
                }
            }
            if let client = pins.client {
                Annotation(isBuddy ? otherDisplayName : "You", coordinate: client.coordinate) {
                    pin(icon: "person.fill", color: .blue)
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .all))
        .tint(Theme.brand)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .overlay(alignment: .topTrailing) {
            Button {
                fitCamera()
            } label: {
                Image(systemName: "scope")
                    .font(.headline)
                    .foregroundStyle(Theme.brand)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: Circle())
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 1)
            }
            .padding(12)
            .accessibilityLabel("Recenter map")
        }
        .safeAreaInset(edge: .bottom) {
            TrackingInfoCard(
                name: otherDisplayName,
                subtitle: isBuddy ? "Client" : "Errand Buddy",
                distance: displayDistance,
                travelTime: displayTravelTime
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationTitle("Live Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .task { await start() }
        .onChange(of: pins) { _, newPins in
            let count = [newPins.buddy, newPins.client].compactMap { $0 }.count
            if count != fittedPinCount {
                fittedPinCount = count
                fitCamera()
            }
            refreshRoute()
        }
        .onChange(of: status) { _, newStatus in
            if newStatus == .accepted || newStatus == .inProgress {
                syncBroadcast()
            } else {
                tearDown()
            }
        }
        .onDisappear { tearDown() }
    }

    private func pin(icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(Circle().fill(color))
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
    }

    private func start() async {
        guard isActive, let me = supabase.currentUser else { return }
        locationManager.requestPermission()
        locationManager.startUpdating()
        syncBroadcast()
        observeStatus(userId: me.id)
        observeOtherLocation()
        await loadOtherName()
    }

    private func syncBroadcast() {
        locationManager.updateBroadcast(uid: supabase.currentUser?.id, status: status)
    }

    private func observeStatus(userId: UUID) {
        requestSubscription?.remove()
        requestSubscription = supabase.listenToMyRequests(userId: userId) { requests in
            guard let updated = requests.first(where: { $0.id == request.id }) else { return }
            status = updated.status
        }
    }

    private func observeOtherLocation() {
        let otherId = isBuddy ? request.clientId : request.buddyId
        guard let otherId else { return }
        locationSubscription?.remove()
        locationSubscription = supabase.listenToUserLocation(userId: otherId) { coordinate in
            guard let coordinate else { return }
            otherPoint = TrackedPoint(coordinate)
        }
    }

    private func loadOtherName() async {
        let otherId = isBuddy ? request.clientId : request.buddyId
        guard let otherId, let user = try? await supabase.fetchUser(id: otherId) else { return }
        otherName = user.name
    }

    private func fitCamera() {
        let points = [pins.buddy, pins.client].compactMap { $0 }
        guard let first = points.first else { return }

        if points.count == 1 {
            withAnimation {
                cameraPosition = .region(
                    MKCoordinateRegion(center: first.coordinate,
                                       latitudinalMeters: 600,
                                       longitudinalMeters: 600)
                )
            }
            return
        }

        let mapPoints = points.map { MKMapPoint($0.coordinate) }
        let minX = mapPoints.map(\.x).min() ?? 0
        let maxX = mapPoints.map(\.x).max() ?? 0
        let minY = mapPoints.map(\.y).min() ?? 0
        let maxY = mapPoints.map(\.y).max() ?? 0
        let rect = MKMapRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        let minPadding = MKMapPointsPerMeterAtLatitude(first.latitude) * 200
        let padX = max(rect.width * 0.4, minPadding)
        let padY = max(rect.height * 0.6, minPadding)
        withAnimation {
            cameraPosition = .rect(rect.insetBy(dx: -padX, dy: -padY))
        }
    }

    private func refreshRoute() {
        guard isActive, let buddy = pins.buddy, let client = pins.client else { return }

        if let lastBuddy = routedBuddy, let lastClient = routedClient,
           buddy.distance(to: lastBuddy) < routeRefreshDistance,
           client.distance(to: lastClient) < routeRefreshDistance {
            return
        }

        routeTask?.cancel()
        routeTask = Task {
            let wait = routeMinInterval - Date().timeIntervalSince(lastRouteRequest)
            if wait > 0 {
                try? await Task.sleep(for: .seconds(wait))
            }
            guard !Task.isCancelled, isActive else { return }

            lastRouteRequest = Date()
            routedBuddy = buddy
            routedClient = client

            let directionsRequest = MKDirections.Request()
            directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: buddy.coordinate))
            directionsRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: client.coordinate))
            directionsRequest.transportType = .walking

            do {
                let response = try await MKDirections(request: directionsRequest).calculate()
                guard !Task.isCancelled else { return }
                route = response.routes.first
                routeFailed = response.routes.isEmpty
            } catch {
                guard !Task.isCancelled else { return }
                route = nil
                routeFailed = true
            }
        }
    }

    private func tearDown() {
        locationSubscription?.remove()
        locationSubscription = nil
        requestSubscription?.remove()
        requestSubscription = nil
        routeTask?.cancel()
        routeTask = nil
        locationManager.stopBroadcasting()
        locationManager.stopUpdating()
    }
}
