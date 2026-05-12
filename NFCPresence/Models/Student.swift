// Student.swift - Modèle représentant un étudiant

import Foundation
import SwiftData

@Model
class Student {
    @Attribute(.unique) var id: UUID
    var email: String
    var nom: String
    var deviceID: String

    init(email: String, nom: String, deviceID: String) {
        self.id = UUID()
        self.email = email
        self.nom = nom
        self.deviceID = deviceID
    }
}
