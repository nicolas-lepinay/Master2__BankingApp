# Insight exploratoire

Approche réactive professionnelle : TransactionCacheService écoute les dépendances                                                                                                                                            │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Problème actuel                                                                                                                                                                                                               │ │
│ │                                                                                                                                                                                                                               │ │
│ │ - Les TransactionWithBalance ne se mettent à jour que quand les transactions changent                                                                                                                                         │ │
│ │ - Mais elles dépendent aussi de : Counterparty, Category, Account                                                                                                                                                             │ │
│ │ - Solution actuelle (recalcul manuel) = couplage fort et non-scalable                                                                                                                                                         │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Solution : Pattern Observer avec Streams                                                                                                                                                                                      │ │
│ │                                                                                                                                                                                                                               │ │
│ │ 1. TransactionCacheService écoute les streams des dépendances                                                                                                                                                                 │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Dans le constructeur de TransactionCacheService, s'abonner aux streams :
TransactionCacheService(...) {
  // Écouter les changements de counterparties
  _counterpartiesSubscription = _counterpartiesStore.stream.listen(
    (_) => _onDependencyChanged('counterparties'),
  );

  // Écouter les changements de catégories
  _categoriesSubscription = _categoriesStore.stream.listen(
    (_) => _onDependencyChanged('categories'),
  );

  // Écouter les changements de comptes
  _accountsSubscription = _accountsStore.stream.listen(
    (_) => _onDependencyChanged('accounts'),
  );
}

Future<void> _onDependencyChanged(String source) async {
  // Recalculer TOUTES les transactions enrichies
  await recomputeAllEnrichedData();

  // Notifier le stream pour que les ViewModels se rafraîchissent
  _notifyTransactionsChanged();
}                                                                                                                                                                                                                             │ │
│ │                                                                                                                                                                                                                               │ │
│ │ 2. Supprimer le recalcul manuel de CacheManager                                                                                                                                                                               │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Retirer la ligne ajoutée dans addCounterparty() :                                                                                                                                                                             │ │
│ │ Future<void> addCounterparty(CounterpartyModel counterparty) async {                                                                                                                                                          │ │
│ │   await _counterpartyService.addCounterparty(counterparty);                                                                                                                                                                   │ │
│ │   // ❌ Plus besoin de ça - le stream le fera automatiquement                                                                                                                                                                  │  │
│ │   // await _transactionService.recomputeAllEnrichedData();                                                                                                                                                                    │ │
│ │ }                                                                                                                                                                                                                             │ │
│ │                                                                                                                                                                                                                               │ │
3. MemoryStore a déjà l'infrastructure stream complète

✅ AUCUNE MODIFICATION nécessaire dans MemoryStore :
- StreamController déjà existant (ligne 28-29)
- Getter stream déjà existant (ligne 142)
- _notifyListeners() appelé automatiquement sur toutes les mutations

Code existant dans memory_store.dart:
```dart
class MemoryStore<K, V> {
  final StreamController<Map<K, V>> _controller =
      StreamController<Map<K, V>>.broadcast();

  Stream<Map<K, V>> get stream => _controller.stream;

  void _notifyListeners() {
    if (!_controller.isClosed) {
      _controller.add(Map.unmodifiable(_storage));
    }
  }
}
```

## Bénéfices

✅ **Découplage** : CacheManager ne sait plus rien des dépendances
✅ **Scalable** : Ajouter une dépendance = 1 ligne dans le constructeur
✅ **Réactif** : Les ViewModels se mettent à jour automatiquement
✅ **Professionnel** : Pattern Observer standard (GoF)
✅ **Maintenable** : La logique de dépendance est localisée

## Fichiers à modifier

1. ✅ `lib/data/cache/stores/memory_store.dart` - **AUCUNE modification** (streams déjà présents)
2. 🔨 `lib/data/cache/domain_services/transaction_cache_service.dart` - Écouter les streams
3. 🔨 `lib/data/cache/cache_manager.dart` - Retirer le recalcul manuel 

# Plan détaillé - Pattern Observer pour invalidation automatique du cache

