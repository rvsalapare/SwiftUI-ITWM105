import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var goToOTP = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.rotation")
                .font(.system(size: 48))
                .foregroundStyle(Color(red: 0.42, green: 0.08, blue: 0.1))
                .padding(.top, 40)

            Text("Forgot Password")
                .font(.title2.bold())

            Text("Enter your university email and we'll send you a code to reset your password.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            TextField("University Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            if let errorMessage {
                Text(errorMessage).font(.caption).foregroundStyle(.red)
            }

            Button {
                Task { await sendResetCode() }
            } label: {
                if isSending { ProgressView().tint(.white) } else { Text("Request Password").frame(maxWidth: .infinity) }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.42, green: 0.08, blue: 0.1))
            .padding(.horizontal)
            .disabled(email.isEmpty || isSending)

            Spacer()
        }
        .navigationDestination(isPresented: $goToOTP) {
            OTPVerificationView(email: email, purpose: .passwordReset)
        }
    }

    private func sendResetCode() async {
        isSending = true
        errorMessage = nil
        do {
            try await supabase.sendPasswordResetOTP(email: email)
            goToOTP = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSending = false
    }
}

#Preview {
    NavigationStack { ForgotPasswordView() }.environmentObject(SupabaseManager.shared)
}
