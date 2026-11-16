import SwiftUI

struct FormFieldRow<Content: View>: View {
    let icon: String
    let content: Content

    init(icon: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.brand)
                .frame(width: 20)
            content
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.fieldRadius))
    }
}

#Preview {
    FormFieldRow(icon: "envelope.fill") {
        TextField("University Email", text: .constant(""))
    }
    .padding()
}
