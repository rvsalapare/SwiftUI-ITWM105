import Foundation

enum UserRole: String, Codable {
    case client
    case buddy
}

struct AppUser: Identifiable, Codable {
    var id: UUID
    var name: String
    var universityEmail: String
    var studentNumber: String?
    var contactNumber: String
    var role: UserRole
    var aboutMe: String?
    var profileIconName: String = "person.crop.circle.fill"
    var isOnline: Bool = false
    var averageRating: Double = 0.0
    var ratingCount: Int = 0
    var createdAt: Date = Date()

    var isAvailable: Bool = false
    var currentLatitude: Double?
    var currentLongitude: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, role
        case universityEmail = "university_email"
        case studentNumber = "student_number"
        case contactNumber = "contact_number"
        case aboutMe = "about_me"
        case profileIconName = "profile_icon_name"
        case isOnline = "is_online"
        case averageRating = "average_rating"
        case ratingCount = "rating_count"
        case createdAt = "created_at"
        case isAvailable = "is_available"
        case currentLatitude = "current_latitude"
        case currentLongitude = "current_longitude"
    }
}

enum ServiceType: String, Codable, CaseIterable {
    case pabili
    case pahatid
    case paprint

    var displayName: String {
        switch self {
        case .pabili: return "Pabili"
        case .pahatid: return "Pahatid"
        case .paprint: return "Paprint"
        }
    }

    var iconName: String {
        switch self {
        case .pabili: return "cart.fill"
        case .pahatid: return "shippingbox.fill"
        case .paprint: return "printer.fill"
        }
    }
}

enum RequestStatus: String, Codable {
    case pending
    case accepted
    case inProgress = "in_progress"
    case completed
    case cancelled
}

enum PaymentMethod: String, Codable {
    case cash
    case gcash
    case card
}

struct ServiceRequest: Identifiable, Codable {
    var id: UUID = UUID()
    var clientId: UUID
    var buddyId: UUID?
    var type: ServiceType
    var isUrgent: Bool = false

    var meetingPlace: String
    var destination: String?
    var note: String?
    var status: RequestStatus = .pending

    var itemDescription: String?
    var recipientName: String?

    var fileURL: String?
    var fileName: String?
    var pages: Int?
    var copies: Int?
    var pageSize: String?
    var colorOption: String?

    var paymentMethod: PaymentMethod?
    var serviceFee: Double = 0.0
    var deliveryFee: Double = 0.0
    var totalAmount: Double = 0.0

    var buddyLatitude: Double?
    var buddyLongitude: Double?

    var createdAt: Date = Date()
    var completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, type, status, note, pages, copies
        case clientId = "client_id"
        case buddyId = "buddy_id"
        case isUrgent = "is_urgent"
        case meetingPlace = "meeting_place"
        case destination
        case itemDescription = "item_description"
        case recipientName = "recipient_name"
        case fileURL = "file_url"
        case fileName = "file_name"
        case pageSize = "page_size"
        case colorOption = "color_option"
        case paymentMethod = "payment_method"
        case serviceFee = "service_fee"
        case deliveryFee = "delivery_fee"
        case totalAmount = "total_amount"
        case buddyLatitude = "buddy_latitude"
        case buddyLongitude = "buddy_longitude"
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }
}

struct Rating: Identifiable, Codable {
    var id: UUID = UUID()
    var requestId: UUID
    var raterId: UUID
    var ratedUserId: UUID
    var stars: Int
    var comment: String?
    var createdAt: Date = Date()

    enum CodingKeys: String, CodingKey {
        case id, stars, comment
        case requestId = "request_id"
        case raterId = "rater_id"
        case ratedUserId = "rated_user_id"
        case createdAt = "created_at"
    }
}

struct Conversation: Identifiable, Codable {
    var id: UUID = UUID()
    var participantIds: [UUID]
    var lastMessage: String?
    var lastMessageAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case participantIds = "participant_ids"
        case lastMessage = "last_message"
        case lastMessageAt = "last_message_at"
    }
}

struct Message: Identifiable, Codable {
    var id: UUID = UUID()
    var conversationId: UUID
    var senderId: UUID
    var text: String
    var sentAt: Date = Date()

    enum CodingKeys: String, CodingKey {
        case id, text
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case sentAt = "sent_at"
    }
}

struct AppFeedback: Identifiable, Codable {
    var id: UUID = UUID()
    var userId: UUID
    var stars: Int
    var suggestion: String?
    var createdAt: Date = Date()

    enum CodingKeys: String, CodingKey {
        case id, stars, suggestion
        case userId = "user_id"
        case createdAt = "created_at"
    }
}
