import SwiftUI

struct ChatThreadView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @Environment(\.dismiss) private var dismiss

    let conversation: Conversation
    let otherUser: AppUser

    @State private var messages: [Message] = []
    @State private var draft = ""
    @State private var subscription: DataSubscription?
    @State private var showBlockSheet = false
    @State private var showReportSheet = false
    @State private var sendError: String?
    @State private var isSending = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            bubble(for: message)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    if let last = messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }

            Divider()

            if let sendError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(sendError)
                        .font(.caption)
                    Spacer()
                    Button("Dismiss") { self.sendError = nil }
                        .font(.caption.bold())
                }
                .foregroundStyle(.red)
                .padding(.horizontal)
                .padding(.top, 8)
            }

            HStack(spacing: 8) {
                TextField("Type a message...", text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
            .padding()
        }
        .navigationTitle(otherUser.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Report User", systemImage: "exclamationmark.bubble") { showReportSheet = true }
                    Button("Block User", systemImage: "hand.raised.fill", role: .destructive) { showBlockSheet = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showBlockSheet) {
            BlockUserSheet(userToBlock: otherUser) { dismiss() }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportUserSheet(userToReport: otherUser)
        }
        .task { attachListener() }
        .onDisappear { subscription?.remove() }
    }

    private func bubble(for message: Message) -> some View {
        let isMine = message.senderId == supabase.currentUser?.id
        return HStack {
            if isMine { Spacer(minLength: 40) }
            Text(message.text)
                .padding(10)
                .background(isMine ? Theme.brand : Color(.secondarySystemGroupedBackground))
                .foregroundStyle(isMine ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
            if !isMine { Spacer(minLength: 40) }
        }
        .id(message.id)
    }

    private func attachListener() {
        let uid = supabase.currentUser?.id
        subscription = supabase.listenToMessages(conversationId: conversation.id) { fetched in
            messages = fetched
            if let uid, fetched.contains(where: { $0.senderId != uid && $0.readAt == nil }) {
                markRead(userId: uid)
            }
        }
    }

    private func markRead(userId: UUID) {
        Task {
            try? await supabase.markConversationRead(conversationId: conversation.id, userId: userId)
        }
    }

    private func send() async {
        guard let uid = supabase.currentUser?.id else { return }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        isSending = true
        sendError = nil
        let message = Message(conversationId: conversation.id, senderId: uid, text: text)
        do {
            try await supabase.sendMessage(conversationId: conversation.id, message: message)
            draft = ""
        } catch {
            sendError = "Message not sent. Check your connection and try again."
        }
        isSending = false
    }
}
