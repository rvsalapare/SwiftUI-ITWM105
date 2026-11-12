import SwiftUI

struct AboutView: View {
    private let brand = Color(red: 0.42, green: 0.08, blue: 0.1)

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
                    .foregroundStyle(.white, brand)
                    .padding(.top, 24)

                VStack(spacing: 4) {
                    Text("PasuEU").font(.title.bold())
                    Text(versionText).font(.subheadline).foregroundStyle(.secondary)
                }

                Text("PasuEU connects students who need a hand with students who can help. Ask an Errand Buddy to buy something, deliver an item, or print your documents, all inside campus.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    infoRow(icon: "cart.fill", title: "Pabili", detail: "Have something bought for you.")
                    infoRow(icon: "shippingbox.fill", title: "Pahatid", detail: "Have an item delivered to someone.")
                    infoRow(icon: "printer.fill", title: "Paprint", detail: "Upload a file and have it printed.")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
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

    private func infoRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(brand)
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
