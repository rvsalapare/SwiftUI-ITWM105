import SwiftUI

struct RequestProgressTracker: View {
    let status: RequestStatus

    private let labels = ["Pending", "Accepted", "In progress", "Completed"]
    private let circleSize: CGFloat = 24

    private var currentIndex: Int {
        switch status {
        case .pending: return 0
        case .accepted: return 1
        case .inProgress: return 2
        case .completed: return 3
        case .cancelled: return -1
        }
    }

    var body: some View {
        CardContainer(alignment: .center, fillsWidth: true) {
            if status == .cancelled {
                cancelledState
            } else {
                stepsRow
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Request status: \(status == .cancelled ? "Cancelled" : labels[currentIndex])")
    }

    private var cancelledState: some View {
        HStack(spacing: 8) {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
            Text("Cancelled")
                .font(.headline)
        }
        .foregroundStyle(.red)
    }

    private var stepsRow: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(labels.indices, id: \.self) { index in
                step(at: index)
                if index < labels.count - 1 {
                    Rectangle()
                        .fill(index < currentIndex ? Theme.brand : Color(.systemGray4))
                        .frame(height: 3)
                        .frame(maxWidth: .infinity)
                        .padding(.top, circleSize / 2 - 1.5)
                }
            }
        }
    }

    private func step(at index: Int) -> some View {
        let isFinished = index < currentIndex || (index == currentIndex && status == .completed)
        let isCurrent = index == currentIndex && status != .completed

        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isFinished || isCurrent ? Theme.brand : Color(.systemGray4))
                    .frame(width: circleSize, height: circleSize)

                if isCurrent {
                    Circle()
                        .stroke(Theme.brand.opacity(0.25), lineWidth: 5)
                        .frame(width: circleSize + 6, height: circleSize + 6)
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                } else if isFinished {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
            }
            .frame(width: circleSize + 6, height: circleSize + 6)

            Text(labels[index])
                .font(.caption2.weight(isCurrent ? .bold : .regular))
                .foregroundStyle(isFinished || isCurrent ? Color.primary : Color.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 60)
    }
}

#Preview {
    VStack(spacing: 16) {
        RequestProgressTracker(status: .pending)
        RequestProgressTracker(status: .inProgress)
        RequestProgressTracker(status: .completed)
        RequestProgressTracker(status: .cancelled)
    }
    .padding()
}
