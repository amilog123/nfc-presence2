// SupabaseService.swift - Gestion des appels à la base de données Supabase

import Foundation

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    private let baseURL = Config.supabaseURL
    private let anonKey = Config.supabaseAnonKey

    // Persisté après vérification du magic link (deep link handler)
    var authToken: String? {
        get { UserDefaults.standard.string(forKey: "supabase_auth_token") }
        set { UserDefaults.standard.set(newValue, forKey: "supabase_auth_token") }
    }

    var studentID: UUID? {
        get {
            guard let str = UserDefaults.standard.string(forKey: "supabase_student_id") else { return nil }
            return UUID(uuidString: str)
        }
        set { UserDefaults.standard.set(newValue?.uuidString, forKey: "supabase_student_id") }
    }

    private init() {}

    private var baseHeaders: [String: String] {
        var h = ["apikey": anonKey, "Content-Type": "application/json"]
        if let token = authToken { h["Authorization"] = "Bearer \(token)" }
        return h
    }

    // MARK: - 1. Login

    /// Envoie un magic link à l'adresse email via Supabase Auth OTP.
    func login(email: String) async throws {
        let url = try makeURL("/auth/v1/otp")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        baseHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "create_user": true
        ])
        let (_, response) = try await URLSession.shared.data(for: request)
        try validate(response)
    }

    // MARK: - 2. Sessions du jour

    func getSessions() async throws -> [SessionDTO] {
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        let url = try makeURL("/rest/v1/sessions",
                              query: ["date": "eq.\(today)", "order": "creneau.asc"])
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        baseHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try JSONDecoder.supabase.decode([SessionDTO].self, from: data)
    }

    // MARK: - 3. Signer une session

    func signSession(sessionID: UUID, nfcUID: String, imageBase64: String, hash: String) async throws {
        guard let studentID else { throw SupabaseError.notAuthenticated }

        let url = try makeURL("/rest/v1/signatures")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        baseHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "student_id": studentID.uuidString,
            "session_id": sessionID.uuidString,
            "nfc_uid": nfcUID,
            "image_base64": imageBase64,
            "hash": hash,
            "device_id": Config.deviceID,
            "timestamp": DateFormatter.iso8601Full.string(from: Date())
        ])

        let (_, response) = try await URLSession.shared.data(for: request)
        try validate(response)
    }

    // MARK: - 4. Historique

    func getHistory() async throws -> [SignatureDTO] {
        guard let studentID else { throw SupabaseError.notAuthenticated }

        let url = try makeURL("/rest/v1/signatures",
                              query: ["student_id": "eq.\(studentID.uuidString)",
                                      "select":     "*,sessions(titre)",
                                      "order":      "timestamp.desc"])
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        baseHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try JSONDecoder.supabase.decode([SignatureDTO].self, from: data)
    }

    // MARK: - Helpers

    private func makeURL(_ path: String, query: [String: String] = [:]) throws -> URL {
        var components = URLComponents(string: baseURL + path)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw SupabaseError.invalidURL }
        return url
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw SupabaseError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw SupabaseError.httpError(http.statusCode) }
    }
}

// MARK: - DTOs (décodage des réponses Supabase)

struct SessionDTO: Decodable {
    let id: UUID
    let titre: String
    let date: String
    let creneau: String
    let salle: String
    let nfcTagUID: String

    enum CodingKeys: String, CodingKey {
        case id, titre, date, creneau, salle
        case nfcTagUID = "nfc_tag_uid"
    }
}

struct SignatureDTO: Decodable {
    let id: UUID
    let studentID: UUID
    let sessionID: UUID
    let creneau: String
    let imageURL: String?
    let timestamp: Date
    let deviceID: String
    let hash: String
    let sessions: SessionInfo?

    struct SessionInfo: Decodable {
        let titre: String
    }

    enum CodingKeys: String, CodingKey {
        case id, creneau, hash, timestamp, sessions
        case studentID = "student_id"
        case sessionID = "session_id"
        case imageURL  = "image_url"
        case deviceID  = "device_id"
    }
}

// MARK: - Erreurs

enum SupabaseError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:  return "Utilisateur non connecté"
        case .invalidURL:        return "URL invalide"
        case .invalidResponse:   return "Réponse serveur invalide"
        case .httpError(let c):  return "Erreur HTTP \(c)"
        }
    }
}

// MARK: - Extensions privées

private extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static let iso8601Full: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return f
    }()
}

private extension JSONDecoder {
    static let supabase: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
