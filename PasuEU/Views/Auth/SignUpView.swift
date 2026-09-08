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
            VStack(spacing: 16) {
                Text(role == .buddy ? "Register and become a BUDDY!" : "SIGN UP!")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.42, green: 0.08, blue: 0.1))

                Picker("I am a...", selection: $role) {
                    Text("Client").tag(UserRole.client)
                    Text("Errand Buddy").tag(UserRole.buddy)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Group {
                    TextField("Name *", text: $name)
                    if role == .buddy {
                        TextField("Student Number *", text: $studentNumber)
                    }
                    TextField("University Email *", text: $universityEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    TextField("Contact Number *", text: $contactNumber)
                        .keyboardType(.phonePad)
                    SecureField("Password *", text: $password)
                    SecureField("Confirm Password *", text: $confirmPassword)
                }
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

                if let errorMessage {
                    Text(errorMessage).font(.caption).foregroundStyle(.red)
                }

                Button {
                    Task { await signUp() }
                } label: {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Create Account").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.42, green: 0.08, blue: 0.1))
                .padding(.horizontal)
                .disabled(!isFormValid || isLoading)

                Button("Already have an account? Login") { dismiss() }
                    .font(.footnote)
                    .padding(.bottom, 24)
            }
        }
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
