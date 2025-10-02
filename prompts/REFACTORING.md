# Insight exploratoire
│ │ Analyse et Plan de Refactoring : HomeScreenViewModel avec Pattern Réactif                                                                                                                                                     │ │
│ │                                                                                                                                                                                                                               │ │
│ │ 📋 Analyse de l'architecture actuelle                                                                                                                                                                                         │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Situation actuelle                                                                                                                                                                                                            │ │
│ │                                                                                                                                                                                                                               │ │
│ │ HomeScreenViewModel :                                                                                                                                                                                                         │ │
│ │ - Étend BaseViewModel (pas BaseListViewModel)                                                                                                                                                                                 │ │
│ │ - Utilise Event Bus pour détecter les changements de transactions (ligne 122-124)                                                                                                                                             │ │
│ │ - Appelle manuellement _refreshSelectedAccountSummary() quand une transaction change                                                                                                                                          │ │
│ │ - CacheManager recalcule manuellement les AccountSummary après chaque ajout/suppression de transaction (lignes 301-313, 316-333)                                                                                              │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Dépendances identifiées                                                                                                                                                                                                       │ │
│ │                                                                                                                                                                                                                               │ │
│ │ AccountSummary dépend de :                                                                                                                                                                                                    │ │
│ │ - Transactions enrichies (TransactionWithBalance) du compte                                                                                                                                                                   │ │
│ │ - Calculé par BalanceComputationEngine.computeAccountSummary() (ligne 190-240 de balance_computation_engine.dart)                                                                                                             │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Architecture streams existante :                                                                                                                                                                                              │ │
│ │ - ✅ AccountRepository.watchAccountSummary(accountId) existe déjà                                                                                                                                                              │  │
│ │ - ✅ Ce stream écoute accountsStream qui émet quand les summaries changent                                                                                                                                                     │  │
│ │ - ✅ AccountCacheService a un _summariesStore (MemoryStore) avec stream                                                                                                                                                        │  │
│ │                                                                                                                                                                                                                               │ │
│ │ Problème architectural :                                                                                                                                                                                                      │ │
│ │ - Recalcul manuel : CacheManager.addTransaction() et removeTransaction() appellent manuellement recomputeSummaryForAccount()                                                                                                  │ │
│ │ - Couplage fort : Comme pour TransactionWithBalance avec Counterparty, c'est un recalcul manuel non-scalable                                                                                                                  │ │
│ │ - Event Bus inutile : HomeScreenViewModel écoute TransactionEvent alors que les streams suffiraient                                                                                                                           │ │
│ │                                                                                                                                                                                                                               │ │
│ │ ---                                                                                                                                                                                                                           │ │
│ │ 🎯 Réponses aux questions                                                                                                                                                                                                     │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Question 1 : HomeScreenViewModel devrait-il utiliser BaseListViewModel ?                                                                                                                                                      │ │
│ │                                                                                                                                                                                                                               │ │
│ │ RÉPONSE : NON, car :                                                                                                                                                                                                          │ │
│ │                                                                                                                                                                                                                               │ │
│ │ 1. HomeScreenViewModel ne gère PAS une liste :                                                                                                                                                                                │ │
│ │   - Il gère UN selectedAccountSummary (objet unique)                                                                                                                                                                          │ │
│ │   - Il gère UNE liste de accounts (mais sans pagination/filtrage)                                                                                                                                                             │ │
│ │   - BaseListViewModel est conçu pour pagination/filtrage de listes                                                                                                                                                            │ │
│ │ 2. BaseListViewModel apporterait de la complexité inutile :                                                                                                                                                                   │ │
│ │   - Pagination non nécessaire pour la liste des comptes                                                                                                                                                                       │ │
│ │   - Filtrage par recherche non nécessaire ici                                                                                                                                                                                 │ │
│ │   - Le carousel de cartes a sa propre logique de navigation                                                                                                                                                                   │ │
│ │ 3. Mais il DEVRAIT utiliser les streams (réponse à la question 2)                                                                                                                                                             │ │
│ │                                                                                                                                                                                                                               │ │
│ │ ---                                                                                                                                                                                                                           │ │
│ │ Question 2 : Peut-on recalculer automatiquement les AccountSummary et supprimer les Event Bus ?                                                                                                                               │ │
│ │                                                                                                                                                                                                                               │ │
│ │ RÉPONSE : OUI, avec le même Pattern Observer que TransactionWithBalance !                                                                                                                                                     │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Solution recommandée :                                                                                                                                                                                                        │ │
│ │                                                                                                                                                                                                                               │ │
│ │ 1. AccountCacheService observe TransactionCacheService :                                                                                                                                                                      │ │
│ │   - Quand les transactions enrichies changent → recalculer les summaries                                                                                                                                                      │ │
│ │   - Pattern identique à TransactionCacheService qui observe counterparties/categories                                                                                                                                         │ │
│ │ 2. HomeScreenViewModel utilise le stream :                                                                                                                                                                                    │ │
│ │   - Remplacer l'Event Bus par watchAccountSummary(accountId)                                                                                                                                                                  │ │
│ │   - Mise à jour automatique sans recalcul manuel                                                                                                                                                                              │ │
│ │ 3. Event Bus devient OPTIONNEL :                                                                                                                                                                                              │ │
│ │   - Peut être conservé pour la communication inter-écrans (ex: AccountSelectedEvent)                                                                                                                                          │ │
│ │   - Mais inutile pour la réactivité des données (streams suffisent)                                                                                                                                                           │ │
│ │                                                                                                                                                                                                                               │ │
│ │ ---                                                                                                                                                                                                                           │ │
│ │ 🔨 Plan de refactoring détaillé                                                                                                                                                                                               │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Étape 1 : AccountCacheService observe TransactionCacheService (Pattern Observer)                                                                                                                                              │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Fichier : lib/data/cache/domain_services/account_cache_service.dart                                                                                                                                                           │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Modifications :                                                                                                                                                                                                               │ │
│ │                                                                                                                                                                                                                               │ │
│ │ 1. Ajouter StreamSubscription pour observer les transactions enrichies                                                                                                                                                        │ │
│ │ 2. Dans le constructeur, s'abonner au stream des transactions enrichies                                                                                                                                                       │ │
│ │ 3. Callback _onEnrichedTransactionsChanged() recalcule les summaries affectés                                                                                                                                                 │ │
│ │ 4. Annuler la subscription dans dispose()                                                                                                                                                                                     │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Code à ajouter :                                                                                                                                                                                                              │ │
│ │ // Après ligne 47 (_summariesStore)                                                                                                                                                                                           │ │
│ │ StreamSubscription<Map<int, List<TransactionWithBalance>>>? _enrichedTransactionsSubscription;                                                                                                                                │ │
│ │                                                                                                                                                                                                                               │ │
│ │ // Dans le constructeur (ligne ~70)                                                                                                                                                                                           │ │
│ │ AccountCacheService({...}) : ... {                                                                                                                                                                                            │ │
│ │   // Observer les changements de transactions enrichies                                                                                                                                                                       │ │
│ │   _enrichedTransactionsSubscription = _enrichedStore.stream.listen(                                                                                                                                                           │ │
│ │     (_) => _onEnrichedTransactionsChanged(),                                                                                                                                                                                  │ │
│ │   );                                                                                                                                                                                                                          │ │
│ │ }                                                                                                                                                                                                                             │ │
│ │                                                                                                                                                                                                                               │ │
│ │ // Nouvelle méthode (après ligne 271)                                                                                                                                                                                         │ │
│ │ Future<void> _onEnrichedTransactionsChanged() async {                                                                                                                                                                         │ │
│ │   // Recalculer TOUS les summaries car on ne sait pas quels comptes sont affectés                                                                                                                                             │ │
│ │   final enrichedByAccount = <int, List<TransactionWithBalance>>{};                                                                                                                                                            │ │
│ │                                                                                                                                                                                                                               │ │
│ │   for (final account in _accountsStore.getAll().values) {                                                                                                                                                                     │ │
│ │     enrichedByAccount[account.id] = _enrichedStore.get(account.id) ?? [];                                                                                                                                                     │ │
│ │   }                                                                                                                                                                                                                           │ │
│ │                                                                                                                                                                                                                               │ │
│ │   await recomputeAllSummaries(enrichedByAccount);                                                                                                                                                                             │ │
│ │   _notifyAccountsChanged();                                                                                                                                                                                                   │ │
│ │ }                                                                                                                                                                                                                             │ │
│ │                                                                                                                                                                                                                               │ │
│ │ // Dans dispose() (ligne ~350)                                                                                                                                                                                                │ │
│ │ void dispose() {                                                                                                                                                                                                              │ │
│ │   _enrichedTransactionsSubscription?.cancel();                                                                                                                                                                                │ │
│ │   _accountsController.close();                                                                                                                                                                                                │ │
│ │ }                                                                                                                                                                                                                             │ │
│ │                                                                                                                                                                                                                               │ │
│ │ ---                                                                                                                                                                                                                           │ │
│ │ Étape 2 : Supprimer le recalcul manuel de CacheManager                                                                                                                                                                        │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Fichier : lib/data/cache/cache_manager.dart                                                                                                                                                                                   │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Simplifier addTransaction() (lignes 301-313) :                                                                                                                                                                                │ │
│ │ // AVANT                                                                                                                                                                                                                      │ │
│ │ Future<void> addTransaction(TransactionModel transaction) async {                                                                                                                                                             │ │
│ │   _checkInitialized();                                                                                                                                                                                                        │ │
│ │   await _transactionService.addTransaction(transaction);                                                                                                                                                                      │ │
│ │                                                                                                                                                                                                                               │ │
│ │   // Recalculer le summary du compte concerné                                                                                                                                                                                 │ │
│ │   final enrichedTransactions = _transactionService.getTransactionsWithBalance(                                                                                                                                                │ │
│ │     transaction.accountId,                                                                                                                                                                                                    │ │
│ │   );                                                                                                                                                                                                                          │ │
│ │   await _accountService.recomputeSummaryForAccount(                                                                                                                                                                           │ │
│ │     transaction.accountId,                                                                                                                                                                                                    │ │
│ │     enrichedTransactions,                                                                                                                                                                                                     │ │
│ │   );                                                                                                                                                                                                                          │ │
│ │ }                                                                                                                                                                                                                             │ │
│ │                                                                                                                                                                                                                               │ │
│ │ // APRÈS                                                                                                                                                                                                                      │ │
│ │ Future<void> addTransaction(TransactionModel transaction) async {                                                                                                                                                             │ │
│ │   _checkInitialized();                                                                                                                                                                                                        │ │
│ │   await _transactionService.addTransaction(transaction);                                                                                                                                                                      │ │
│ │                                                                                                                                                                                                                               │ │
│ │   // ✅ Plus besoin de recalcul manuel - Pattern Observer le fait automatiquement                                                                                                                                              │  │
│ │ }                                                                                                                                                                                                                             │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Même chose pour removeTransaction() (lignes 316-333)                                                                                                                                                                          │ │
│ │                                                                                                                                                                                                                               │ │
│ │ ---                                                                                                                                                                                                                           │ │
│ │ Étape 3 : HomeScreenViewModel utilise le stream (sans BaseListViewModel)                                                                                                                                                      │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Fichier : lib/presentation/viewmodels/screens/home_screen_view_model.dart                                                                                                                                                     │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Modifications :                                                                                                                                                                                                               │ │
│ │                                                                                                                                                                                                                               │ │
│ │ 1. Ajouter StreamSubscription pour watchAccountSummary() (ligne ~102)                                                                                                                                                         │ │
│ │ 2. Supprimer _transactionEventSubscription et _handleTransactionEvent()                                                                                                                                                       │ │
│ │ 3. S'abonner au stream dans selectAccount() / selectAccountByIndex()                                                                                                                                                          │ │
│ │ 4. Annuler dans dispose()                                                                                                                                                                                                     │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Code modifié :                                                                                                                                                                                                                │ │
│ │ class HomeScreenViewModel extends BaseViewModel<HomeScreenViewState> {                                                                                                                                                        │ │
│ │   final AccountRepository _accountRepository;                                                                                                                                                                                 │ │
│ │   StreamSubscription<AccountEvent>? _accountEventSubscription;                                                                                                                                                                │ │
│ │   StreamSubscription<AccountSummary>? _accountSummarySubscription; // Nouveau                                                                                                                                                 │ │
│ │                                                                                                                                                                                                                               │ │
│ │   // SUPPRIMER _transactionEventSubscription                                                                                                                                                                                  │ │
│ │                                                                                                                                                                                                                               │ │
│ │   void _subscribeToEvents() {                                                                                                                                                                                                 │ │
│ │     final eventBus = AppEventBus.instance;                                                                                                                                                                                    │ │
│ │                                                                                                                                                                                                                               │ │
│ │     // Écouter les événements de comptes                                                                                                                                                                                      │ │
│ │     _accountEventSubscription = eventBus.accountEvents.listen((event) {                                                                                                                                                       │ │
│ │       _handleAccountEvent(event);                                                                                                                                                                                             │ │
│ │     });                                                                                                                                                                                                                       │ │
│ │                                                                                                                                                                                                                               │ │
│ │     // ✅ SUPPRIMER l'écoute des TransactionEvent                                                                                                                                                                              │  │
│ │   }                                                                                                                                                                                                                           │ │
│ │                                                                                                                                                                                                                               │ │
│ │   // SUPPRIMER _handleTransactionEvent()                                                                                                                                                                                      │ │
│ │                                                                                                                                                                                                                               │ │
│ │   Future<void> selectAccount(int accountId, {bool notifyEventBus = true}) async {                                                                                                                                             │ │
│ │     final account = state.accounts.firstWhere(...);                                                                                                                                                                           │ │
│ │     state = state.copyWith(selectedAccount: account);                                                                                                                                                                         │ │
│ │                                                                                                                                                                                                                               │ │
│ │     // Annuler l'ancienne subscription                                                                                                                                                                                        │ │
│ │     await _accountSummarySubscription?.cancel();                                                                                                                                                                              │ │
│ │                                                                                                                                                                                                                               │ │
│ │     // S'abonner au stream du summary de ce compte                                                                                                                                                                            │ │
│ │     _accountSummarySubscription = _accountRepository                                                                                                                                                                          │ │
│ │         .watchAccountSummary(accountId)                                                                                                                                                                                       │ │
│ │         .listen((summary) {                                                                                                                                                                                                   │ │
│ │       state = state.copyWith(selectedAccountSummary: summary);                                                                                                                                                                │ │
│ │     });                                                                                                                                                                                                                       │ │
│ │                                                                                                                                                                                                                               │ │
│ │     // Charger immédiatement le summary (Sync-First)                                                                                                                                                                          │ │
│ │     final summary = _accountRepository.getAccountSummary(accountId);                                                                                                                                                          │ │
│ │     state = state.copyWith(selectedAccountSummary: summary);                                                                                                                                                                  │ │
│ │                                                                                                                                                                                                                               │ │
│ │     // Notifier Event Bus si demandé                                                                                                                                                                                          │ │
│ │     if (notifyEventBus) { ... }                                                                                                                                                                                               │ │
│ │   }                                                                                                                                                                                                                           │ │
│ │                                                                                                                                                                                                                               │ │
│ │   // SUPPRIMER _refreshSelectedAccountSummary() - plus nécessaire                                                                                                                                                             │ │
│ │                                                                                                                                                                                                                               │ │
│ │   @override                                                                                                                                                                                                                   │ │
│ │   void dispose() {                                                                                                                                                                                                            │ │
│ │     _accountEventSubscription?.cancel();                                                                                                                                                                                      │ │
│ │     _accountSummarySubscription?.cancel(); // Nouveau                                                                                                                                                                         │ │
│ │     super.dispose();                                                                                                                                                                                                          │ │
│ │   }                                                                                                                                                                                                                           │ │
│ │ }                                                                                                                                                                                                                             │ │
│ │                                                                                                                                                                                                                               │ │
│ │ ---                                                                                                                                                                                                                           │ │
│ │ ✅ Bénéfices du refactoring                                                                                                                                                                                                    │  │
│ │                                                                                                                                                                                                                               │ │
│ │ 1. Découplage : CacheManager ne sait plus qu'il faut recalculer les summaries                                                                                                                                                 │ │
│ │ 2. Scalable : Si on ajoute d'autres dépendances aux summaries, aucune modification de CacheManager                                                                                                                            │ │
│ │ 3. Cohérence : Même Pattern Observer que TransactionWithBalance                                                                                                                                                               │ │
│ │ 4. Réactivité : Mises à jour automatiques dans toute l'app                                                                                                                                                                    │ │
│ │ 5. Event Bus optionnel : Conservé uniquement pour communication inter-écrans, pas pour réactivité des données                                                                                                                 │ │
│ │                                                                                                                                                                                                                               │ │
│ │ ---                                                                                                                                                                                                                           │ │
│ │ 📊 Résumé des fichiers à modifier                                                                                                                                                                                             │ │
│ │                                                                                                                                                                                                                               │ │
│ │ | Fichier                     | Type de changement                                              |                                                                                                                             │ │
│ │ |-----------------------------|-----------------------------------------------------------------|                                                                                                                             │ │
│ │ | account_cache_service.dart  | Ajout Pattern Observer (observe enrichedStore)                  |                                                                                                                             │ │
│ │ | cache_manager.dart          | Suppression recalcul manuel (addTransaction, removeTransaction) |                                                                                                                             │ │
│ │ | home_screen_view_model.dart | Utilisation stream au lieu d'Event Bus                          |                                                                                                                             │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Lignes de code : ~60 lignes ajoutées, ~40 lignes supprimées (net : +20 lignes)                                                                                                                                                │ │
│ │                                                                                                                                                                                                                               │ │
│ │ ---                                                                                                                                                                                                                           │ │
│ │ 🚨 Event Bus : À conserver ou supprimer ?                                                                                                                                                                                     │ │
│ │                                                                                                                                                                                                                               │ │
│ │ VERDICT : CONSERVER PARTIELLEMENT                                                                                                                                                                                             │ │
│ │                                                                                                                                                                                                                               │ │
│ │ À CONSERVER :                                                                                                                                                                                                                 │ │
│ │ - AccountSelectedEvent : Communication entre écrans (ex: HomeScreen → TransactionListScreen)                                                                                                                                  │ │
│ │ - AccountCreatedEvent, AccountUpdatedEvent, AccountDeletedEvent : Notifications globales                                                                                                                                      │ │
│ │                                                                                                                                                                                                                               │ │
│ │ À SUPPRIMER :                                                                                                                                                                                                                 │ │
│ │ - Écoute de TransactionEvent dans HomeScreenViewModel → Remplacer par stream                                                                                                                                                  │ │
│ │ - Recalculs manuels déclenchés par Event Bus → Pattern Observer                                                                                                                                                               │ │
│ │                                                                                                                                                                                                                               │ │
│ │ Philosophie :                                                                                                                                                                                                                 │ │
│ │ - Streams = Réactivité des données (changements de state)                                                                                                                                                                     │ │
│ │ - Event Bus = Communication applicative (navigation, notifications)

