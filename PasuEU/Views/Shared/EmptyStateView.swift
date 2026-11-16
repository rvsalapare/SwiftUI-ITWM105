import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var retryTitle: String = "Try again"
    var retry: (() -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let retry {
                Button(action: retry) {
                    Label(retryTitle, systemImage: "arrow.clockwise")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.brand)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    VStack {
        EmptyStateView(icon: "tray", title: "No open requests right now",
                       message: "New requests will show up here as soon as a client posts one.")
        EmptyStateView(icon: "wifi.exclamationmark", title: "Couldn't load",
                       message: "Check your connection and try again.", retry: {})
    }
    .padding()
}
