import SwiftUI

struct HomeView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State private var sharingSubscription: DataSubscription?
    @State private var isSharingLocation = false
    @State private var hasRequestedPermission = false

    var body: some View {
        TabView {
            HomeDashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }

            RequestHistoryView()
                .tabItem { Label("Transactions", systemImage: "list.bullet.rectangle.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.brand)
        .task { attachLocationSharing() }
        .onChange(of: supabase.currentUser?.id) {
            attachLocationSharing()
        }
        .onDisappear { stopLocationSharing() }
    }

    private func attachLocationSharing() {
        sharingSubscription?.remove()
        sharingSubscription = nil
        guard let uid = supabase.currentUser?.id else {
            stopLocationSharing()
            return
        }
        sharingSubscription = supabase.listenToMyRequests(userId: uid) { requests in
            updateLocationSharing(for: requests, userId: uid)
        }
    }

    private func updateLocationSharing(for requests: [ServiceRequest], userId: UUID) {
        let location = LocationManager.shared
        guard let active = requests.first(where: { $0.status == .accepted || $0.status == .inProgress }) else {
            if isSharingLocation {
                isSharingLocation = false
                location.stopBroadcasting()
                location.stopUpdating()
            }
            return
        }

        if !isSharingLocation {
            isSharingLocation = true
            if !hasRequestedPermission {
                hasRequestedPermission = true
                location.requestPermission()
            }
            location.startUpdating()
        }
        location.updateBroadcast(uid: userId, status: active.status)
    }

    private func stopLocationSharing() {
        sharingSubscription?.remove()
        sharingSubscription = nil
        if isSharingLocation {
            isSharingLocation = false
            LocationManager.shared.stopBroadcasting()
            LocationManager.shared.stopUpdating()
        }
    }
}
