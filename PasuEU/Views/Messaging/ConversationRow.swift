import Foundation

struct ConversationRow: Identifiable {
    let conversation: Conversation
    let otherUser: AppUser
    let unreadCount: Int
    var id: UUID { conversation.id }
}
