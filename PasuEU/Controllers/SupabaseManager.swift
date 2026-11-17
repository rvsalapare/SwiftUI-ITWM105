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

struct RequestUpdateFailed: LocalizedError {
    var errorDescription: String? {
        "That update didn't work"
    }
}

@MainActor
final class SupabaseManager: ObservableObject {

    static let shared = SupabaseManager()

    let client: SupabaseClient

    @Published var currentUser: AppUser?
    @Published var isSignedIn: Bool = false
    @Published private(set) var unreadMessageCount = 0
    @Published private(set) var unreadByConversation: [UUID: Int] = [:]
    @Published private(set) var notifications: [AppNotification] = []

    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    private var notificationUserId: UUID?
    private var notificationSession: UUID?
    private var notificationSubscription: DataSubscription?
    private var notificationRefreshTask: Task<Void, Never>?
    private var notificationGeneration = 0

    private var unreadUserId: UUID?
    private var unreadSession: UUID?
    private var unreadSubscriptions: [DataSubscription] = []
    private var unreadRefreshTask: Task<Void, Never>?
    private var unreadRefreshGeneration = 0

    private init() {

        client = SupabaseClient(
            supabaseURL: URL(string: "https://orjusbhjpkfwjkzffgfj.supabase.co")!,
            supabaseKey: "sb_publishable_-cTkpoUjOWJA2a6Sav2oWQ_nBg1RJSM"
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
            name: role == .client ? "Aiah Arceta" : "Mikha Lim",
            universityEmail: role == .client
                ? "aiah@student.mseuf.edu.ph"
                : "mikha@student.mseuf.edu.ph",
            studentNumber: role == .buddy ? "22-00123" : nil,
            contactNumber: "0917 123 4567",
            role: role,
            aboutMe: role == .buddy ? "Happy to help with errands around campus!" : nil,
            isOnline: true,
            averageRating: role == .buddy ? 0 : 0,
            ratingCount: role == .buddy ? 0 : 0,
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
        stopUnreadTracking()
        stopNotificationTracking()
        LocalStore.shared.clearAll()
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
            LocalStore.shared.saveUser(user)
            return user
        } catch {
            if isNetworkError(error), let cached = LocalStore.shared.loadUser(id: uid) {
                self.currentUser = cached
                return cached
            }
            print("Failed to load user: \(error)")
            return nil
        }
    }

    private func isNetworkError(_ error: Error) -> Bool {
        if error is URLError { return true }
        return (error as NSError).domain == NSURLErrorDomain
    }

    func listenToAvailableBuddies(onChange: @escaping ([AppUser]) -> Void,
                                  onError: ((Error) -> Void)? = nil) -> DataSubscription {
        Task { await fetchAvailableBuddies(onChange: onChange, onError: onError) }

        let channel = client.realtimeV2.channel("public:users:buddies")
        Task {
            let changes = channel.postgresChange(AnyAction.self, table: "users")
            try? await channel.subscribeWithError()
            for await _ in changes {
                await fetchAvailableBuddies(onChange: onChange, onError: onError)
            }
        }
        return DataSubscription(channel: channel, client: client)
    }

