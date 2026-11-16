import SwiftUI

enum OTPPurpose {
    case passwordReset
    case emailVerification
}

struct OTPVerificationView: View {
    @EnvironmentObject var supabase: SupabaseManager

    let email: String
    let purpose: OTPPurpose

    @State private var digits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?
    @State private var isVerifying = false
    @State private var errorMessage: String?
    @State private var goToReset = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 48))
                .foregroundStyle(Theme.brand)
                .padding(.top, 40)

            Text("Verify Your Email")
                .font(.title2.bold())

            Text("Enter the 6-digit code sent to \(email)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    TextField("", text: $digits[index])
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.title2.bold())
                        .frame(width: 42, height: 52)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .focused($focusedIndex, equals: index)
                        .onChange(of: digits[index]) { _, newValue in
                            if newValue.count > 1 { digits[index] = String(newValue.suffix(1)) }
                            if !newValue.isEmpty && index < 5 { focusedIndex = index + 1 }
                        }
                }
            }

            if let errorMessage {
                Text(errorMessage).font(.caption).foregroundStyle(.red)
            }

            Button {
                Task { await verify() }
            } label: {
                if isVerifying { ProgressView().tint(.white) } else { Text("Verify").frame(maxWidth: .infinity) }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.brand)
            .padding(.horizontal)
            .disabled(digits.contains("") || isVerifying)

            Button("Resend code for another one") {
                Task { try? await supabase.sendPasswordResetOTP(email: email) }
            }
            .font(.footnote)

            Spacer()
        }
        .navigationDestination(isPresented: $goToReset) {
            ResetPasswordView(email: email)
        }
        .onAppear { focusedIndex = 0 }
    }

    private var code: String { digits.joined() }

    private func verify() async {
        isVerifying = true
        errorMessage = nil
        /*do {
            try await supabase.client.auth.verifyOTP(
                email: email, token: code,
                type: purpose == .passwordReset ? .recovery : .email
            )
            goToReset = true
        } catch {
            errorMessage = "That code didn't work — check it and try again."
        }
        isVerifying = false*/
    }
}

#Preview {
    NavigationStack { OTPVerificationView(email: "student@msuef.edu.ph", purpose: .passwordReset) }
        .environmentObject(SupabaseManager.shared)
}
