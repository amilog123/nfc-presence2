// SessionListView.swift - Liste des sessions de cours disponibles
import SwiftUI

struct SessionListView: View {
    @State private var sessions: [SessionDTO] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Chargement des sessions…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if sessions.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Sessions du jour")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await loadData() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Erreur", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .task { await loadData() }
    }

    private var list: some View {
        List(sessions, id: \.id) { session in
            NavigationLink(destination: NFCScanView(session: session)) {
                SessionRow(session: session)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Aucune session aujourd'hui")
                .font(.headline)
            Text("Revenez lorsqu'un cours est planifié.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            sessions = try await SupabaseService.shared.getSessions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct SessionRow: View {
    let session: SessionDTO

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.titre)
                    .font(.headline)
                HStack(spacing: 6) {
                    Label(session.salle, systemImage: "mappin.circle")
                    Text("·")
                    Label(creneauLabel, systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var creneauLabel: String {
        session.creneau == "matin" ? "Matin" : "Après-midi"
    }
}

#Preview {
    SessionListView()
}
