import SwiftUI
import SwiftData

@main
struct PasuEUApp: App {
    @StateObject private var supabase = SupabaseManager.shared

    private let container: ModelContainer

    init() {
        let container = Self.makeContainer()
        self.container = container
        LocalStore.shared.configure(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(supabase)
        }
        .modelContainer(container)
    }

    private static func makeContainer() -> ModelContainer {
        do {
            return try ModelContainer(
                for: CachedRequest.self, CachedUser.self, CachedConversation.self, CachedMessage.self
            )
        } catch {
            let memoryOnly = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(
                for: CachedRequest.self, CachedUser.self, CachedConversation.self, CachedMessage.self,
                configurations: memoryOnly
            )
        }
    }
}
