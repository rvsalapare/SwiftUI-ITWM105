import Foundation

struct ChatEntry: Identifiable {
    let message: Message
    let separatorDate: Date?
    let isFirstInGroup: Bool
    let isLastInGroup: Bool

    var id: UUID { message.id }

    static func build(from messages: [Message]) -> [ChatEntry] {
        let calendar = Calendar.current
        var entries: [ChatEntry] = []

        for (index, message) in messages.enumerated() {
            let previous = index > 0 ? messages[index - 1] : nil
            let next = index < messages.count - 1 ? messages[index + 1] : nil

            let startsNewDay = previous.map { !calendar.isDate($0.sentAt, inSameDayAs: message.sentAt) } ?? true
            let continuesPrevious = !startsNewDay && previous?.senderId == message.senderId
            let continuesIntoNext = next.map {
                calendar.isDate($0.sentAt, inSameDayAs: message.sentAt) && $0.senderId == message.senderId
            } ?? false

            entries.append(ChatEntry(
                message: message,
                separatorDate: startsNewDay ? message.sentAt : nil,
                isFirstInGroup: !continuesPrevious,
                isLastInGroup: !continuesIntoNext
            ))
        }

        return entries
    }
}
