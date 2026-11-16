import SwiftUI

struct RatingView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @Environment(\.dismiss) private var dismiss

    let request: ServiceRequest

    @State private var stars = 0
    @State private var comment = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var didSubmit = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Give our app a rating:")
                    .font(.headline)

                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { value in
                        Image(systemName: value <= stars ? "star.fill" : "star")
                            .font(.title)
                            .foregroundStyle(.yellow)
                            .onTapGesture { stars = value }
                    }
                }

                Text("Suggestions for improvements")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextEditor(text: $comment)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.3)))
                    .padding(.horizontal)

                if didSubmit {
                    Text("Thank you for your support!")
                        .foregroundStyle(.green)
                }

                if let errorMessage {
                    Text(errorMessage).font(.caption).foregroundStyle(.red)
                }

                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting { ProgressView() } else { Text("Confirm") }
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.brand)
                .disabled(stars == 0 || isSubmitting || didSubmit)

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
        guard let raterId = supabase.currentUser?.id,
              let ratedUserId = request.buddyId else { return }
        isSubmitting = true
        errorMessage = nil
        do {
            let rating = Rating(
                requestId: request.id,
                raterId: raterId,
                ratedUserId: ratedUserId,
                stars: stars,
                comment: comment.isEmpty ? nil : comment
            )
            try await supabase.submitRating(rating)
            didSubmit = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
