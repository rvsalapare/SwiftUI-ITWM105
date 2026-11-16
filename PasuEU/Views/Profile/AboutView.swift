import SwiftUI

struct AboutView: View {
    private let teamMembers = ["Romina Victoria Salapare"]

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "figure.walk.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white, Theme.brand)
                    .padding(.top, 24)

                VStack(spacing: 4) {
                    Text("PasuEU").font(.title.bold())
                    Text(versionText).font(.subheadline).foregroundStyle(.secondary)
                }

                Text("PasuEU connects students who need a hand with students who can help. Ask an Errand Buddy to buy something, deliver an item, or print your documents, all inside campus.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("Manuel S. Enverga University Foundation")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.brand)

                CardContainer(spacing: 12, fillsWidth: true) {
                    infoRow(icon: "cart.fill", title: "Pabili", detail: "Have something bought for you.")
                    infoRow(icon: "shippingbox.fill", title: "Pahatid", detail: "Have an item delivered to someone.")
                    infoRow(icon: "printer.fill", title: "Paprint", detail: "Upload a file and have it printed.")
                }
                .padding(.horizontal)

                CardContainer(spacing: 12, fillsWidth: true) {
                    Text("Team").font(.headline)
                    ForEach(teamMembers, id: \.self) { member in
                        memberRow(name: member)
                    }
                }
                .padding(.horizontal)

                Text("Built for ITWM105 with SwiftUI and Supabase.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func memberRow(name: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.fill")
                .foregroundStyle(Theme.brand)
                .frame(width: 28)
            Text(name).font(.subheadline)
        }
    }

    private func infoRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.brand)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack { AboutView() }
}
