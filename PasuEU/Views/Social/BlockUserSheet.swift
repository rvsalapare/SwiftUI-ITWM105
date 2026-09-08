import SwiftUI

struct BlockUserSheet: View {
    @EnvironmentObject var supabase: SupabaseManager
    @Environment(\.dismiss) private var dismiss

    let userToBlock: AppUser
    var onBlocked: () -> Void = {}

    @State private var isBlocking = false
    @State private var didBlock = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 44))
                .foregroundStyle(.red)
                .padding(.top, 32)

            Text("Block user")
                .font(.title3.bold())

            Text("Are you sure you want to block \(userToBlock.name)? You won't see requests or messages from each other anymore.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if didBlock {
                Text("User blocked.")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            }

            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                Button {
                    Task { await block() }
                } label: {
                    if isBlocking { ProgressView().tint(.white) } else { Text("Confirm") }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .frame(maxWidth: .infinity)
                .disabled(isBlocking || didBlock)
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    private func block() async {
        guard let uid = supabase.currentUser?.id else { return }
        isBlocking = true
        do {
            try await supabase.blockUser(blockerId: uid, blockedId: userToBlock.id)
            didBlock = true
            onBlocked()
            dismiss()
        } catch {
            isBlocking = false
        }
    }
}

#Preview {
    BlockUserSheet(userToBlock: AppUser(
        id: UUID(), name: "Carlo Reyes", universityEmail: "carlo.reyes@student.msuef.edu.ph",
        contactNumber: "0900000000", role: .buddy
    ))
    .environmentObject(SupabaseManager.shared)
}
