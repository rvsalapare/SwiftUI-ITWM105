import SwiftUI

struct ConversationListView: View {
    @EnvironmentObject var supabase: SupabaseManager

    @State private var rows: [ConversationRow] = []
    @State private var subscription: DataSubscription?
    @State private var loadFailed = false
    @State private var hydrateGeneration = 0

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
                            if loadFailed {
                                OfflineNotice()
                            }

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

            let unreadCount = supabase.unreadByConversation[row.id] ?? 0
            let isUnread = unreadCount > 0

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
                UnreadBadge(count: unreadCount)
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
        if rows.isEmpty {
            rows = cachedRows(currentUserId: uid)
        }
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

    private func cachedRows(currentUserId: UUID) -> [ConversationRow] {
        LocalStore.shared.loadConversations(ownerId: currentUserId).compactMap { conversation in
            guard let otherId = conversation.participantIds.first(where: { $0 != currentUserId }),
                  let otherUser = LocalStore.shared.loadUser(id: otherId) else { return nil }
            return ConversationRow(conversation: conversation, otherUser: otherUser)
        }
    }

    private func hydrate(_ conversations: [Conversation], currentUserId: UUID) async {
        hydrateGeneration += 1
        let generation = hydrateGeneration
        var result: [ConversationRow] = []
        for conversation in conversations {
            guard let otherId = conversation.participantIds.first(where: { $0 != currentUserId }) else { continue }
            let fetched = try? await supabase.fetchUser(id: otherId)
            guard let otherUser = fetched ?? LocalStore.shared.loadUser(id: otherId) else { continue }
            result.append(ConversationRow(conversation: conversation, otherUser: otherUser))
        }
        guard generation == hydrateGeneration else { return }
        rows = result
        loadFailed = false
    }
}

#Preview {
    ConversationListView().environmentObject(SupabaseManager.shared)
}
