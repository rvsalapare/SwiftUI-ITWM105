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

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(
                    role == .buddy ? "Become an Errand Buddy" : "Create Your Account",
                    subtitle: role == .buddy ? "Earn by helping fellow students" : "Get help with errands around campus",
                    icon: role == .buddy ? "figure.walk.circle.fill" : "person.crop.circle.fill",
                    style: .centered
                )

                VStack(spacing: 16) {
                    Picker("I am a...", selection: $role) {
                        Text("Client").tag(UserRole.client)
                        Text("Errand Buddy").tag(UserRole.buddy)
                    }
                    .pickerStyle(.segmented)

                    FormFieldRow(icon: "person.fill") {
                        TextField("Name", text: $name)
                    }
                    if role == .buddy {
                        FormFieldRow(icon: "number") {
                            TextField("Student Number", text: $studentNumber)
                        }
                    }
                    FormFieldRow(icon: "envelope.fill") {
                        TextField("University Email", text: $universityEmail)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                    }
                    if !trimmedEmail.isEmpty && !isEmailValid {
                        Text("Use your university email (\(Self.requiredEmailSuffix))")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    FormFieldRow(icon: "phone.fill") {
                        TextField("Contact Number", text: $contactNumber)
                            .keyboardType(.phonePad)
                    }
                    FormFieldRow(icon: "lock.fill") {
                        SecureField("Password", text: $password)
                    }
                    FormFieldRow(icon: "lock.fill") {
                        SecureField("Confirm Password", text: $confirmPassword)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    PrimaryButton("Create Account", isLoading: isLoading, isDisabled: !isFormValid) {
                        Task { await signUp() }
                    }

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

    private static let requiredEmailSuffix = "@student.mseuf.edu.ph"

    private var trimmedEmail: String {
        universityEmail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isEmailValid: Bool {
        let email = trimmedEmail.lowercased()
        return email.hasSuffix(Self.requiredEmailSuffix) && email.count > Self.requiredEmailSuffix.count
    }

    private var isFormValid: Bool {
        !name.isEmpty && isEmailValid && !contactNumber.isEmpty
            && password.count >= 6 && password == confirmPassword
            && (role == .client || !studentNumber.isEmpty)
    }

    private func signUp() async {
        isLoading = true
        errorMessage = nil
        do {
            try await supabase.signUp(
                name: name,
                universityEmail: trimmedEmail,
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
