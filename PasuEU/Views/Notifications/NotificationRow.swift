import SwiftUI

struct NotificationRow: View {
    let notification: AppNotification

    private var timeText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: notification.createdAt, relativeTo: Date())
    }

    var body: some View {
        CardContainer(spacing: 0, padding: Theme.spacingMedium, fillsWidth: true) {
            HStack(alignment: .top, spacing: Theme.spacingMedium) {
                Image(systemName: notification.kind.symbol)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(notification.kind.tint)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(notification.title)
                        .font(.subheadline.weight(notification.isRead ? .semibold : .bold))
                        .foregroundStyle(.primary)
                    if let detail = notification.body, !detail.isEmpty {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    Text(timeText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !notification.isRead {
                    Circle()
                        .fill(Theme.brand)
                        .frame(width: 10, height: 10)
                        .padding(.top, 4)
                        .accessibilityLabel("Unread")
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.brand.opacity(notification.isRead ? 0 : 0.35), lineWidth: 1.5)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        NotificationRow(notification: AppNotification(
            id: UUID(), userId: UUID(), type: "new_request", title: "New Pabili request",
            body: "A client is waiting at the Library.", requestId: nil, conversationId: nil,
            readAt: nil, createdAt: Date().addingTimeInterval(-300)
        ))
        NotificationRow(notification: AppNotification(
            id: UUID(), userId: UUID(), type: "message", title: "New message",
            body: nil, requestId: nil, conversationId: nil,
            readAt: Date(), createdAt: Date().addingTimeInterval(-86_400)
        ))
    }
    .padding()
}
