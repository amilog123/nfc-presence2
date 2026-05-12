// Config.swift - Configuration globale (clés API, URLs, constantes)

import Foundation

enum Config {
    static let supabaseURL = "https://anxzduocfykjtfrtzgih.supabase.co"
    static let supabaseAnonKey = "sb_publishable_SWRfreyaxSDtqfLnWbszLQ_ewkY9kPa"

    static var deviceID: String {
        let key = "nfc_presence_device_id"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: key)
        return newID
    }
}
