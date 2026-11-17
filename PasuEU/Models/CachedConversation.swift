import Foundation
import SwiftData

@Model
final class CachedConversation {
    @Attribute(.unique) var id: UUID
    var ownerId: UUID
    var participantIdsRaw: String
    var lastMessage: String?
    var lastMessageAt: Date?

    init(_ conversation: Conversation, ownerId: UUID) {
        self.id = conversation.id
        self.ownerId = ownerId
        self.participantIdsRaw = Self.join(conversation.participantIds)
        self.lastMessage = conversation.lastMessage
        self.lastMessageAt = conversation.lastMessageAt
    }

    func update(from conversation: Conversation, ownerId: UUID) {
        self.ownerId = ownerId
        participantIdsRaw = Self.join(conversation.participantIds)
        lastMessage = conversation.lastMessage
        lastMessageAt = conversation.lastMessageAt
    }

    func toConversation() -> Conversation {
        var conversation = Conversation(
            participantIds: participantIdsRaw
                .split(separator: ",")
                .compactMap { UUID(uuidString: String($0)) }
        )
        conversation.id = id
        conversation.lastMessage = lastMessage
        conversation.lastMessageAt = lastMessageAt
        return conversation
    }

    private static func join(_ ids: [UUID]) -> String {
        ids.map(\.uuidString).joined(separator: ",")
    }
}