# Plan ultra-détaillé - Pattern Observer pour AccountSummary

## 📋 Contexte et problématique

### Problème actuel
Les `AccountSummary` sont des **entités calculées** qui dépendent des transactions enrichies (`TransactionWithBalance`) :

```dart
class AccountSummary {
  final Account account;
  final AccountBalance currentBalance;        // ← Dépend des transactions
  final AccountBalance confirmedBalance;      // ← Dépend des transactions
  final List<TransactionWithBalance> recentTransactions; // ← Dépendance directe
  final int totalTransactionsCount;           // ← Dépend des transactions
  final Money totalIncome;                    // ← Dépend des transactions
  final Money totalExpenses;                  // ← Dépend des transactions
  final DateTime lastTransactionDate;         // ← Dépend des transactions
}
```

**Bug actuel** : Quand on ajoute/supprime une transaction, `CacheManager` doit **manuellement** recalculer les `AccountSummary` :

```dart
// CacheManager.addTransaction() - ligne 301-313
Future<void> addTransaction(TransactionModel transaction) async {
  await _transactionService.addTransaction(transaction);

  // ⚠️ Recalcul manuel - couplage fort
  final enrichedTransactions = _transactionService.getTransactionsWithBalance(
    transaction.accountId,
  );
  await _accountService.recomputeSummaryForAccount(
    transaction.accountId,
    enrichedTransactions,
  );
}
```

