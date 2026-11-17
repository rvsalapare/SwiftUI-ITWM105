import SwiftUI

struct AppNotification: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var type: String
    var title: String
    var body: String?
    var requestId: UUID?
    var conversationId: UUID?
    var readAt: Date?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, type, title, body
        case userId = "user_id"
        case requestId = "request_id"
        case conversationId = "conversation_id"
        case readAt = "read_at"
        case createdAt = "created_at"
    }

    enum Kind {
        case newRequest
        case statusUpdate
        case message
        case rating
        case other

        var symbol: String {
            switch self {
            case .newRequest: return "plus.circle.fill"
            case .statusUpdate: return "arrow.triangle.2.circlepath"
            case .message: return "message.fill"
            case .rating: return "star.fill"
            case .other: return "bell.fill"
            }
        }

        var tint: Color {
            switch self {
            case .newRequest: return Theme.brand
            case .statusUpdate: return .blue
            case .message: return .green
            case .rating: return .orange
            case .other: return .gray
            }
        }
    }

    var isRead: Bool { readAt != nil }

    var kind: Kind {
        let value = type.lowercased()
        if value.contains("rating") { return .rating }
        if value.contains("message") { return .message }
        if value.contains("new_request") || value == "request" { return .newRequest }
        if value.contains("status") || value.contains("accepted") || value.contains("progress")
            || value.contains("completed") || value.contains("cancel") {
            return .statusUpdate
        }
        return .other
    }
}

extension AppNotification {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "other"
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        body = try container.decodeIfPresent(String.self, forKey: .body)
        requestId = try container.decodeIfPresent(UUID.self, forKey: .requestId)
        conversationId = try container.decodeIfPresent(UUID.self, forKey: .conversationId)
        readAt = try container.decodeIfPresent(Date.self, forKey: .readAt)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}
