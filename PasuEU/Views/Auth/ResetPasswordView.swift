import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @Environment(\.dismiss) private var dismiss

    let email: String

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var didSucceed = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color(red: 0.42, green: 0.08, blue: 0.1))
                .padding(.top, 40)

            Text("Reset Password")
                .font(.title2.bold())

            SecureField("New Password", text: $newPassword)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            SecureField("Confirm New Password", text: $confirmPassword)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            if let errorMessage {
                Text(errorMessage).font(.caption).foregroundStyle(.red)
            }

            if didSucceed {
                Text("Password updated! You can log in now.")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }

            Button {
                Task { await save() }
            } label: {
                if isSaving { ProgressView().tint(.white) } else { Text("Save New Password").frame(maxWidth: .infinity) }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.42, green: 0.08, blue: 0.1))
            .padding(.horizontal)
            .disabled(!isValid || isSaving || didSucceed)

            Spacer()
        }
    }

    private var isValid: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            try await supabase.updatePassword(newPassword)
            didSucceed = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

#Preview {
    NavigationStack { ResetPasswordView(email: "student@msuef.edu.ph") }
        .environmentObject(SupabaseManager.shared)
}
