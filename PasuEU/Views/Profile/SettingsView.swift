import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State private var notificationsOn = true
    @State private var showFeedbackSheet = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    Toggle(isOn: $notificationsOn) {
                        Label("Notification", systemImage: "bell.fill")
                    }
                    NavigationLink {
                        Text("About PasuEU — version, university, and team info.")
                            .padding()
                    } label: {
                        Label("About", systemImage: "info.circle.fill")
                    }
                    NavigationLink {
                        Text("Help & FAQ content goes here.")
                            .padding()
                    } label: {
                        Label("Help", systemImage: "questionmark.circle.fill")
                    }
                }

                Section("Feedback") {
                    Button {

                    } label: {
                        Label("Report", systemImage: "exclamationmark.bubble.fill")
                    }
                    Button {
                        showFeedbackSheet = true
                    } label: {
                        Label("Feedback", systemImage: "text.bubble.fill")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        try? supabase.signOut()
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showFeedbackSheet) {
                AppFeedbackView()
            }
        }
    }
}
