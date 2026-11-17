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
    @State private var loadFailed = false

    private var latestSentId: UUID? {
        messages.last(where: { $0.senderId == supabase.currentUser?.id })?.id
    }

    var body: some View {
        VStack(spacing: 0) {
            if loadFailed && !messages.isEmpty {
                OfflineNotice()
                    .padding(.top, 8)
            }

            if messages.isEmpty && loadFailed {
                EmptyStateView(
                    icon: "wifi.exclamationmark",
                    title: "Couldn't load this conversation",
                    message: "Check your connection and try again.",
                    retry: { attachListener() }
                )
                .frame(maxHeight: .infinity)
            } else if messages.isEmpty {
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right",
                    title: "Say hello to \(otherUser.name)",
                    message: "Your messages will show up here."
                )
                .frame(maxHeight: .infinity)
            } else {
                messageList
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

            ChatInputBar(text: $draft, isSending: isSending) {
                Task { await send() }
            }
        }
        .navigationTitle(otherUser.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                headerTitle
            }
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

    private var headerTitle: some View {
        HStack(spacing: 8) {
            Image(systemName: otherUser.profileIconName)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Theme.brand)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 0) {
                Text(otherUser.name)
                    .font(.subheadline.bold())
                Text(otherUser.isOnline ? "Online" : "Offline")
                    .font(.caption2)
                    .foregroundStyle(otherUser.isOnline ? Color.green : Color.secondary)
            }
        }
    }

    private var messageList: some View {
        GeometryReader { proxy in
            ScrollViewReader { reader in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(ChatEntry.build(from: messages)) { entry in
                            entryView(entry, maxWidth: proxy.size.width * 0.78)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }
                .defaultScrollAnchor(.bottom)
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    scrollToLatest(reader, animated: false)
                }
                .onChange(of: messages.count) { oldCount, _ in
                    scrollToLatest(reader, animated: oldCount > 0)
                }
            }
        }
    }

    private func entryView(_ entry: ChatEntry, maxWidth: CGFloat) -> some View {
        let isMine = entry.message.senderId == supabase.currentUser?.id
        return VStack(spacing: 0) {
            if let separatorDate = entry.separatorDate {
                DateSeparator(date: separatorDate)
            }

            MessageBubble(
                text: entry.message.text,
                isMine: isMine,
                showsTail: entry.isLastInGroup,
                maxWidth: maxWidth,
                footer: footer(for: entry, isMine: isMine)
            )
            .padding(.top, entry.isFirstInGroup ? 10 : 2)
        }
        .id(entry.id)
    }

    private func footer(for entry: ChatEntry, isMine: Bool) -> String? {
        guard entry.isLastInGroup else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var text = formatter.string(from: entry.message.sentAt)
        if isMine && entry.message.id == latestSentId {
            text += entry.message.readAt != nil ? " · Seen" : " · Sent"
        }
        return text
    }

    private func scrollToLatest(_ reader: ScrollViewProxy, animated: Bool) {
        guard let last = messages.last?.id else { return }
        if animated {
            withAnimation {
                reader.scrollTo(last, anchor: .bottom)
            }
        } else {
            reader.scrollTo(last, anchor: .bottom)
        }
    }

    private func attachListener() {
        let uid = supabase.currentUser?.id
        subscription?.remove()
        loadFailed = false
        if messages.isEmpty {
            messages = LocalStore.shared.loadMessages(conversationId: conversation.id)
        }
        if let uid {
            markRead(userId: uid)
        }
        subscription = supabase.listenToMessages(
            conversationId: conversation.id,
            onChange: { fetched in
                messages = fetched
                loadFailed = false
                if let uid, fetched.contains(where: { $0.senderId != uid && $0.readAt == nil }) {
                    markRead(userId: uid)
                }
            },
            onError: { _ in
                loadFailed = true
            }
        )
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
