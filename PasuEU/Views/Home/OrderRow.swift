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

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(request.type.displayName)
                            .font(.subheadline.bold())
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(request.createdAt.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    badgesRow

                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle")
                        Text(request.meetingPlace)
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .overlay(alignment: .leading) {
            if request.isUrgent {
                Rectangle()
                    .fill(.red)
                    .frame(width: 3)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    @ViewBuilder
    private var badgesRow: some View {
        if request.isUrgent || isNew {
            HStack(spacing: 6) {
                if request.isUrgent {
                    OrderBadge(text: "URGENT", symbol: "exclamationmark.triangle.fill", color: .red)
                }
                if isNew {
                    OrderBadge(text: "NEW", color: .green)
                }
                Spacer(minLength: 0)
            }
        } else {
            OrderBadge(text: "NEW", color: .green)
                .hidden()
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        OrderRow(request: ServiceRequest(
            clientId: UUID(), type: .pabili, isUrgent: true, meetingPlace: "Library", createdAt: Date()
        ))
        OrderRow(request: ServiceRequest(
            clientId: UUID(), type: .pahatid, isUrgent: true, meetingPlace: "Engineering Building, Room 204",
            createdAt: Date().addingTimeInterval(-3_600)
        ))
        OrderRow(request: ServiceRequest(
            clientId: UUID(), type: .paprint, meetingPlace: "Gate 2", createdAt: Date()
        ))
        OrderRow(request: ServiceRequest(
            clientId: UUID(), type: .pabili, meetingPlace: "Cafeteria", createdAt: Date().addingTimeInterval(-3_600)
        ))
    }
    .padding()
}