## 📋 Contexte et problématique

### Problème actuel
Les `TransactionWithBalance` sont des **entités enrichies** qui contiennent des références à d'autres domaines :
```dart
class TransactionWithBalance {
  final Transaction transaction;
  final Account account;           // ← Dépendance
  final AccountBalance balanceAfter;
  final Counterparty? counterparty; // ← Dépendance
  final List<Category> categories;  // ← Dépendance
}
```

**Bug identifié** : Quand on modifie un `Counterparty` (ex: téléchargement de logo), les `TransactionWithBalance` en cache restent inchangées car elles contiennent l'**ancienne référence** au counterparty.

**Solution actuelle (temporaire)** :
```dart
// CacheManager.addCounterparty() - lib/data/cache/cache_manager.dart:406
Future<void> addCounterparty(CounterpartyModel counterparty) async {
  await _counterpartyService.addCounterparty(counterparty);

  // ⚠️ Recalcul manuel - couplage fort
  await _transactionService.recomputeAllEnrichedData();
}
```

**Problèmes de cette approche** :
- ❌ **Couplage fort** : CacheManager doit connaître les dépendances entre domaines
- ❌ **Non-scalable** : Faut ajouter le recalcul dans TOUTES les méthodes (addCategory, updateCounterparty, removeCategory, etc.)
- ❌ **Code dupliqué** : Même logique répétée partout
- ❌ **Difficile à maintenir** : Risque d'oublier le recalcul quelque part

### Solution proposée : Pattern Observer avec Streams

**Principe** : TransactionCacheService devient un **observateur** de ses dépendances.

```
┌─────────────────────────────────────────────────────────┐
│              AVANT (couplage fort)                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  CacheManager.addCounterparty()                         │
│       ↓                                                 │
│  CounterpartyCacheService.add()                         │
│       ↓                                                 │
│  CacheManager appelle manuellement :                    │
│  TransactionCacheService.recomputeAllEnrichedData()     │
│                                                         │
│  ⚠️ CacheManager DOIT SAVOIR que Transactions          │
│     dépendent des Counterparties                        │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│              APRÈS (découplage)                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  CacheManager.addCounterparty()                         │
│       ↓                                                 │
│  CounterpartyCacheService.add()                         │
│       ↓                                                 │
│  MemoryStore émet sur son stream                        │
│       ↓                                                 │
│  TransactionCacheService (qui écoute) réagit            │
│  automatiquement et recalcule                           │
│                                                         │
│  ✅ CacheManager ne sait rien des dépendances          │
└─────────────────────────────────────────────────────────┘
```

**Bénéfices** :
- ✅ **Découplage complet** : CacheManager ne connaît plus les dépendances
- ✅ **Scalable** : Ajouter une dépendance = 1 ligne dans le constructeur
- ✅ **Maintenable** : Logique de dépendance localisée dans TransactionCacheService
- ✅ **Professionnel** : Pattern Observer standard (GoF)
- ✅ **Réactif** : Mises à jour automatiques dans toute l'app

---

## 🏗️ Architecture technique

### Infrastructure déjà en place (RIEN À AJOUTER ✅)

**MemoryStore a déjà un stream complet** :
```dart
// lib/data/cache/stores/memory_store.dart:28-29
final StreamController<Map<K, V>> _controller =
    StreamController<Map<K, V>>.broadcast();

// lib/data/cache/stores/memory_store.dart:142
Stream<Map<K, V>> get stream => _controller.stream;
```

**MemoryStore notifie automatiquement sur toutes les mutations** :
- `set()` → appelle `_notifyListeners()` (ligne 82)
- `setAll()` → appelle `_notifyListeners()` (ligne 92)
- `remove()` → appelle `_notifyListeners()` (ligne 103)
- `removeAll()` → appelle `_notifyListeners()` (ligne 114)
- `clear()` → appelle `_notifyListeners()` (ligne 129)

**Conclusion** : L'infrastructure stream est **DÉJÀ COMPLÈTE**. Il suffit de s'y abonner.

---