**Problèmes de cette approche** :
- ❌ **Couplage fort** : CacheManager doit savoir que AccountSummary dépend des transactions
- ❌ **Non-scalable** : Faut ajouter le recalcul dans toutes les méthodes (addTransaction, removeTransaction, updateTransaction, etc.)
- ❌ **Code dupliqué** : Même logique répétée dans addTransaction() et removeTransaction()
- ❌ **Event Bus inutile** : HomeScreenViewModel écoute TransactionEvent alors que les streams suffisent

### Solution proposée : Pattern Observer avec Streams

**Principe** : AccountCacheService devient un **observateur** de TransactionCacheService.

```
┌─────────────────────────────────────────────────────────┐
│              AVANT (couplage fort)                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  CacheManager.addTransaction()                          │
│       ↓                                                 │
│  TransactionCacheService.addTransaction()               │
│       ↓                                                 │
│  CacheManager appelle manuellement :                    │
│  AccountCacheService.recomputeSummaryForAccount()       │
│                                                         │
│  ⚠️ CacheManager DOIT SAVOIR que AccountSummary        │
│     dépend des Transactions                             │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│              APRÈS (découplage)                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  CacheManager.addTransaction()                          │
│       ↓                                                 │
│  TransactionCacheService.addTransaction()               │
│       ↓                                                 │
│  _enrichedStore émet sur son stream                     │
│       ↓                                                 │
│  AccountCacheService (qui écoute) réagit                │
│  automatiquement et recalcule les summaries             │
│                                                         │
│  ✅ CacheManager ne sait rien des dépendances          │
└─────────────────────────────────────────────────────────┘
```

