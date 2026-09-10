import SwiftUI

struct RequestDetailView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State var request: ServiceRequest
    @State private var isDownloading = false
    @State private var errorMessage: String?
    @State private var showRating = false
    @State private var showReportSheet = false

    private let brand = Color(red: 0.42, green: 0.08, blue: 0.1)

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero

                VStack(spacing: 16) {
                    card {
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
                        card {
                            HStack {
                                Image(systemName: "doc.fill").foregroundStyle(brand)
                                Text(fileName)
                                Spacer()
                                if isDownloading {
                                    ProgressView()
                                } else {
                                    Button("Download") { Task { await downloadFile() } }
                                        .font(.subheadline.bold())
                                        .foregroundStyle(brand)
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

                    if request.status == .accepted || request.status == .inProgress {
                        navCard(icon: "map.fill", title: "View live location on map") {
                            MapTrackingView(request: request)
                        }
                    }

                    if let buddyId = request.buddyId, request.status != .pending {
                        navCard(icon: "message.fill", title: "Message about this order") {
                            MessageBuddyLink(buddyId: buddyId)
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
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .sheet(isPresented: $showReportSheet) {
                            ReportProblemLink(userId: buddyId)
                        }

                        Button {
                            Task { await updateStatus(.cancelled) }
                        } label: {
                            Label("Cancel order", systemImage: "xmark.circle")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
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
        .sheet(isPresented: $showRating) {
            RatingView(request: request)
        }
    }

    private var hero: some View {
        ZStack {
            LinearGradient(
                colors: [brand, Color(red: 0.24, green: 0.04, blue: 0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(spacing: 10) {
                Image(systemName: request.type.iconName)
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(.white.opacity(0.18))
                    .clipShape(Circle())
                Text(request.type.displayName)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                statusPill
            }
            .padding(.top, 60)
        }
        .frame(height: 190)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 32, bottomTrailingRadius: 32))
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

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10, content: content)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
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
                Image(systemName: icon).foregroundStyle(brand)
                Text(title).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if let currentUser = supabase.currentUser {
            if currentUser.role == .buddy && request.status == .pending {
                primaryButton("Accept this request") { Task { await accept() } }
            } else if currentUser.role == .buddy && request.status == .accepted {
                primaryButton("Mark as In Progress") { Task { await updateStatus(.inProgress) } }
            } else if currentUser.role == .buddy && request.status == .inProgress {
                primaryButton("Mark as Completed") { Task { await updateStatus(.completed) } }
            } else if currentUser.role == .client && request.status == .completed {
                primaryButton("Rate this Buddy") { showRating = true }
            }
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(brand)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
            try data.write(to: tempURL)
        } catch {
            errorMessage = error.localizedDescription
        }
        isDownloading = false
    }
}
