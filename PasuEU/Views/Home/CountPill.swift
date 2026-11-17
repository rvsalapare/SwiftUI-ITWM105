import SwiftUI

struct CountPill: View {
    let count: Int

    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isPulsing: Bool { pulse && !reduceMotion }

    var body: some View {
        Text("\(count)")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Theme.brand, in: Capsule())
            .scaleEffect(isPulsing ? 1.12 : 1)
            .animation(
                isPulsing ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : .default,
                value: isPulsing
            )
            .onAppear { pulse = count > 0 }
            .onChange(of: count > 0) { _, hasOrders in
                pulse = hasOrders
            }
            .accessibilityLabel("\(count) open \(count == 1 ? "order" : "orders")")
    }
}

#Preview {
    HStack(spacing: 16) {
        CountPill(count: 3)
        CountPill(count: 0)
    }
    .padding()
}
