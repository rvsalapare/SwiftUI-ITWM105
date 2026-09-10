import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var studentNumber = ""
    @State private var universityEmail = ""
    @State private var contactNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var role: UserRole = .client
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let brand = Color(red: 0.42, green: 0.08, blue: 0.1)

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero

                VStack(spacing: 16) {
                    Picker("I am a...", selection: $role) {
                        Text("Client").tag(UserRole.client)
                        Text("Errand Buddy").tag(UserRole.buddy)
                    }
                    .pickerStyle(.segmented)

                    fieldRow(icon: "person.fill") {
                        TextField("Name", text: $name)
                    }
                    if role == .buddy {
                        fieldRow(icon: "number") {
                            TextField("Student Number", text: $studentNumber)
                        }
                    }
                    fieldRow(icon: "envelope.fill") {
                        TextField("University Email", text: $universityEmail)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                    }
                    fieldRow(icon: "phone.fill") {
                        TextField("Contact Number", text: $contactNumber)
                            .keyboardType(.phonePad)
                    }
                    fieldRow(icon: "lock.fill") {
                        SecureField("Password", text: $password)
                    }
                    fieldRow(icon: "lock.fill") {
                        SecureField("Confirm Password", text: $confirmPassword)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await signUp() }
                    } label: {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Account")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(isFormValid ? brand : brand.opacity(0.4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(!isFormValid || isLoading)

                    Button("Already have an account? Login") { dismiss() }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 24)
                }
                .padding(24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
    }

    private var hero: some View {
        VStack(spacing: 8) {
            Image(systemName: role == .buddy ? "figure.walk.circle.fill" : "person.crop.circle.fill")
                .font(.system(size: 38))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
                .background(.white.opacity(0.18))
                .clipShape(Circle())

            Text(role == .buddy ? "Become an Errand Buddy" : "Create Your Account")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text(role == .buddy ? "Earn by helping fellow students" : "Get help with errands around campus")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
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

    private var isFormValid: Bool {
        !name.isEmpty && !universityEmail.isEmpty && !contactNumber.isEmpty
            && password.count >= 6 && password == confirmPassword
            && (role == .client || !studentNumber.isEmpty)
    }

    private func signUp() async {
        isLoading = true
        errorMessage = nil
        do {
            try await supabase.signUp(
                name: name,
                universityEmail: universityEmail,
                studentNumber: role == .buddy ? studentNumber : nil,
                contactNumber: contactNumber,
                password: password,
                role: role
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    SignUpView().environmentObject(SupabaseManager.shared)
}
