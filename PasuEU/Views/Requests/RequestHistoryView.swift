import SwiftUI

struct RequestHistoryView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State private var requests: [ServiceRequest] = []

    var body: some View {
        NavigationStack {
            List(requests) { request in
                NavigationLink {
                    RequestDetailView(request: request)
                } label: {
                    HStack {
                        Image(systemName: request.type.iconName)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color(red: 0.42, green: 0.08, blue: 0.1))
                            .clipShape(Circle())
                        VStack(alignment: .leading) {
                            Text(request.type.displayName)
                                .font(.subheadline.bold())
                            Text(request.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(request.status.rawValue.capitalized)
                            .font(.caption.bold())
                    }
                }
            }
            .overlay {
                if requests.isEmpty {
                    ContentUnavailableView("No transactions yet",
                                            systemImage: "list.bullet.rectangle")
                }
            }
            .navigationTitle("Transactions")
            .task { attachListener() }
        }
    }

    private func attachListener() {
        guard let uid = supabase.currentUser?.id else { return }
        _ = supabase.listenToMyRequests(clientId: uid) { requests in
            self.requests = requests
        }
    }
}