**Bénéfices** :
- ✅ **Découplage complet** : CacheManager ne connaît plus les dépendances
- ✅ **Scalable** : Ajouter une dépendance = 1 ligne dans le constructeur
- ✅ **Maintenable** : Logique de dépendance localisée dans AccountCacheService
- ✅ **Professionnel** : Pattern Observer standard (GoF)
- ✅ **Réactif** : Mises à jour automatiques dans toute l'app
- ✅ **Cohérent** : Même pattern que TransactionCacheService → Counterparties/Categories

---

## 🏗️ Architecture technique

### Infrastructure déjà en place (RIEN À AJOUTER à MemoryStore ✅)

**MemoryStore a déjà un stream complet** :
```dart
// lib/data/cache/stores/memory_store.dart:28-29
final StreamController<Map<K, V>> _controller =
    StreamController<Map<K, V>>.broadcast();

// lib/data/cache/stores/memory_store.dart:142
Stream<Map<K, V>> get stream => _controller.stream;
```

**_enrichedStore notifie automatiquement** quand TransactionCacheService modifie les transactions enrichies.

**Conclusion** : L'infrastructure stream est **DÉJÀ COMPLÈTE**. Il suffit de s'y abonner.

---

## 🔨 Implémentation étape par étape

### PHASE 1 : AccountCacheService observe _enrichedStore (Pattern Observer)

**Fichier** : `lib/data/cache/domain_services/account_cache_service.dart`

---

#### Étape 1.1 : Ajouter la référence à _enrichedStore et StreamSubscription

**Position** : Après la ligne 47 (`_summariesStore`)

