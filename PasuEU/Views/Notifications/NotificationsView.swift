import SwiftUI

private struct NotificationGroup: Identifiable {
    let id: String
    let title: String
    var items: [AppNotification]
}

struct NotificationsView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var openedRequest: ServiceRequest?
    @State private var showRequest = false
    @State private var chatUserId: UUID?
    @State private var showChat = false

    private var groups: [NotificationGroup] {
        let calendar = Calendar.current
        var result: [NotificationGroup] = []
        for notification in supabase.notifications.sorted(by: { $0.createdAt > $1.createdAt }) {
            let (key, title) = groupInfo(for: notification.createdAt, calendar: calendar)
            if let index = result.firstIndex(where: { $0.id == key }) {
                result[index].items.append(notification)
            } else {
                result.append(NotificationGroup(id: key, title: title, items: [notification]))
            }
        }
        return result
    }

    private func groupInfo(for date: Date, calendar: Calendar) -> (String, String) {
        if calendar.isDateInToday(date) { return ("today", "Today") }
        if calendar.isDateInYesterday(date) { return ("yesterday", "Yesterday") }
        return ("earlier", "Earlier")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader("Notifications")
                    .overlay(alignment: .topLeading) {
                        backButton
                    }

                VStack(alignment: .leading, spacing: Theme.spacingXLarge) {
                    if supabase.notifications.isEmpty {
                        EmptyStateView(
                            icon: "bell.slash",
                            title: "No notifications yet",
                            message: "Updates about your requests and messages will show up here."
                        )
                    } else {
                        markAllRow

                        ForEach(groups) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.title.uppercased())
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 4)

                                ForEach(group.items) { notification in
                                    Button {
                                        Task { await open(notification) }
                                    } label: {
                                        NotificationRow(notification: notification)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(Theme.spacingXLarge)
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showRequest) {
            if let openedRequest {
                RequestDetailView(request: openedRequest)
            }
        }
        .navigationDestination(isPresented: $showChat) {
            if let chatUserId {
                MessageBuddyLink(buddyId: chatUserId)
            }
        }
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.18))
                .clipShape(Circle())
        }
        .padding(.top, 64)
        .padding(.leading, Theme.spacingXLarge)
        .accessibilityLabel("Back")
    }

    private var markAllRow: some View {
        HStack {
            Spacer()
            Button {
                guard let uid = supabase.currentUser?.id else { return }
                Task { await supabase.markAllNotificationsRead(userId: uid) }
            } label: {
                Label("Mark all as read", systemImage: "checkmark.circle")
                    .font(.subheadline.bold())
            }
            .foregroundStyle(Theme.brand)
            .disabled(supabase.unreadNotificationCount == 0)
        }
    }

    private func open(_ notification: AppNotification) async {
        await supabase.markNotificationRead(id: notification.id)

        if let conversationId = notification.conversationId, notification.kind == .message {
            await openChat(conversationId: conversationId)
        } else if let requestId = notification.requestId {
            await openRequest(requestId: requestId)
        } else if let conversationId = notification.conversationId {
            await openChat(conversationId: conversationId)
        }
    }

    private func openRequest(requestId: UUID) async {
        guard let request = try? await supabase.loadRequest(id: requestId) else { return }
        openedRequest = request
        showRequest = true
    }

    private func openChat(conversationId: UUID) async {
        guard let me = supabase.currentUser?.id,
              let conversation = try? await supabase.loadConversation(id: conversationId),
              let otherId = conversation.participantIds.first(where: { $0 != me }) else { return }
        chatUserId = otherId
        showChat = true
    }
}

#Preview {
    NavigationStack {
        NotificationsView().environmentObject(SupabaseManager.shared)
    }
}
