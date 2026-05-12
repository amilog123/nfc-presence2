// NFCScanView.swift - Vue de scan NFC pour pointer la présence

import SwiftUI

struct NFCScanView: View {
    let session: SessionDTO

    @StateObject private var nfcService = NFCService()
    @State private var isScanning = false
    @State private var scannedUID: String?
    @State private var errorMessage: String?
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            sessionInfo
            nfcIllustration
            scanButton
            Spacer()
        }
        .padding(.horizontal, 32)
        .navigationTitle("Scanner le badge")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: Binding(
            get: { scannedUID != nil },
            set: { if !$0 { scannedUID = nil } }
        )) {
            if let uid = scannedUID {
                SignatureView(session: session, nfcUID: uid)
            }
        }
        .alert("Erreur de scan", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Sous-vues

    private var sessionInfo: some View {
        VStack(spacing: 6) {
            Text(session.titre)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                Label(session.salle, systemImage: "mappin.circle")
                Text("·")
                Label(session.creneau == "matin" ? "Matin" : "Après-midi",
                      systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var nfcIllustration: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(.blue.opacity(isScanning ? 0 : 0.25), lineWidth: 2)
                    .scaleEffect(isScanning ? 1.8 + Double(i) * 0.4 : 1)
                    .animation(
                        isScanning
                            ? .easeOut(duration: 1.2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.3)
                            : .default,
                        value: isScanning
                    )
                    .frame(width: 80, height: 80)
            }
            Image(systemName: "wave.3.right.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(isScanning ? .blue : .secondary)
                .symbolEffect(.pulse, isActive: isScanning)
        }
        .frame(height: 180)
    }

    private var scanButton: some View {
        VStack(spacing: 12) {
            Button(action: startScan) {
                Group {
                    if isScanning {
                        HStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text("Approchez le badge…")
                        }
                    } else {
                        Text("Scanner le badge du prof")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isScanning)

            if isScanning {
                Text("Tenez votre iPhone près du badge NFC")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Action

    private func startScan() {
        isScanning = true
        Task {
            do {
                let uid = try await nfcService.scan()
                scannedUID = uid
            } catch {
                errorMessage = error.localizedDescription
            }
            isScanning = false
        }
    }
}

#Preview {
    NavigationStack {
        NFCScanView(session: SessionDTO(
            id: UUID(),
            titre: "Mathématiques S2",
            date: "2026-05-11",
            creneau: "matin",
            salle: "B204",
            nfcTagUID: "04:AB:CD:12:34:56:78"
        ))
    }
}
