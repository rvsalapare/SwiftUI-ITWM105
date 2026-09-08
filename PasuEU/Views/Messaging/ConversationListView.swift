import SwiftUI

private struct ConversationRow: Identifiable {
    let conversation: Conversation
    let otherUser: AppUser
    var id: UUID { conversation.id }
}

struct ConversationListView: View {
    @EnvironmentObject var supabase: SupabaseManager

    @State private var rows: [ConversationRow] = []
    @State private var subscription: DataSubscription?

    var body: some View {
        NavigationStack {
            List(rows) { row in
                NavigationLink {
                    ChatThreadView(conversation: row.conversation, otherUser: row.otherUser)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: row.otherUser.profileIconName)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color(red: 0.42, green: 0.08, blue: 0.1))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.otherUser.name).font(.subheadline.bold())
                            Text(row.conversation.lastMessage ?? "Say hello!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                }
            }
            .overlay {
                if rows.isEmpty {
                    ContentUnavailableView("No messages yet", systemImage: "message")
                }
            }
            .navigationTitle("Messages")
            .task { attachListener() }
            .onDisappear { subscription?.remove() }
        }
    }

    private func attachListener() {
        guard let uid = supabase.currentUser?.id else { return }
        subscription = supabase.listenToConversations(userId: uid) { conversations in
            Task { await hydrate(conversations, currentUserId: uid) }
        }
    }

    private func hydrate(_ conversations: [Conversation], currentUserId: UUID) async {
        var result: [ConversationRow] = []
        for conversation in conversations {
            guard let otherId = conversation.participantIds.first(where: { $0 != currentUserId }),
                  let otherUser = try? await supabase.fetchUser(id: otherId) else { continue }
            result.append(ConversationRow(conversation: conversation, otherUser: otherUser))
        }
        rows = result
    }
}

#Preview {
    ConversationListView().environmentObject(SupabaseManager.shared)
}
