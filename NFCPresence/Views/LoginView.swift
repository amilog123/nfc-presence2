// LoginView.swift - Vue de connexion étudiant / enseignant

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var linkSent = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            header

            if linkSent {
                confirmation
            } else {
                form
            }

            Spacer()
        }
        .padding(.horizontal, 32)
        .alert("Erreur", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Sous-vues

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "wave.3.right.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            Text("NFCPresence")
                .font(.largeTitle.bold())
            Text("Pointage de présence par NFC")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var form: some View {
        VStack(spacing: 16) {
            TextField("Adresse email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

            Button(action: sendLink) {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Recevoir le lien de connexion")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.isEmpty || isLoading)
        }
    }

    private var confirmation: some View {
        VStack(spacing: 12) {
            Text("Vérifiez vos emails")
                .font(.title2.bold())
            Text("Un lien de connexion a été envoyé à\n**\(email)**")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Utiliser une autre adresse") {
                withAnimation { linkSent = false; email = "" }
            }
            .font(.footnote)
            .padding(.top, 8)
        }
    }

    // MARK: - Actions

    private func sendLink() {
        isLoading = true
        Task {
            do {
                try await SupabaseService.shared.login(email: email)
                withAnimation { linkSent = true }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    LoginView()
}
