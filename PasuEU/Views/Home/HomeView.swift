import SwiftUI

struct HomeView: View {
    @EnvironmentObject var supabase: SupabaseManager

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
    }
}