## 🔨 Implémentation étape par étape

### Étape 1 : Ajouter les abonnements aux streams dans TransactionCacheService

**Fichier** : `lib/data/cache/domain_services/transaction_cache_service.dart`

**Modifications à apporter** :

#### 1.1 - Ajouter les StreamSubscription comme propriétés privées

**Position** : Après la ligne 72 (après `_transactionsController`)

```dart
// ═══════════════════════════════════════════════════════════
// STREAM CONTROLLERS
// ═══════════════════════════════════════════════════════════

final StreamController<List<Transaction>> _transactionsController =
    StreamController<List<Transaction>>.broadcast();

// ═══════════════════════════════════════════════════════════
// SUBSCRIPTIONS AUX DÉPENDANCES (Pattern Observer)
// ═══════════════════════════════════════════════════════════

/// Abonnement au stream des counterparties
/// Permet de recalculer les transactions enrichies quand un counterparty change
StreamSubscription<Map<int, CounterpartyModel>>? _counterpartiesSubscription;

/// Abonnement au stream des catégories
/// Permet de recalculer les transactions enrichies quand une catégorie change
StreamSubscription<Map<int, CategoryModel>>? _categoriesSubscription;

/// Abonnement au stream des comptes
/// Permet de recalculer les transactions enrichies quand un compte change
StreamSubscription<Map<int, AccountModel>>? _accountsSubscription;
```

**Raison** : Ces subscriptions seront utilisées pour :
1. Écouter les changements dans les stores de dépendances
2. Pouvoir les annuler dans `dispose()` pour éviter les fuites mémoire

---

#### 1.2 - Modifier le constructeur pour initialiser les abonnements

**Position** : Remplacer le constructeur actuel (lignes 78-90)

**AVANT** :
```dart
TransactionCacheService({
  required MemoryStore<int, TransactionModel> transactionsStore,
  required MemoryStore<int, List<TransactionWithBalance>> enrichedStore,
  required MemoryStore<int, AccountModel> accountsStore,
  required MemoryStore<int, CategoryModel> categoriesStore,
  required MemoryStore<int, CounterpartyModel> counterpartiesStore,
  BalanceComputationEngine? computationEngine,
})  : _transactionsStore = transactionsStore,
      _enrichedStore = enrichedStore,
      _accountsStore = accountsStore,
      _categoriesStore = categoriesStore,
      _counterpartiesStore = counterpartiesStore,
      _computationEngine = computationEngine ?? BalanceComputationEngine();
```

**APRÈS** :
```dart
TransactionCacheService({
  required MemoryStore<int, TransactionModel> transactionsStore,
  required MemoryStore<int, List<TransactionWithBalance>> enrichedStore,
  required MemoryStore<int, AccountModel> accountsStore,
  required MemoryStore<int, CategoryModel> categoriesStore,
  required MemoryStore<int, CounterpartyModel> counterpartiesStore,
  BalanceComputationEngine? computationEngine,
})  : _transactionsStore = transactionsStore,
      _enrichedStore = enrichedStore,
      _accountsStore = accountsStore,
      _categoriesStore = categoriesStore,
      _counterpartiesStore = counterpartiesStore,
      _computationEngine = computationEngine ?? BalanceComputationEngine() {
  // ═══════════════════════════════════════════════════════════
  // INITIALISATION DES OBSERVATEURS (Pattern Observer)
  // ═══════════════════════════════════════════════════════════

  // Observer les changements de counterparties
  // Quand un counterparty est ajouté/modifié/supprimé,
  // les TransactionWithBalance doivent être recalculées
  _counterpartiesSubscription = _counterpartiesStore.stream.listen(
    (_) => _onDependencyChanged('counterparties'),
  );

  // Observer les changements de catégories
  // Quand une catégorie est ajoutée/modifiée/supprimée,
  // les TransactionWithBalance doivent être recalculées
  _categoriesSubscription = _categoriesStore.stream.listen(
    (_) => _onDependencyChanged('categories'),
  );

  // Observer les changements de comptes
  // Quand un compte est modifié (ex: nom, devise),
  // les TransactionWithBalance doivent être recalculées
  _accountsSubscription = _accountsStore.stream.listen(
    (_) => _onDependencyChanged('accounts'),
  );

  print('✅ TransactionCacheService: Observateurs initialisés');
}
```

