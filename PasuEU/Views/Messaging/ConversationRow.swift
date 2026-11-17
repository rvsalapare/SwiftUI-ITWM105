import Foundation

struct ConversationRow: Identifiable {
    let conversation: Conversation
    let otherUser: AppUser
    var id: UUID { conversation.id }
}
