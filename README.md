# NFCPresence 📱


Application iOS native de signature de présence par NFC, développée en SwiftUI dans le cadre d'un projet pédagogique Master 1 EPITA.

## 🎯 Concept

NFCPresence remplace les feuilles de présence papier et les solutions web classiques (type Edusign) par une application iOS native exploitant le NFC. L'étudiant scanne le badge NFC du professeur avec son iPhone, puis signe manuscritement sa présence. Ce double contrôle (badge physique + signature) garantit une présence réelle en salle.

## 🔐 Pourquoi c'est mieux qu'un QR code ?

| Méthode | Fraude possible ? |
|---|---|
| QR Code (Edusign) | ✅ Photo partageable à distance |
| NFCPresence | ❌ Badge physique obligatoire en salle |

## 📱 Fonctionnalités

- **Authentification** email + mot de passe via Supabase Auth
- **Sessions du jour** récupérées depuis le backend
- **Scan NFC** du badge professeur (ISO 14443, MIFARE, ISO 15693)
- **Signature manuscrite** via PencilKit (Apple Pencil compatible)
- **Hash SHA-256** de chaque signature pour garantir l'intégrité
- **Historique** des présences de l'étudiant
- **Device binding** via identifiant unique par appareil

## 🛠 Stack technique

| Composant | Technologie |
|---|---|
| Application iOS | SwiftUI (iOS 18+) |
| Persistance locale | SwiftData |
| Signature manuscrite | PencilKit |
| Lecture NFC | CoreNFC |
| Hachage | CryptoKit (SHA-256) |
| Backend | Supabase (PostgreSQL + Auth + REST API) |
| Langage | Swift 5.9+ |
| IDE | Xcode 16+ |

## 🗄 Modèle de données

```
students     → id, email, nom, device_id
teachers     → id, nom, email, nfc_tag_uid
sessions     → id, titre, date, creneau, salle, nfc_tag_uid
signatures   → id, student_id, session_id, creneau, image_base64, hash, device_id, timestamp
```

## 🔄 Parcours étudiant

```
1. Connexion email + mot de passe
2. Consultation des sessions du jour
3. Clic sur une session → écran de scan NFC
4. Scan du badge NFC du professeur
5. Signature manuscrite
6. Validation → présence enregistrée en base
```

## 🚀 Installation

### Prérequis
- Mac avec Xcode 16+
- iPhone avec iOS 18+
- Compte Apple Developer (gratuit suffisant pour les tests)

### Lancement
```bash
git clone https://github.com/amilog123/nfc-presence.git
cd nfc-presence
open NFCPresence.xcodeproj
```

1. Sélectionner votre iPhone comme destination
2. Lancer avec ▶️

### Configuration Supabase
Les clés API sont dans `NFCPresence/Config.swift` :
```swift
static let supabaseURL = "https://anxzduocfykjtfrtzgih.supabase.co"
static let supabaseAnonKey = "VOTRE_CLE_ANON"
```

## 📁 Structure du projet

```
NFCPresence/
├── Config.swift              # Clés API et configuration
├── NFCPresenceApp.swift      # Point d'entrée, navigation
├── Models/
│   ├── Student.swift         # Modèle étudiant (SwiftData)
│   ├── Session.swift         # Modèle session (SwiftData)
│   └── Signature.swift       # Modèle signature (SwiftData)
├── Services/
│   ├── SupabaseService.swift # Appels API REST Supabase
│   ├── NFCService.swift      # Lecture tags NFC
│   └── HashService.swift     # Hachage SHA-256
└── Views/
    ├── LoginView.swift        # Écran de connexion
    ├── SessionListView.swift  # Liste des sessions du jour
    ├── NFCScanView.swift      # Scan du badge NFC
    ├── SignatureView.swift    # Signature manuscrite
    └── HistoryView.swift      # Historique des présences
```

## 👩‍💻 Auteur

Amina Serrano — Master 1 EPITA 2026