**Points clés** :
1. **Constructeur avec body** : On ajoute `{ ... }` après l'initialisation
2. **Écoute des 3 dépendances** : counterparties, categories, accounts
3. **Callback unique** : `_onDependencyChanged(source)` pour logger la source
4. **Log de confirmation** : Pour debugger l'initialisation

---

#### 1.3 - Implémenter la méthode `_onDependencyChanged()`

**Position** : Après la ligne 343 (après `recomputeAllEnrichedData()`)

```dart
/// Recalcule TOUS les comptes (appelé à l'initialisation ou changement global)
///
/// Algorithme : Pour chaque compte, recalculer les transactions enrichies
///
/// Complexité : O(m * n log n) où m = nombre de comptes
///
/// Utilisé lors de :
/// - Initialisation du cache
/// - Changement global des catégories ou contreparties
Future<void> recomputeAllEnrichedData() async {
  final accounts = _accountsStore.getAll();

  for (final account in accounts.values) {
    await _recomputeEnrichedData(account.id);
  }
}

// ═══════════════════════════════════════════════════════════
// PATTERN OBSERVER - GESTION DES DÉPENDANCES
// ═══════════════════════════════════════════════════════════

/// Appelé automatiquement quand une dépendance change
///
/// Pattern Observer : TransactionCacheService observe les stores
/// de counterparties, categories et accounts. Quand l'un d'eux émet
/// un événement, cette méthode est appelée automatiquement.
///
/// Algorithme :
/// 1. Logger la source du changement (debug)
/// 2. Recalculer TOUTES les transactions enrichies
/// 3. Notifier le stream pour que les ViewModels se rafraîchissent
///
/// Complexité : O(m * n log n) où m = nombre de comptes
///
/// Paramètres :
/// - [source] : Nom de la dépendance qui a changé (pour logging)
///
/// Exemples de déclenchement :
/// - addCounterparty() → counterpartiesStore émet → _onDependencyChanged()
/// - updateCategory() → categoriesStore émet → _onDependencyChanged()
/// - removeAccount() → accountsStore émet → _onDependencyChanged()
void _onDependencyChanged(String source) {
  print('🔄 TransactionCacheService: Dépendance "$source" changée, recalcul...');

  // 1. Recalculer TOUTES les transactions enrichies
  //    (car on ne sait pas quels comptes sont affectés)
  recomputeAllEnrichedData();

  // 2. Notifier le stream pour que les ViewModels se rafraîchissent
  //    Cela déclenche une mise à jour de l'UI automatiquement
  _notifyTransactionsChanged();

  print('✅ TransactionCacheService: Recalcul terminé suite à changement de "$source"');
}
```

**Points importants** :
1. **Documentation exhaustive** : Explique le pattern, l'algorithme, les exemples
2. **Logging détaillé** : Pour suivre le flux de recalcul
3. **Synchrone** : Pas besoin d'async ici car `recomputeAllEnrichedData()` est déjà async
   - **CORRECTION** : Doit être async car appelle `recomputeAllEnrichedData()` qui est async

**VERSION CORRIGÉE** :
```dart
Future<void> _onDependencyChanged(String source) async {
  print('🔄 TransactionCacheService: Dépendance "$source" changée, recalcul...');

  // 1. Recalculer TOUTES les transactions enrichies
  await recomputeAllEnrichedData();

  // 2. Notifier le stream pour que les ViewModels se rafraîchissent
  _notifyTransactionsChanged();

  print('✅ TransactionCacheService: Recalcul terminé suite à changement de "$source"');
}
```

---

#### 1.4 - Mettre à jour la méthode `dispose()`

**Position** : Remplacer la méthode `dispose()` actuelle (lignes 369-371)

**AVANT** :
```dart
/// Ferme les streams et libère les ressources
void dispose() {
  _transactionsController.close();
}
```

