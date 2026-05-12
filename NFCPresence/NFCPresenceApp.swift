// NFCPresenceApp.swift - Point d'entrée de l'application

import SwiftUI
import SwiftData

@main
struct NFCPresenceApp: App {

    // Observe UserDefaults directement — se met à jour quand le token change
    @AppStorage("supabase_auth_token") private var authToken: String = ""

    var isLoggedIn: Bool { !authToken.isEmpty }

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .modelContainer(appContainer)
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    // MARK: - SwiftData

    private var appContainer: ModelContainer {
        let schema = Schema([Student.self, Session.self, Signature.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("SwiftData : impossible de créer le ModelContainer — \(error)")
        }
    }

    // MARK: - Deep link (magic link Supabase)
    //
    // Supabase redirige vers : nfcpresence://login#access_token=...&refresh_token=...
    // Configurer dans Xcode : Info > URL Types > Scheme = "nfcpresence"
    // Et dans Supabase Dashboard > Auth > Redirect URLs : nfcpresence://login

    private func handleDeepLink(_ url: URL) {
        // Le fragment (#…) contient les tokens, pas la query string
        guard let fragment = url.fragment, !fragment.isEmpty else { return }

        // Réutiliser URLComponents pour parser le fragment comme une query
        var components = URLComponents()
        components.query = fragment
        let params = components.queryItems?.reduce(into: [String: String]()) {
            $0[$1.name] = $1.value ?? ""
        } ?? [:]

        guard let accessToken = params["access_token"], !accessToken.isEmpty else { return }

        SupabaseService.shared.authToken = accessToken

        if let refreshToken = params["refresh_token"] {
            UserDefaults.standard.set(refreshToken, forKey: "supabase_refresh_token")
        }
    }
}

// MARK: - Navigation principale

private struct MainTabView: View {
    var body: some View {
        TabView {
            SessionListView()
                .tabItem {
                    Label("Sessions", systemImage: "calendar")
                }
            HistoryView()
                .tabItem {
                    Label("Historique", systemImage: "clock.arrow.circlepath")
                }
        }
    }
}