**Code à ajouter** :
```dart
  /// Store des résumés de comptes (AccountSummary)
  final MemoryStore<int, AccountSummary> _summariesStore;

  // ═══════════════════════════════════════════════════════════
  // RÉFÉRENCE À L'ENRICHED STORE (pour Pattern Observer)
  // ═══════════════════════════════════════════════════════════

  /// Référence au store des transactions enrichies (pour observer les changements)
  /// Quand les transactions enrichies changent, les AccountSummary doivent être recalculés
  final MemoryStore<int, List<TransactionWithBalance>> _enrichedStore;

  // ═══════════════════════════════════════════════════════════
  // COMPUTATION ENGINE
  // ═══════════════════════════════════════════════════════════
```

**ET après la ligne 60 (`_accountsController`)** :

```dart
  final StreamController<List<Account>> _accountsController =
      StreamController<List<Account>>.broadcast();

  // ═══════════════════════════════════════════════════════════
  // SUBSCRIPTIONS AUX DÉPENDANCES (Pattern Observer)
  // ═══════════════════════════════════════════════════════════

  /// Abonnement au stream des transactions enrichies
  /// Permet de recalculer les AccountSummary quand les transactions changent
  StreamSubscription<Map<int, List<TransactionWithBalance>>>?
      _enrichedTransactionsSubscription;

  // ═══════════════════════════════════════════════════════════
  // CONSTRUCTEUR (Dependency Injection)
  // ═══════════════════════════════════════════════════════════
```

---

#### Étape 1.2 : Modifier le constructeur pour accepter _enrichedStore et initialiser l'observer

**Position** : Remplacer le constructeur actuel (lignes 66-72)

**AVANT** :
```dart
  AccountCacheService({
    required MemoryStore<int, AccountModel> accountsStore,
    required MemoryStore<int, AccountSummary> summariesStore,
    BalanceComputationEngine? computationEngine,
  })  : _accountsStore = accountsStore,
        _summariesStore = summariesStore,
        _computationEngine = computationEngine ?? BalanceComputationEngine();
```

**APRÈS** :
```dart
  AccountCacheService({
    required MemoryStore<int, AccountModel> accountsStore,
    required MemoryStore<int, AccountSummary> summariesStore,
    required MemoryStore<int, List<TransactionWithBalance>> enrichedStore,
    BalanceComputationEngine? computationEngine,
  })  : _accountsStore = accountsStore,
        _summariesStore = summariesStore,
        _enrichedStore = enrichedStore,
        _computationEngine = computationEngine ?? BalanceComputationEngine() {
    // ═══════════════════════════════════════════════════════════
    // INITIALISATION DES OBSERVATEURS (Pattern Observer)
    // ═══════════════════════════════════════════════════════════

    // Observer les changements de transactions enrichies
    // Quand les transactions enrichies changent (ajout/suppression/modification),
    // les AccountSummary doivent être recalculés car ils en dépendent
    _enrichedTransactionsSubscription = _enrichedStore.stream.listen(
      (_) => _onEnrichedTransactionsChanged(),
    );

    print('✅ AccountCacheService: Observateur initialisé (enrichedStore)');
  }
```

**Points clés** :
1. **Nouveau paramètre** : `required MemoryStore<int, List<TransactionWithBalance>> enrichedStore`
2. **Initialisation** : `_enrichedStore = enrichedStore,`
3. **Constructeur avec body** : Ajouter `{ ... }` pour initialiser l'observer
4. **Écoute du stream** : `_enrichedStore.stream.listen(...)`

---

#### Étape 1.3 : Implémenter la méthode `_onEnrichedTransactionsChanged()`

**Position** : Après la ligne 271 (après `recomputeAllSummaries()`)

```dart
  /// Recalcule TOUS les summaries (appelé à l'initialisation)
  ///
  /// [Code existant de recomputeAllSummaries()...]
  Future<void> recomputeAllSummaries(
    Map<int, List<TransactionWithBalance>> enrichedTransactionsByAccount,
  ) async {
    final accounts = _accountsStore.getAll();

    for (final account in accounts.values) {
      final enrichedTransactions =
          enrichedTransactionsByAccount[account.id] ?? [];
      await _recomputeSummary(account, enrichedTransactions);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PATTERN OBSERVER - GESTION DES DÉPENDANCES
  // ═══════════════════════════════════════════════════════════

  /// Appelé automatiquement quand les transactions enrichies changent
  ///
  /// Pattern Observer : AccountCacheService observe le store des transactions
  /// enrichies (_enrichedStore). Quand celui-ci émet un événement, cette méthode
  /// est appelée automatiquement.
  ///
  /// Algorithme :
  /// 1. Logger le changement (debug)
  /// 2. Recalculer TOUS les AccountSummary (car on ne sait pas quels comptes sont affectés)
  /// 3. Notifier le stream pour que les ViewModels se rafraîchissent
  ///
  /// Complexité : O(m * n) où m = nombre de comptes, n = nombre de transactions par compte
  ///
  /// Exemples de déclenchement :
  /// - addTransaction() → enrichedStore émet → _onEnrichedTransactionsChanged()
  /// - removeTransaction() → enrichedStore émet → _onEnrichedTransactionsChanged()
  /// - updateTransaction() → enrichedStore émet → _onEnrichedTransactionsChanged()
  Future<void> _onEnrichedTransactionsChanged() async {
    print(
      '🔄 AccountCacheService: Transactions enrichies changées, recalcul des summaries...',
    );

    // 1. Construire la map enrichedByAccount à partir de _enrichedStore
    //    (car recomputeAllSummaries() attend ce format)
    final enrichedByAccount = <int, List<TransactionWithBalance>>{};

    for (final account in _accountsStore.getAll().values) {
      enrichedByAccount[account.id] = _enrichedStore.get(account.id) ?? [];
    }

    // 2. Recalculer TOUS les summaries
    await recomputeAllSummaries(enrichedByAccount);

    // 3. Notifier le stream pour que les ViewModels se rafraîchissent
    //    Cela déclenche une mise à jour de l'UI automatiquement
    _notifyAccountsChanged();

    print(
      '✅ AccountCacheService: Recalcul des summaries terminé',
    );
  }

  /// Recalcule le summary d'un compte spécifique
  ///
  /// [Code existant de recomputeSummaryForAccount()...]
```