**APRÈS** :
```dart
/// Ferme les streams et libère les ressources
///
/// IMPORTANT : Annule les abonnements aux dépendances pour éviter
/// les fuites mémoire (Pattern Observer)
void dispose() {
  // Annuler les abonnements aux streams des dépendances
  _counterpartiesSubscription?.cancel();
  _categoriesSubscription?.cancel();
  _accountsSubscription?.cancel();

  // Fermer le stream controller des transactions
  _transactionsController.close();

  print('✅ TransactionCacheService: Ressources libérées');
}
```

**Raison** : Les StreamSubscription doivent être annulées pour éviter les fuites mémoire.

---

### Étape 2 : Retirer le recalcul manuel du CacheManager

**Fichier** : `lib/data/cache/cache_manager.dart`

#### 2.1 - Simplifier `addCounterparty()`

**Position** : Ligne ~400-407

**AVANT** :
```dart
/// Ajoute une contrepartie
Future<void> addCounterparty(CounterpartyModel counterparty) async {
  _checkInitialized();
  await _counterpartyService.addCounterparty(counterparty);

  // Recalculer les transactions enrichies car elles contiennent le counterparty
  // Cela permet de mettre à jour les logos dans l'UI sans redémarrage
  await _transactionService.recomputeAllEnrichedData();
}
```

**APRÈS** :
```dart
/// Ajoute une contrepartie
///
/// Le recalcul des transactions enrichies est automatique grâce au
/// Pattern Observer : TransactionCacheService écoute le stream de
/// counterparties et recalcule automatiquement.
Future<void> addCounterparty(CounterpartyModel counterparty) async {
  _checkInitialized();
  await _counterpartyService.addCounterparty(counterparty);

  // ✅ Plus besoin de recalcul manuel - le Pattern Observer le fait automatiquement
}
```

**Raison** : Le recalcul est maintenant géré automatiquement par l'observer.

---

#### 2.2 - Appliquer la même logique aux autres méthodes

**Liste des méthodes à simplifier** (si elles ont un recalcul manuel) :

1. **`updateCounterparty()`** - Ligne ~410
2. **`removeCounterparty()`** - Ligne ~415
3. **`addCategory()`** - Si elle existe et a un recalcul manuel
4. **`updateCategory()`** - Si elle existe et a un recalcul manuel
5. **`removeCategory()`** - Si elle existe et a un recalcul manuel
6. **`updateAccount()`** - Si elle existe et a un recalcul manuel

**Pattern à appliquer partout** :
```dart
// ❌ AVANT (couplage)
Future<void> updateCounterparty(CounterpartyModel counterparty) async {
  _checkInitialized();
  await _counterpartyService.updateCounterparty(counterparty);
  await _transactionService.recomputeAllEnrichedData(); // Couplage
}

// ✅ APRÈS (découplage)
Future<void> updateCounterparty(CounterpartyModel counterparty) async {
  _checkInitialized();
  await _counterpartyService.updateCounterparty(counterparty);
  // Pattern Observer gère le recalcul automatiquement
}
```

---

### Étape 3 : Vérification et tests

#### 3.1 - Vérifier que ça compile

```bash
flutter analyze
```

**Résultat attendu** : 0 errors, 0 warnings

---

#### 3.2 - Test manuel : Scénario du logo

**Procédure de test** :
1. Lancer l'app
2. Créer une transaction avec un nouveau Counterparty (ex: "Lidl")
3. Télécharger un logo pour ce counterparty
4. Fermer la bottom sheet
5. **VÉRIFIER** : Le logo apparaît immédiatement dans la liste des transactions

**Logs attendus** :
```
✅ TransactionCacheService: Observateurs initialisés
...
[Ajout du counterparty]
🔄 TransactionCacheService: Dépendance "counterparties" changée, recalcul...
✅ TransactionCacheService: Recalcul terminé suite à changement de "counterparties"
📥 TransactionListViewModel.initialize() - Sync-First pattern
🔄 TransactionListViewModel received stream update: X items
```

