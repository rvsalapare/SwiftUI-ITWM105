import SwiftUI

struct RequestDetailView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State var request: ServiceRequest
    @State private var isDownloading = false
    @State private var errorMessage: String?
    @State private var showRating = false
    @State private var showReportSheet = false

    var body: some View {
        List {
            Section {
                Label(request.type.displayName, systemImage: request.type.iconName)
                    .font(.headline)
                statusBadge
            }

            Section("Details") {
                if let item = request.itemDescription {
                    LabeledContent("Item", value: item)
                }
                if let recipient = request.recipientName {
                    LabeledContent("Recipient", value: recipient)
                }
                LabeledContent("Meeting place", value: request.meetingPlace)
                if let destination = request.destination {
                    LabeledContent("Destination", value: destination)
                }
                if let note = request.note, !note.isEmpty {
                    LabeledContent("Note", value: note)
                }
                if request.isUrgent {
                    Label("Urgent", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            if request.type == .paprint, let fileName = request.fileName {
                Section("Attached File") {
                    HStack {
                        Image(systemName: "doc.fill")
                        Text(fileName)
                        Spacer()
                        if isDownloading {
                            ProgressView()
                        } else {
                            Button("Download") { Task { await downloadFile() } }
                        }
                    }
                    LabeledContent("Pages", value: "\(request.pages ?? 0)")
                    LabeledContent("Copies", value: "\(request.copies ?? 0)")
                }
            }

            if request.status == .accepted || request.status == .inProgress {
                Section("Live Tracking") {
                    NavigationLink {
                        MapTrackingView(request: request)
                    } label: {
                        Label("View live location on map", systemImage: "map.fill")
                    }
                }
            }

            if let buddyId = request.buddyId, request.status != .pending {
                Section {
                    NavigationLink {
                        MessageBuddyLink(buddyId: buddyId)
                    } label: {
                        Label("Message about this order", systemImage: "message.fill")
                    }
                }
            }

            Section {
                actionButton
            }

            if request.status == .accepted || request.status == .inProgress,
               let buddyId = request.buddyId {
                Section {
                    Button("Report a problem", systemImage: "exclamationmark.bubble") {
                        showReportSheet = true
                    }
                    .foregroundStyle(.orange)
                    .sheet(isPresented: $showReportSheet) {
                        ReportProblemLink(userId: buddyId)
                    }

                    Button("Cancel order", systemImage: "xmark.circle", role: .destructive) {
                        Task { await updateStatus(.cancelled) }
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.caption)
            }
        }
        .navigationTitle("Request Details")
        .sheet(isPresented: $showRating) {
            RatingView(request: request)
        }
    }

    private var statusBadge: some View {
        Text(statusLabel)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
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

    private var statusColor: Color {
        switch request.status {
        case .pending: return .orange
        case .accepted, .inProgress: return .blue
        case .completed: return .green
        case .cancelled: return .red
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        guard let currentUser = supabase.currentUser else { EmptyView() }

        if currentUser.role == .buddy && request.status == .pending {
            Button("Accept this request") {
                Task { await accept() }
            }
        } else if currentUser.role == .buddy && request.status == .accepted {
            Button("Mark as In Progress") {
                Task { await updateStatus(.inProgress) }
            }
        } else if currentUser.role == .buddy && request.status == .inProgress {
            Button("Mark as Completed") {
                Task { await updateStatus(.completed) }
            }
        } else if currentUser.role == .client && request.status == .completed {
            Button("Rate this Buddy") { showRating = true }
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
            try data.write(to: tempURL)

        } catch {
            errorMessage = error.localizedDescription
        }
        isDownloading = false
    }
}
