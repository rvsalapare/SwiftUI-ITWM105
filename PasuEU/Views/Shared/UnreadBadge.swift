import SwiftUI

struct UnreadBadge: View {
    let count: Int
    var tint: Color = Theme.brand
    var bordered = false

    var body: some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .frame(minWidth: 20)
            .background(tint)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(.white, lineWidth: bordered ? 1.5 : 0))
            .accessibilityLabel("\(count) unread")
    }
}

#Preview {
    HStack(spacing: 16) {
        UnreadBadge(count: 3)
        UnreadBadge(count: 120, tint: .red, bordered: true)
    }
    .padding()
}
