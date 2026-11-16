import Foundation
import Combine
import CoreLocation

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = LocationManager()

    private let manager = CLLocationManager()

    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private(set) var broadcastingUID: UUID?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
    }

    func updateBroadcast(uid: UUID?, status: RequestStatus) {
        guard let uid, status == .accepted || status == .inProgress else {
            broadcastingUID = nil
            return
        }
        broadcastingUID = uid
        if let coordinate = currentLocation {
            Task { try? await SupabaseManager.shared.updateLiveLocation(uid: uid, coordinate: coordinate) }
        }
    }

    func stopBroadcasting() {
        broadcastingUID = nil
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse ||
                manager.authorizationStatus == .authorizedAlways {
                self.startUpdating()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        Task { @MainActor in
            self.currentLocation = coordinate
            if let uid = self.broadcastingUID {
                try? await SupabaseManager.shared.updateLiveLocation(uid: uid, coordinate: coordinate)
            }
        }
    }
}
