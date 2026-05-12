// LoginView.swift - Connexion email + mot de passe
import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            header
            form
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

            SecureField("Mot de passe", text: $password)
                .textContentType(.password)
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

            Button(action: signIn) {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Se connecter")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.isEmpty || password.isEmpty || isLoading)
        }
    }

    private func signIn() {
        isLoading = true
        Task {
            do {
                try await SupabaseService.shared.signInWithPassword(email: email, password: password)
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
