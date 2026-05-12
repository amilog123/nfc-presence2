// HistoryView.swift - Historique des présences de l'étudiant

import SwiftUI

struct HistoryView: View {
    @State private var entries: [SignatureDTO] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Chargement de l'historique…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if entries.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Historique")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await loadHistory() } } label: {
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
        .task { await loadHistory() }
    }

    // MARK: - Sous-vues

    private var list: some View {
        List(entries, id: \.id) { entry in
            HistoryRow(entry: entry)
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Aucune signature pour le moment")
                .font(.headline)
            Text("Vos présences signées apparaîtront ici.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Chargement

    private func loadHistory() async {
        isLoading = true
        defer { isLoading = false }
        do {
            entries = try await SupabaseService.shared.getHistory()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - HistoryRow

private struct HistoryRow: View {
    let entry: SignatureDTO

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.sessions?.titre ?? "Session inconnue")
                    .font(.headline)
                HStack(spacing: 6) {
                    Text(entry.timestamp, style: .date)
                    Text("·")
                    Text(entry.creneau == "matin" ? "Matin" : "Après-midi")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(entry.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
}
