import SwiftUI

struct RequestDetailView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State var request: ServiceRequest
    @State private var isDownloading = false
    @State private var downloadedFileURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?
    @State private var showRating = false
    @State private var showReportSheet = false
    @State private var showCancelConfirmation = false
    @State private var buddy: AppUser?
    @State private var client: AppUser?
    @State private var subscription: DataSubscription?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(request.type.displayName, icon: request.type.iconName, style: .badge) {
                    statusPill
                }

                VStack(spacing: 16) {
                    RequestProgressTracker(status: request.status)

                    CardContainer {
                        detailRow(label: "Meeting place", value: request.meetingPlace)
                        if let item = request.itemDescription {
                            Divider().padding(.leading, 4)
                            detailRow(label: "Item", value: item)
                        }
                        if let recipient = request.recipientName {
                            Divider().padding(.leading, 4)
                            detailRow(label: "Recipient", value: recipient)
                        }
                        if let destination = request.destination {
                            Divider().padding(.leading, 4)
                            detailRow(label: "Destination", value: destination)
                        }
                        if let note = request.note, !note.isEmpty {
                            Divider().padding(.leading, 4)
                            detailRow(label: "Note", value: note)
                        }
                        if request.isUrgent {
                            Divider().padding(.leading, 4)
                            Label("Marked as urgent", systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline.bold())
                                .foregroundStyle(.red)
                        }
                    }

                    if request.type == .paprint, let fileName = request.fileName {
                        CardContainer {
                            HStack {
                                Image(systemName: "doc.fill").foregroundStyle(Theme.brand)
                                Text(fileName)
                                Spacer()
                                if isDownloading {
                                    ProgressView()
                                } else {
                                    Button("Download") { Task { await downloadFile() } }
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Theme.brand)
                                }
                            }
                            Divider().padding(.leading, 4)
                            HStack {
                                detailRow(label: "Pages", value: "\(request.pages ?? 0)")
                                Spacer()
                                detailRow(label: "Copies", value: "\(request.copies ?? 0)")
                            }
                        }
                    }

                    FeeBreakdownCard(request: request)

                    peopleSection

                    if request.status == .accepted || request.status == .inProgress {
                        navCard(icon: "map.fill", title: "View live location on map") {
                            MapTrackingView(request: request)
                        }
                    }

                    actionButton

                    if request.status == .accepted || request.status == .inProgress,
                       let buddyId = request.buddyId {
                        Button {
                            showReportSheet = true
                        } label: {
                            Label("Report a problem", systemImage: "exclamationmark.bubble")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .foregroundStyle(.orange)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                        .sheet(isPresented: $showReportSheet) {
                            ReportProblemLink(userId: buddyId)
                        }

                        Button {
                            showCancelConfirmation = true
                        } label: {
                            Label("Cancel order", systemImage: "xmark.circle")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                    }

                    if let errorMessage {
                        Text(errorMessage).foregroundStyle(.red).font(.caption)
                    }
                }
                .padding(24)
                .padding(.top, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showShareSheet) {
            if let downloadedFileURL {
                ShareSheet(items: [downloadedFileURL])
                    .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $showRating) {
            RatingView(request: request)
        }
        .confirmationDialog(
            "Are you sure you want to cancel this request?",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel order", role: .destructive) {
                Task { await updateStatus(.cancelled) }
            }
            Button("Keep order", role: .cancel) {}
        }
        .task(id: request.buddyId) {
            await loadBuddy()
        }
        .task(id: request.clientId) {
            await loadClient()
        }
        .onAppear { startListening() }
        .onDisappear { stopListening() }
    }

    private var showsContactNumbers: Bool {
        request.status == .accepted || request.status == .inProgress
    }

    private var otherPersonId: UUID? {
        guard let me = supabase.currentUser?.id else { return request.buddyId }
        return me == request.clientId ? request.buddyId : request.clientId
    }

    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PEOPLE")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            if let client {
                personCard(client, role: "Client", showsRating: false)
            }
            if let buddy {
                personCard(buddy, role: "Errand Buddy", showsRating: true)
            }

            if request.buddyId != nil, request.status != .pending, let otherPersonId {
                navCard(icon: "message.fill", title: "Message about this order") {
                    MessageBuddyLink(buddyId: otherPersonId)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func personCard(_ user: AppUser, role: String, showsRating: Bool) -> some View {
        CardContainer {
            HStack(spacing: 12) {
                Image(systemName: user.profileIconName)
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.brand)
                VStack(alignment: .leading, spacing: 2) {
                    Text(role).font(.caption).foregroundStyle(.secondary)
                    Text(user.name).font(.headline)
                    if showsRating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill").foregroundStyle(.yellow)
                            if user.ratingCount > 0 {
                                Text(String(format: "%.1f", user.averageRating))
                                Text("(\(user.ratingCount) \(user.ratingCount == 1 ? "rating" : "ratings"))")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("No ratings yet").foregroundStyle(.secondary)
                            }
                        }
                        .font(.subheadline)
                    }
                    if showsContactNumbers {
                        Label(user.contactNumber, systemImage: "phone.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
                Spacer()
            }
        }
    }

    private func startListening() {
        guard subscription == nil else { return }
        subscription = supabase.listenToRequest(id: request.id) { updated in
            request = updated
        }
    }

    private func stopListening() {
        subscription?.remove()
        subscription = nil
    }

    private func loadBuddy() async {
        guard let buddyId = request.buddyId else {
            buddy = nil
            return
        }
        buddy = try? await supabase.fetchUser(id: buddyId)
    }

    private func loadClient() async {
        if let current = supabase.currentUser, current.id == request.clientId {
            client = current
            return
        }
        client = try? await supabase.fetchUser(id: request.clientId)
    }

    private var statusPill: some View {
        Text(statusLabel)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.white.opacity(0.2))
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }

    private var statusLabel: String {
        switch request.status {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func navCard<Destination: View>(icon: String, title: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon).foregroundStyle(Theme.brand)
                Text(title).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: Theme.fieldRadius))
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if let currentUser = supabase.currentUser {
            if currentUser.role == .buddy && request.status == .pending {
                PrimaryButton("Accept this request") { Task { await accept() } }
            } else if currentUser.role == .buddy && request.status == .accepted {
                PrimaryButton("Mark as In Progress") { Task { await updateStatus(.inProgress) } }
            } else if currentUser.role == .buddy && request.status == .inProgress {
                PrimaryButton("Mark as Completed") { Task { await updateStatus(.completed) } }
            } else if currentUser.role == .client && request.status == .completed {
                PrimaryButton("Rate this Buddy") { showRating = true }
            }
        }
    }

    private func accept() async {
        guard let uid = supabase.currentUser?.id else { return }
        do {
            try await supabase.acceptRequest(request.id, buddyId: uid)
            request.status = .accepted
            request.buddyId = uid
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateStatus(_ status: RequestStatus) async {
        do {
            try await supabase.updateRequestStatus(request.id, status: status)
            request.status = status
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func downloadFile() async {
        guard let fileName = request.fileName else { return }
        isDownloading = true
        do {
            let data = try await supabase.downloadFile(path: "\(request.id.uuidString)/\(fileName)")
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(fileName)
            try data.write(to: tempURL, options: .atomic)
            downloadedFileURL = tempURL
            showShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isDownloading = false
    }
}
