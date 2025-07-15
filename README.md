# Banking App - Migration vers Architecture MVVM

## 📋 Contexte du Projet

**Application Flutter de banque** en cours de migration depuis une architecture centralisée vers une architecture **MVVM** avec cache en mémoire pour optimiser les performances et préparer l'intégration future avec **Turso.tech**.

### 🎯 Objectifs Principaux
1. **Résoudre les problèmes de performance O(n²)** dans le calcul des soldes
2. **Implémenter l'architecture MVVM** avec repositories et cache
3. **Charger toutes les données au démarrage** (cache-first)
4. **Préparer l'intégration Turso** pour le multi-utilisateur
5. **Séparer le fichier monolithique** `database.dart` (822 lignes)

---

## 🏗️ Architecture Technique

### Stack Technologique
- **Flutter** + **Dart**
- **Drift ORM** pour SQLite
- **Riverpod** pour la gestion d'état
- **MVVM Pattern** avec repositories
- **Cache en mémoire** avec CacheManager singleton
- **Localisation i18n** avec package l10n

### Structure des Dossiers
```
lib/
├── core/
│   ├── l10n/                 # Localisation (EN/FR)
│   ├── services/             # UserPreferencesService
│   ├── theme/                # AppColors, AppTextStyles
│   └── utils/                # Formatters, CardColorUtils
├── data/
│   ├── cache/                # CacheManager (singleton)
│   ├── datasources/local/    # LocalDataSources (Drift)
│   ├── models/               # Data models (Drift)
│   └── repositories/         # Repository implementations
├── domain/
│   ├── entities/             # Domain entities (business logic)
│   ├── repositories/         # Repository interfaces
│   └── value_objects/        # Money, DateRange
└── presentation/
    ├── providers/            # Riverpod providers
    ├── screens/              # UI screens
    ├── viewmodels/           # MVVM ViewModels
    └── widgets/              # UI components
```

---

## 📊 État d'Avancement - TODO List Complète

### ✅ ÉTAPES TERMINÉES

#### Étape 1: Entités Domain ✅
- [x] `lib/domain/entities/account.dart` - Entité compte avec logique métier
- [x] `lib/domain/entities/transaction.dart` - Entité transaction avec enums
- [x] `lib/domain/entities/transaction_with_balance.dart` - Transaction enrichie
- [x] `lib/domain/value_objects/money.dart` - Value object monétaire
- [x] Suppression de l'entité User (remplacée par UserPreferencesService)

#### Étape 2: Repositories et DataSources ✅
- [x] Interfaces repository dans `domain/repositories/`
- [x] Implémentations dans `data/repositories/`
- [x] DataSources locales pour Drift
- [x] Modèles avec mapping Drift ↔ Domain

#### Étape 3: Cache et Optimisations ✅
- [x] `lib/data/cache/cache_manager.dart` - Cache singleton O(n)
- [x] Repositories utilisant le cache
- [x] Calculs de soldes optimisés

#### Étape 4: ViewModels MVVM ✅
- [x] `lib/presentation/viewmodels/base_view_model.dart` - Classe de base
- [x] `lib/presentation/viewmodels/account_view_model.dart` - Gestion comptes
- [x] `lib/presentation/viewmodels/transaction_view_model.dart` - Gestion transactions
- [x] `lib/presentation/viewmodels/search_view_model.dart` - Recherche avancée
- [x] `lib/presentation/viewmodels/app_view_model.dart` - Initialisation app

#### Étape 5: Migration Widgets (EN COURS)
- [x] **5.1** `lib/presentation/providers/viewmodel_providers.dart` - Providers Riverpod
- [x] **5.2** `lib/presentation/screens/home_screen_mvvm.dart` - HomeScreen migré
- [x] **5.3** Widgets de transaction migrés :
  - [x] `lib/presentation/widgets/transaction_item_mvvm.dart`
  - [x] `lib/presentation/widgets/transactions_list_mvvm.dart`
  - [x] `lib/presentation/widgets/add_transaction_bottom_sheet_mvvm.dart`
  - [x] `lib/presentation/widgets/bank_card_widget_mvvm.dart`

### ✅ ÉTAPES RÉCEMMENT TERMINÉES

#### Étape 5.4: Écrans de Recherche ✅
- [x] `lib/presentation/widgets/search_field_mvvm.dart` - Champ de recherche avec suggestions
- [x] `lib/presentation/widgets/search_suggestions_overlay_mvvm.dart` - Overlay de suggestions
- [x] `lib/presentation/screens/search_results_screen_mvvm.dart` - Écran de résultats
- [x] Intégration SearchField dans HomeScreen MVVM
- [x] Filtres avancés avec dates et montants

#### Étape 5.5: Finalisation l10n ✅
- [x] Ajout de 24 nouvelles clés de localisation
- [x] Traductions EN/FR pour toutes les fonctionnalités de recherche
- [x] Correction des hardcoded strings dans HomeScreen MVVM
- [x] Support complet l10n pour widgets MVVM

### 🔄 ÉTAPES EN COURS

#### Étape 6: Refactorisation Database.dart (PRÊT)
- [ ] Séparer le fichier monolithique `database.dart` (822 lignes)
- [ ] Réorganiser les requêtes par domaine
- [ ] Nettoyer les anciens providers obsolètes

