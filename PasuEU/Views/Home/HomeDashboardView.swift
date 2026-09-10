import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State private var availableBuddies: [AppUser] = []
    @State private var openRequests: [ServiceRequest] = []
    @State private var showNewRequestSheet = false
    @State private var selectedType: ServiceType = .pabili
    @State private var isAvailable = false

    private let brand = Color(red: 0.42, green: 0.08, blue: 0.1)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if supabase.currentUser?.role == .client {
                        clientServices
                        buddyCountBadge
                    } else {
                        availabilityToggle
                        buddyStats
                        buddyOpenOrders
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .toolbarBackground(brand, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        ConversationListView()
                    } label: {
                        Image(systemName: "message.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showNewRequestSheet) {
            NewRequestView(type: selectedType)
        }
        .task {
            attachListeners()
            isAvailable = supabase.currentUser?.isAvailable ?? false
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: supabase.currentUser?.profileIconName ?? "person.crop.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(brand)
                .frame(width: 54, height: 54)
                .background(brand.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Good day, \(supabase.currentUser?.name ?? "there")!")
                    .font(.title3.bold())
                Text(supabase.currentUser?.role == .buddy
                     ? "Ready to accept orders?"
                     : "What can we do for you?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Buddy-only sections

    private var availabilityToggle: some View {
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
        .tint(brand)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var buddyStats: some View {
        HStack(spacing: 12) {
            statCard(icon: "star.fill",
                     value: String(format: "%.1f", supabase.currentUser?.averageRating ?? 0),
                     label: "Rating", tint: .yellow)
            statCard(icon: "checkmark.seal.fill",
                     value: "\(supabase.currentUser?.ratingCount ?? 0)",
                     label: "Completed", tint: .green)
            statCard(icon: "envelope.badge.fill",
                     value: "\(openRequests.count)",
                     label: "Open Now", tint: brand)
        }
    }

    private func statCard(icon: String, value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var buddyOpenOrders: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Available Orders").font(.headline)

            if openRequests.isEmpty {
                emptyOrdersState
            }

            ForEach(openRequests) { request in
                NavigationLink {
                    RequestDetailView(request: request)
                } label: {
                    orderRow(for: request)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyOrdersState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No open requests right now")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("New requests will show up here as soon as a client posts one.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func orderRow(for request: ServiceRequest) -> some View {
        HStack(spacing: 12) {
            Image(systemName: request.type.iconName)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(brand)
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
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Client-only sections

    private var clientServices: some View {
        VStack(spacing: 12) {
            ForEach(ServiceType.allCases, id: \.self) { type in
                Button {
                    selectedType = type
                    showNewRequestSheet = true
                } label: {
                    HStack {
                        Image(systemName: type.iconName)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.15))
                            .clipShape(Circle())
                        VStack(alignment: .leading) {
                            Text(type.displayName).font(.headline)
                            Text(subtitle(for: type))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .foregroundStyle(.white)
                    .background(brand)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private func subtitle(for type: ServiceType) -> String {
        switch type {
        case .pabili: return "Bring me stuff I need"
        case .pahatid: return "Deliver a package or document"
        case .paprint: return "Print my file for me"
        }
    }

    private var buddyCountBadge: some View {
        HStack {
            Image(systemName: "person.2.fill")
            Text("Online Buddies: \(availableBuddies.count)")
                .font(.subheadline.bold())
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func attachListeners() {
        _ = supabase.listenToAvailableBuddies { buddies in
            self.availableBuddies = buddies
        }
        _ = supabase.listenToOpenRequests { requests in
            self.openRequests = requests
        }
    }
}

#Preview {
    HomeView().environmentObject(SupabaseManager.shared)
}
