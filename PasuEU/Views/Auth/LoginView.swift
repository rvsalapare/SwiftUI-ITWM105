import SwiftUI

struct LoginView: View {
    @EnvironmentObject var supabase: SupabaseManager

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignUp = false
    @State private var showForgotPassword = false

    private let brand = Color(red: 0.42, green: 0.08, blue: 0.1)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero

                    VStack(spacing: 20) {
                        VStack(spacing: 14) {
                            fieldRow(icon: "envelope.fill") {
                                TextField("University Email", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                            }
                            fieldRow(icon: "lock.fill") {
                                SecureField("Password", text: $password)
                            }

                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    showForgotPassword = true
                                }
                                .font(.caption.bold())
                                .foregroundStyle(brand)
                            }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task { await signIn() }
                        } label: {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Log In")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                        .background(canSubmit ? brand : brand.opacity(0.4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .disabled(!canSubmit)

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

    private var hero: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 38))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
                .background(.white.opacity(0.18))
                .clipShape(Circle())

            Text("Welcome Back")
                .font(.title2.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 76)
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                colors: [brand, Color(red: 0.24, green: 0.04, blue: 0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 32, bottomTrailingRadius: 32))
    }

    private func fieldRow<Content: View>(icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(brand)
                .frame(width: 20)
            content()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        .foregroundStyle(brand)
        .background(brand.opacity(0.1))
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
