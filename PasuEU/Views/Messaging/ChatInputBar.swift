import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    let isSending: Bool
    let onSend: () -> Void

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Type a message...", text: $text, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(Capsule())

            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(canSend ? Theme.brand : Color(.systemGray3))
                    .clipShape(Circle())
            }
            .disabled(!canSend)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }
}

#Preview {
    VStack {
        Spacer()
        ChatInputBar(text: .constant("Hello"), isSending: false) {}
    }
}
