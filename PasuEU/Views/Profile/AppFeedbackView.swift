import SwiftUI

struct AppFeedbackView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var stars = 0
    @State private var suggestion = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Give our app a rating:").font(.headline)
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { value in
                        Image(systemName: value <= stars ? "star.fill" : "star")
                            .font(.title)
                            .foregroundStyle(.yellow)
                            .onTapGesture { stars = value }
                    }
                }
                TextEditor(text: $suggestion)
                    .frame(height: 120)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.3)))
                    .padding(.horizontal)

                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting { ProgressView() } else { Text("Confirm") }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.42, green: 0.08, blue: 0.1))
                .disabled(stars == 0 || isSubmitting)

                Spacer()
            }
            .padding()
            .navigationTitle("Feedback")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
        }
    }

    private func submit() async {
        guard let uid = supabase.currentUser?.id else { return }
        isSubmitting = true
        let feedback = AppFeedback(userId: uid, stars: stars, suggestion: suggestion.isEmpty ? nil : suggestion)
        try? await supabase.submitFeedback(feedback)
        isSubmitting = false
        dismiss()
    }
}
