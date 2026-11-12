import SwiftUI

struct HelpView: View {
    private struct Entry: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
    }

    private let entries: [Entry] = [
        Entry(question: "How do I make a request?",
              answer: "On the Home tab, choose Pabili, Pahatid or Paprint, fill in the details, pick a payment method and confirm. Your request is then visible to available Errand Buddies."),
        Entry(question: "How does a buddy accept my request?",
              answer: "Buddies see open requests on their Home tab and can accept one. Once accepted, you can message your buddy and follow them on the map."),
        Entry(question: "How do I track my buddy?",
              answer: "Open the request from Home or Transactions and tap the live tracking card. Location sharing must be allowed for the app."),
        Entry(question: "How does Paprint work?",
              answer: "Choose your file, then set pages, copies, paper size and color. Your assigned buddy can download the file and print it for you."),
        Entry(question: "How do I become an Errand Buddy?",
              answer: "Choose the Buddy role when you sign up. Buddies can switch themselves online or offline to control when they receive requests."),
        Entry(question: "How do I rate a buddy?",
              answer: "After a request is completed, open it and leave a star rating and an optional comment."),
        Entry(question: "How do I block or report someone?",
              answer: "Open the chat with that person and use the menu to block or report them. You can also report a problem from a request's details."),
        Entry(question: "I forgot my password.",
              answer: "On the login screen tap Forgot Password. We will email a code you can use to set a new password.")
    ]

    var body: some View {
        List(entries) { entry in
            DisclosureGroup {
                Text(entry.answer)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } label: {
                Text(entry.question).font(.headline)
            }
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { HelpView() }
}
