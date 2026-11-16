import SwiftUI
import UniformTypeIdentifiers

private enum RequestStep: Int, CaseIterable {
    case service, payment, confirmation

    var label: String {
        switch self {
        case .service: return "Service"
        case .payment: return "Payment"
        case .confirmation: return "Confirmation"
        }
    }
}

struct NewRequestView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @Environment(\.dismiss) private var dismiss

    let type: ServiceType

    @State private var step: RequestStep = .service

    @State private var meetingPlace = ""
    @State private var destination = ""
    @State private var note = ""
    @State private var isUrgent = false
    @State private var itemDescription = ""
    @State private var recipientName = ""

    @State private var showFileImporter = false
    @State private var pickedFileURL: URL?
    @State private var pages = 1
    @State private var copies = 1
    @State private var pageSize = "A4"
    @State private var colorOption = FeeRates.blackAndWhiteOption

    @State private var paymentMethod: PaymentMethod = .cash
    @State private var gcashNumber = ""
    @State private var gcashOTP = ""
    @State private var cardNumber = ""
    @State private var cardExpiry = ""
    @State private var cardCVC = ""
    @State private var cardholderName = ""

    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var estimate: FeeEstimate {
        FeeRates.estimate(type: type, isUrgent: isUrgent, pages: pages,
                          copies: copies, colorOption: colorOption)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                stepIndicator

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch step {
                        case .service: serviceSection
                        case .payment: paymentSection
                        case .confirmation: confirmationSection
                        }

                        feeEstimateCard

                        if let errorMessage {
                            Text(errorMessage).font(.caption).foregroundStyle(.red)
                        }
                    }
                    .padding()
                }

                bottomBar
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(type.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf, .image, .plainText, .data],
                onCompletion: { result in
                    if case .success(let url) = result { pickedFileURL = url }
                }
            )
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(RequestStep.allCases, id: \.self) { s in
                VStack(spacing: 4) {
                    Circle()
                        .fill(s.rawValue <= step.rawValue ? Theme.brand : Color(.systemGray4))
                        .frame(width: 10, height: 10)
                    Text(s.label)
                        .font(.caption2)
                        .foregroundStyle(s == step ? .primary : .secondary)
                }
                if s != .confirmation {
                    Rectangle()
                        .fill(s.rawValue < step.rawValue ? Theme.brand : Color(.systemGray4))
                        .frame(height: 2)
                        .offset(y: -8)
                }
            }
        }
        .padding()
        .background(.white)
    }

    private var serviceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(type.displayName, systemImage: type.iconName)
                .font(.headline)
                .foregroundStyle(Theme.brand)

            if type == .paprint {
                fieldLabel("Attach your file")
                Button {
                    showFileImporter = true
                } label: {
                    Label(pickedFileURL?.lastPathComponent ?? "Upload from device",
                          systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)

                HStack {
                    Stepper("Pages: \(pages)", value: $pages, in: 1...500)
                    Stepper("Copies: \(copies)", value: $copies, in: 1...50)
                }
                Picker("Page size", selection: $pageSize) {
                    Text("A4").tag("A4"); Text("Letter").tag("Letter"); Text("Legal").tag("Legal")
                }
                .pickerStyle(.segmented)
                Picker("Color", selection: $colorOption) {
                    Text("Black & White").tag(FeeRates.blackAndWhiteOption)
                    Text("Colored").tag(FeeRates.coloredOption)
                }
                .pickerStyle(.segmented)
            } else {
                fieldLabel(type == .pabili ? "Your Order" : "Item to be delivered")
                TextField("Enter item here", text: $itemDescription, axis: .vertical)
                    .textFieldStyle(.roundedBorder)

                if type == .pahatid {
                    fieldLabel("Recipient")
                    TextField("Enter recipient's name here", text: $recipientName)
                        .textFieldStyle(.roundedBorder)
                }
            }

            fieldLabel("Meeting place")
            TextField("Enter meet-up place here", text: $meetingPlace)
                .textFieldStyle(.roundedBorder)

            if type != .pabili {
                fieldLabel("Location")
                TextField("Enter destination place here", text: $destination)
                    .textFieldStyle(.roundedBorder)
            }

            fieldLabel("Note")
            TextField("Enter any specifications", text: $note, axis: .vertical)
                .textFieldStyle(.roundedBorder)

            Toggle("Mark as urgent", isOn: $isUrgent)
        }
        .cardStyle()
    }

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            fieldLabel("Choose a payment method")
            Picker("Payment", selection: $paymentMethod) {
                Text("Cash").tag(PaymentMethod.cash)
                Text("GCash").tag(PaymentMethod.gcash)
                Text("Credit/Debit Card").tag(PaymentMethod.card)
            }
            .pickerStyle(.segmented)

            switch paymentMethod {
            case .cash:
                Text("Pay your buddy directly in cash upon meet-up.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            case .gcash:
                fieldLabel("GCash Number")
                TextField("09XXXXXXXXX", text: $gcashNumber)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                fieldLabel("OTP")
                HStack {
                    TextField("Enter OTP", text: $gcashOTP)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    Button("Send") {  }
                        .buttonStyle(.bordered)
                }

            case .card:
                fieldLabel("Card Number")
                TextField("XXXX XXXX XXXX XXXX", text: $cardNumber)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    TextField("MM/YY", text: $cardExpiry)
                        .textFieldStyle(.roundedBorder)
                    TextField("CVC", text: $cardCVC)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
                TextField("Name on Card", text: $cardholderName)
                    .textFieldStyle(.roundedBorder)
            }

        }
        .cardStyle()
    }

    private var feeEstimateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Estimated fees", systemImage: "pesosign.circle.fill")
                .font(.headline)
                .foregroundStyle(Theme.brand)

            feeRow("Service fee", estimate.baseServiceFee)
            if estimate.urgentSurcharge > 0 {
                feeRow("Urgent surcharge", estimate.urgentSurcharge)
            }
            if estimate.deliveryFee > 0 {
                feeRow("Delivery fee", estimate.deliveryFee)
            }
            if type == .paprint {
                feeRow(
                    "Print cost",
                    estimate.printCost,
                    detail: "\(pages) \(pages == 1 ? "page" : "pages") × \(copies) \(copies == 1 ? "copy" : "copies") × \(peso(FeeRates.printRate(for: colorOption)))"
                )
            }

            Divider()

            HStack {
                Text("Total").bold()
                Spacer()
                Text(peso(estimate.total)).bold()
            }
        }
        .cardStyle()
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

    private var confirmationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Review your request", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(Theme.brand)

            summaryRow("Service", type.displayName)
            if !itemDescription.isEmpty { summaryRow("Item", itemDescription) }
            if !recipientName.isEmpty { summaryRow("Recipient", recipientName) }
            if type == .paprint { summaryRow("File", pickedFileURL?.lastPathComponent ?? "—") }
            summaryRow("Meeting place", meetingPlace)
            if !destination.isEmpty { summaryRow("Destination", destination) }
            summaryRow("Payment", paymentLabel)
            summaryRow("Total", peso(estimate.total))
            if isUrgent { Label("Marked as urgent", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
        }
        .cardStyle()
    }

    private var paymentLabel: String {
        switch paymentMethod {
        case .cash: return "Cash"
        case .gcash: return "GCash"
        case .card: return "Credit/Debit Card"
        }
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if step != .service {
                Button("Back") { goBack() }
                    .buttonStyle(.bordered)
            }
            Button {
                if step == .confirmation {
                    Task { await submit() }
                } else {
                    goNext()
                }
            } label: {
                if isSubmitting {
                    ProgressView().tint(.white).frame(maxWidth: .infinity)
                } else {
                    Text(step == .confirmation ? "Submit" : "Next").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.brand)
            .disabled(!canProceed || isSubmitting)
        }
        .padding()
        .background(.white)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text).font(.caption).foregroundStyle(.secondary)
    }

    private func goNext() {
        withAnimation { step = RequestStep(rawValue: step.rawValue + 1) ?? step }
    }

    private func goBack() {
        withAnimation { step = RequestStep(rawValue: step.rawValue - 1) ?? step }
    }

    private var canProceed: Bool {
        switch step {
        case .service:
            guard !meetingPlace.isEmpty else { return false }
            switch type {
            case .pabili: return !itemDescription.isEmpty
            case .pahatid: return !itemDescription.isEmpty && !recipientName.isEmpty
            case .paprint: return pickedFileURL != nil
            }
        case .payment:
            switch paymentMethod {
            case .cash: return true
            case .gcash: return !gcashNumber.isEmpty
            case .card: return !cardNumber.isEmpty && !cardExpiry.isEmpty && !cardCVC.isEmpty
            }
        case .confirmation:
            return true
        }
    }

    private func submit() async {
        guard let clientId = supabase.currentUser?.id else { return }
        isSubmitting = true
        errorMessage = nil
        let fees = estimate

        var request = ServiceRequest(
            clientId: clientId,
            type: type,
            isUrgent: isUrgent,
            meetingPlace: meetingPlace,
            destination: destination.isEmpty ? nil : destination,
            note: note.isEmpty ? nil : note,
            itemDescription: type == .pabili || type == .pahatid ? itemDescription : nil,
            recipientName: type == .pahatid ? recipientName : nil,
            pages: type == .paprint ? pages : nil,
            copies: type == .paprint ? copies : nil,
            pageSize: type == .paprint ? pageSize : nil,
            colorOption: type == .paprint ? colorOption : nil,
            paymentMethod: paymentMethod,
            serviceFee: fees.serviceFee,
            deliveryFee: fees.deliveryFee,
            totalAmount: fees.total
        )

        do {
            if type == .paprint, let fileURL = pickedFileURL {
                let accessed = fileURL.startAccessingSecurityScopedResource()
                defer { if accessed { fileURL.stopAccessingSecurityScopedResource() } }

                let data = try Data(contentsOf: fileURL)
                let downloadURL = try await supabase.uploadFile(
                    data: data, fileName: fileURL.lastPathComponent, requestId: request.id
                )
                request.fileURL = downloadURL.absoluteString
                request.fileName = fileURL.lastPathComponent
            }

            try await supabase.createRequest(request)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}

private extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}

#Preview {
    NewRequestView(type: .paprint).environmentObject(SupabaseManager.shared)
}
