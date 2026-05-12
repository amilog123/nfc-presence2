// HashService.swift - Génération et vérification des hash de présence

import UIKit
import CryptoKit

enum HashService {
    static func sha256(of image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return nil }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
