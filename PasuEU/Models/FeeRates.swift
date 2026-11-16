import Foundation

struct FeeRates {
    static let baseServiceFee: Double = 15
    static let urgentSurcharge: Double = 10
    static let pahatidDeliveryFee: Double = 20
    static let blackAndWhitePerPage: Double = 3
    static let colorPerPage: Double = 8

    static let blackAndWhiteOption = "Black & White"
    static let coloredOption = "Colored"

    static func printRate(for colorOption: String) -> Double {
        colorOption == coloredOption ? colorPerPage : blackAndWhitePerPage
    }

    static func estimate(type: ServiceType, isUrgent: Bool, pages: Int, copies: Int,
                         colorOption: String) -> FeeEstimate {
        FeeEstimate(
            baseServiceFee: baseServiceFee,
            urgentSurcharge: isUrgent ? urgentSurcharge : 0,
            deliveryFee: type == .pahatid ? pahatidDeliveryFee : 0,
            printCost: type == .paprint
                ? printRate(for: colorOption) * Double(pages) * Double(copies)
                : 0
        )
    }
}