---

#### 3.3 - Test de régression : Autres scénarios

**Cas à tester** :
1. ✅ Créer une transaction → Elle apparaît immédiatement
2. ✅ Modifier une transaction → Les changements apparaissent
3. ✅ Supprimer une transaction → Elle disparaît immédiatement
4. ✅ Créer une catégorie → Les transactions avec cette catégorie se mettent à jour
5. ✅ Modifier un compte → Les transactions du compte se mettent à jour
6. ✅ Télécharger un logo → Le logo apparaît immédiatement (**BUG INITIAL**)

---

### Étape 4 : Optimisations futures (optionnelles)

#### 4.1 - Éviter le recalcul global (optimisation performance)

**Problème actuel** : `_onDependencyChanged()` recalcule **TOUS** les comptes, même si un seul counterparty a changé.

**Optimisation possible** : Identifier les comptes affectés et ne recalculer qu'eux.

**Exemple** :
```dart
// Version optimisée (future)
Future<void> _onCounterpartyChanged(int counterpartyId) async {
  // 1. Identifier les comptes qui ont des transactions avec ce counterparty
  final affectedAccounts = <int>{};
  for (final transaction in _transactionsStore.getAll().values) {
    if (transaction.counterpartyId == counterpartyId) {
      affectedAccounts.add(transaction.accountId);
    }
  }

  // 2. Recalculer uniquement les comptes affectés
  for (final accountId in affectedAccounts) {
    await _recomputeEnrichedData(accountId);
  }

  // 3. Notifier
  _notifyTransactionsChanged();
}
```

**Décision** : Ne PAS implémenter maintenant. Attendre que la performance devienne un problème réel.

**Raison** : Optimisation prématurée = racine du mal. Le recalcul global est simple et fonctionne.

---

#### 4.2 - Debouncing pour éviter les recalculs multiples

**Problème potentiel** : Si on ajoute 10 counterparties d'un coup, 10 recalculs se déclenchent.

**Solution possible** : Debouncing avec `rxdart` ou `Timer`.

**Exemple** :
```dart
Timer? _debounceTimer;

void _onDependencyChanged(String source) {
  // Annuler le timer précédent si existant
  _debounceTimer?.cancel();

  // Attendre 300ms avant de recalculer
  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
    recomputeAllEnrichedData();
    _notifyTransactionsChanged();
  });
}
```

**Décision** : Ne PAS implémenter maintenant. Attendre un besoin réel.

---

## 📊 Résumé des changements

### Fichiers modifiés

| Fichier | Lignes modifiées | Type de changement |
|---------|------------------|-------------------|
| `lib/data/cache/domain_services/transaction_cache_service.dart` | ~72-90, ~343, ~369-371 | Ajout Pattern Observer |
| `lib/data/cache/cache_manager.dart` | ~400-407 + autres méthodes | Suppression recalcul manuel |

### Lignes de code ajoutées

- **StreamSubscription** : 3 propriétés (~6 lignes)
- **Constructeur body** : Abonnements aux streams (~20 lignes)
- **`_onDependencyChanged()`** : Nouvelle méthode (~15 lignes)
- **`dispose()`** : Annulation des subscriptions (~5 lignes)

**Total** : ~46 lignes ajoutées

### Lignes de code supprimées

- **Recalcul manuel** dans CacheManager : ~1 ligne par méthode × N méthodes

**Total** : ~6 lignes supprimées (net : +40 lignes)

---

## 🎯 Checklist d'implémentation

### Phase 1 : Préparation
- [ ] Lire ce plan en entier
- [ ] Comprendre le Pattern Observer
- [ ] Vérifier que `flutter analyze` passe avant modification

### Phase 2 : Modification de TransactionCacheService
- [ ] Ajouter les 3 StreamSubscription (ligne ~72)
- [ ] Modifier le constructeur avec body (lignes 78-90)
- [ ] Implémenter `_onDependencyChanged()` (après ligne 343)
- [ ] Mettre à jour `dispose()` (lignes 369-371)
- [ ] Vérifier compilation : `flutter analyze`

