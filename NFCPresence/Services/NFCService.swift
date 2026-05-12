// NFCService.swift - Lecture et écriture des tags NFC

import Foundation
#if !targetEnvironment(simulator)
import CoreNFC
#endif

@MainActor
class NFCService: NSObject, ObservableObject {

#if targetEnvironment(simulator)

    func scan() async throws -> String {
        try await Task.sleep(for: .seconds(1))
        return "04:AB:CD:12:34:56:78"
    }

#else

    private var continuation: CheckedContinuation<String, Error>?

    func scan() async throws -> String {
        guard NFCTagReaderSession.readingAvailable else {
            throw NFCError.notAvailable
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
            session.alertMessage = "Approchez le tag NFC du professeur"
            session.begin()
        }
    }

#endif
}

#if !targetEnvironment(simulator)
extension NFCService: NFCTagReaderSessionDelegate {

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        let nfcError = error as? NFCReaderError
        guard nfcError?.code != .readerSessionInvalidationErrorUserCanceled else { return }
        Task { @MainActor in
            self.continuation?.resume(throwing: error)
            self.continuation = nil
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetectTags tags: [NFCTag]) {
        guard let tag = tags.first else { return }

        session.connect(to: tag) { error in
            if let error {
                session.invalidate(errorMessage: "Connexion échouée")
                Task { @MainActor in
                    self.continuation?.resume(throwing: error)
                    self.continuation = nil
                }
                return
            }

            guard case .iso7816(let iso7816Tag) = tag else {
                session.invalidate(errorMessage: "Tag non compatible")
                Task { @MainActor in
                    self.continuation?.resume(throwing: NFCError.unsupportedTag)
                    self.continuation = nil
                }
                return
            }

            let uid = iso7816Tag.identifier
                .map { String(format: "%02X", $0) }
                .joined(separator: ":")

            session.alertMessage = "Présence enregistrée ✓"
            session.invalidate()

            Task { @MainActor in
                self.continuation?.resume(returning: uid)
                self.continuation = nil
            }
        }
    }
}
#endif

enum NFCError: LocalizedError {
    case notAvailable
    case unsupportedTag

    var errorDescription: String? {
        switch self {
        case .notAvailable:  return "Le NFC n'est pas disponible sur cet appareil"
        case .unsupportedTag: return "Tag NFC non compatible (ISO 7816 requis)"
        }
    }
}
