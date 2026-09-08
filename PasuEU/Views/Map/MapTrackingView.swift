import SwiftUI
import MapKit

struct MapTrackingView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @StateObject private var locationManager = LocationManager.shared

    let request: ServiceRequest

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var buddyCoordinate: CLLocationCoordinate2D?
    @State private var subscription: DataSubscription?

    var body: some View {
        Map(position: $cameraPosition) {
            if let buddyCoordinate {
                Annotation("Buddy", coordinate: buddyCoordinate) {
                    Image(systemName: "figure.walk.circle.fill")
                        .font(.title)
                        .foregroundStyle(.white, Color(red: 0.42, green: 0.08, blue: 0.1))
                        .background(Circle().fill(.white))
                }
            }
            if let userCoordinate = locationManager.currentLocation,
               supabase.currentUser?.role == .client {
                Annotation("You", coordinate: userCoordinate) {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .navigationTitle("Live Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            locationManager.requestPermission()
            if supabase.currentUser?.role == .buddy, let uid = supabase.currentUser?.id {
                locationManager.broadcastingUID = uid
            }
            observeBuddyLocation()
        }
        .onDisappear {
            subscription?.remove()
            locationManager.broadcastingUID = nil
        }
    }

    private func observeBuddyLocation() {
        guard let buddyId = request.buddyId else { return }
        subscription = supabase.listenToBuddyLocation(buddyId: buddyId) { coordinate in
            guard let coordinate else { return }
            buddyCoordinate = coordinate
            cameraPosition = .region(
                MKCoordinateRegion(center: coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            )
        }
    }
}