    private func fetchAvailableBuddies(onChange: @escaping ([AppUser]) -> Void,
                                       onError: ((Error) -> Void)?) async {
        do {
            let buddies: [AppUser] = try await client.from("users")
                .select()
                .eq("role", value: UserRole.buddy.rawValue)
                .eq("is_available", value: true)
                .execute()
                .value
            onChange(buddies)
        } catch {
            onError?(error)
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

    func listenToMyRequests(userId: UUID, onChange: @escaping ([ServiceRequest]) -> Void,
                            onError: ((Error) -> Void)? = nil) -> DataSubscription {
        Task { await fetchMyRequests(userId: userId, onChange: onChange, onError: onError) }

        let channel = client.realtimeV2.channel("public:requests:mine:\(userId):\(UUID().uuidString)")
        Task {
            let changes = channel.postgresChange(AnyAction.self, table: "requests")
            try? await channel.subscribeWithError()
            for await _ in changes {
                await fetchMyRequests(userId: userId, onChange: onChange, onError: onError)
            }
        }
        return DataSubscription(channel: channel, client: client)
    }

    private func fetchMyRequests(userId: UUID, onChange: @escaping ([ServiceRequest]) -> Void,
                                 onError: ((Error) -> Void)?) async {
        do {
            let requests: [ServiceRequest] = try await client.from("requests")
                .select()
                .or("client_id.eq.\(userId.uuidString),buddy_id.eq.\(userId.uuidString)")
                .order("created_at", ascending: false)
                .execute()
                .value
            LocalStore.shared.saveRequests(requests, ownerId: userId)
            onChange(requests)
        } catch {
            onError?(error)
        }
    }

    func listenToOpenRequests(onChange: @escaping ([ServiceRequest]) -> Void,
                              onError: ((Error) -> Void)? = nil) -> DataSubscription {
        Task { await fetchOpenRequests(onChange: onChange, onError: onError) }

        let channel = client.realtimeV2.channel("public:requests:open")
        Task {
            let changes = channel.postgresChange(AnyAction.self, table: "requests")
            try? await channel.subscribeWithError()
            for await _ in changes {
                await fetchOpenRequests(onChange: onChange, onError: onError)
            }
        }
        return DataSubscription(channel: channel, client: client)
    }

    private func fetchOpenRequests(onChange: @escaping ([ServiceRequest]) -> Void,
                                   onError: ((Error) -> Void)?) async {
        do {
            let requests: [ServiceRequest] = try await client.from("requests")
                .select()
                .eq("status", value: RequestStatus.pending.rawValue)
                .order("created_at", ascending: false)
                .execute()
                .value
            if let ownerId = currentUser?.id {
                LocalStore.shared.saveRequests(requests, ownerId: ownerId, scope: .pending)
            }
            onChange(requests)
        } catch {
            onError?(error)
        }
    }

    func listenToCompletedJobs(buddyId: UUID, onChange: @escaping ([ServiceRequest]) -> Void,
                               onError: ((Error) -> Void)? = nil) -> DataSubscription {
        Task { await fetchCompletedJobs(buddyId: buddyId, onChange: onChange, onError: onError) }

        let channel = client.realtimeV2.channel("public:requests:jobs:\(buddyId)")
        Task {
            let changes = channel.postgresChange(AnyAction.self, table: "requests")
            try? await channel.subscribeWithError()
            for await _ in changes {
                await fetchCompletedJobs(buddyId: buddyId, onChange: onChange, onError: onError)
            }
        }
        return DataSubscription(channel: channel, client: client)
    }

    private func fetchCompletedJobs(buddyId: UUID, onChange: @escaping ([ServiceRequest]) -> Void,
                                    onError: ((Error) -> Void)?) async {
        do {
            let jobs: [ServiceRequest] = try await client.from("requests")
                .select()
                .eq("buddy_id", value: buddyId)
                .eq("status", value: RequestStatus.completed.rawValue)
                .order("created_at", ascending: false)
                .execute()
                .value
            LocalStore.shared.saveRequests(jobs, ownerId: buddyId, scope: .completedJobs)
            onChange(jobs)
        } catch {
            onError?(error)
        }
    }

    func listenToRequest(id: UUID, onChange: @escaping (ServiceRequest) -> Void) -> DataSubscription {
        Task { await fetchRequest(id: id, onChange: onChange) }

        let channel = client.realtimeV2.channel("public:requests:single:\(id)")
        Task {
            let changes = channel.postgresChange(AnyAction.self, table: "requests")
            try? await channel.subscribeWithError()
            for await _ in changes {
                await fetchRequest(id: id, onChange: onChange)
            }
        }
        return DataSubscription(channel: channel, client: client)
    }

    private func fetchRequest(id: UUID, onChange: @escaping (ServiceRequest) -> Void) async {
        guard let request: ServiceRequest = try? await client.from("requests")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value else { return }
        onChange(request)
    }

    func acceptRequest(_ requestId: UUID, buddyId: UUID) async throws {
        let updated: [ServiceRequest] = try await client.from("requests")
            .update([
                "buddy_id": buddyId.uuidString.lowercased(),
                "status": RequestStatus.accepted.rawValue
            ])
            .eq("id", value: requestId.uuidString.lowercased())
            .select()
            .execute()
            .value

        guard !updated.isEmpty else {
            throw RequestUpdateFailed()
        }
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

    func listenToUserLocation(userId: UUID, onChange: @escaping (CLLocationCoordinate2D?) -> Void) -> DataSubscription {
        Task {
            if let user = try? await fetchUser(id: userId),
               let lat = user.currentLatitude, let lng = user.currentLongitude {
                onChange(CLLocationCoordinate2D(latitude: lat, longitude: lng))
            }
        }

        let channel = client.realtimeV2.channel("public:users:location:\(userId)")
        Task {
            let changes = channel.postgresChange(UpdateAction.self, table: "users")
            try? await channel.subscribeWithError()
            for await change in changes {
                guard let record = try? change.decodeRecord(as: AppUser.self, decoder: JSONDecoder()),
                      record.id == userId,
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

    func listenToMessages(conversationId: UUID, onChange: @escaping ([Message]) -> Void,
                          onError: ((Error) -> Void)? = nil) -> DataSubscription {
        Task { await fetchMessages(conversationId: conversationId, onChange: onChange, onError: onError) }

        let channel = client.realtimeV2.channel("public:messages:\(conversationId)")
        Task {
            let changes = channel.postgresChange(InsertAction.self, table: "messages")
            try? await channel.subscribeWithError()
            for await _ in changes {
                await fetchMessages(conversationId: conversationId, onChange: onChange, onError: onError)
            }
        }
        return DataSubscription(channel: channel, client: client)
    }

    private func fetchMessages(conversationId: UUID, onChange: @escaping ([Message]) -> Void,
                               onError: ((Error) -> Void)?) async {
        do {
            let messages: [Message] = try await client.from("messages")
                .select()
                .eq("conversation_id", value: conversationId)
                .order("sent_at", ascending: true)
                .execute()
                .value
            LocalStore.shared.saveMessages(messages, conversationId: conversationId)
            onChange(messages)
        } catch {
            onError?(error)
        }
    }

    private func fetchConversations(userId: UUID, onChange: @escaping ([Conversation]) -> Void,
                                    onError: ((Error) -> Void)?) async {
        do {
            let conversations: [Conversation] = try await client.from("conversations")
                .select()
                .contains("participant_ids", value: [userId.uuidString])
                .order("last_message_at", ascending: false)
                .execute()
                .value
            LocalStore.shared.saveConversations(conversations, ownerId: userId)
            onChange(conversations)
        } catch {
            onError?(error)
        }
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

    func markConversationRead(conversationId: UUID, userId: UUID) async throws {
        clearUnreadLocally(for: conversationId)
        do {
            try await client.from("messages")
                .update(["read_at": ISO8601DateFormatter().string(from: Date())])
                .eq("conversation_id", value: conversationId)
                .neq("sender_id", value: userId)
                .filter("read_at", operator: "is", value: "null")
                .execute()
        } catch {
            await refreshUnreadCount()
            throw error
        }
        await refreshUnreadCount()
    }

    func startUnreadTracking(userId: UUID) {
        stopUnreadTracking()
        let session = UUID()
        unreadSession = session
        unreadUserId = userId

        Task { await refreshUnreadCount() }

        for table in ["messages", "conversations"] {
            let channel = client.realtimeV2.channel("public:\(table):unread:\(userId):\(session.uuidString)")
            Task {
                let changes = channel.postgresChange(AnyAction.self, table: table)
                try? await channel.subscribeWithError()
                for await _ in changes {
                    guard unreadSession == session else { break }
                    scheduleUnreadRefresh()
                }
            }
            unreadSubscriptions.append(DataSubscription(channel: channel, client: client))
        }
    }

    func stopUnreadTracking() {
        unreadSession = nil
        unreadUserId = nil
        unreadRefreshTask?.cancel()
        unreadRefreshTask = nil
        unreadRefreshGeneration += 1
        for subscription in unreadSubscriptions {
            subscription.remove()
        }
        unreadSubscriptions = []
        unreadByConversation = [:]
        unreadMessageCount = 0
    }

    func refreshUnreadCount() async {
        guard let userId = unreadUserId else { return }
        unreadRefreshGeneration += 1
        let generation = unreadRefreshGeneration
        do {
            let conversations: [Conversation] = try await client.from("conversations")
                .select()
                .contains("participant_ids", value: [userId.uuidString])
                .execute()
                .value
            let counts = try await unreadCounts(userId: userId, conversationIds: conversations.map(\.id))
            guard generation == unreadRefreshGeneration, unreadUserId == userId else { return }
            unreadByConversation = counts
            unreadMessageCount = counts.values.reduce(0, +)
        } catch {
            return
        }
    }

    private func scheduleUnreadRefresh() {
        unreadRefreshTask?.cancel()
        unreadRefreshTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await refreshUnreadCount()
        }
    }

    func startNotificationTracking(userId: UUID) {
        stopNotificationTracking()
        let session = UUID()
        notificationSession = session
        notificationUserId = userId

        Task { await refreshNotifications() }

        let channel = client.realtimeV2.channel("public:notifications:\(userId):\(session.uuidString)")
        Task {
            let changes = channel.postgresChange(AnyAction.self, table: "notifications")
            try? await channel.subscribeWithError()
            for await _ in changes {
                guard notificationSession == session else { break }
                scheduleNotificationRefresh()
            }
        }
        notificationSubscription = DataSubscription(channel: channel, client: client)
    }

    func stopNotificationTracking() {
        notificationSession = nil
        notificationUserId = nil
        notificationRefreshTask?.cancel()
        notificationRefreshTask = nil
        notificationGeneration += 1
        notificationSubscription?.remove()
        notificationSubscription = nil
        notifications = []
    }

    func refreshNotifications() async {
        guard let userId = notificationUserId else { return }
        notificationGeneration += 1
        let generation = notificationGeneration
        do {
            let fetched: [AppNotification] = try await client.from("notifications")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value
            guard generation == notificationGeneration, notificationUserId == userId else { return }
            notifications = fetched
        } catch {
            return
        }
    }

    private func scheduleNotificationRefresh() {
        notificationRefreshTask?.cancel()
        notificationRefreshTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await refreshNotifications()
        }
    }

    func markNotificationRead(id: UUID) async {
        guard let index = notifications.firstIndex(where: { $0.id == id }),
              !notifications[index].isRead else { return }
        notificationGeneration += 1
        var updated = notifications
        updated[index].readAt = Date()
        notifications = updated

        do {
            try await client.from("notifications")
                .update(["read_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: id)
                .execute()
        } catch {
            await refreshNotifications()
        }
    }

    func markAllNotificationsRead(userId: UUID) async {
        guard notifications.contains(where: { !$0.isRead }) else { return }
        notificationGeneration += 1
        let now = Date()
        notifications = notifications.map { notification in
            var copy = notification
            if copy.readAt == nil {
                copy.readAt = now
            }
            return copy
        }

        do {
            try await client.from("notifications")
                .update(["read_at": ISO8601DateFormatter().string(from: now)])
                .eq("user_id", value: userId)
                .filter("read_at", operator: "is", value: "null")
                .execute()
        } catch {
            await refreshNotifications()
        }
    }

    func loadRequest(id: UUID) async throws -> ServiceRequest {
        try await client.from("requests")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    func loadConversation(id: UUID) async throws -> Conversation {
        try await client.from("conversations")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    private func clearUnreadLocally(for conversationId: UUID) {
        unreadRefreshGeneration += 1
        guard unreadByConversation[conversationId] != nil else { return }
        var updated = unreadByConversation
        updated[conversationId] = nil
        unreadByConversation = updated
        unreadMessageCount = updated.values.reduce(0, +)
    }

    func unreadCounts(userId: UUID, conversationIds: [UUID]) async throws -> [UUID: Int] {
        guard !conversationIds.isEmpty else { return [:] }
        let rows: [[String: UUID]] = try await client.from("messages")
            .select("conversation_id")
            .in("conversation_id", values: conversationIds)
            .neq("sender_id", value: userId)
            .filter("read_at", operator: "is", value: "null")
            .execute()
            .value
        var counts: [UUID: Int] = [:]
        for row in rows {
            if let id = row["conversation_id"] {
                counts[id, default: 0] += 1
            }
        }
        return counts
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

    func listenToConversations(userId: UUID, onChange: @escaping ([Conversation]) -> Void,
                               onError: ((Error) -> Void)? = nil) -> DataSubscription {
        Task { await fetchConversations(userId: userId, onChange: onChange, onError: onError) }

        let channel = client.realtimeV2.channel("public:conversations:\(userId)")
        Task {
            let changes = channel.postgresChange(AnyAction.self, table: "conversations")
            try? await channel.subscribeWithError()
            for await _ in changes {
                await fetchConversations(userId: userId, onChange: onChange, onError: onError)
            }
        }
        return DataSubscription(channel: channel, client: client)
    }

    func fetchUser(id: UUID) async throws -> AppUser {
        let user: AppUser = try await client.from("users")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        LocalStore.shared.saveUser(user)
        return user
    }

    func submitFeedback(_ feedback: AppFeedback) async throws {
        try await client.from("feedback").insert(feedback).execute()
    }

    func submitIssue(userId: UUID, description: String) async throws {
        try await client.from("issue_reports")
            .insert([
                "user_id": userId.uuidString,
                "description": description
            ])
            .execute()
    }
}