**Points importants** :
1. **Documentation exhaustive** : Explique le pattern, l'algorithme, les exemples
2. **Logging détaillé** : Pour suivre le flux de recalcul
3. **Asynchrone** : Doit être `async` car appelle `recomputeAllSummaries()` qui est async
4. **Construction de enrichedByAccount** : Récupère les données de _enrichedStore pour chaque compte

---

#### Étape 1.4 : Mettre à jour la méthode `dispose()`

**Position** : Chercher la méthode `dispose()` (actuellement elle n'existe probablement pas)

**Si `dispose()` n'existe pas** (ajouter après `_notifyAccountsChanged()` vers ligne 350) :

```dart
  /// Notifie les listeners d'un changement
  void _notifyAccountsChanged() {
    if (!_accountsController.isClosed) {
      _accountsController.add(getAllAccounts());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════

  /// Ferme les streams et libère les ressources
  ///
  /// IMPORTANT : Annule les abonnements aux dépendances pour éviter
  /// les fuites mémoire (Pattern Observer)
  void dispose() {
    // Annuler l'abonnement au stream des transactions enrichies
    _enrichedTransactionsSubscription?.cancel();

    // Fermer le stream controller des comptes
    _accountsController.close();

    print('✅ AccountCacheService: Ressources libérées');
  }
}
```

**Si `dispose()` existe déjà**, ajouter simplement :
```dart
void dispose() {
  _enrichedTransactionsSubscription?.cancel(); // ← AJOUTER CETTE LIGNE
  _accountsController.close();
}
```

---

### PHASE 2 : Modifier CacheManager pour passer _enrichedStore à AccountCacheService

**Fichier** : `lib/data/cache/cache_manager.dart`

---

#### Étape 2.1 : Passer _enrichedStore au constructeur d'AccountCacheService

**Position** : Ligne ~155-159

**AVANT** :
```dart
    _accountService = AccountCacheService(
      accountsStore: _accountsStore,
      summariesStore: _summariesStore,
      computationEngine: _computationEngine,
    );
```

**APRÈS** :
```dart
    _accountService = AccountCacheService(
      accountsStore: _accountsStore,
      summariesStore: _summariesStore,
      enrichedStore: _enrichedStore, // ← AJOUTER CETTE LIGNE
      computationEngine: _computationEngine,
    );
```

**Raison** : AccountCacheService a maintenant besoin de _enrichedStore pour observer ses changements.

---

### PHASE 3 : Supprimer le recalcul manuel de CacheManager

**Fichier** : `lib/data/cache/cache_manager.dart`

---

#### Étape 3.1 : Simplifier `addTransaction()`

**Position** : Lignes 301-313

**AVANT** :
```dart
  /// Ajoute une transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    _checkInitialized();
    await _transactionService.addTransaction(transaction);

    // Recalculer le summary du compte concerné
    final enrichedTransactions = _transactionService.getTransactionsWithBalance(
      transaction.accountId,
    );
    await _accountService.recomputeSummaryForAccount(
      transaction.accountId,
      enrichedTransactions,
    );
  }
```

**APRÈS** :
```dart
  /// Ajoute une transaction
  ///
  /// Le recalcul des AccountSummary est automatique grâce au
  /// Pattern Observer : AccountCacheService écoute le stream de
  /// transactions enrichies et recalcule automatiquement.
  Future<void> addTransaction(TransactionModel transaction) async {
    _checkInitialized();
    await _transactionService.addTransaction(transaction);

    // ✅ Plus besoin de recalcul manuel - le Pattern Observer le fait automatiquement
  }
```

---

#### Étape 3.2 : Simplifier `removeTransaction()`

**Position** : Lignes 316-333

**AVANT** :
```dart
  /// Supprime une transaction
  Future<void> removeTransaction(int transactionId) async {
    _checkInitialized();
    final transaction = _transactionService.getTransactionById(transactionId);
    if (transaction == null) return;

    final accountId = transaction.accountId;

    await _transactionService.removeTransaction(transactionId);

    // Recalculer le summary du compte concerné
    final enrichedTransactions = _transactionService.getTransactionsWithBalance(
      accountId,
    );
    await _accountService.recomputeSummaryForAccount(
      accountId,
      enrichedTransactions,
    );
  }
```

**APRÈS** :
```dart
  /// Supprime une transaction
  ///
  /// Le recalcul des AccountSummary est automatique grâce au
  /// Pattern Observer : AccountCacheService écoute le stream de
  /// transactions enrichies et recalcule automatiquement.
  Future<void> removeTransaction(int transactionId) async {
    _checkInitialized();
    final transaction = _transactionService.getTransactionById(transactionId);
    if (transaction == null) return;

    await _transactionService.removeTransaction(transactionId);

    // ✅ Plus besoin de recalcul manuel - le Pattern Observer le fait automatiquement
  }
```

**Note** : On peut aussi supprimer la ligne `final accountId = transaction.accountId;` car elle n'est plus utilisée.

---

### PHASE 4 : HomeScreenViewModel utilise le stream (sans BaseListViewModel)

**Fichier** : `lib/presentation/viewmodels/screens/home_screen_view_model.dart`

---

#### Étape 4.1 : Ajouter StreamSubscription pour AccountSummary

**Position** : Ligne ~102 (après `_transactionEventSubscription`)

**AVANT** :
```dart
  final AccountRepository _accountRepository;
  StreamSubscription<AccountEvent>? _accountEventSubscription;
  StreamSubscription<TransactionEvent>? _transactionEventSubscription;

  HomeScreenViewModel(this._accountRepository)
```

**APRÈS** :
```dart
  final AccountRepository _accountRepository;
  StreamSubscription<AccountEvent>? _accountEventSubscription;
  StreamSubscription<AccountSummary>? _accountSummarySubscription;
  // SUPPRIMER _transactionEventSubscription

  HomeScreenViewModel(this._accountRepository)
```

---

#### Étape 4.2 : Supprimer l'écoute de TransactionEvent

**Position** : Lignes 113-125

**AVANT** :
```dart
  void _subscribeToEvents() {
    final eventBus = AppEventBus.instance;

    // Écouter les événements de comptes
    _accountEventSubscription = eventBus.accountEvents.listen((event) {
      _handleAccountEvent(event);
    });

    // Écouter les événements de transactions pour mettre à jour les soldes
    _transactionEventSubscription = eventBus.transactionEvents.listen((event) {
      _handleTransactionEvent(event);
    });
  }
```

**APRÈS** :
```dart
  void _subscribeToEvents() {
    final eventBus = AppEventBus.instance;

    // Écouter les événements de comptes
    _accountEventSubscription = eventBus.accountEvents.listen((event) {
      _handleAccountEvent(event);
    });

    // ✅ Plus besoin d'écouter TransactionEvent - le stream le fait automatiquement
  }
```

---

#### Étape 4.3 : Supprimer _handleTransactionEvent()

**Position** : Lignes 146-151

**SUPPRIMER COMPLÈTEMENT** :
```dart
  void _handleTransactionEvent(TransactionEvent event) {
    // Si une transaction affecte le compte sélectionné, recharger son résumé
    if (state.selectedAccount?.id == event.accountId) {
      _refreshSelectedAccountSummary();
    }
  }
```

---

#### Étape 4.4 : Modifier selectAccount() pour utiliser le stream

**Position** : Lignes 263-289

**AVANT** :
```dart
  Future<void> selectAccount(
    int accountId, {
    bool notifyEventBus = true,
  }) async {
    final account = state.accounts.firstWhere(
      (account) => account.id == accountId,
      orElse: () => throw StateError('Account with id $accountId not found'),
    );

    state = state.copyWith(selectedAccount: account);

    // Charger le résumé du compte sélectionné
    await _refreshSelectedAccountSummary();

    // Notifier l'Event Bus si demandé
    if (notifyEventBus) {
      final eventBus = AppEventBus.instance;
      eventBus.fire(
        AccountSelectedEvent(
          accountId: accountId,
          timestamp: DateTime.now(),
          eventId: '${DateTime.now().millisecondsSinceEpoch}_account_selected',
        ),
      );
    }
  }
```

**APRÈS** :
```dart
  Future<void> selectAccount(
    int accountId, {
    bool notifyEventBus = true,
  }) async {
    final account = state.accounts.firstWhere(
      (account) => account.id == accountId,
      orElse: () => throw StateError('Account with id $accountId not found'),
    );

    state = state.copyWith(selectedAccount: account);

    // Annuler l'ancienne subscription si elle existe
    await _accountSummarySubscription?.cancel();

    // S'abonner au stream du summary de ce compte (Pattern Réactif)
    _accountSummarySubscription = _accountRepository
        .watchAccountSummary(accountId)
        .listen((summary) {
      print('🔄 HomeScreenViewModel: AccountSummary mis à jour via stream');
      state = state.copyWith(selectedAccountSummary: summary);
    });

    // Charger immédiatement le summary (Sync-First Pattern)
    await executeWithErrorHandling(() async {
      final summary = _accountRepository.getAccountSummary(accountId);
      state = state.copyWith(selectedAccountSummary: summary);
    });

    // Notifier l'Event Bus si demandé
    if (notifyEventBus) {
      final eventBus = AppEventBus.instance;
      eventBus.fire(
        AccountSelectedEvent(
          accountId: accountId,
          timestamp: DateTime.now(),
          eventId: '${DateTime.now().millisecondsSinceEpoch}_account_selected',
        ),
      );
    }
  }
```

**Points clés** :
1. **Annuler l'ancienne subscription** : Éviter les fuites mémoire
2. **S'abonner au stream** : `watchAccountSummary(accountId)`
3. **Sync-First** : Charger immédiatement, puis écouter les mises à jour
4. **Logging** : Pour debugger les mises à jour

---

#### Étape 4.5 : Supprimer _refreshSelectedAccountSummary()

**Position** : Lignes 299-310

**SUPPRIMER COMPLÈTEMENT** :
```dart
  /// Rafraîchit le résumé du compte sélectionné
  Future<void> _refreshSelectedAccountSummary() async {
    if (state.selectedAccount == null) return;

    await executeWithErrorHandling(() async {
      final accountSummary = _accountRepository.getAccountSummary(
        state.selectedAccount!.id,
      );

      state = state.copyWith(selectedAccountSummary: accountSummary);
    });
  }
```

**Raison** : Cette méthode n'est plus nécessaire car le stream met à jour automatiquement.

---

#### Étape 4.6 : Mettre à jour dispose()

**Position** : Lignes 428-432

**AVANT** :
```dart
  @override
  void dispose() {
    _accountEventSubscription?.cancel();
    _transactionEventSubscription?.cancel();
    super.dispose();
  }
```

**APRÈS** :
```dart
  @override
  void dispose() {
    _accountEventSubscription?.cancel();
    _accountSummarySubscription?.cancel(); // ← AJOUTER
    // SUPPRIMER _transactionEventSubscription?.cancel();
    super.dispose();
  }
```

---

## ✅ Vérification et tests

### Étape 5.1 : Vérifier la compilation

```bash
flutter analyze
```

**Résultat attendu** : 0 errors (warnings de style acceptables)

---

### Étape 5.2 : Test manuel - Scénario d'ajout de transaction

**Procédure de test** :
1. Lancer l'app
2. Noter le solde actuel affiché sur la carte du compte
3. Créer une nouvelle transaction
4. Fermer la bottom sheet
5. **VÉRIFIER** : Le solde sur la carte se met à jour **immédiatement** sans rafraîchissement manuel

**Logs attendus** :
```
✅ AccountCacheService: Observateur initialisé (enrichedStore)
...
[Ajout de transaction]
🔄 TransactionCacheService: [log d'ajout de transaction]
🔄 AccountCacheService: Transactions enrichies changées, recalcul des summaries...
✅ AccountCacheService: Recalcul des summaries terminé
🔄 HomeScreenViewModel: AccountSummary mis à jour via stream
```

---

### Étape 5.3 : Test manuel - Scénario de suppression de transaction

**Procédure de test** :
1. Supprimer une transaction existante
2. **VÉRIFIER** : Le solde sur la carte se met à jour **immédiatement**

---

## 📊 Résumé des changements

### Fichiers modifiés

| Fichier | Lignes modifiées | Type de changement |
|---------|------------------|-------------------|
| `account_cache_service.dart` | ~47, ~60, ~66-72, ~271, ~350 | Ajout Pattern Observer |
| `cache_manager.dart` | ~155-159, ~301-313, ~316-333 | Passage enrichedStore + Suppression recalcul manuel |
| `home_screen_view_model.dart` | ~102, ~113-125, ~146-151, ~263-289, ~299-310, ~428-432 | Utilisation stream au lieu d'Event Bus |

### Lignes de code ajoutées/supprimées

- **account_cache_service.dart** : +70 lignes
- **cache_manager.dart** : +1 ligne (enrichedStore), -15 lignes (recalcul manuel)
- **home_screen_view_model.dart** : +15 lignes (stream), -25 lignes (Event Bus + refresh manuel)

**Total** : ~60 lignes ajoutées, ~40 lignes supprimées (net : +20 lignes)

---

## 🚨 Pièges à éviter

### Piège 1 : Oublier le `await` dans `_onEnrichedTransactionsChanged()`

**Mauvais** :
```dart
void _onEnrichedTransactionsChanged() {
  recomputeAllSummaries(enrichedByAccount); // ❌ Pas de await
  _notifyAccountsChanged();
}
```

**Bon** :
```dart
Future<void> _onEnrichedTransactionsChanged() async {
  await recomputeAllSummaries(enrichedByAccount); // ✅ await
  _notifyAccountsChanged();
}
```

**Raison** : Sans `await`, la notification se fait AVANT la fin du recalcul.

---

### Piège 2 : Oublier d'annuler _accountSummarySubscription dans selectAccount()

**Conséquence** : Fuite mémoire. Chaque fois qu'on change de compte, une nouvelle subscription est créée sans annuler l'ancienne.

**Solution** : Toujours `await _accountSummarySubscription?.cancel()` avant de créer une nouvelle subscription.

---

### Piège 3 : Oublier de passer enrichedStore au constructeur d'AccountCacheService

**Erreur de compilation** : `The parameter 'enrichedStore' is required.`

**Solution** : Ajouter `enrichedStore: _enrichedStore,` dans `CacheManager.initialize()` ligne ~158.

---

### Piège 4 : Supprimer _transactionEventSubscription mais oublier de le supprimer de dispose()

**Conséquence** : Erreur de compilation `Undefined name '_transactionEventSubscription'`

**Solution** : Supprimer `_transactionEventSubscription?.cancel();` de `dispose()`.

---

## 📚 Références et patterns utilisés

### Pattern Observer (Gang of Four)
- **Définition** : Un objet (Subject) notifie automatiquement ses dépendants (Observers) quand son état change.
- **Avantage** : Découplage entre Subject et Observers.
- **Implémentation Dart** : Utilisation des Streams.

### Sync-First Pattern (Phase 8)
- **Principe** : Charger immédiatement les données synchrones, puis écouter les mises à jour via stream.
- **Dans HomeScreenViewModel** : `getAccountSummary()` (sync) + `watchAccountSummary()` (stream)

### Reactive Programming
- **Principe** : Les données "fluent" à travers l'application via des streams.
- **Dans cette app** :
  - MemoryStore (Subject) → Stream → AccountCacheService (Observer) → HomeScreenViewModel (Consumer)

---

## ✅ Critères de succès

### Succès technique
- [ ] `flutter analyze` → 0 errors
- [ ] Aucune fuite mémoire (subscriptions annulées)
- [ ] Tous les tests existants passent

### Succès fonctionnel
- [ ] Le solde sur la carte HomeScreen se met à jour immédiatement après ajout de transaction
- [ ] Le solde sur la carte HomeScreen se met à jour immédiatement après suppression de transaction
- [ ] Aucun appel manuel à `_refreshSelectedAccountSummary()` n'est nécessaire

### Succès architectural
- [ ] CacheManager ne contient plus de recalcul manuel de summaries
- [ ] AccountCacheService est le seul responsable du recalcul de summaries
- [ ] HomeScreenViewModel ne dépend plus de TransactionEvent
- [ ] Code plus maintenable et scalable

---

## 🎓 Pédagogie : Pourquoi ce refactoring est professionnel

1. **Séparation of Concerns** : Chaque service gère ses propres dépendances
2. **Single Responsibility Principle** : AccountCacheService est responsable de l'invalidation de son cache
3. **Open/Closed Principle** : Ajouter une dépendance = 1 ligne, pas besoin de modifier CacheManager
4. **Dependency Inversion Principle** : CacheManager dépend d'abstractions (streams), pas d'implémentations
5. **Cohérence architecturale** : Même pattern que TransactionCacheService → Counterparties/Categories

**Résultat** : Code SOLID, maintenable, testable, scalable. 🚀

---

## 🔄 Comparaison avec le refactoring TransactionWithBalance

| Aspect | TransactionWithBalance | AccountSummary |
|--------|------------------------|----------------|
| **Entité dépendante** | TransactionWithBalance | AccountSummary |
| **Dépendances** | Counterparty, Category, Account | TransactionWithBalance |
| **Observer** | TransactionCacheService | AccountCacheService |
| **Observé** | counterpartiesStore, categoriesStore, accountsStore | enrichedStore |
| **Pattern** | Observer (GoF) | Observer (GoF) |
| **Méthode de recalcul** | `recomputeAllEnrichedData()` | `recomputeAllSummaries()` |
| **ViewModel affecté** | TransactionListViewModel | HomeScreenViewModel |
| **Event Bus supprimé** | CounterpartyLogoDownloadedEvent | TransactionEvent |

**Cohérence architecturale parfaite** : Les deux refactorings appliquent exactement le même pattern, ce qui rend le code prévisible et maintenable. 🎯