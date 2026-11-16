import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State private var notificationsOn = true
    @State private var showFeedbackSheet = false
    @State private var showReportIssueSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ScreenHeader("Settings")

                    VStack(alignment: .leading, spacing: 24) {
                        sectionBlock(title: "General") {
                            toggleRow(icon: "bell.fill", title: "Notifications", isOn: $notificationsOn)
                            Divider().padding(.leading, 60)
                            navRow(icon: "info.circle.fill", title: "About") {
                                AboutView()
                            }
                            Divider().padding(.leading, 60)
                            navRow(icon: "questionmark.circle.fill", title: "Help") {
                                HelpView()
                            }
                        }

                        sectionBlock(title: "Feedback") {
                            actionRow(icon: "exclamationmark.bubble.fill", title: "Report an issue", tint: .orange) {
                                showReportIssueSheet = true
                            }
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
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
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
            .sheet(isPresented: $showReportIssueSheet) {
                ReportIssueView()
            }
        }
    }

    private func sectionBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            CardContainer(alignment: .center, spacing: 0, padding: 0, content: content)
        }
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                iconBadge(icon)
                Text(title)
            }
        }
        .tint(Theme.brand)
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
            .foregroundStyle(tint ?? Theme.brand)
            .frame(width: 28, height: 28)
            .background((tint ?? Theme.brand).opacity(0.12))
            .clipShape(Circle())
    }
}

#Preview {
    SettingsView().environmentObject(SupabaseManager.shared)
}
