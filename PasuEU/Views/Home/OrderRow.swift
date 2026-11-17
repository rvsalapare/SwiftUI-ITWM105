import SwiftUI

struct OrderRow: View {
    let request: ServiceRequest

    private var isNew: Bool {
        Date().timeIntervalSince(request.createdAt) < 300
    }

    var body: some View {
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
                            Label("URGENT", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.red)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        if isNew {
                            Text("NEW")
                                .font(.caption2.bold())
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(.green)
                                .foregroundStyle(.white)
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
}

#Preview {
    VStack(spacing: 12) {
        OrderRow(request: ServiceRequest(clientId: UUID(), type: .pabili, isUrgent: true, meetingPlace: "Library"))
        OrderRow(request: ServiceRequest(clientId: UUID(), type: .paprint, meetingPlace: "Gate 2"))
    }
    .padding()
}
