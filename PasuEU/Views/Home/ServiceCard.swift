import SwiftUI

private struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct ServiceCard: View {
    let type: ServiceType
    let action: () -> Void

    private var tagline: String {
        switch type {
        case .pabili: return "We buy it for you"
        case .pahatid: return "We deliver it to someone"
        case .paprint: return "Upload a file and we print it"
        }
    }

    var body: some View {
        Button(action: action) {
            CardContainer(spacing: 0, padding: Theme.spacingLarge, fillsWidth: true) {
                HStack(spacing: Theme.spacingLarge) {
                    Image(systemName: type.iconName)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Theme.brand)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(type.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(tagline)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(ServiceType.allCases, id: \.self) { type in
            ServiceCard(type: type) {}
        }
    }
    .padding()
}
