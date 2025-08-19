# Application Bancaire Mobile

> Application bancaire moderne développée en Flutter avec architecture MVVM, gestion multi-devises et conversion automatique en temps reel via Firebase Cloud Functions.

## Vue d'ensemble

Cette application bancaire permet aux utilisateurs de gerer leurs comptes et transactions avec support de 36 devises internationales. L'architecture MVVM avec cache intelligent optimise les performances pour une utilisation fluide meme avec des milliers de transactions.

### Fonctionnalites principales

- 🏦 **Gestion multi-comptes** avec support de 36 devises
- 💱 **Conversion automatique** des devises en temps reel 
- 🔍 **Recherche avancee** avec filtres multi-critères
- 📊 **Calcul optimise** des soldes et historiques
- 🌍 **Localisation** francais/anglais avec formatage adaptatif
- 🎨 **Theme adaptatif** (clair/sombre) avec persistance des preferences
- 🚀 **Performance optimisée** avec architecture cache-first

### Captures d'écran

<img width="404" height="860" alt="Image" src="https://github.com/user-attachments/assets/359e8de7-58f7-4937-9a11-0376be2c23b5" />

<img width="404" height="860" alt="Image" src="https://github.com/user-attachments/assets/db847541-262e-4c87-a2e6-fa78ce05a200" />

<img width="404" height="860" alt="Image" src="https://github.com/user-attachments/assets/e813efa2-7317-4bcd-9fe5-f2d9321a6cd3" />

<img width="404" height="860" alt="Image" src="https://github.com/user-attachments/assets/05d4eb95-9e89-47e4-99fd-75aecc217b6c" />


## Architecture technique

### Stack technologique
- **Frontend** : Flutter 3.8.1+ avec Dart
- **State Management** : Riverpod avec pattern MVVM
- **Base de donnees** : SQLite via Drift ORM
- **Backend** : Firebase Cloud Functions (TypeScript)
- **API** : ExchangeRate-API avec cache intelligent
- **Localisation** : i18n avec support multilingue

### Pattern architectural
```
├── presentation/     # MVVM ViewModels & UI
├── domain/          # Entités métier & interfaces
├── data/            # Repositories & Cache
└── core/            # Services transversaux
```

## Installation et lancement

### Prerequis
- Flutter SDK 3.8.1 ou supérieur
- Dart SDK 3.2.0 ou supérieur
- Android Studio / IntelliJ IDEA ou VS Code
- Git pour le clonage du repository

### Etapes d'installation

1. **Cloner le repository**
   ```bash
   git clone <repository-url>
   cd Master2__BankingApp
   ```

2. **Installer les dépendances Flutter**
   ```bash
   flutter pub get
   ```

3. **Generer les fichiers Drift** (base de données)
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Verifier l'installation**
   ```bash
   flutter analyze
   flutter doctor
   ```

### Lancement de l'application

#### Dans Android Studio / IntelliJ IDEA
1. Ouvrir le projet dans l'IDE
2. Attendre l'indexation et la synchronisation
3. Sélectionner un émulateur Android/iOS ou connecter un device
4. Cliquer sur "Run" ou utiliser le raccourci `Ctrl+F5`

#### Dans VS Code
1. Ouvrir le dossier du projet
2. Installer l'extension Flutter si pas encore fait
3. Ouvrir le fichier `lib/main.dart`
4. Appuyer sur `F5` ou utiliser la commande "Flutter: Launch Emulator"

#### En ligne de commande
```bash
# Lancer sur un émulateur/device connecté
flutter run

# Lancer en mode debug avec hot reload
flutter run --debug

# Lancer en mode release (performance optimale)
flutter run --release
```

## Tests et validation

### Execution des tests
```bash
# Tests unitaires
flutter test

# Analyse statique du code
flutter analyze

# Verification des performances
flutter run --profile
```

### Structure de test
- Tests unitaires pour les ViewModels et Services
- Tests d'intégration pour les Repositories
- Tests de widgets pour l'interface utilisateur

## Utilisation de l'application

### Premiere utilisation
1. **Creation du premier compte** : Sélectionner une devise parmi les 36 supportees
2. **Configuration des preferences** : Choisir la langue et le theme
3. **Ajout de transactions** : Saisir revenus et dépenses avec conversion automatique

### Fonctionnalites avancees
- **Recherche intelligente** : Filtrer par dates, montants, types de transactions
- **Transactions suivies** : Marquer des transactions importantes comme favorites
- **Conversion multi-devises** : Saisir une transaction dans une devise differente du compte
- **Categorisation** : Organiser les transactions avec jusqu'à 4 niveaux de categories

## Configuration pour le developpement

### Variables d'environnement
Les clés API sont securisées via Firebase Cloud Functions. Aucune configuration locale requise.

### Structure des donnees
La base de donnees SQLite contient :
- Comptes bancaires avec devises
- Transactions avec conversion automatique
- Cache des taux de change (optimise 24h)
- Preferences utilisateur persistantes

### Firebase Cloud Functions
Le systeme de conversion utilise Firebase pour optimiser les appels API :
- Cache Firestore partage entre tous les utilisateurs
- Mise a jour quotidienne automatique des taux
- Fallback robuste en cas d'indisponibilité

## Commandes utiles

```bash
# Generation des localisations
flutter gen-l10n

# Build pour production Android
flutter build apk --release

# Build pour production iOS  
flutter build ios --release

# Nettoyage du cache
flutter clean && flutter pub get
```

## Resolution de problemes

### Problemes courants
- **Build runner echoue** : Exécuter `flutter clean` puis régénérer
- **Localisation manquante** : Verifier `flutter gen-l10n`
- **Cache corrompu** : Supprimer le dossier `.dart_tool`

### Support
Pour toute question technique ou bug report, consulter la documentation interne ou contacter le développeur.

---

**Architecture** : MVVM avec Riverpod | **Performance** : Cache-first O(n) | **Devises** : 36 supportées | **Localisation** : FR/EN
