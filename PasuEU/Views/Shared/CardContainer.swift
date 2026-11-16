import SwiftUI

struct CardContainer<Content: View>: View {
    var alignment: HorizontalAlignment
    var spacing: CGFloat
    var padding: CGFloat
    var cornerRadius: CGFloat
    var fillsWidth: Bool
    let content: Content

    init(alignment: HorizontalAlignment = .leading,
         spacing: CGFloat = 10,
         padding: CGFloat = Theme.spacingLarge,
         cornerRadius: CGFloat = Theme.cardRadius,
         fillsWidth: Bool = false,
         @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.fillsWidth = fillsWidth
        self.content = content()
    }

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            content
        }
        .padding(padding)
        .frame(maxWidth: fillsWidth ? .infinity : nil, alignment: Alignment(horizontal: alignment, vertical: .center))
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    CardContainer {
        Text("Meeting place")
        Text("Library").font(.subheadline)
    }
    .padding()
}