### 📋 ÉTAPES À VENIR

#### Étape 7: Migration Complète et Nettoyage
- [ ] Remplacer tous les anciens widgets par les versions MVVM
- [ ] Supprimer les providers obsolètes
- [ ] Tests de l'architecture complète

---

## 🔧 Détails Techniques Critiques

### 1. **Gestion des Couleurs de Cartes**
**Problème identifié** : L'algorithme `colors[id % colors.length]` ne fonctionne pas avec des IDs non-consécutifs.

**Solution implémentée** :
```dart
// lib/core/utils/card_color_utils_mvvm.dart
static Color getCardColor(domain.Account account, List<domain.Account> allAccounts) {
  // Tri par ID pour ordre stable
  final sortedAccounts = List<domain.Account>.from(allAccounts)
    ..sort((a, b) => a.id.compareTo(b.id));
  
  // Index dans liste triée = couleur cohérente
  final accountIndex = sortedAccounts.indexWhere((a) => a.id == account.id);
  return cardColors[accountIndex % cardColors.length];
}
```

### 2. **Localisation i18n**
**Règle critique** : Aucune string codée en dur autorisée.

**Pattern à respecter** :
```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  // Utiliser l10n.keyName au lieu de "String"
}
```

### 3. **Architecture Cache-First**
**Principe** : Toutes les données sont chargées au démarrage dans le CacheManager.

**Flow de données** :
```
UI → ViewModel → Repository → Cache (+ DataSource si nécessaire)
```

**Problème identifié** : Certains widgets utilisent encore directement la DB :
- `full_transactions_bottom_sheet.dart` ligne 244
- `followed_transactions_carousel.dart`
- `draggable_black_container.dart`

### 4. **ViewModels et State Management**
**BaseViewModel** avec gestion d'erreurs intégrée :
```dart
abstract class BaseViewModel<T extends BaseViewState> extends StateNotifier<T> {
  Future<void> executeWithErrorHandling(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      state = state.failure(e.toString()) as T;
    }
  }
}
```

### 5. **Providers Riverpod**
**Structure hiérarchique** :
- DataSources → Repositories → ViewModels → UI
- Providers utilitaires pour l'UI (convenience providers)
- Family providers pour paramètres dynamiques

---

## 🚨 Points d'Attention Techniques

### Widgets Nécessitant Migration
```
URGENT - Utilisent encore anciens providers :
- draggable_black_container.dart
- followed_transactions_carousel.dart  
- full_transactions_bottom_sheet.dart
- edit_transaction_bottom_sheet.dart
- perspective_transaction_item.dart
```

### Calculs de Soldes
**Critique** : Le solde après chaque transaction doit être recalculé en cascade si une transaction antérieure est modifiée.

**Implémentation** : Via CacheManager.updateTransactionBalances()

### Providers à Nettoyer
```
À SUPPRIMER après migration complète :
- Anciens providers de database_provider.dart
- Providers de transactions directs
- Providers redondants
```

---

## 🎯 Plan d'Actions Immédiat

### Phase Actuelle : Étape 5.4
1. **Migrer les écrans de recherche** vers MVVM
2. **Ajouter l10n à tous les widgets** MVVM créés
3. **Corriger les widgets** utilisant encore anciens providers

### Phase Suivante : Étape 6
1. **Refactoriser database.dart** (822 lignes → modules)
2. **Migration progressive** des références
3. **Nettoyage des providers** obsolètes

### Phase Finale : Étape 7
1. **Tests complets** de l'architecture
2. **Validation des performances** O(n)
3. **Préparation intégration Turso**

---

## 📝 Commandes de Développement

### Analyse du Code
```bash
flutter analyze lib/presentation/viewmodels/ --no-fatal-infos
```

### Génération Drift
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Tests Architecture
```bash
flutter test test/architecture/
```

---

## 🔗 Fichiers Clés Modifiés

### Nouveaux Fichiers MVVM
- `lib/presentation/viewmodels/*.dart` (5 fichiers)
- `lib/presentation/providers/viewmodel_providers.dart`
- `lib/presentation/screens/home_screen_mvvm.dart`
- `lib/presentation/screens/search_results_screen_mvvm.dart`
- `lib/presentation/widgets/*_mvvm.dart` (7 fichiers)
- `lib/core/utils/card_color_utils_mvvm.dart`

### Architecture Domain
- `lib/domain/entities/*.dart` (4 entités)
- `lib/domain/repositories/*.dart` (4 interfaces)
- `lib/domain/value_objects/*.dart` (2 value objects)

### Cache et Repositories
- `lib/data/cache/cache_manager.dart`
- `lib/data/repositories/*_impl.dart` (4 implémentations)

---

## 🎖️ Métriques de Qualité

- **0 erreurs** de compilation dans les ViewModels
- **Architecture MVVM** respectée
- **Cache O(n)** au lieu de O(n²)
- **Séparation des responsabilités** claire
- **Prêt pour Turso** multi-utilisateur

---

*Dernière mise à jour : Après étape 5.5 - Finalisation l10n et recherche*
*Prochaine étape : 6 - Refactorisation database.dart*