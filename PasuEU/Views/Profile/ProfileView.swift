import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State private var isEditing = false
    @State private var name = ""
    @State private var contactNumber = ""
    @State private var aboutMe = ""
    @State private var selectedIcon = "person.crop.circle.fill"
    @State private var showIconPicker = false
    @State private var errorMessage: String?
    @State private var isSaving = false

    private let iconOptions = [
        "person.crop.circle.fill", "face.smiling.fill", "star.circle.fill",
        "bolt.circle.fill", "leaf.circle.fill", "flame.circle.fill",
        "moon.stars.fill", "graduationcap.fill", "book.circle.fill",
        "pawprint.circle.fill", "gamecontroller.fill", "paintpalette.fill"
    ]

    private let brand = Color(red: 0.42, green: 0.08, blue: 0.1)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero

                    VStack(spacing: 20) {
                        identityBlock

                        if isEditing {
                            editForm
                            actionButtons
                        } else {
                            readOnlyDetails
                            Button {
                                loadEditableFields()
                                isEditing = true
                            } label: {
                                Label("Edit Profile", systemImage: "pencil")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .background(brand)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(24)
                    .padding(.top, 44)
                }
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea(edges: .top)
        }
        .sheet(isPresented: $showIconPicker) {
            iconPickerSheet
        }
    }

    // MARK: - Hero header + overlapping avatar

    private var hero: some View {
        ZStack {
            LinearGradient(
                colors: [brand, Color(red: 0.24, green: 0.04, blue: 0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: 150)
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 32, bottomTrailingRadius: 32))

            VStack {
                Text("Profile")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.top, 54)
                Spacer()
            }

            VStack {
                Spacer()
                avatar
                    .offset(y: 50)
            }
        }
        .frame(height: 150)
        .padding(.bottom, 50)
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(Color(.systemBackground))
                .frame(width: 108, height: 108)
                .overlay(
                    Circle()
                        .fill(brand.opacity(0.12))
                        .frame(width: 96, height: 96)
                )
                .overlay(
                    Image(systemName: selectedIcon)
                        .font(.system(size: 44))
                        .foregroundStyle(brand)
                )
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

            if isEditing {
                Button {
                    showIconPicker = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title)
                        .foregroundStyle(brand, .white)
                        .background(Circle().fill(.white))
                }
            }
        }
    }

    private var identityBlock: some View {
        VStack(spacing: 8) {
            if let user = supabase.currentUser {
                Text(user.name).font(.title3.bold())

                Text(user.role == .buddy ? "Errand Buddy" : "Client")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(brand.opacity(0.1))
                    .foregroundStyle(brand)
                    .clipShape(Capsule())

                if user.role == .buddy {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").foregroundStyle(.yellow)
                        Text(String(format: "%.1f", user.averageRating))
                        Text("(\(user.ratingCount) ratings)").foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private var iconPickerSheet: some View {
        NavigationStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                ForEach(iconOptions, id: \.self) { icon in
                    Image(systemName: icon)
                        .font(.title)
                        .frame(width: 52, height: 52)
                        .foregroundStyle(selectedIcon == icon ? .white : brand)
                        .background(selectedIcon == icon ? brand : brand.opacity(0.1))
                        .clipShape(Circle())
                        .onTapGesture {
                            selectedIcon = icon
                            showIconPicker = false
                        }
                }
            }
            .padding()
            .navigationTitle("Choose an Icon")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    // MARK: - Edit mode

    private var editForm: some View {
        VStack(spacing: 12) {
            fieldRow(icon: "person.fill") {
                TextField("Name", text: $name)
            }
            fieldRow(icon: "phone.fill") {
                TextField("Contact Number", text: $contactNumber)
                    .keyboardType(.phonePad)
            }
            fieldRow(icon: "text.quote") {
                TextField("About Me", text: $aboutMe)
            }
        }
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

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Cancel") {
                isEditing = false
                errorMessage = nil
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Button {
                Task { await save() }
            } label: {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Save Changes")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(brand)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(isSaving)
        }
    }

    // MARK: - Read-only mode

    private var readOnlyDetails: some View {
        VStack(spacing: 10) {
            detailRow(icon: "envelope.fill", label: "Email", value: supabase.currentUser?.universityEmail ?? "")
            detailRow(icon: "phone.fill", label: "Contact", value: supabase.currentUser?.contactNumber ?? "")
            if let about = supabase.currentUser?.aboutMe, !about.isEmpty {
                detailRow(icon: "text.quote", label: "About", value: about)
            }
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(brand)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func loadEditableFields() {
        name = supabase.currentUser?.name ?? ""
        contactNumber = supabase.currentUser?.contactNumber ?? ""
        aboutMe = supabase.currentUser?.aboutMe ?? ""
        selectedIcon = supabase.currentUser?.profileIconName ?? "person.crop.circle.fill"
    }

    private func save() async {
        guard let uid = supabase.currentUser?.id else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await supabase.updateProfile(
                uid: uid, name: name, contactNumber: contactNumber,
                aboutMe: aboutMe, profileIconName: selectedIcon
            )
            supabase.currentUser?.name = name
            supabase.currentUser?.contactNumber = contactNumber
            supabase.currentUser?.aboutMe = aboutMe
            supabase.currentUser?.profileIconName = selectedIcon
            isEditing = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

#Preview {
    ProfileView().environmentObject(SupabaseManager.shared)
}
