import SwiftUI

struct RootView: View {
    @EnvironmentObject var supabase: SupabaseManager

    @AppStorage("hasSeenSplash") private var hasSeenSplash = false

    var body: some View {
        Group {
            if supabase.isSignedIn {
                HomeView()
            } else if hasSeenSplash {
                LoginView()
            } else {
                SplashView(onGetStarted: { hasSeenSplash = true })
            }
        }
    }
}
