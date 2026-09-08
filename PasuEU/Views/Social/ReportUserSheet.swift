import SwiftUI

struct ReportUserSheet: View {
    @EnvironmentObject var supabase: SupabaseManager
    @Environment(\.dismiss) private var dismiss

    let userToReport: AppUser

    private let reasons = [
        "Inappropriate behavior", "Did not show up", "Scam or fraud",
        "Harassment", "Other"
    ]

    @State private var selectedReason = "Inappropriate behavior"
    @State private var details = ""
    @State private var isSubmitting = false
    @State private var didSubmit = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.bubble.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color(red: 0.42, green: 0.08, blue: 0.1))
                .padding(.top, 28)

            Text("Report \(userToReport.name)")
                .font(.title3.bold())

            Picker("Reason", selection: $selectedReason) {
                ForEach(reasons, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)

            TextEditor(text: $details)
                .frame(height: 100)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.3)))
                .padding(.horizontal)

            if didSubmit {
                Text("Report submitted. Thank you.")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            }

            Button {
                Task { await submit() }
            } label: {
                if isSubmitting { ProgressView().tint(.white) } else { Text("Confirm").frame(maxWidth: .infinity) }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.42, green: 0.08, blue: 0.1))
            .padding(.horizontal)
            .disabled(isSubmitting || didSubmit)

            Spacer()
        }
    }

    private func submit() async {
        guard let uid = supabase.currentUser?.id else { return }
        isSubmitting = true
        let reason = details.isEmpty ? selectedReason : "\(selectedReason): \(details)"
        do {
            try await supabase.reportUser(reporterId: uid, reportedId: userToReport.id, reason: reason)
            didSubmit = true
        } catch {
            isSubmitting = false
        }
    }
}
