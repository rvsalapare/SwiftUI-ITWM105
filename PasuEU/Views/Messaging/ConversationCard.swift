import SwiftUI

struct ConversationCard: View {
    let row: ConversationRow
    let unreadCount: Int

    private var isUnread: Bool { unreadCount > 0 }

    private var timeText: String? {
        guard let date = row.conversation.lastMessageAt else { return nil }
        let calendar = Calendar.current
        let seconds = Date().timeIntervalSince(date)
        if calendar.isDateInToday(date) {
            if seconds < 60 { return "now" }
            if seconds < 3600 { return "\(Int(seconds / 60))m" }
            return "\(Int(seconds / 3600))h"
        }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    var body: some View {
        CardContainer(spacing: 0, padding: Theme.spacingMedium, fillsWidth: true) {
            HStack(alignment: .top, spacing: Theme.spacingMedium) {
                avatar

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.otherUser.name)
                            .font(.subheadline.weight(isUnread ? .bold : .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        if let timeText {
                            Text(timeText)
                                .font(.caption)
                                .foregroundStyle(isUnread ? Theme.brand : .secondary)
                        }
                    }

                    HStack(alignment: .center) {
                        Text(row.conversation.lastMessage ?? "Say hello!")
                            .font(.caption.weight(isUnread ? .bold : .regular))
                            .foregroundStyle(isUnread ? .primary : .secondary)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        if isUnread {
                            UnreadBadge(count: unreadCount)
                        }
                    }
                }
            }
        }
        .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
    }

    private var avatar: some View {
        Image(systemName: row.otherUser.profileIconName)
            .font(.title2)
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(Theme.brand)
            .clipShape(Circle())
            .overlay(alignment: .bottomTrailing) {
                if row.otherUser.isOnline {
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color(.secondarySystemGroupedBackground), lineWidth: 2))
                        .accessibilityLabel("Online")
                }
            }
    }
}
