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
            VStack(spacing: 24) {
                Text("LOG IN!")
                    .font(.title2.bold())
                    .padding(.top, 40)

                VStack(spacing: 14) {
                    TextField("University Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            showForgotPassword = true
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await signIn() }
                } label: {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Log In").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.42, green: 0.08, blue: 0.1))
                .padding(.horizontal)
                .disabled(email.isEmpty || password.isEmpty || isLoading)

                Button("Don't have an account? Create Account") {
                    showSignUp = true
                }
                .font(.footnote)

                demoSection

                Spacer()
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .navigationDestination(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }

    private var demoSection: some View {
        VStack(spacing: 10) {
            HStack {
                VStack { Divider() }
                Text("or preview the app").font(.caption2).foregroundStyle(.secondary)
                VStack { Divider() }
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

            HStack(spacing: 12) {
                Button("Demo — Client") {
                    supabase.signInWithDemoAccount(role: .client)
                }
                .buttonStyle(.bordered)

                Button("Demo — Buddy") {
                    supabase.signInWithDemoAccount(role: .buddy)
                }
                .buttonStyle(.bordered)
            }
            .font(.footnote)
            .tint(Color(red: 0.42, green: 0.08, blue: 0.1))
        }
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
