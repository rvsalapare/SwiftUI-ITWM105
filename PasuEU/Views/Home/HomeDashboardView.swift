import SwiftUI

private enum OrderFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case pabili = "Pabili"
    case pahatid = "Pahatid"
    case paprint = "Paprint"

    var id: String { rawValue }

    func includes(_ type: ServiceType) -> Bool {
        switch self {
        case .all: return true
        case .pabili: return type == .pabili
        case .pahatid: return type == .pahatid
        case .paprint: return type == .paprint
        }
    }
}

struct HomeDashboardView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State private var availableBuddies: [AppUser] = []
    @State private var openRequests: [ServiceRequest] = []
    @State private var completedJobs: [ServiceRequest] = []
    @State private var myRequests: [ServiceRequest] = []
    @State private var jobsFailed = false
    @State private var jobsSubscription: DataSubscription?
    @State private var myRequestsSubscription: DataSubscription?
    @State private var orderFilter: OrderFilter = .all
    @State private var showNewRequestSheet = false
    @State private var selectedType: ServiceType = .pabili
    @State private var isAvailable = false
    @State private var buddiesFailed = false
    @State private var requestsFailed = false
    @State private var buddiesSubscription: DataSubscription?
    @State private var requestsSubscription: DataSubscription?

    private var isBuddy: Bool { supabase.currentUser?.role == .buddy }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var firstName: String {
        supabase.currentUser?.name
            .split(separator: " ")
            .first
            .map(String.init) ?? "there"
    }

    private var roleLine: String {
        isBuddy ? "Ready for errands?" : "What do you need today?"
    }

    private var activeRequest: ServiceRequest? {
        myRequests
            .filter { $0.status == .pending || $0.status == .accepted || $0.status == .inProgress }
            .max(by: { $0.createdAt < $1.createdAt })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ScreenHeader(
                        "\(greeting), \(firstName)",
                        subtitle: roleLine,
                        icon: supabase.currentUser?.profileIconName ?? "person.crop.circle.fill",
                        style: .centered
                    )
                    .overlay(alignment: .topTrailing) {
                        messagesLink
                    }

                    VStack(alignment: .leading, spacing: Theme.spacingXLarge) {
                        if let activeRequest {
                            NavigationLink {
                                RequestDetailView(request: activeRequest)
                            } label: {
                                ActiveRequestBanner(request: activeRequest, isBuddy: isBuddy)
                            }
                            .buttonStyle(.plain)
                        }

                        if isBuddy {
                            availabilityToggle
                            buddyOverview
                            buddyOpenOrders
                            completedJobsList
                        } else {
                            clientServices
                            buddyCountBadge
                        }
                    }
                    .padding(Theme.spacingXLarge)
                }
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea(edges: .top)
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showNewRequestSheet) {
            NewRequestView(type: selectedType)
        }
        .task {
            attachListeners()
            isAvailable = supabase.currentUser?.isAvailable ?? false
        }
        .onChange(of: supabase.currentUser?.id) {
            attachJobsListener()
            attachMyRequestsListener()
        }
        .onDisappear {
            buddiesSubscription?.remove()
            buddiesSubscription = nil
            requestsSubscription?.remove()
            requestsSubscription = nil
            jobsSubscription?.remove()
            jobsSubscription = nil
            myRequestsSubscription?.remove()
            myRequestsSubscription = nil
        }
    }

    private var messagesLink: some View {
        NavigationLink {
            ConversationListView()
        } label: {
            Image(systemName: "message.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.18))
                .clipShape(Circle())
        }
        .padding(.top, 64)
        .padding(.trailing, Theme.spacingXLarge)
        .accessibilityLabel("Messages")
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingMedium) {
            Text(title).font(.headline)
            content()
        }
    }

    private var availabilityToggle: some View {
        CardContainer(fillsWidth: true) {
            Toggle(isOn: Binding(
                get: { isAvailable },
                set: { newValue in
                    isAvailable = newValue
                    Task {
                        if let uid = supabase.currentUser?.id {
                            try? await supabase.setAvailability(newValue, for: uid)
                        }
                    }
                }
            )) {
                HStack(spacing: 10) {
                    Image(systemName: isAvailable ? "bolt.fill" : "moon.zzz.fill")
                        .foregroundStyle(isAvailable ? .green : .secondary)
                    Text(isAvailable ? "You're online and visible to clients" : "You're offline")
                        .font(.subheadline.bold())
                }
            }
            .tint(Theme.brand)
        }
    }

    private var buddyOverview: some View {
        section("Overview") {
            buddyStats
            earningsCard
        }
    }

    private var buddyStats: some View {
        HStack(spacing: Theme.spacingMedium) {
            statCard(icon: "star.fill",
                     value: String(format: "%.1f", supabase.currentUser?.averageRating ?? 0),
                     label: "Rating", tint: .yellow)
            statCard(icon: "checkmark.seal.fill",
                     value: "\(completedJobs.count)",
                     label: "Completed", tint: .green)
            statCard(icon: "envelope.badge.fill",
                     value: "\(openRequests.count)",
                     label: "Open Now", tint: Theme.brand)
        }
    }

    private func statCard(icon: String, value: String, label: String, tint: Color) -> some View {
        CardContainer(alignment: .center, spacing: 6, padding: Theme.spacingMedium, fillsWidth: true) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var buddyOpenOrders: some View {
        section("Available Orders") {
            Picker("Filter", selection: $orderFilter) {
                ForEach(OrderFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            if openRequests.isEmpty && requestsFailed {
                EmptyStateView(
                    icon: "wifi.exclamationmark",
                    title: "Couldn't load orders",
                    message: "Check your connection and try again.",
                    retry: { attachRequestsListener() }
                )
            } else if openRequests.isEmpty {
                emptyOrdersState
            } else if visibleOrders.isEmpty {
                EmptyStateView(
                    icon: "line.3.horizontal.decrease.circle",
                    title: "No \(orderFilter.rawValue) orders right now",
                    message: "Try another filter to see the other open requests."
                )
            }

            ForEach(visibleOrders) { request in
                NavigationLink {
                    RequestDetailView(request: request)
                } label: {
                    orderRow(for: request)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var visibleOrders: [ServiceRequest] {
        let filtered = openRequests.filter { orderFilter.includes($0.type) }
        return filtered.filter(\.isUrgent) + filtered.filter { !$0.isUrgent }
    }

    private var totalEarned: Double {
        completedJobs.reduce(0) { $0 + $1.totalAmount }
    }

    private var earningsCard: some View {
        CardContainer(spacing: 0, fillsWidth: true) {
            HStack(spacing: 14) {
                Image(systemName: "pesosign.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Theme.brand)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total earned").font(.caption).foregroundStyle(.secondary)
                    Text(peso(totalEarned)).font(.title2.bold())
                }
                Spacer()
                Text("\(completedJobs.count) \(completedJobs.count == 1 ? "job" : "jobs")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var completedJobsList: some View {
        section("Completed Jobs") {
            if completedJobs.isEmpty && jobsFailed {
                EmptyStateView(
                    icon: "wifi.exclamationmark",
                    title: "Couldn't load your jobs",
                    message: "Check your connection and try again.",
                    retry: { attachJobsListener() }
                )
            } else if completedJobs.isEmpty {
                EmptyStateView(
                    icon: "checkmark.seal",
                    title: "No completed jobs yet",
                    message: "Jobs you finish will show up here with what you earned."
                )
            }

            ForEach(completedJobs) { job in
                NavigationLink {
                    RequestDetailView(request: job)
                } label: {
                    jobRow(for: job)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func jobRow(for job: ServiceRequest) -> some View {
        CardContainer(spacing: 0, padding: Theme.spacingMedium, fillsWidth: true) {
            HStack(spacing: Theme.spacingMedium) {
                Image(systemName: job.type.iconName)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Theme.brand)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(job.type.displayName).font(.subheadline.bold())
                    Text((job.completedAt ?? job.createdAt).formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(peso(job.totalAmount))
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            }
        }
    }

    private func peso(_ amount: Double) -> String {
        String(format: "₱%.2f", amount)
    }

    private var emptyOrdersState: some View {
        EmptyStateView(
            icon: "tray",
            title: "No open requests right now",
            message: "New requests will show up here as soon as a client posts one."
        )
    }

    private func orderRow(for request: ServiceRequest) -> some View {
        CardContainer(spacing: 0, padding: Theme.spacingMedium, fillsWidth: true) {
            HStack(spacing: Theme.spacingMedium) {
                Image(systemName: request.type.iconName)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Theme.brand)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(request.type.displayName)
                            .font(.subheadline.bold())
                        if request.isUrgent {
                            Text("URGENT")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.red.opacity(0.15))
                                .foregroundStyle(.red)
                                .clipShape(Capsule())
                        }
                    }
                    Text(request.meetingPlace)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(request.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var clientServices: some View {
        section("Our Services") {
            ForEach(ServiceType.allCases, id: \.self) { type in
                ServiceCard(type: type) {
                    selectedType = type
                    showNewRequestSheet = true
                }
            }
        }
    }

    @ViewBuilder
    private var buddyCountBadge: some View {
        if availableBuddies.isEmpty && buddiesFailed {
            EmptyStateView(
                icon: "wifi.exclamationmark",
                title: "Couldn't load online buddies",
                message: "Check your connection and try again.",
                retry: { attachBuddiesListener() }
            )
        } else {
            CardContainer(spacing: 0, fillsWidth: true) {
                HStack {
                    Image(systemName: "person.2.fill")
                    Text("Online Buddies: \(availableBuddies.count)")
                        .font(.subheadline.bold())
                    Spacer()
                }
            }
        }
    }

    private func attachListeners() {
        attachBuddiesListener()
        attachRequestsListener()
        attachJobsListener()
        attachMyRequestsListener()
    }

    private func attachMyRequestsListener() {
        myRequestsSubscription?.remove()
        myRequestsSubscription = nil
        guard let uid = supabase.currentUser?.id else { return }
        myRequestsSubscription = supabase.listenToMyRequests(userId: uid) { requests in
            self.myRequests = requests
        }
    }

    private func attachJobsListener() {
        jobsSubscription?.remove()
        jobsSubscription = nil
        jobsFailed = false
        guard supabase.currentUser?.role == .buddy, let uid = supabase.currentUser?.id else { return }
        jobsSubscription = supabase.listenToCompletedJobs(
            buddyId: uid,
            onChange: { jobs in
                self.completedJobs = jobs
                jobsFailed = false
            },
            onError: { _ in
                jobsFailed = true
            }
        )
    }

    private func attachBuddiesListener() {
        buddiesSubscription?.remove()
        buddiesFailed = false
        buddiesSubscription = supabase.listenToAvailableBuddies(
            onChange: { buddies in
                self.availableBuddies = buddies
                buddiesFailed = false
            },
            onError: { _ in
                buddiesFailed = true
            }
        )
    }

    private func attachRequestsListener() {
        requestsSubscription?.remove()
        requestsFailed = false
        requestsSubscription = supabase.listenToOpenRequests(
            onChange: { requests in
                self.openRequests = requests
                requestsFailed = false
            },
            onError: { _ in
                requestsFailed = true
            }
        )
    }
}

#Preview {
    HomeView().environmentObject(SupabaseManager.shared)
}
