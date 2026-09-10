import SwiftUI

struct RequestHistoryView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State private var requests: [ServiceRequest] = []

    private let brand = Color(red: 0.42, green: 0.08, blue: 0.1)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero

                    VStack(spacing: 12) {
                        if requests.isEmpty {
                            emptyState
                        } else {
                            ForEach(requests) { request in
                                NavigationLink {
                                    RequestDetailView(request: request)
                                } label: {
                                    row(for: request)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(24)
                    .padding(.top, 8)
                }
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea(edges: .top)
            .task { attachListener() }
        }
    }

    private var hero: some View {
        ZStack {
            LinearGradient(
                colors: [brand, Color(red: 0.24, green: 0.04, blue: 0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack {
                Text("Transactions")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 60)
                Spacer()
            }
        }
        .frame(height: 120)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 32, bottomTrailingRadius: 32))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "list.bullet.rectangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No transactions yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Requests you create will show up here once submitted.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func row(for request: ServiceRequest) -> some View {
        HStack(spacing: 12) {
            Image(systemName: request.type.iconName)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(brand)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(request.type.displayName).font(.subheadline.bold())
                Text(request.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            statusPill(for: request.status)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statusPill(for status: RequestStatus) -> some View {
        Text(label(for: status))
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color(for: status).opacity(0.15))
            .foregroundStyle(color(for: status))
            .clipShape(Capsule())
    }

    private func label(for status: RequestStatus) -> String {
        switch status {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    private func color(for status: RequestStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .accepted, .inProgress: return .blue
        case .completed: return .green
        case .cancelled: return .red
        }
    }

    private func attachListener() {
        guard let uid = supabase.currentUser?.id else { return }
        _ = supabase.listenToMyRequests(clientId: uid) { requests in
            self.requests = requests
        }
    }
}

#Preview {
    RequestHistoryView().environmentObject(SupabaseManager.shared)
}
