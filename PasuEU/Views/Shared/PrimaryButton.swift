import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isLoading: Bool
    var isDisabled: Bool
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, isLoading: Bool = false,
         isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(isDisabled ? Theme.brand.opacity(Theme.disabledOpacity) : Theme.brand)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 12) {
        PrimaryButton("Log In") {}
        PrimaryButton("Log In", isDisabled: true) {}
        PrimaryButton("Log In", isLoading: true) {}
    }
    .padding()
}
