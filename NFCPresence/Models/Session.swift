// Session.swift - Modèle représentant une session de cours

import Foundation
import SwiftData

enum Creneau: String, Codable {
    case matin = "matin"
    case apresMidi = "apres-midi"
}

@Model
class Session {
    @Attribute(.unique) var id: UUID
    var titre: String
    var date: Date
    var creneau: Creneau
    var salle: String
    var nfcTagUID: String

    init(titre: String, date: Date, creneau: Creneau, salle: String, nfcTagUID: String) {
        self.id = UUID()
        self.titre = titre
        self.date = date
        self.creneau = creneau
        self.salle = salle
        self.nfcTagUID = nfcTagUID
    }
}