### Phase 3 : Modification de CacheManager
- [ ] Simplifier `addCounterparty()` (ligne ~400-407)
- [ ] Simplifier les autres méthodes si nécessaire
- [ ] Vérifier compilation : `flutter analyze`

### Phase 4 : Tests
- [ ] Test manuel : Scénario du logo
- [ ] Test manuel : Autres scénarios de régression
- [ ] Vérifier les logs dans la console

### Phase 5 : Documentation
- [ ] Mettre à jour `_README.md` avec le résumé de ce refactoring
- [ ] Archiver ce plan comme "complété"

---

## 🚨 Pièges à éviter

### Piège 1 : Oublier le `await` dans `_onDependencyChanged()`

**Mauvais** :
```dart
void _onDependencyChanged(String source) {
  recomputeAllEnrichedData(); // ❌ Pas de await
  _notifyTransactionsChanged();
}
```

**Bon** :
```dart
Future<void> _onDependencyChanged(String source) async {
  await recomputeAllEnrichedData(); // ✅ await
  _notifyTransactionsChanged();
}
```

**Raison** : Sans `await`, la notification se fait AVANT la fin du recalcul.

---

### Piège 2 : Oublier d'annuler les subscriptions dans `dispose()`

**Conséquence** : Fuite mémoire. Les listeners continuent d'écouter après la destruction du service.

**Solution** : Toujours `?.cancel()` dans `dispose()`.

---

### Piège 3 : Modifier MemoryStore inutilement

**RAPPEL** : MemoryStore a DÉJÀ tout ce qu'il faut (stream + notifications).

**À NE PAS FAIRE** : Modifier MemoryStore.

---

### Piège 4 : Supprimer `recomputeAllEnrichedData()` complètement

**ATTENTION** : Cette méthode est toujours nécessaire pour l'initialisation du cache.

**Usage légitime** :
- Initialisation du cache (CacheManager.initialize())
- Callback de `_onDependencyChanged()`

**Usage à supprimer** :
- Appels manuels depuis CacheManager.addCounterparty() etc.

---

## 📚 Références et patterns utilisés

### Pattern Observer (Gang of Four)
- **Définition** : Un objet (Subject) notifie automatiquement ses dépendants (Observers) quand son état change.
- **Avantage** : Découplage entre Subject et Observers.
- **Implémentation Dart** : Utilisation des Streams.

### Reactive Programming
- **Principe** : Les données "fluent" à travers l'application via des streams.
- **Dans cette app** : MemoryStore (Subject) → Stream → TransactionCacheService (Observer) → ViewModels (Consumers)

### Dependency Injection
- **Principe** : Les dépendances sont injectées via le constructeur.
- **Dans ce refactoring** : Les MemoryStores sont injectés dans TransactionCacheService.

---

## ✅ Critères de succès

### Succès technique
- [ ] `flutter analyze` → 0 errors
- [ ] Aucune fuite mémoire (subscriptions annulées)
- [ ] Tous les tests existants passent

### Succès fonctionnel
- [ ] Le logo du counterparty apparaît immédiatement après téléchargement
- [ ] Les modifications de catégories se reflètent immédiatement
- [ ] Les modifications de comptes se reflètent immédiatement

### Succès architectural
- [ ] CacheManager ne contient plus de recalcul manuel
- [ ] TransactionCacheService est le seul responsable du recalcul
- [ ] Code plus maintenable et scalable

---

## 🎓 Pédagogie : Pourquoi ce refactoring est professionnel

1. **Séparation of Concerns** : Chaque service gère ses propres dépendances
2. **Single Responsibility Principle** : TransactionCacheService est responsable de l'invalidation de son cache
3. **Open/Closed Principle** : Ajouter une dépendance = 1 ligne, pas besoin de modifier CacheManager
4. **Liskov Substitution Principle** : Les services restent substituables
5. **Dependency Inversion Principle** : CacheManager dépend d'abstractions (streams), pas d'implémentations

**Résultat** : Code SOLID, maintenable, testable, scalable. 🚀