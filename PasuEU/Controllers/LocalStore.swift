import Foundation
import SwiftData

@MainActor
final class LocalStore {
    enum Scope {
        case all
        case pending
        case completedJobs

        func includes(_ row: CachedRequest, ownerId: UUID) -> Bool {
            switch self {
            case .all:
                return true
            case .pending:
                return row.statusRaw == RequestStatus.pending.rawValue
            case .completedJobs:
                return row.statusRaw == RequestStatus.completed.rawValue && row.buddyId == ownerId
            }
        }
    }

    static let shared = LocalStore()

    private var context: ModelContext?

    private init() {}

    func configure(context: ModelContext) {
        self.context = context
    }

    func saveRequests(_ requests: [ServiceRequest], ownerId: UUID, scope: Scope = .all) {
        guard let context else { return }
        let existing = (try? context.fetch(FetchDescriptor<CachedRequest>())) ?? []
        var rowsById: [UUID: CachedRequest] = [:]
        for row in existing {
            rowsById[row.id] = row
        }

        var incomingIds = Set<UUID>()
        for request in requests {
            incomingIds.insert(request.id)
            if let row = rowsById[request.id] {
                row.update(from: request, ownerId: ownerId)
            } else {
                context.insert(CachedRequest(request, ownerId: ownerId))
            }
        }

        for row in existing where row.ownerId == ownerId
            && !incomingIds.contains(row.id)
            && scope.includes(row, ownerId: ownerId) {
            context.delete(row)
        }

        try? context.save()
    }

    func loadRequests(ownerId: UUID) -> [ServiceRequest] {
        guard let context else { return [] }
        let owner = ownerId
        let descriptor = FetchDescriptor<CachedRequest>(
            predicate: #Predicate { $0.ownerId == owner },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let rows = (try? context.fetch(descriptor)) ?? []
        return rows.map { $0.toRequest() }
    }

    func saveUser(_ user: AppUser) {
        guard let context else { return }
        let userId = user.id
        let descriptor = FetchDescriptor<CachedUser>(predicate: #Predicate { $0.id == userId })
        if let row = (try? context.fetch(descriptor))?.first {
            row.update(from: user)
        } else {
            context.insert(CachedUser(user))
        }
        try? context.save()
    }

    func loadUser(id: UUID) -> AppUser? {
        guard let context else { return nil }
        let userId = id
        let descriptor = FetchDescriptor<CachedUser>(predicate: #Predicate { $0.id == userId })
        return (try? context.fetch(descriptor))?.first?.toUser()
    }

    func saveConversations(_ conversations: [Conversation], ownerId: UUID) {
        guard let context else { return }
        let existing = (try? context.fetch(FetchDescriptor<CachedConversation>())) ?? []
        var rowsById: [UUID: CachedConversation] = [:]
        for row in existing {
            rowsById[row.id] = row
        }

        var incomingIds = Set<UUID>()
        for conversation in conversations {
            incomingIds.insert(conversation.id)
            if let row = rowsById[conversation.id] {
                row.update(from: conversation, ownerId: ownerId)
            } else {
                context.insert(CachedConversation(conversation, ownerId: ownerId))
            }
        }

        for row in existing where row.ownerId == ownerId && !incomingIds.contains(row.id) {
            context.delete(row)
        }

        try? context.save()
    }

    func loadConversations(ownerId: UUID) -> [Conversation] {
        guard let context else { return [] }
        let owner = ownerId
        let descriptor = FetchDescriptor<CachedConversation>(predicate: #Predicate { $0.ownerId == owner })
        let rows = (try? context.fetch(descriptor)) ?? []
        return rows
            .sorted { ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast) }
            .map { $0.toConversation() }
    }

    func saveMessages(_ messages: [Message], conversationId: UUID) {
        guard let context else { return }
        let thread = conversationId
        let descriptor = FetchDescriptor<CachedMessage>(predicate: #Predicate { $0.conversationId == thread })
        let existing = (try? context.fetch(descriptor)) ?? []
        var rowsById: [UUID: CachedMessage] = [:]
        for row in existing {
            rowsById[row.id] = row
        }

        var incomingIds = Set<UUID>()
        for message in messages {
            incomingIds.insert(message.id)
            if let row = rowsById[message.id] {
                row.update(from: message)
            } else {
                context.insert(CachedMessage(message))
            }
        }

        for row in existing where !incomingIds.contains(row.id) {
            context.delete(row)
        }

        try? context.save()
    }

    func loadMessages(conversationId: UUID) -> [Message] {
        guard let context else { return [] }
        let thread = conversationId
        let descriptor = FetchDescriptor<CachedMessage>(
            predicate: #Predicate { $0.conversationId == thread },
            sortBy: [SortDescriptor(\.sentAt)]
        )
        let rows = (try? context.fetch(descriptor)) ?? []
        return rows.map { $0.toMessage() }
    }

    func clearAll() {
        guard let context else { return }
        try? context.delete(model: CachedRequest.self)
        try? context.delete(model: CachedUser.self)
        try? context.delete(model: CachedConversation.self)
        try? context.delete(model: CachedMessage.self)
        try? context.save()
    }
}
