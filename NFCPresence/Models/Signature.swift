// Signature.swift - Modèle représentant une signature de présence

import Foundation
import SwiftData

@Model
class Signature {
    @Attribute(.unique) var id: UUID
    var studentID: UUID
    var sessionID: UUID
    var creneau: Creneau
    var imageURL: String?
    var timestamp: Date
    var deviceID: String
    var hash: String

    init(studentID: UUID, sessionID: UUID, creneau: Creneau, imageURL: String? = nil, deviceID: String, hash: String) {
        self.id = UUID()
        self.studentID = studentID
        self.sessionID = sessionID
        self.creneau = creneau
        self.imageURL = imageURL
        self.timestamp = Date()
        self.deviceID = deviceID
        self.hash = hash
    }
}
