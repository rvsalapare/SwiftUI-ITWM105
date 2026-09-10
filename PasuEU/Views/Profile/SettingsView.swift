import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State private var notificationsOn = true
    @State private var showFeedbackSheet = false

    private let brand = Color(red: 0.42, green: 0.08, blue: 0.1)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero

                    VStack(alignment: .leading, spacing: 24) {
                        sectionBlock(title: "General") {
                            toggleRow(icon: "bell.fill", title: "Notifications", isOn: $notificationsOn)
                            Divider().padding(.leading, 60)
                            navRow(icon: "info.circle.fill", title: "About") {
                                Text("About PasuEU — version, university, and team info.")
                                    .padding()
                            }
                            Divider().padding(.leading, 60)
                            navRow(icon: "questionmark.circle.fill", title: "Help") {
                                Text("Help & FAQ content goes here.")
                                    .padding()
                            }
                        }

                        sectionBlock(title: "Feedback") {
                            actionRow(icon: "exclamationmark.bubble.fill", title: "Report an issue", tint: .orange) {}
                            Divider().padding(.leading, 60)
                            actionRow(icon: "text.bubble.fill", title: "Send Feedback") {
                                showFeedbackSheet = true
                            }
                        }

                        Button {
                            try? supabase.signOut()
                        } label: {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(24)
                    .padding(.top, 8)
                }
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea(edges: .top)
            .sheet(isPresented: $showFeedbackSheet) {
                AppFeedbackView()
            }
        }
    }

    private var hero: some View {
        ZStack {
            LinearGradient(
                colors: [brand, Color(red: 0.24, green: 0.04, blue: 0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack {
                Text("Settings")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 60)
                Spacer()
            }
        }
        .frame(height: 120)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 32, bottomTrailingRadius: 32))
    }

    private func sectionBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            VStack(spacing: 0, content: content)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                iconBadge(icon)
                Text(title)
            }
        }
        .tint(brand)
        .padding()
    }

    private func navRow<Destination: View>(icon: String, title: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 12) {
                iconBadge(icon)
                Text(title).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private func actionRow(icon: String, title: String, tint: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconBadge(icon, tint: tint)
                Text(title).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private func iconBadge(_ icon: String, tint: Color? = nil) -> some View {
        Image(systemName: icon)
            .foregroundStyle(tint ?? brand)
            .frame(width: 28, height: 28)
            .background((tint ?? brand).opacity(0.12))
            .clipShape(Circle())
    }
}

#Preview {
    SettingsView().environmentObject(SupabaseManager.shared)
}
