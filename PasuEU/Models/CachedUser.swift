import Foundation
import SwiftData

@Model
final class CachedUser {
    @Attribute(.unique) var id: UUID
    var name: String
    var universityEmail: String
    var studentNumber: String?
    var contactNumber: String
    var roleRaw: String
    var aboutMe: String?
    var profileIconName: String
    var isOnline: Bool
    var averageRating: Double
    var ratingCount: Int
    var createdAt: Date
    var isAvailable: Bool
    var currentLatitude: Double?
    var currentLongitude: Double?

    init(_ user: AppUser) {
        self.id = user.id
        self.name = user.name
        self.universityEmail = user.universityEmail
        self.studentNumber = user.studentNumber
        self.contactNumber = user.contactNumber
        self.roleRaw = user.role.rawValue
        self.aboutMe = user.aboutMe
        self.profileIconName = user.profileIconName
        self.isOnline = user.isOnline
        self.averageRating = user.averageRating
        self.ratingCount = user.ratingCount
        self.createdAt = user.createdAt
        self.isAvailable = user.isAvailable
        self.currentLatitude = user.currentLatitude
        self.currentLongitude = user.currentLongitude
    }

    func update(from user: AppUser) {
        name = user.name
        universityEmail = user.universityEmail
        studentNumber = user.studentNumber
        contactNumber = user.contactNumber
        roleRaw = user.role.rawValue
        aboutMe = user.aboutMe
        profileIconName = user.profileIconName
        isOnline = user.isOnline
        averageRating = user.averageRating
        ratingCount = user.ratingCount
        createdAt = user.createdAt
        isAvailable = user.isAvailable
        currentLatitude = user.currentLatitude
        currentLongitude = user.currentLongitude
    }

    func toUser() -> AppUser {
        var user = AppUser(
            id: id,
            name: name,
            universityEmail: universityEmail,
            contactNumber: contactNumber,
            role: UserRole(rawValue: roleRaw) ?? .client
        )
        user.studentNumber = studentNumber
        user.aboutMe = aboutMe
        user.profileIconName = profileIconName
        user.isOnline = isOnline
        user.averageRating = averageRating
        user.ratingCount = ratingCount
        user.createdAt = createdAt
        user.isAvailable = isAvailable
        user.currentLatitude = currentLatitude
        user.currentLongitude = currentLongitude
        return user
    }
}
