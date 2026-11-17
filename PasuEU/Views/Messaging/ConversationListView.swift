import SwiftUI

struct ConversationListView: View {
    @EnvironmentObject var supabase: SupabaseManager

    @State private var rows: [ConversationRow] = []
    @State private var subscription: DataSubscription?
    @State private var loadFailed = false
    @State private var hydrateGeneration = 0
    @State private var searchText = ""

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

                            FormFieldRow(icon: "magnifyingglass") {
                                TextField("Search by name", text: $searchText)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }

                            if visibleRows.isEmpty {
                                EmptyStateView(
                                    icon: "magnifyingglass",
                                    title: "No results",
                                    message: "No conversations match \"\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\"."
                                )
                            }

                            ForEach(visibleRows) { row in
                                NavigationLink {
                                    ChatThreadView(conversation: row.conversation, otherUser: row.otherUser)
                                } label: {
                                    ConversationCard(row: row, unreadCount: supabase.unreadByConversation[row.id] ?? 0)
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

    private var visibleRows: [ConversationRow] {
        let sorted = rows.sorted { left, right in
            switch (left.conversation.lastMessageAt, right.conversation.lastMessageAt) {
            case let (leftDate?, rightDate?): return leftDate > rightDate
            case (_?, nil): return true
            default: return false
            }
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sorted }
        return sorted.filter { $0.otherUser.name.localizedCaseInsensitiveContains(query) }
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
