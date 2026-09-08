import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State private var availableBuddies: [AppUser] = []
    @State private var openRequests: [ServiceRequest] = []
    @State private var showNewRequestSheet = false
    @State private var selectedType: ServiceType = .pabili

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if supabase.currentUser?.role == .client {
                        clientServices
                        buddyCountBadge
                    } else {
                        buddyOpenOrders
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .toolbarBackground(Color(red: 0.42, green: 0.08, blue: 0.1), for: .navigationBar)
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
        .task { attachListeners() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Good day, \(supabase.currentUser?.name ?? "there")!")
                .font(.title3.bold())
            Text(supabase.currentUser?.role == .buddy
                 ? "Ready to accept orders?"
                 : "What can we do for you?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

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
                    .background(Color(red: 0.42, green: 0.08, blue: 0.1))
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

    private var buddyOpenOrders: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Available Orders:").font(.headline)
            if openRequests.isEmpty {
                Text("No open requests right now.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(openRequests) { request in
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
                            Text(request.type.displayName.uppercased()).font(.subheadline.bold())
                            Text("Added \(request.createdAt.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Circle().fill(.red).frame(width: 8, height: 8)
                    }
                    .padding(10)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
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
