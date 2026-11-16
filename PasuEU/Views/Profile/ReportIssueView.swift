import SwiftUI

struct ReportIssueView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var issueText = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var trimmedText: String {
        issueText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Describe the issue you ran into:")
                    .font(.headline)

                TextEditor(text: $issueText)
                    .frame(minHeight: 160)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.3)))

                Button {
                    Task { await send() }
                } label: {
                    Group {
                        if isSubmitting { ProgressView() } else { Text("Send") }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.brand)
                .disabled(trimmedText.isEmpty || isSubmitting)

                Spacer()
            }
            .padding()
            .navigationTitle("Report an issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
            .alert("Couldn't send your report", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func send() async {
        guard let uid = supabase.currentUser?.id else {
            errorMessage = "You need to be signed in to report an issue."
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await supabase.submitIssue(userId: uid, description: trimmedText)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ReportIssueView().environmentObject(SupabaseManager.shared)
}
