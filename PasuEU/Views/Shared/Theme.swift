import SwiftUI

enum Theme {
    static let brand = Color(red: 0.42, green: 0.08, blue: 0.1)
    static let brandDark = Color(red: 0.24, green: 0.04, blue: 0.06)

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [brand, brandDark],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    static let cardRadius: CGFloat = 14
    static let fieldRadius: CGFloat = 12
    static let heroRadius: CGFloat = 32

    static let disabledOpacity: Double = 0.4

    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 12
    static let spacingLarge: CGFloat = 16
    static let spacingXLarge: CGFloat = 24
}
