import SwiftUI

struct FeeBreakdownCard: View {
    let request: ServiceRequest

    private var printCost: Double {
        request.totalAmount - request.serviceFee - request.deliveryFee
    }

    private var printDetail: String {
        let pages = request.pages ?? 0
        let copies = request.copies ?? 0
        var detail = "\(pages) \(pages == 1 ? "page" : "pages") × \(copies) \(copies == 1 ? "copy" : "copies")"
        if let colorOption = request.colorOption {
            detail += ", \(colorOption)"
        }
        return detail
    }

    private var paymentLabel: String {
        switch request.paymentMethod {
        case .cash: return "Cash"
        case .gcash: return "GCash"
        case .card: return "Credit/Debit Card"
        case nil: return "—"
        }
    }

    var body: some View {
        CardContainer(spacing: 8, fillsWidth: true) {
            Label("Fee breakdown", systemImage: "pesosign.circle.fill")
                .font(.headline)
                .foregroundStyle(Theme.brand)

            feeRow("Service fee", request.serviceFee)
            if request.deliveryFee > 0 {
                feeRow("Delivery fee", request.deliveryFee)
            }
            if request.type == .paprint {
                feeRow("Print cost", printCost, detail: printDetail)
            }

            Divider()

            HStack {
                Text("Total").bold()
                Spacer()
                Text(peso(request.totalAmount)).bold()
            }
            .font(.subheadline)

            HStack {
                Text("Payment").foregroundStyle(.secondary)
                Spacer()
                Text(paymentLabel)
            }
            .font(.subheadline)
        }
    }

    private func feeRow(_ label: String, _ amount: Double, detail: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(peso(amount))
        }
        .font(.subheadline)
    }

    private func peso(_ amount: Double) -> String {
        String(format: "₱%.2f", amount)
    }
}

#Preview {
    FeeBreakdownCard(request: ServiceRequest(
        clientId: UUID(),
        type: .paprint,
        meetingPlace: "Library",
        pages: 3,
        copies: 2,
        colorOption: "Colored",
        paymentMethod: .gcash,
        serviceFee: 15,
        deliveryFee: 0,
        totalAmount: 63
    ))
    .padding()
}
