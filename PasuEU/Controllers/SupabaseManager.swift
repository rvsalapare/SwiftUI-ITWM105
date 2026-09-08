import Foundation
import Combine
import Supabase
import CoreLocation

final class DataSubscription {
    private let channel: RealtimeChannelV2
    private let client: SupabaseClient

    init(channel: RealtimeChannelV2, client: SupabaseClient) {
        self.channel = channel
        self.client = client
    }

    func remove() {
        Task { await client.removeChannel(channel) }
    }
}

@MainActor
final class SupabaseManager: ObservableObject {

    static let shared = SupabaseManager()

    let client: SupabaseClient

    @Published var currentUser: AppUser?
    @Published var isSignedIn: Bool = false

    private init() {

        client = SupabaseClient(
            supabaseURL: URL(string: "https://YOUR_PROJECT_REF.supabase.co")!,
            supabaseKey: "YOUR_PUBLIC_ANON_KEY"
        )

        Task {
            if let session = try? await client.auth.session {
                isSignedIn = true
                await loadCurrentUser(uid: session.user.id)
            }
        }
    }

    func signInWithDemoAccount(role: UserRole) {
        let demoUser = AppUser(
            id: UUID(uuidString: role == .client
                ? "00000000-0000-0000-0000-0000000000C1"
                : "00000000-0000-0000-0000-0000000000B1")!,
            name: role == .client ? "Juan Dela Cruz" : "Carlo Reyes",
            universityEmail: role == .client
                ? "juan.delacruz@student.msuef.edu.ph"
                : "carlo.reyes@student.msuef.edu.ph",
            studentNumber: role == .buddy ? "22-00123" : nil,
            contactNumber: "0917 123 4567",
            role: role,
            aboutMe: role == .buddy ? "Happy to help with errands around campus!" : nil,
            isOnline: true,
            averageRating: role == .buddy ? 4.8 : 0,
            ratingCount: role == .buddy ? 12 : 0,
            isAvailable: role == .buddy
        )
        currentUser = demoUser
        isSignedIn = true
    }

