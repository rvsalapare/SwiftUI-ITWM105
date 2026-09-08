import SwiftUI

struct MessageBuddyLink: View {
    @EnvironmentObject var supabase: SupabaseManager
    let buddyId: UUID

    @State private var conversation: Conversation?
    @State private var otherUser: AppUser?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let conversation, let otherUser {
                ChatThreadView(conversation: conversation, otherUser: otherUser)
            } else if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).padding()
            } else {
                ProgressView().task { await load() }
            }
        }
    }

    private func load() async {
        guard let uid = supabase.currentUser?.id else { return }
        do {
            async let conversationTask = supabase.getOrCreateConversation(userA: uid, userB: buddyId)
            async let userTask = supabase.fetchUser(id: buddyId)
            let (fetchedConversation, fetchedUser) = try await (conversationTask, userTask)
            conversation = fetchedConversation
            otherUser = fetchedUser
        } catch {
            errorMessage = "Couldn't open this conversation."
        }
    }
}
