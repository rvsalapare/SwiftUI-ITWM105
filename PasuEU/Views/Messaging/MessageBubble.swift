import SwiftUI

struct MessageBubble: View {
    let text: String
    let isMine: Bool
    let showsTail: Bool
    let maxWidth: CGFloat
    let footer: String?

    private let largeRadius: CGFloat = 18
    private let tailRadius: CGFloat = 4

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: largeRadius,
            bottomLeadingRadius: showsTail && !isMine ? tailRadius : largeRadius,
            bottomTrailingRadius: showsTail && isMine ? tailRadius : largeRadius,
            topTrailingRadius: largeRadius
        )
    }

    var body: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 2) {
            Text(text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isMine ? Theme.brand : Color(.secondarySystemGroupedBackground))
                .foregroundStyle(isMine ? Color.white : Color.primary)
                .clipShape(shape)

            if let footer {
                Text(footer)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: maxWidth, alignment: isMine ? .trailing : .leading)
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
    }
}

#Preview {
    VStack(spacing: 2) {
        MessageBubble(text: "Hi! I'm at the library.", isMine: false, showsTail: true, maxWidth: 280, footer: "3:42 PM")
        MessageBubble(text: "On my way.", isMine: true, showsTail: true, maxWidth: 280, footer: "3:43 PM · Seen")
    }
    .padding()
}
