import SwiftUI

struct OfflineNotice: View {
    var body: some View {
        Label("Offline: showing saved data", systemImage: "wifi.slash")
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(Capsule())
    }
}

#Preview {
    OfflineNotice()
        .padding()
}
