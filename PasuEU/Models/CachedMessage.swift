import Foundation
import SwiftData

@Model
final class CachedMessage {
    @Attribute(.unique) var id: UUID
    var conversationId: UUID
    var senderId: UUID
    var text: String
    var sentAt: Date
    var readAt: Date?

    init(_ message: Message) {
        self.id = message.id
        self.conversationId = message.conversationId
        self.senderId = message.senderId
        self.text = message.text
        self.sentAt = message.sentAt
        self.readAt = message.readAt
    }

    func update(from message: Message) {
        conversationId = message.conversationId
        senderId = message.senderId
        text = message.text
        sentAt = message.sentAt
        readAt = message.readAt
    }

    func toMessage() -> Message {
        var message = Message(conversationId: conversationId, senderId: senderId, text: text)
        message.id = id
        message.sentAt = sentAt
        message.readAt = readAt
        return message
    }
}
