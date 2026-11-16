import Foundation

struct FeeEstimate {
    let baseServiceFee: Double
    let urgentSurcharge: Double
    let deliveryFee: Double
    let printCost: Double

    var serviceFee: Double { baseServiceFee + urgentSurcharge }
    var total: Double { serviceFee + deliveryFee + printCost }
}