    func signUp(name: String, universityEmail: String, studentNumber: String?,
                contactNumber: String, password: String, role: UserRole) async throws {
        let result = try await client.auth.signUp(email: universityEmail, password: password)
        let uid = result.user.id

        let user = AppUser(
            id: uid,
            name: name,
            universityEmail: universityEmail,
            studentNumber: studentNumber,
            contactNumber: contactNumber,
            role: role
        )
        try await client.from("users").insert(user).execute()
        currentUser = user
        isSignedIn = true
    }

    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        try await loadCurrentUser(uid: session.user.id)
        isSignedIn = true
    }

    func signOut() throws {
        Task { try? await client.auth.signOut() }
        currentUser = nil
        isSignedIn = false
    }

    func sendPasswordResetOTP(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    func verifyPasswordResetOTP(email: String, code: String) async throws {
        try await client.auth.verifyOTP(email: email, token: code, type: .recovery)
    }

    func updatePassword(_ newPassword: String) async throws {
        try await client.auth.update(user: UserAttributes(password: newPassword))
    }

    @discardableResult
    private func loadCurrentUser(uid: UUID) async -> AppUser? {
        do {
            let user: AppUser = try await client.from("users")
                .select()
                .eq("id", value: uid)
                .single()
                .execute()
                .value
            self.currentUser = user
            return user
        } catch {
            print("Failed to load user: \(error)")
            return nil
        }
    }

    func listenToAvailableBuddies(onChange: @escaping ([AppUser]) -> Void) -> DataSubscription {
        Task { await fetchAvailableBuddies(onChange: onChange) }

        let channel = client.realtimeV2.channel("public:users:buddies")
        Task {
            let changes = channel.postgresChange(AnyAction.self, table: "users")
            await channel.subscribe()
            for await _ in changes {
                await fetchAvailableBuddies(onChange: onChange)
            }
        }
        return DataSubscription(channel: channel, client: client)
    }

    private func fetchAvailableBuddies(onChange: @escaping ([AppUser]) -> Void) async {
        do {
            let buddies: [AppUser] = try await client.from("users")
                .select()
                .eq("role", value: UserRole.buddy.rawValue)
                .eq("is_available", value: true)
                .execute()
                .value
            onChange(buddies)
        } catch {
            onChange([])
        }
    }

    func setAvailability(_ isAvailable: Bool, for uid: UUID) async throws {
        try await client.from("users")
            .update(["is_available": isAvailable])
            .eq("id", value: uid)
            .execute()
    }

    func updateLiveLocation(uid: UUID, coordinate: CLLocationCoordinate2D) async throws {
        try await client.from("users")
            .update([
                "current_latitude": coordinate.latitude,
                "current_longitude": coordinate.longitude
            ])
            .eq("id", value: uid)
            .execute()
    }

    func createRequest(_ request: ServiceRequest) async throws {
        try await client.from("requests").insert(request).execute()
    }

    func listenToMyRequests(clientId: UUID, onChange: @escaping ([ServiceRequest]) -> Void) -> DataSubscription {
        Task { await fetchMyRequests(clientId: clientId, onChange: onChange) }

        let channel = client.realtimeV2.channel("public:requests:mine:\(clientId)")
        Task {
            let changes = channel.postgresChange(AnyAction.self, table: "requests")
            await channel.subscribe()
            for await _ in changes {
                await fetchMyRequests(clientId: clientId, onChange: onChange)
            }
        }
        return DataSubscription(channel: channel, client: client)
    }

    private func fetchMyRequests(clientId: UUID, onChange: @escaping ([ServiceRequest]) -> Void) async {
        do {
            let requests: [ServiceRequest] = try await client.from("requests")
                .select()
                .eq("client_id", value: clientId)
                .order("created_at", ascending: false)
                .execute()
                .value
            onChange(requests)
        } catch {
            onChange([])
        }
    }

    func listenToOpenRequests(onChange: @escaping ([ServiceRequest]) -> Void) -> DataSubscription {
        Task { await fetchOpenRequests(onChange: onChange) }

        let channel = client.realtimeV2.channel("public:requests:open")
        Task {
            let changes = channel.postgresChange(AnyAction.self, table: "requests")
            await channel.subscribe()
            for await _ in changes {
                await fetchOpenRequests(onChange: onChange)
            }
        }
        return DataSubscription(channel: channel, client: client)
    }

    private func fetchOpenRequests(onChange: @escaping ([ServiceRequest]) -> Void) async {
        do {
            let requests: [ServiceRequest] = try await client.from("requests")
                .select()
                .eq("status", value: RequestStatus.pending.rawValue)
                .order("created_at", ascending: false)
                .execute()
                .value
            onChange(requests)
        } catch {
            onChange([])
        }
    }

    func acceptRequest(_ requestId: UUID, buddyId: UUID) async throws {
        try await client.from("requests")
            .update(["buddy_id": buddyId.uuidString, "status": RequestStatus.accepted.rawValue])
            .eq("id", value: requestId)
            .execute()
    }

    func updateRequestStatus(_ requestId: UUID, status: RequestStatus) async throws {
        var payload: [String: String] = ["status": status.rawValue]
        if status == .completed {
            payload["completed_at"] = ISO8601DateFormatter().string(from: Date())
        }
        try await client.from("requests")
            .update(payload)
            .eq("id", value: requestId)
            .execute()
    }

    func listenToBuddyLocation(buddyId: UUID, onChange: @escaping (CLLocationCoordinate2D?) -> Void) -> DataSubscription {
        let channel = client.realtimeV2.channel("public:users:location:\(buddyId)")
        Task {
            let changes = channel.postgresChange(UpdateAction.self, table: "users")
            await channel.subscribe()
            for await change in changes {
                guard let record = try? change.decodeRecord(as: AppUser.self, decoder: JSONDecoder()),
                      record.id == buddyId,
                      let lat = record.currentLatitude, let lng = record.currentLongitude else { continue }
                onChange(CLLocationCoordinate2D(latitude: lat, longitude: lng))
            }
        }
        return DataSubscription(channel: channel, client: client)
    }

    func uploadFile(data: Data, fileName: String, requestId: UUID) async throws -> URL {
        let path = "\(requestId.uuidString)/\(fileName)"
        try await client.storage.from("request-files").upload(path: path, file: data)
        return try client.storage.from("request-files").getPublicURL(path: path)
    }

    func downloadFile(path: String) async throws -> Data {
        try await client.storage.from("request-files").download(path: path)
    }

    func submitRating(_ rating: Rating) async throws {
        try await client.from("ratings").insert(rating).execute()
    }

    func sendMessage(conversationId: UUID, message: Message) async throws {
        try await client.from("messages").insert(message).execute()
        try await client.from("conversations")
            .update([
                "last_message": message.text,
                "last_message_at": ISO8601DateFormatter().string(from: message.sentAt)
            ])
            .eq("id", value: conversationId)
            .execute()
    }

    func listenToMessages(conversationId: UUID, onChange: @escaping ([Message]) -> Void) -> DataSubscription {
        Task { await fetchMessages(conversationId: conversationId, onChange: onChange) }

        let channel = client.realtimeV2.channel("public:messages:\(conversationId)")
        Task {
            let changes = channel.postgresChange(InsertAction.self, table: "messages")
            await channel.subscribe()
            for await _ in changes {
                await fetchMessages(conversationId: conversationId, onChange: onChange)
            }
        }
        return DataSubscription(channel: channel, client: client)
    }

    private func fetchMessages(conversationId: UUID, onChange: @escaping ([Message]) -> Void) async {
        do {
            let messages: [Message] = try await client.from("messages")
                .select()
                .eq("conversation_id", value: conversationId)
                .order("sent_at", ascending: true)
                .execute()
                .value
            onChange(messages)
        } catch {
            onChange([])
        }
    }

    func getOrCreateConversation(between userA: UUID, and userB: UUID) async throws -> UUID {
        let existing: [Conversation] = try await client.from("conversations")
            .select()
            .contains("participant_ids", value: [userA.uuidString])
            .execute()
            .value

        if let match = existing.first(where: { $0.participantIds.contains(userB) }) {
            return match.id
        }

        let conversation = Conversation(participantIds: [userA, userB])
        try await client.from("conversations").insert(conversation).execute()
        return conversation.id
    }

    func listenToConversations(for userId: UUID, onChange: @escaping ([Conversation]) -> Void) -> DataSubscription {
        Task { await fetchConversations(userId: userId, onChange: onChange) }

        let channel = client.realtimeV2.channel("public:conversations:\(userId)")
        Task {
            let changes = channel.postgresChange(AnyAction.self, table: "conversations")
            await channel.subscribe()
            for await _ in changes {
                await fetchConversations(userId: userId, onChange: onChange)
            }
        }
        return DataSubscription(channel: channel, client: client)
    }

    private func fetchConversations(userId: UUID, onChange: @escaping ([Conversation]) -> Void) async {
        do {
            let conversations: [Conversation] = try await client.from("conversations")
                .select()
                .contains("participant_ids", value: [userId.uuidString])
                .order("last_message_at", ascending: false)
                .execute()
                .value
            onChange(conversations)
        } catch {
            onChange([])
        }
    }

    func fetchUser(uid: UUID) async throws -> AppUser {
        try await client.from("users").select().eq("id", value: uid).single().execute().value
    }

    func blockUser(blockerId: UUID, blockedId: UUID) async throws {
        try await client.from("blocked_users")
            .insert(["blocker_id": blockerId.uuidString, "blocked_id": blockedId.uuidString])
            .execute()
    }

    func isBlocked(blockerId: UUID, blockedId: UUID) async throws -> Bool {
        let rows: [[String: String]] = try await client.from("blocked_users")
            .select()
            .eq("blocker_id", value: blockerId)
            .eq("blocked_id", value: blockedId)
            .execute()
            .value
        return !rows.isEmpty
    }

    func reportUser(reporterId: UUID, reportedId: UUID, reason: String) async throws {
        try await client.from("reports")
            .insert([
                "reporter_id": reporterId.uuidString,
                "reported_id": reportedId.uuidString,
                "reason": reason
            ])
            .execute()
    }

    func updateProfile(uid: UUID, name: String, contactNumber: String,
                        aboutMe: String, profileIconName: String) async throws {
        try await client.from("users")
            .update([
                "name": name,
                "contact_number": contactNumber,
                "about_me": aboutMe,
                "profile_icon_name": profileIconName
            ])
            .eq("id", value: uid)
            .execute()
    }

    func getOrCreateConversation(userA: UUID, userB: UUID) async throws -> Conversation {
        let existing: [Conversation] = try await client.from("conversations")
            .select()
            .contains("participant_ids", value: [userA.uuidString, userB.uuidString])
            .execute()
            .value
        if let match = existing.first(where: { $0.participantIds.count == 2 }) {
            return match
        }
        let new = Conversation(participantIds: [userA, userB])
        try await client.from("conversations").insert(new).execute()
        return new
    }

    func listenToConversations(userId: UUID, onChange: @escaping ([Conversation]) -> Void) -> DataSubscription {
        Task { await fetchConversations(userId: userId, onChange: onChange) }

        let channel = client.realtimeV2.channel("public:conversations:\(userId)")
        Task {
            let changes = channel.postgresChange(AnyAction.self, table: "conversations")
            await channel.subscribe()
            for await _ in changes {
                await fetchConversations(userId: userId, onChange: onChange)
            }
        }
        return DataSubscription(channel: channel, client: client)
    }

    private func fetchConversations(userId: UUID, onChange: @escaping ([Conversation]) -> Void) async {
        do {
            let conversations: [Conversation] = try await client.from("conversations")
                .select()
                .contains("participant_ids", value: [userId.uuidString])
                .order("last_message_at", ascending: false)
                .execute()
                .value
            onChange(conversations)
        } catch {
            onChange([])
        }
    }

    func fetchUser(id: UUID) async throws -> AppUser {
        try await client.from("users")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    func blockUser(blockerId: UUID, blockedId: UUID) async throws {
        try await client.from("blocks")
            .insert(["blocker_id": blockerId.uuidString, "blocked_id": blockedId.uuidString])
            .execute()
    }

    func reportUser(reporterId: UUID, reportedId: UUID, reason: String) async throws {
        try await client.from("reports")
            .insert([
                "reporter_id": reporterId.uuidString,
                "reported_id": reportedId.uuidString,
                "reason": reason
            ])
            .execute()
    }

    func submitFeedback(_ feedback: AppFeedback) async throws {
        try await client.from("feedback").insert(feedback).execute()
    }
}
