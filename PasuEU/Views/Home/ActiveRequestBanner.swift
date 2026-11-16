import SwiftUI

struct ActiveRequestBanner: View {
    let request: ServiceRequest
    let isBuddy: Bool

    private var statusLabel: String {
        switch request.status {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .inProgress: return "In progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    private var statusLine: String {
        switch request.status {
        case .pending: return "Waiting for a buddy"
        case .accepted: return isBuddy ? "You accepted this request" : "Your buddy is on the way"
        case .inProgress: return "In progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var body: some View {
        HStack(spacing: Theme.spacingMedium) {
            Image(systemName: request.type.iconName)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.18))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(request.type.displayName)
                        .font(.headline)
                    Text(statusLabel)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                Text(statusLine)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.85))
        }
        .foregroundStyle(.white)
        .padding(Theme.spacingLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.brandGradient)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ActiveRequestBanner(
        request: ServiceRequest(clientId: UUID(), type: .pabili, meetingPlace: "Library", status: .accepted),
        isBuddy: false
    )
    .padding()
}
