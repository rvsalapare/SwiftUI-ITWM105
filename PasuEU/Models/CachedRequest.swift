import Foundation
import SwiftData

@Model
final class CachedRequest {
    @Attribute(.unique) var id: UUID
    var ownerId: UUID
    var clientId: UUID
    var buddyId: UUID?
    var typeRaw: String
    var isUrgent: Bool
    var meetingPlace: String
    var destination: String?
    var note: String?
    var statusRaw: String
    var itemDescription: String?
    var recipientName: String?
    var fileURL: String?
    var fileName: String?
    var pages: Int?
    var copies: Int?
    var pageSize: String?
    var colorOption: String?
    var paymentMethodRaw: String?
    var serviceFee: Double
    var deliveryFee: Double
    var totalAmount: Double
    var buddyLatitude: Double?
    var buddyLongitude: Double?
    var createdAt: Date
    var completedAt: Date?

    init(_ request: ServiceRequest, ownerId: UUID) {
        self.id = request.id
        self.ownerId = ownerId
        self.clientId = request.clientId
        self.buddyId = request.buddyId
        self.typeRaw = request.type.rawValue
        self.isUrgent = request.isUrgent
        self.meetingPlace = request.meetingPlace
        self.destination = request.destination
        self.note = request.note
        self.statusRaw = request.status.rawValue
        self.itemDescription = request.itemDescription
        self.recipientName = request.recipientName
        self.fileURL = request.fileURL
        self.fileName = request.fileName
        self.pages = request.pages
        self.copies = request.copies
        self.pageSize = request.pageSize
        self.colorOption = request.colorOption
        self.paymentMethodRaw = request.paymentMethod?.rawValue
        self.serviceFee = request.serviceFee
        self.deliveryFee = request.deliveryFee
        self.totalAmount = request.totalAmount
        self.buddyLatitude = request.buddyLatitude
        self.buddyLongitude = request.buddyLongitude
        self.createdAt = request.createdAt
        self.completedAt = request.completedAt
    }

    func update(from request: ServiceRequest, ownerId: UUID) {
        self.ownerId = ownerId
        clientId = request.clientId
        buddyId = request.buddyId
        typeRaw = request.type.rawValue
        isUrgent = request.isUrgent
        meetingPlace = request.meetingPlace
        destination = request.destination
        note = request.note
        statusRaw = request.status.rawValue
        itemDescription = request.itemDescription
        recipientName = request.recipientName
        fileURL = request.fileURL
        fileName = request.fileName
        pages = request.pages
        copies = request.copies
        pageSize = request.pageSize
        colorOption = request.colorOption
        paymentMethodRaw = request.paymentMethod?.rawValue
        serviceFee = request.serviceFee
        deliveryFee = request.deliveryFee
        totalAmount = request.totalAmount
        buddyLatitude = request.buddyLatitude
        buddyLongitude = request.buddyLongitude
        createdAt = request.createdAt
        completedAt = request.completedAt
    }

    func toRequest() -> ServiceRequest {
        var request = ServiceRequest(
            clientId: clientId,
            type: ServiceType(rawValue: typeRaw) ?? .pabili,
            meetingPlace: meetingPlace
        )
        request.id = id
        request.buddyId = buddyId
        request.isUrgent = isUrgent
        request.destination = destination
        request.note = note
        request.status = RequestStatus(rawValue: statusRaw) ?? .pending
        request.itemDescription = itemDescription
        request.recipientName = recipientName
        request.fileURL = fileURL
        request.fileName = fileName
        request.pages = pages
        request.copies = copies
        request.pageSize = pageSize
        request.colorOption = colorOption
        request.paymentMethod = paymentMethodRaw.flatMap(PaymentMethod.init(rawValue:))
        request.serviceFee = serviceFee
        request.deliveryFee = deliveryFee
        request.totalAmount = totalAmount
        request.buddyLatitude = buddyLatitude
        request.buddyLongitude = buddyLongitude
        request.createdAt = createdAt
        request.completedAt = completedAt
        return request
    }
}
