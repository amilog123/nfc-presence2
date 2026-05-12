// SessionListView.swift - Liste des sessions de cours disponibles

import SwiftUI

struct SessionListView: View {
    @State private var sessions: [SessionDTO] = []
    @State private var signedIDs: Set<UUID> = []
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

    // MARK: - Sous-vues

    private var list: some View {
        List(sessions, id: \.id) { session in
            let signed = signedIDs.contains(session.id)
            Group {
                if signed {
                    SessionRow(session: session, signed: true)
                } else {
                    NavigationLink(destination: NFCScanView(session: session)) {
                        SessionRow(session: session, signed: false)
                    }
                }
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

    // MARK: - Chargement

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let fetchedSessions = SupabaseService.shared.getSessions()
            async let fetchedHistory  = SupabaseService.shared.getHistory()
            let (s, h) = try await (fetchedSessions, fetchedHistory)
            sessions  = s
            signedIDs = Set(h.map(\.sessionID))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - SessionRow

private struct SessionRow: View {
    let session: SessionDTO
    let signed: Bool

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
            SignedBadge(signed: signed)
        }
        .padding(.vertical, 4)
    }

    private var creneauLabel: String {
        session.creneau == "matin" ? "Matin" : "Après-midi"
    }
}

// MARK: - SignedBadge

private struct SignedBadge: View {
    let signed: Bool

    var body: some View {
        Text(signed ? "Signé" : "Non signé")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(signed ? Color.green.opacity(0.15) : Color.secondary.opacity(0.12))
            .foregroundStyle(signed ? .green : .secondary)
            .clipShape(Capsule())
    }
}

#Preview {
    SessionListView()
}
