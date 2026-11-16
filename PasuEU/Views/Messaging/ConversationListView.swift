import SwiftUI

struct ConversationListView: View {
    @EnvironmentObject var supabase: SupabaseManager

    @State private var rows: [ConversationRow] = []
    @State private var subscription: DataSubscription?
    @State private var loadFailed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ScreenHeader("Messages")

                    VStack(spacing: 12) {
                        if rows.isEmpty && loadFailed {
                            EmptyStateView(
                                icon: "wifi.exclamationmark",
                                title: "Couldn't load your messages",
                                message: "Check your connection and try again.",
                                retry: { attachListener() }
                            )
                        } else if rows.isEmpty {
                            emptyState
                        } else {
                            ForEach(rows) { row in
                                NavigationLink {
                                    ChatThreadView(conversation: row.conversation, otherUser: row.otherUser)
                                } label: {
                                    conversationRow(row)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(24)
                    .padding(.top, 8)
                }
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea(edges: .top)
            .task { attachListener() }
            .onDisappear { subscription?.remove() }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "message",
            title: "No messages yet",
            message: "Start a conversation from an active request to see it here."
        )
    }

    private func conversationRow(_ row: ConversationRow) -> some View {
        HStack(spacing: 12) {
            Image(systemName: row.otherUser.profileIconName)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Theme.brand)
                .clipShape(Circle())

            let isUnread = row.unreadCount > 0

            VStack(alignment: .leading, spacing: 2) {
                Text(row.otherUser.name)
                    .font(.subheadline.weight(isUnread ? .bold : .semibold))
                Text(row.conversation.lastMessage ?? "Say hello!")
                    .font(.caption.weight(isUnread ? .bold : .regular))
                    .foregroundStyle(isUnread ? .primary : .secondary)
                    .lineLimit(1)
            }
            Spacer()
            if isUnread {
                Text(row.unreadCount > 99 ? "99+" : "\(row.unreadCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .frame(minWidth: 20)
                    .background(Theme.brand)
                    .clipShape(Capsule())
                    .accessibilityLabel("\(row.unreadCount) unread")
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.fieldRadius))
    }

    private func attachListener() {
        guard let uid = supabase.currentUser?.id else { return }
        subscription?.remove()
        loadFailed = false
        subscription = supabase.listenToConversations(
            userId: uid,
            onChange: { conversations in
                Task { await hydrate(conversations, currentUserId: uid) }
            },
            onError: { _ in
                loadFailed = true
            }
        )
    }

    private func hydrate(_ conversations: [Conversation], currentUserId: UUID) async {
        let counts = (try? await supabase.unreadCounts(
            userId: currentUserId,
            conversationIds: conversations.map(\.id)
        )) ?? [:]
        var result: [ConversationRow] = []
        for conversation in conversations {
            guard let otherId = conversation.participantIds.first(where: { $0 != currentUserId }),
                  let otherUser = try? await supabase.fetchUser(id: otherId) else { continue }
            result.append(ConversationRow(
                conversation: conversation,
                otherUser: otherUser,
                unreadCount: counts[conversation.id] ?? 0
            ))
        }
        rows = result
        loadFailed = false
    }
}

#Preview {
    ConversationListView().environmentObject(SupabaseManager.shared)
}
