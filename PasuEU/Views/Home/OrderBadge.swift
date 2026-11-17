import SwiftUI

struct OrderBadge: View {
    let text: String
    var symbol: String?
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            if let symbol {
                Image(systemName: symbol)
            }
            Text(text)
                .lineLimit(1)
        }
        .font(.caption2.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .frame(height: 20)
        .background(color)
        .clipShape(Capsule())
        .fixedSize()
    }
}

#Preview {
    HStack(spacing: 6) {
        OrderBadge(text: "URGENT", symbol: "exclamationmark.triangle.fill", color: .red)
        OrderBadge(text: "NEW", color: .green)
    }
    .padding()
}
