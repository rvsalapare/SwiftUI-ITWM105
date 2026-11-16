import SwiftUI

struct LoginView: View {
    @EnvironmentObject var supabase: SupabaseManager

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignUp = false
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ScreenHeader("Welcome Back", icon: "person.2.fill", style: .centered)

                    VStack(spacing: 20) {
                        VStack(spacing: 14) {
                            FormFieldRow(icon: "envelope.fill") {
                                TextField("University Email", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                            }
                            FormFieldRow(icon: "lock.fill") {
                                SecureField("Password", text: $password)
                            }

                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    showForgotPassword = true
                                }
                                .font(.caption.bold())
                                .foregroundStyle(Theme.brand)
                            }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        PrimaryButton("Log In", isLoading: isLoading, isDisabled: !canSubmit) {
                            Task { await signIn() }
                        }

                        Button("Don't have an account? Create Account") {
                            showSignUp = true
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                        demoSection
                    }
                    .padding(24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea(edges: .top)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .navigationDestination(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }

    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !isLoading
    }

    private var demoSection: some View {
        VStack(spacing: 10) {
            HStack {
                VStack { Divider() }
                Text("or preview the app")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                VStack { Divider() }
            }
            .padding(.top, 8)

            HStack(spacing: 12) {
                demoButton("Demo — Client") {
                    supabase.signInWithDemoAccount(role: .client)
                }
                demoButton("Demo — Buddy") {
                    supabase.signInWithDemoAccount(role: .buddy)
                }
            }
        }
    }

    private func demoButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .foregroundStyle(Theme.brand)
        .background(Theme.brand.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func signIn() async {
        isLoading = true
        errorMessage = nil
        do {
            try await supabase.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    LoginView().environmentObject(SupabaseManager.shared)
}
