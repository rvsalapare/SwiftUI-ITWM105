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

    private let brandColor = Color(red: 0.42, green: 0.08, blue: 0.1)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    avatar

                    if let user = supabase.currentUser, !isEditing {
                        VStack(spacing: 4) {
                            Text(user.name).font(.headline)
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill").foregroundStyle(.yellow)
                                Text(String(format: "%.1f", user.averageRating))
                                Text("(\(user.ratingCount))").foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                        }
                    }

                    if isEditing {
                        editForm
                        actionButtons
                    } else {
                        readOnlyDetails
                        Button("Edit Profile") {
                            loadEditableFields()
                            isEditing = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(brandColor)
                    }

                    if let errorMessage {
                        Text(errorMessage).font(.caption).foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .navigationTitle(isEditing ? "Edit Profile" : "Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showIconPicker) {
            iconPickerSheet
        }
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 110, height: 110)
                .overlay(
                    Image(systemName: selectedIcon)
                        .font(.system(size: 48))
                        .foregroundStyle(brandColor)
                )

            if isEditing {
                Button {
                    showIconPicker = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title)
                        .foregroundStyle(brandColor, .white)
                        .background(Circle().fill(.white))
                }
            }
        }
        .padding(.top, 12)
    }

    private var iconPickerSheet: some View {
        NavigationStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                ForEach(iconOptions, id: \.self) { icon in
                    Image(systemName: icon)
                        .font(.title)
                        .frame(width: 52, height: 52)
                        .foregroundStyle(selectedIcon == icon ? .white : brandColor)
                        .background(selectedIcon == icon ? brandColor : brandColor.opacity(0.1))
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

    private var editForm: some View {
        VStack(spacing: 12) {
            labeledField("Name", text: $name)
            labeledField("Contact Number", text: $contactNumber)
            labeledField("About Me", text: $aboutMe)
        }
    }

    private func labeledField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            TextField(label, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Cancel") {
                isEditing = false
                errorMessage = nil
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)

            Button {
                Task { await save() }
            } label: {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Save Changes")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(brandColor)
            .frame(maxWidth: .infinity)
            .disabled(isSaving)
        }
    }

    private var readOnlyDetails: some View {
        VStack(spacing: 10) {
            detailRow("Email", supabase.currentUser?.universityEmail ?? "")
            detailRow("Contact", supabase.currentUser?.contactNumber ?? "")
            detailRow("Role", supabase.currentUser?.role == .buddy ? "Errand Buddy" : "Client")
            if let about = supabase.currentUser?.aboutMe, !about.isEmpty {
                detailRow("About", about)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
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
