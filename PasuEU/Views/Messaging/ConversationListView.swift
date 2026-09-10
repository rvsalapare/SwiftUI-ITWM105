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

    private let brand = Color(red: 0.42, green: 0.08, blue: 0.1)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero

                    VStack(spacing: 12) {
                        if rows.isEmpty {
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

    private var hero: some View {
        ZStack {
            LinearGradient(
                colors: [brand, Color(red: 0.24, green: 0.04, blue: 0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack {
                Text("Messages")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 60)
                Spacer()
            }
        }
        .frame(height: 120)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 32, bottomTrailingRadius: 32))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "message")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No messages yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Start a conversation from an active request to see it here.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func conversationRow(_ row: ConversationRow) -> some View {
        HStack(spacing: 12) {
            Image(systemName: row.otherUser.profileIconName)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(brand)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(row.otherUser.name).font(.subheadline.bold())
                Text(row.conversation.lastMessage ?? "Say hello!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
