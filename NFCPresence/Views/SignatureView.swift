// SignatureView.swift - Vue de confirmation / signature de présence

import SwiftUI
import PencilKit

struct SignatureView: View {
    let session: SessionDTO
    let nfcUID: String

    @State private var canvasView = PKCanvasView()
    @State private var isDrawingEmpty = true
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if showSuccess {
                successScreen
            } else {
                signatureScreen
            }
        }
        .navigationBarBackButtonHidden(isSubmitting || showSuccess)
        .alert("Erreur", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Écran de signature

    private var signatureScreen: some View {
        VStack(spacing: 0) {
            sessionHeader
                .padding()

            Divider()

            Text("Signez dans le cadre ci-dessous")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 16)

            canvasArea
                .padding(.horizontal, 20)
                .padding(.top, 8)

            actions
                .padding(20)
        }
        .navigationTitle("Signature")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sessionHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.titre)
                    .font(.headline)
                HStack(spacing: 6) {
                    Text(session.salle)
                    Text("·")
                    Text(session.creneau == "matin" ? "Matin" : "Après-midi")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var canvasArea: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                )

            if isDrawingEmpty {
                Text("Signez ici…")
                    .foregroundStyle(.tertiary)
                    .padding(16)
            }

            CanvasRepresentable(canvasView: $canvasView, isDrawingEmpty: $isDrawingEmpty)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button(action: submit) {
                Group {
                    if isSubmitting {
                        HStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text("Envoi en cours…")
                        }
                    } else {
                        Text("Valider la signature")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isDrawingEmpty || isSubmitting)

            Button("Effacer") {
                canvasView.drawing = PKDrawing()
            }
            .foregroundStyle(.secondary)
            .disabled(isDrawingEmpty || isSubmitting)
        }
    }

    // MARK: - Écran de succès

    private var successScreen: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .transition(.scale.combined(with: .opacity))
            VStack(spacing: 8) {
                Text("Présence enregistrée !")
                    .font(.title2.bold())
                Text("Votre signature a été transmise avec succès.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Button("Retour aux sessions") { dismiss() }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Validation

    private func submit() {
        guard let image = canvasView.drawing
            .image(from: canvasView.bounds, scale: UIScreen.main.scale)
            .withBackground(.white),
              let hash = HashService.sha256(of: image),
              let imageData = image.jpegData(compressionQuality: 0.8)
        else { return }

        let imageBase64 = imageData.base64EncodedString()
        isSubmitting = true

        Task {
            do {
                try await SupabaseService.shared.signSession(
                    sessionID: session.id,
                    nfcUID: nfcUID,
                    imageBase64: imageBase64,
                    hash: hash
                )
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(duration: 0.4)) { showSuccess = true }
            } catch {
                errorMessage = error.localizedDescription
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            isSubmitting = false
        }
    }
}

// MARK: - PencilKit wrapper

private struct CanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var isDrawingEmpty: Bool

    func makeCoordinator() -> Coordinator { Coordinator(isDrawingEmpty: $isDrawingEmpty) }

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.tool = PKInkingTool(.pen, color: .label, width: 2)
        canvasView.delegate = context.coordinator
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var isDrawingEmpty: Bool
        init(isDrawingEmpty: Binding<Bool>) { _isDrawingEmpty = isDrawingEmpty }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            isDrawingEmpty = canvasView.drawing.strokes.isEmpty
        }
    }
}

// MARK: - UIImage + fond blanc

private extension UIImage {
    /// Ajoute un fond blanc (nécessaire pour que le hash soit stable sur fond transparent)
    func withBackground(_ color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, true, scale)
        defer { UIGraphicsEndImageContext() }
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        draw(at: .zero)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

#Preview {
    NavigationStack {
        SignatureView(
            session: SessionDTO(
                id: UUID(),
                titre: "Mathématiques S2",
                date: "2026-05-11",
                creneau: "matin",
                salle: "B204",
                nfcTagUID: "04:AB:CD:12:34:56:78"
            ),
            nfcUID: "04:AB:CD:12:34:56:78"
        )
    }
}
