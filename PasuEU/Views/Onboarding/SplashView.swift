import SwiftUI

struct SplashView: View {
    var onGetStarted: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.brand, Color(red: 0.18, green: 0.03, blue: 0.04)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "person.2.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)

                VStack(spacing: 6) {
                    Text("Welcome to")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("PasuEU")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("Errands made easy, campus made closer.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                Button(action: onGetStarted) {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .foregroundStyle(Theme.brand)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    SplashView(onGetStarted: {})
}
