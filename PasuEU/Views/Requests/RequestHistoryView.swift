import SwiftUI

private struct HistorySection: Identifiable {
    let id: String
    let title: String
    var requests: [ServiceRequest]
}

struct RequestHistoryView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State private var requests: [ServiceRequest] = []
    @State private var loadFailed = false
    @State private var subscription: DataSubscription?
    @State private var filter: HistoryFilter = .all

    private var visibleRequests: [ServiceRequest] {
        requests.filter { filter.includes($0.status) }
    }

    private var sections: [HistorySection] {
        let calendar = Calendar.current
        var result: [HistorySection] = []
        for request in visibleRequests.sorted(by: { $0.createdAt > $1.createdAt }) {
            let (key, title) = sectionInfo(for: request.createdAt, calendar: calendar)
            if let index = result.firstIndex(where: { $0.id == key }) {
                result[index].requests.append(request)
            } else {
                result.append(HistorySection(id: key, title: title, requests: [request]))
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ScreenHeader("Transactions")

                    VStack(alignment: .leading, spacing: 16) {
                        if requests.isEmpty && loadFailed {
                            EmptyStateView(
                                icon: "wifi.exclamationmark",
                                title: "Couldn't load your transactions",
                                message: "Check your connection and try again.",
                                retry: { attachListener() }
                            )
                        } else if requests.isEmpty {
                            emptyState
                        } else {
                            filterChips

                            if visibleRequests.isEmpty {
                                EmptyStateView(
                                    icon: "line.3.horizontal.decrease.circle",
                                    title: "No \(filter.rawValue.lowercased()) transactions",
                                    message: filter.emptyMessage
                                )
                            }

                            ForEach(sections) { section in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(section.title.uppercased())
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                        .padding(.leading, 4)

                                    ForEach(section.requests) { request in
                                        NavigationLink {
                                            RequestDetailView(request: request)
                                        } label: {
                                            row(for: request)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
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
            .onChange(of: supabase.currentUser?.id) {
                attachListener()
            }
            .onDisappear {
                subscription?.remove()
                subscription = nil
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HistoryFilter.allCases) { option in
                    Button {
                        filter = option
                    } label: {
                        Text(option.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(filter == option ? Theme.brand : Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(filter == option ? Color.white : Color.primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(filter == option ? .isSelected : [])
                }
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "list.bullet.rectangle",
            title: "No transactions yet",
            message: "Requests you create will show up here once submitted."
        )
    }

    private func isEarning(_ request: ServiceRequest) -> Bool {
        guard let uid = supabase.currentUser?.id else { return false }
        return supabase.currentUser?.role == .buddy
            && request.buddyId == uid
            && request.status == .completed
    }

    private func peso(_ amount: Double) -> String {
        String(format: "₱%.2f", amount)
    }

    private func sectionInfo(for date: Date, calendar: Calendar) -> (String, String) {
        if calendar.isDateInToday(date) { return ("today", "Today") }
        if calendar.isDateInYesterday(date) { return ("yesterday", "Yesterday") }
        let parts = calendar.dateComponents([.year, .month], from: date)
        let key = "\(parts.year ?? 0)-\(parts.month ?? 0)"
        return (key, date.formatted(.dateTime.month(.wide).year()))
    }

    private func row(for request: ServiceRequest) -> some View {
        HStack(spacing: 12) {
            Image(systemName: request.type.iconName)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Theme.brand)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(request.type.displayName).font(.subheadline.bold())
                Text(request.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if isEarning(request) {
                    Text("+\(peso(request.totalAmount))")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                    Text("Earned")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text(peso(request.totalAmount))
                        .font(.subheadline.bold())
                }
                statusPill(for: request.status)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.fieldRadius))
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
        subscription?.remove()
        loadFailed = false
        subscription = supabase.listenToMyRequests(
            userId: uid,
            onChange: { requests in
                self.requests = requests
                loadFailed = false
            },
            onError: { _ in
                loadFailed = true
            }
        )
    }
}

#Preview {
    RequestHistoryView().environmentObject(SupabaseManager.shared)
}
