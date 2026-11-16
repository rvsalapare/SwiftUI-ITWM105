import SwiftUI

struct ScreenHeader<Accessory: View>: View {
    enum Style {
        case bar
        case centered
        case badge
    }

    let title: String
    var subtitle: String?
    var icon: String?
    var style: Style
    let accessory: Accessory

    init(_ title: String, subtitle: String? = nil, icon: String? = nil, style: Style = .bar,
         @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.style = style
        self.accessory = accessory()
    }

    var body: some View {
        switch style {
        case .bar:
            ZStack {
                Theme.brandGradient
                VStack {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .padding(.top, 60)
                    Spacer()
                }
            }
            .frame(height: 120)
            .clipShape(heroShape)

        case .centered:
            VStack(spacing: subtitle == nil ? 10 : 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 38))
                        .foregroundStyle(.white)
                        .frame(width: 76, height: 76)
                        .background(.white.opacity(0.18))
                        .clipShape(Circle())
                }

                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 76)
            .padding(.bottom, 40)
            .background(Theme.brandGradient)
            .clipShape(heroShape)

        case .badge:
            ZStack {
                Theme.brandGradient
                VStack(spacing: 10) {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(.white.opacity(0.18))
                            .clipShape(Circle())
                    }
                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    accessory
                }
                .padding(.top, 60)
            }
            .frame(height: 190)
            .clipShape(heroShape)
        }
    }

    private var heroShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(bottomLeadingRadius: Theme.heroRadius, bottomTrailingRadius: Theme.heroRadius)
    }
}

extension ScreenHeader where Accessory == EmptyView {
    init(_ title: String, subtitle: String? = nil, icon: String? = nil, style: Style = .bar) {
        self.init(title, subtitle: subtitle, icon: icon, style: style) { EmptyView() }
    }
}

#Preview {
    VStack(spacing: 16) {
        ScreenHeader("Settings")
        ScreenHeader("Welcome Back", icon: "person.2.fill", style: .centered)
        ScreenHeader("Pabili", icon: "cart.fill", style: .badge) {
            Text("Pending").font(.caption.bold()).foregroundStyle(.white)
        }
    }
}
