# Insight exploratoire
J'ai lu les conseils de votre ami mentionnés dans le fichier CONVERSATION.md. Maintenant, analysons-les en profondeur par rapport à votre architecture actuelle.

★ Insight ─────────────────────────────────────
Analyse critique des conseils reçus :
- ✅ Pertinents : Le principe de séparation par domaine est solide
- ⚠️ Inadaptés : Le pattern proposé ignore vos contraintes actuelles
- 🔧 À adapter : Votre architecture MVVM nécessite une approche différente
  ─────────────────────────────────────────────────

📋 ANALYSE CRITIQUE DES CONSEILS

✅ Points Pertinents

1. SRP (Single Responsibility Principle) : Oui, le CacheManager viole le SRP (873 lignes, 6 domaines)
2. Séparation par domaine : Excellente idée conceptuelle
3. Migration progressive : Approche sage pour éviter les régressions

⚠️ Problèmes Majeurs avec la Solution Proposée

1. Ignore les calculs interdépendants critiques ❌

Votre CacheManager fait des calculs O(n) complexes que la solution proposée ne gère pas :

// Votre code actuel (CRITIQUE) :
_calculateAllTransactionsWithBalance() {
// Pour chaque compte :
//   1. Trier transactions par date
//   2. Calculer solde cumulé transaction par transaction
//   3. Construire hiérarchie de catégories
//   4. Enrichir avec counterparty
// Temps : O(n log n) pour tri + O(n) pour calcul
}

La solution proposée ne gère pas ça → Perte de performance garantie

2. Pattern CacheStore<T> générique inadapté ❌

// Proposé par votre ami :
CacheStore<Map<int, AccountModel>> _accountStore;
// Problème : Trop bas niveau, perd la logique métier

Votre besoin réel :
- Pas juste stocker des Maps
- Mais calculer des données enrichies (TransactionWithBalance, AccountSummary)
- Avec des dépendances entre domaines (Transaction → Account → Category)

3. Ignore le pattern Sync-First (Phase 8) ❌

Vous avez un pattern Sync-First critiqué et validé :
- Lectures synchrones rapides
- Pas de Future<T> inutiles
- Fail-fast si cache non initialisé

La solution proposée réintroduit des Future<void> partout → Régression

4. Ne résout pas la vraie complexité ❌

La vraie complexité n'est PAS la taille du fichier, mais :
1. Calcul des soldes : O(n) avec tri par date
2. Hiérarchie de catégories : Remontée récursive jusqu'à level 1
3. Followed transactions : Recherche cross-accounts
4. Exchange rates bidirectionnel : EUR→GBP ET GBP→EUR

Ces logiques doivent rester centralisées pour éviter la duplication.

  ---
🏗️ PLAN D'ARCHITECTURE PROFESSIONNEL DÉTAILLÉ

Philosophie : Separation of Concerns + Composition Over Inheritance

Au lieu de diviser le CacheManager en N caches indépendants, je propose :

Architecture en Layers (3 couches)

┌─────────────────────────────────────────────────┐
│         CacheManager (Orchestrator)             │
│   - Initialisation                              │
│   - API publique unifiée                        │
│   - Coordination inter-domaines                 │
└─────────────────────────────────────────────────┘
↓ utilise
┌─────────────────────────────────────────────────┐
│       Domain Cache Services (6 services)        │
│   AccountCacheService                           │
│   TransactionCacheService                       │
│   CategoryCacheService                          │
│   CounterpartyCacheService                      │
│   ExchangeRateCacheService                      │
│   FollowedTransactionCacheService               │
└─────────────────────────────────────────────────┘
↓ utilise
┌─────────────────────────────────────────────────┐
│    Computation Engines (Logique de calcul)      │
│   BalanceComputationEngine                      │
│   CategoryHierarchyEngine                       │
│   EnrichedDataEngine                            │
└─────────────────────────────────────────────────┘

  ---
📂 STRUCTURE DE FICHIERS DÉTAILLÉE

lib/data/cache/
├── cache_manager.dart                    # Orchestrator (200 lignes max)
│
├── domain_services/                      # Services par domaine
│   ├── account_cache_service.dart        # ~150 lignes
│   ├── transaction_cache_service.dart    # ~180 lignes
│   ├── category_cache_service.dart       # ~100 lignes
│   ├── counterparty_cache_service.dart   # ~80 lignes
│   ├── exchange_rate_cache_service.dart  # ~120 lignes
│   └── followed_transaction_cache_service.dart  # ~100 lignes
│
├── computation_engines/                  # Logique de calcul pure
│   ├── balance_computation_engine.dart   # Calcul O(n) des soldes
│   ├── category_hierarchy_engine.dart    # Remontée hiérarchie
│   └── enriched_data_engine.dart         # Enrichissement données
│
├── stores/                               # Stockage bas niveau
│   ├── memory_store.dart                 # Map<K, V> générique
│   └── stream_store.dart                 # StreamController wrapper
│
└── exceptions/
└── cache_exceptions.dart             # Exceptions spécifiques

  ---
🔧 IMPLÉMENTATION DÉTAILLÉE

1. Memory Store (Bas niveau - Générique)

Fichier : lib/data/cache/stores/memory_store.dart

/// Store mémoire générique thread-safe
///
/// Responsabilité : Stockage clé-valeur en RAM avec notification
class MemoryStore<K, V> {
final Map<K, V> _storage = {};
final StreamController<Map<K, V>> _controller =
StreamController<Map<K, V>>.broadcast();

    /// Obtient une valeur par clé (synchrone)
    V? get(K key) => _storage[key];

    /// Obtient toutes les valeurs
    Map<K, V> getAll() => Map.unmodifiable(_storage);

    /// Définit une valeur
    void set(K key, V value) {
      _storage[key] = value;
      _notifyListeners();
    }

    /// Définit plusieurs valeurs en batch
    void setAll(Map<K, V> entries) {
      _storage.addAll(entries);
      _notifyListeners();
    }

    /// Supprime une valeur
    void remove(K key) {
      _storage.remove(key);
      _notifyListeners();
    }

    /// Vide le store
    void clear() {
      _storage.clear();
      _notifyListeners();
    }

    /// Vérifie si une clé existe
    bool containsKey(K key) => _storage.containsKey(key);

    /// Nombre d'entrées
    int get length => _storage.length;

    /// Stream des changements
    Stream<Map<K, V>> get stream => _controller.stream;

    void _notifyListeners() {
      _controller.add(getAll());
    }

    void dispose() {
      _controller.close();
    }
}

Tests unitaires :
// test/data/cache/stores/memory_store_test.dart
void main() {
group('MemoryStore', () {
late MemoryStore<int, String> store;

      setUp(() {
        store = MemoryStore<int, String>();
      });

      test('should store and retrieve value', () {
        store.set(1, 'test');
        expect(store.get(1), 'test');
      });

      test('should emit stream on change', () {
        expectLater(
          store.stream,
          emits({1: 'test'}),
        );
        store.set(1, 'test');
      });

      // ... 10+ autres tests
    });
}

  ---
2. Balance Computation Engine

Fichier : lib/data/cache/computation_engines/balance_computation_engine.dart

import 'package:bankapp/data/models/models.dart';
import 'package:bankapp/domain/entities/entities.dart';
import 'package:bankapp/domain/value_objects/value_objects.dart';

/// Engine de calcul des soldes (logique pure, testable)
///
/// Responsabilité : Calculer les soldes cumulés de transactions
/// en ordre chronologique pour un compte donné.
///
/// Complexité : O(n log n) pour le tri + O(n) pour le calcul
class BalanceComputationEngine {
/// Calcule les transactions avec solde pour un compte
///
/// Algorithme :
/// 1. Filtrer les transactions du compte
/// 2. Trier par date croissante
/// 3. Calculer le solde cumulé transaction par transaction
/// 4. Retourner List<TransactionWithBalance>
///
/// Paramètres :
/// - [transactions] : Toutes les transactions (peut contenir d'autres comptes)
/// - [account] : Compte pour lequel calculer les soldes
/// - [categories] : Map des catégories (pour enrichissement)
/// - [counterparties] : Map des contreparties (pour enrichissement)
///
/// Retourne : Liste de TransactionWithBalance triée par date
List<TransactionWithBalance> computeTransactionsWithBalance({
required Map<int, TransactionModel> transactions,
required AccountModel account,
required Map<int, CategoryModel> categories,
required Map<int, CounterpartyModel> counterparties,
}) {
// 1. Filtrer les transactions du compte
final accountTransactions = transactions.values
.where((t) => t.accountId == account.id)
.toList();

      // 2. Trier par date croissante (CRITIQUE pour calcul correct)
      accountTransactions.sort((a, b) => a.date.compareTo(b.date));

      // 3. Calculer les soldes cumulés
      final result = <TransactionWithBalance>[];
      double currentBalance = account.initialBalance;

      for (final transaction in accountTransactions) {
        // Calculer le montant signé
        final signedAmount = transaction.type == TransactionType.income.name
            ? transaction.amount
            : -transaction.amount;

        currentBalance += signedAmount;

        // Enrichir avec catégories
        final categoryHierarchy = _buildCategoryHierarchy(
          transaction.deepestCategoryId,
          categories,
        );

        // Enrichir avec contrepartie
        final counterparty = transaction.counterpartyId != null
            ? counterparties[transaction.counterpartyId!]?.toEntity()
            : null;

        // Créer TransactionWithBalance
        result.add(
          TransactionWithBalance(
            transaction: transaction.toEntity(),
            account: account.toEntity(),
            balanceAfter: AccountBalance(
              balance: Money(
                amount: currentBalance,
                currency: account.currency,
              ),
              calculatedAt: DateTime.now(),
            ),
            counterparty: counterparty,
            categories: categoryHierarchy,
          ),
        );
      }

      return result;
    }

    /// Construit la hiérarchie de catégories depuis la plus profonde
    List<Category> _buildCategoryHierarchy(
      int? deepestCategoryId,
      Map<int, CategoryModel> categories,
    ) {
      if (deepestCategoryId == null) return [];

      final hierarchy = <Category>[];
      int? currentId = deepestCategoryId;

      // Remonter la hiérarchie jusqu'à la racine
      while (currentId != null) {
        final categoryModel = categories[currentId];
        if (categoryModel == null) break;

        hierarchy.add(categoryModel.toEntity());

        // Remonter au parent
        currentId = categoryModel.parentId;

        // Sécurité : arrêter à level 1
        if (categoryModel.level <= 1) break;
      }

      return hierarchy;
    }

    /// Calcule le résumé d'un compte (solde, stats)
    ///
    /// Paramètres :
    /// - [account] : Compte à résumer
    /// - [transactionsWithBalance] : Transactions enrichies du compte
    ///
    /// Retourne : AccountSummary complet
    AccountSummary computeAccountSummary({
      required AccountModel account,
      required List<TransactionWithBalance> transactionsWithBalance,
    }) {
      if (transactionsWithBalance.isEmpty) {
        return AccountSummary(
          account: account.toEntity(),
          currentBalance: AccountBalance(
            balance: Money(
              amount: account.initialBalance,
              currency: account.currency,
            ),
            calculatedAt: DateTime.now(),
          ),
          confirmedBalance: AccountBalance(
            balance: Money(
              amount: account.initialBalance,
              currency: account.currency,
            ),
            calculatedAt: DateTime.now(),
          ),
          recentTransactions: [],
          totalTransactionsCount: 0,
          totalIncome: Money(amount: 0, currency: account.currency),
          totalExpenses: Money(amount: 0, currency: account.currency),
          lastTransactionDate: account.creationDate,
        );
      }

      // Calculer totaux income/expenses
      double totalIncome = 0;
      double totalExpenses = 0;

      for (final txWithBalance in transactionsWithBalance) {
        if (txWithBalance.isIncome) {
          totalIncome += txWithBalance.transaction.amount;
        } else {
          totalExpenses += txWithBalance.transaction.amount;
        }
      }

      // Solde actuel = dernier solde calculé
      final currentBalance = transactionsWithBalance.last.balanceAfter;

      // Solde confirmé = dernier solde de transaction confirmée
      final confirmedTransactions = transactionsWithBalance
          .where((t) => t.transaction.isCompleted)
          .toList();

      final confirmedBalance = confirmedTransactions.isNotEmpty
          ? confirmedTransactions.last.balanceAfter
          : AccountBalance(
              balance: Money(
                amount: account.initialBalance,
                currency: account.currency,
              ),
              calculatedAt: DateTime.now(),
            );

      // 10 transactions les plus récentes
      final recentTransactions = transactionsWithBalance.reversed
          .take(10)
          .toList();

      return AccountSummary(
        account: account.toEntity(),
        currentBalance: currentBalance,
        confirmedBalance: confirmedBalance,
        recentTransactions: recentTransactions,
        totalTransactionsCount: transactionsWithBalance.length,
        totalIncome: Money(amount: totalIncome, currency: account.currency),
        totalExpenses: Money(amount: totalExpenses, currency: account.currency),
        lastTransactionDate: transactionsWithBalance.last.transaction.date,
      );
    }
}

Tests unitaires :
// test/data/cache/computation_engines/balance_computation_engine_test.dart
void main() {
group('BalanceComputationEngine', () {
late BalanceComputationEngine engine;

      setUp(() {
        engine = BalanceComputationEngine();
      });

      test('should compute balances in chronological order', () {
        // Arrange
        final account = AccountModel(
          id: 1,
          name: 'Test Account',
          currency: 'EUR',
          initialBalance: 1000.0,
          creationDate: DateTime(2024, 1, 1),
        );

        final transactions = {
          1: TransactionModel(
            id: 1,
            accountId: 1,
            type: TransactionType.expense.name,
            amount: 100.0,
            currency: 'EUR',
            date: DateTime(2024, 1, 5),
          ),
          2: TransactionModel(
            id: 2,
            accountId: 1,
            type: TransactionType.income.name,
            amount: 500.0,
            currency: 'EUR',
            date: DateTime(2024, 1, 3),
          ),
        };

        // Act
        final result = engine.computeTransactionsWithBalance(
          transactions: transactions,
          account: account,
          categories: {},
          counterparties: {},
        );

        // Assert
        expect(result.length, 2);
        // Transaction 2 (1er janvier) doit être AVANT transaction 1 (5 janvier)
        expect(result[0].transaction.id, 2);
        expect(result[0].balanceAfter.balance.amount, 1500.0); // 1000 + 500

        expect(result[1].transaction.id, 1);
        expect(result[1].balanceAfter.balance.amount, 1400.0); // 1500 - 100
      });

      // ... 15+ autres tests
    });
}

  ---
3. Transaction Cache Service

Fichier : lib/data/cache/domain_services/transaction_cache_service.dart

import 'package:bankapp/data/cache/computation_engines/balance_computation_engine.dart';
import 'package:bankapp/data/cache/stores/memory_store.dart';
import 'package:bankapp/data/models/models.dart';
import 'package:bankapp/domain/entities/entities.dart';

/// Service de cache pour les transactions
///
/// Responsabilité :
/// - Stocker les transactions en RAM
/// - Calculer les transactions enrichies avec soldes
/// - Fournir des streams réactifs
///
/// Dépendances :
/// - MemoryStore pour le stockage
/// - BalanceComputationEngine pour les calculs
/// - Références aux autres stores (accounts, categories, counterparties)
class TransactionCacheService {
// Stores
final MemoryStore<int, TransactionModel> _transactionsStore;
final MemoryStore<int, List<TransactionWithBalance>> _enrichedStore;

    // Références aux autres domaines (pour enrichissement)
    final MemoryStore<int, AccountModel> _accountsStore;
    final MemoryStore<int, CategoryModel> _categoriesStore;
    final MemoryStore<int, CounterpartyModel> _counterpartiesStore;

    // Computation engine
    final BalanceComputationEngine _computationEngine;

    // Stream controllers
    final StreamController<List<Transaction>> _transactionsController =
        StreamController<List<Transaction>>.broadcast();

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

    // =========================================================================
    // LECTURES SYNCHRONES
    // =========================================================================

    /// Obtient toutes les transactions (synchrone)
    List<Transaction> getAllTransactions() {
      return _transactionsStore.getAll().values
          .map((m) => m.toEntity())
          .toList();
    }

    /// Obtient une transaction par ID
    Transaction? getTransactionById(int id) {
      return _transactionsStore.get(id)?.toEntity();
    }

    /// Obtient les transactions d'un compte
    List<Transaction> getTransactionsByAccountId(int accountId) {
      return _transactionsStore.getAll().values
          .where((t) => t.accountId == accountId)
          .map((t) => t.toEntity())
          .toList();
    }

    /// Obtient les transactions enrichies avec solde pour un compte
    List<TransactionWithBalance> getTransactionsWithBalance(int accountId) {
      return _enrichedStore.get(accountId) ?? [];
    }

    // =========================================================================
    // ÉCRITURES ASYNCHRONES (avec recalcul)
    // =========================================================================

    /// Ajoute une transaction (recalcule les soldes)
    Future<void> addTransaction(TransactionModel transaction) async {
      // 1. Ajouter au store
      _transactionsStore.set(transaction.id, transaction);

      // 2. Recalculer les transactions enrichies pour le compte affecté
      await _recomputeEnrichedData(transaction.accountId);

      // 3. Notifier les listeners
      _notifyTransactionsChanged();
    }

    /// Met à jour une transaction (recalcule les soldes)
    Future<void> updateTransaction(TransactionModel transaction) async {
      final oldTransaction = _transactionsStore.get(transaction.id);

      // 1. Mettre à jour le store
      _transactionsStore.set(transaction.id, transaction);

      // 2. Recalculer pour le compte actuel
      await _recomputeEnrichedData(transaction.accountId);

      // 3. Si changement de compte, recalculer l'ancien compte aussi
      if (oldTransaction != null &&
          oldTransaction.accountId != transaction.accountId) {
        await _recomputeEnrichedData(oldTransaction.accountId);
      }

      // 4. Notifier
      _notifyTransactionsChanged();
    }

    /// Supprime une transaction (recalcule les soldes)
    Future<void> removeTransaction(int transactionId) async {
      final transaction = _transactionsStore.get(transactionId);
      if (transaction == null) return;

      // 1. Supprimer du store
      _transactionsStore.remove(transactionId);

      // 2. Recalculer pour le compte affecté
      await _recomputeEnrichedData(transaction.accountId);

      // 3. Notifier
      _notifyTransactionsChanged();
    }

    // =========================================================================
    // CALCUL DES DONNÉES ENRICHIES
    // =========================================================================

    /// Recalcule les transactions enrichies pour UN compte
    Future<void> _recomputeEnrichedData(int accountId) async {
      final account = _accountsStore.get(accountId);
      if (account == null) {
        print('⚠️ Account $accountId not found, skipping enriched data computation');
        return;
      }

      // Utiliser l'engine de calcul
      final enrichedTransactions = _computationEngine.computeTransactionsWithBalance(
        transactions: _transactionsStore.getAll(),
        account: account,
        categories: _categoriesStore.getAll(),
        counterparties: _counterpartiesStore.getAll(),
      );

      // Stocker le résultat
      _enrichedStore.set(accountId, enrichedTransactions);
    }

    /// Recalcule TOUS les comptes (appelé à l'initialisation ou changement global)
    Future<void> recomputeAllEnrichedData() async {
      final accounts = _accountsStore.getAll();

      for (final account in accounts.values) {
        await _recomputeEnrichedData(account.id);
      }
    }

    // =========================================================================
    // STREAMS RÉACTIFS
    // =========================================================================

    /// Stream des transactions
    Stream<List<Transaction>> get transactionsStream =>
        _transactionsController.stream;

    void _notifyTransactionsChanged() {
      _transactionsController.add(getAllTransactions());
    }

    // =========================================================================
    // LIFECYCLE
    // =========================================================================

    void dispose() {
      _transactionsController.close();
    }
}

  ---
4. Cache Manager (Orchestrator)

Fichier : lib/data/cache/cache_manager.dart

import 'dart:async';

import 'package:bankapp/data/cache/computation_engines/balance_computation_engine.dart';
import 'package:bankapp/data/cache/domain_services/account_cache_service.dart';
import 'package:bankapp/data/cache/domain_services/transaction_cache_service.dart';
import 'package:bankapp/data/cache/domain_services/category_cache_service.dart';
import 'package:bankapp/data/cache/domain_services/counterparty_cache_service.dart';
import 'package:bankapp/data/cache/domain_services/exchange_rate_cache_service.dart';
import 'package:bankapp/data/cache/domain_services/followed_transaction_cache_service.dart';
import 'package:bankapp/data/cache/stores/memory_store.dart';
import 'package:bankapp/data/models/models.dart';
import 'package:bankapp/domain/entities/entities.dart';
import 'package:bankapp/domain/repositories/exchange_rate_repository.dart';
import 'package:bankapp/domain/value_objects/value_objects.dart';

/// CacheManager - Orchestrateur central du cache RAM
///
/// Responsabilité :
/// - Initialiser tous les domain services
/// - Fournir une API publique unifiée
/// - Coordonner les interactions inter-domaines
///
/// Pattern : Facade + Singleton
///
/// Taille cible : ~200 lignes (vs 873 actuellement)
class CacheManager {
static CacheManager? _instance;
static CacheManager get instance => _instance ??= CacheManager._();

    CacheManager._();

    // =========================================================================
    // STORES BAS NIVEAU (injection dans services)
    // =========================================================================

    late final MemoryStore<int, AccountModel> _accountsStore;
    late final MemoryStore<int, TransactionModel> _transactionsStore;
    late final MemoryStore<int, CategoryModel> _categoriesStore;
    late final MemoryStore<int, CounterpartyModel> _counterpartiesStore;
    late final MemoryStore<String, ExchangeRate> _exchangeRatesStore;
    late final MemoryStore<int, List<TransactionWithBalance>> _enrichedTransactionsStore;
    late final MemoryStore<int, AccountSummary> _accountSummariesStore;

    // =========================================================================
    // DOMAIN SERVICES (logique métier)
    // =========================================================================

    late final AccountCacheService _accountService;
    late final TransactionCacheService _transactionService;
    late final CategoryCacheService _categoryService;
    late final CounterpartyCacheService _counterpartyService;
    late final ExchangeRateCacheService _exchangeRateService;
    late final FollowedTransactionCacheService _followedTransactionService;

    // =========================================================================
    // COMPUTATION ENGINES (réutilisables, testables)
    // =========================================================================

    late final BalanceComputationEngine _balanceEngine;

    // =========================================================================
    // FLAGS D'INITIALISATION
    // =========================================================================

    bool _isInitialized = false;
    bool _isLoading = false;

    bool get isInitialized => _isInitialized;
    bool get isLoading => _isLoading;

    // =========================================================================
    // INITIALISATION
    // =========================================================================

    /// Initialise le cache avec toutes les données
    ///
    /// Cette méthode :
    /// 1. Crée tous les stores
    /// 2. Crée tous les services avec injection de dépendances
    /// 3. Charge les données initiales
    /// 4. Lance les calculs initiaux (soldes, summaries)
    ///
    /// Complexité : O(n log n) pour le tri + O(n) pour les calculs
    Future<void> initialize({
      required List<AccountModel> accounts,
      required List<TransactionModel> transactions,
      required List<CategoryModel> categories,
      required List<CounterpartyModel> counterparties,
      required List<int> followedTransactionIds,
      ExchangeRateRepository? exchangeRateRepository,
    }) async {
      if (_isInitialized || _isLoading) return;

      _isLoading = true;

      try {
        // =====================================================================
        // PHASE 1 : Créer les stores
        // =====================================================================

        _accountsStore = MemoryStore<int, AccountModel>();
        _transactionsStore = MemoryStore<int, TransactionModel>();
        _categoriesStore = MemoryStore<int, CategoryModel>();
        _counterpartiesStore = MemoryStore<int, CounterpartyModel>();
        _exchangeRatesStore = MemoryStore<String, ExchangeRate>();
        _enrichedTransactionsStore = MemoryStore<int, List<TransactionWithBalance>>();
        _accountSummariesStore = MemoryStore<int, AccountSummary>();

        // =====================================================================
        // PHASE 2 : Créer les computation engines
        // =====================================================================

        _balanceEngine = BalanceComputationEngine();

        // =====================================================================
        // PHASE 3 : Créer les domain services (injection de dépendances)
        // =====================================================================

        _accountService = AccountCacheService(
          accountsStore: _accountsStore,
          summariesStore: _accountSummariesStore,
          computationEngine: _balanceEngine,
        );

        _transactionService = TransactionCacheService(
          transactionsStore: _transactionsStore,
          enrichedStore: _enrichedTransactionsStore,
          accountsStore: _accountsStore,
          categoriesStore: _categoriesStore,
          counterpartiesStore: _counterpartiesStore,
          computationEngine: _balanceEngine,
        );

        _categoryService = CategoryCacheService(
          categoriesStore: _categoriesStore,
        );

        _counterpartyService = CounterpartyCacheService(
          counterpartiesStore: _counterpartiesStore,
        );

        _exchangeRateService = ExchangeRateCacheService(
          exchangeRatesStore: _exchangeRatesStore,
          exchangeRateRepository: exchangeRateRepository,
        );

        _followedTransactionService = FollowedTransactionCacheService(
          followedIdsStore: MemoryStore<int, bool>(), // Set simulé avec Map<int, bool>
          enrichedTransactionsStore: _enrichedTransactionsStore,
        );

        // =====================================================================
        // PHASE 4 : Charger les données initiales
        // =====================================================================

        await _loadInitialData(
          accounts: accounts,
          transactions: transactions,
          categories: categories,
          counterparties: counterparties,
          followedTransactionIds: followedTransactionIds,
        );

        // =====================================================================
        // PHASE 5 : Calculs initiaux
        // =====================================================================

        // Calculer transactions enrichies pour tous les comptes
        await _transactionService.recomputeAllEnrichedData();

        // Calculer summaries pour tous les comptes
        await _accountService.recomputeAllSummaries(
          _enrichedTransactionsStore.getAll(),
        );

        // Calculer followed transactions
        await _followedTransactionService.recomputeFollowedTransactions();

        // =====================================================================
        // PHASE 6 : Charger exchange rates (optionnel)
        // =====================================================================

        if (exchangeRateRepository != null) {
          await _exchangeRateService.loadFromRepository();
        }

        // =====================================================================
        // FINALISATION
        // =====================================================================

        _isInitialized = true;
        _isLoading = false;

        print('✅ CacheManager initialized successfully');
      } catch (e, stackTrace) {
        _isLoading = false;
        print('❌ CacheManager initialization failed: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    }

    /// Charge les données initiales dans les stores
    Future<void> _loadInitialData({
      required List<AccountModel> accounts,
      required List<TransactionModel> transactions,
      required List<CategoryModel> categories,
      required List<CounterpartyModel> counterparties,
      required List<int> followedTransactionIds,
    }) async {
      // Charger accounts
      for (final account in accounts) {
        _accountsStore.set(account.id, account);
      }

      // Charger transactions
      for (final transaction in transactions) {
        _transactionsStore.set(transaction.id, transaction);
      }

      // Charger categories
      for (final category in categories) {
        _categoriesStore.set(category.id, category);
      }

      // Charger counterparties
      for (final counterparty in counterparties) {
        _counterpartiesStore.set(counterparty.id, counterparty);
      }

      // Charger followed transaction IDs
      await _followedTransactionService.loadFollowedIds(followedTransactionIds);
    }

    // =========================================================================
    // API PUBLIQUE - DÉLÉGATION AUX SERVICES
    // =========================================================================

    // ----- ACCOUNTS -----

    List<Account> getAllAccounts() => _accountService.getAllAccounts();
    Account? getAccountById(int id) => _accountService.getAccountById(id);
    AccountSummary? getAccountSummary(int accountId) =>
        _accountService.getAccountSummary(accountId);
    Stream<List<Account>> get accountsStream => _accountService.accountsStream;

    Future<void> addAccount(AccountModel account) =>
        _accountService.addAccount(account);

    // ----- TRANSACTIONS -----

    List<Transaction> getAllTransactions() =>
        _transactionService.getAllTransactions();
    Transaction? getTransactionById(int id) =>
        _transactionService.getTransactionById(id);
    List<Transaction> getTransactionsByAccountId(int accountId) =>
        _transactionService.getTransactionsByAccountId(accountId);
    List<TransactionWithBalance> getTransactionsWithBalance(int accountId) =>
        _transactionService.getTransactionsWithBalance(accountId);
    Stream<List<Transaction>> get transactionsStream =>
        _transactionService.transactionsStream;

    Future<void> addTransaction(TransactionModel transaction) =>
        _transactionService.addTransaction(transaction);
    Future<void> updateTransaction(TransactionModel transaction) =>
        _transactionService.updateTransaction(transaction);
    Future<void> removeTransaction(int transactionId) =>
        _transactionService.removeTransaction(transactionId);

    // ----- CATEGORIES -----

    List<Category> getAllCategories() => _categoryService.getAllCategories();
    Stream<List<Category>> get categoriesStream => _categoryService.categoriesStream;

    Future<void> addCategory(CategoryModel category) =>
        _categoryService.addCategory(category);

    // ----- COUNTERPARTIES -----

    List<Counterparty> getAllCounterparties() =>
        _counterpartyService.getAllCounterparties();
    Counterparty? getCounterpartyById(int id) =>
        _counterpartyService.getCounterpartyById(id);
    List<Counterparty> searchCounterpartiesByName(String query, {int limit = 20}) =>
        _counterpartyService.searchByName(query, limit: limit);
    Stream<List<Counterparty>> get counterpartiesStream =>
        _counterpartyService.counterpartiesStream;

    Future<void> addCounterparty(CounterpartyModel counterparty) =>
        _counterpartyService.addCounterparty(counterparty);

    // ----- EXCHANGE RATES -----

    ExchangeRate? getExchangeRate(String fromCurrency, String toCurrency) =>
        _exchangeRateService.getExchangeRate(fromCurrency, toCurrency);
    Map<String, ExchangeRate> getAllExchangeRates() =>
        _exchangeRateService.getAllExchangeRates();
    Stream<Map<String, ExchangeRate>> get exchangeRatesStream =>
        _exchangeRateService.exchangeRatesStream;

    Future<void> addExchangeRates(List<ExchangeRateModel> rates) =>
        _exchangeRateService.addExchangeRates(rates);
    Future<void> reloadExchangeRatesFromDatabase() =>
        _exchangeRateService.loadFromRepository();

    // ----- FOLLOWED TRANSACTIONS -----

    List<TransactionWithBalance> getFollowedTransactionsWithBalance() =>
        _followedTransactionService.getFollowedTransactions();
    List<int> getFollowedTransactionIds() =>
        _followedTransactionService.getFollowedIds();
    bool isTransactionFollowed(int transactionId) =>
        _followedTransactionService.isFollowed(transactionId);
    Stream<List<TransactionWithBalance>> get followedTransactionsStream =>
        _followedTransactionService.followedTransactionsStream;

    Future<void> followTransaction(int transactionId) =>
        _followedTransactionService.followTransaction(transactionId);
    Future<void> unfollowTransaction(int transactionId) =>
        _followedTransactionService.unfollowTransaction(transactionId);

    // =========================================================================
    // OPÉRATIONS GLOBALES
    // =========================================================================

    /// Invalide et recalcule tout le cache
    Future<void> invalidateAll() async {
      if (!_isInitialized) return;

      await _transactionService.recomputeAllEnrichedData();
      await _accountService.recomputeAllSummaries(
        _enrichedTransactionsStore.getAll(),
      );
      await _followedTransactionService.recomputeFollowedTransactions();
    }

    /// Nettoie le cache
    void dispose() {
      _accountService.dispose();
      _transactionService.dispose();
      _categoryService.dispose();
      _counterpartyService.dispose();
      _exchangeRateService.dispose();
      _followedTransactionService.dispose();

      _accountsStore.dispose();
      _transactionsStore.dispose();
      _categoriesStore.dispose();
      _counterpartiesStore.dispose();
      _exchangeRatesStore.dispose();
      _enrichedTransactionsStore.dispose();
      _accountSummariesStore.dispose();

      _isInitialized = false;
      _isLoading = false;
    }
}

  ---
📋 PLAN DE MIGRATION PROGRESSIF (12 PHASES)

Phase 1 : Préparer l'infrastructure (Semaine 1)

Objectif : Créer les fondations sans toucher au code existant

Tâches :
1. ✅ Créer lib/data/cache/stores/memory_store.dart
2. ✅ Tests unitaires pour MemoryStore (100% coverage)
3. ✅ Créer lib/data/cache/computation_engines/balance_computation_engine.dart
4. ✅ Tests unitaires pour BalanceComputationEngine (100% coverage)
5. ✅ Vérifier que flutter test passe (aucune régression)

Validation :
flutter test test/data/cache/stores/
flutter test test/data/cache/computation_engines/

  ---
Phase 2 : Créer TransactionCacheService (Semaine 2)

Objectif : Premier domain service complet

Tâches :
1. ✅ Créer lib/data/cache/domain_services/transaction_cache_service.dart
2. ✅ Implémenter toutes les méthodes CRUD
3. ✅ Implémenter recomputeAllEnrichedData()
4. ✅ Tests unitaires (100% coverage)
5. ✅ Tests d'intégration avec BalanceComputationEngine

Validation :
flutter test test/data/cache/domain_services/transaction_cache_service_test.dart

  ---
Phase 3 : Créer AccountCacheService (Semaine 2)

Tâches :
1. ✅ Créer lib/data/cache/domain_services/account_cache_service.dart
2. ✅ Implémenter CRUD + calcul de summaries
3. ✅ Tests unitaires (100% coverage)

  ---
Phase 4 : Créer les 4 autres services (Semaine 3)

Tâches :
1. ✅ CategoryCacheService (simple, pas de calculs)
2. ✅ CounterpartyCacheService (simple + search)
3. ✅ ExchangeRateCacheService (logique bidirectionnelle)
4. ✅ FollowedTransactionCacheService
5. ✅ Tests unitaires pour chacun

  ---
Phase 5 : Créer le nouveau CacheManager (Semaine 4)

Tâches :
1. ✅ Créer lib/data/cache/cache_manager_v2.dart (nom temporaire)
2. ✅ Implémenter initialisation + délégation
3. ✅ Tests d'intégration complets
4. ✅ Benchmarks de performance (comparer avec v1)

Validation :
flutter test test/data/cache/cache_manager_v2_test.dart

  ---
Phase 6 : Migration Repository par Repository (Semaines 5-6)

Ordre de migration :
1. ✅ ExchangeRateRepositoryImpl (le plus simple)
2. ✅ CategoryRepositoryImpl
3. ✅ CounterpartyRepositoryImpl
4. ✅ AccountRepositoryImpl
5. ✅ TransactionRepositoryImpl (le plus complexe)

Pour chaque repository :
// Ajouter flag de feature toggle
class TransactionRepositoryImpl {
static const bool _useNewCache = false; // Feature flag

    @override
    List<Transaction> getAllTransactions() {
      if (_useNewCache) {
        return CacheManagerV2.instance.getAllTransactions();
      } else {
        return CacheManager.instance.getAllTransactions();
      }
    }
}

  ---
Phase 7 : Tests End-to-End (Semaine 7)

Tâches :
1. ✅ Activer le nouveau cache dans 1 repository
2. ✅ Tests manuels sur simulateur
3. ✅ Vérifier tous les écrans (Home, Transactions, Settings)
4. ✅ Vérifier performance (pas de régression)

  ---
Phase 8 : Migration Complète (Semaine 8)

Tâches :
1. ✅ Activer _useNewCache = true dans tous les repositories
2. ✅ Tests de régression complets
3. ✅ Tests de performance
4. ✅ Fix bugs éventuels

  ---
Phase 9 : Nettoyage (Semaine 9)

Tâches :
1. ✅ Renommer CacheManagerV2 → CacheManager
2. ✅ Supprimer l'ancien CacheManager
3. ✅ Supprimer les feature flags
4. ✅ Nettoyer les imports

  ---
Phase 10 : Documentation (Semaine 10)

Tâches :
1. ✅ Documenter chaque classe avec ///
2. ✅ Créer diagrammes d'architecture (draw.io)
3. ✅ Mettre à jour REFACTORING.md
4. ✅ Créer guide de contribution

  ---
Phase 11 : Optimisations (Semaine 11)

Tâches :
1. ✅ Profiler les performances
2. ✅ Optimiser les calculs si nécessaire
3. ✅ Ajouter cache de 2nd niveau si besoin
4. ✅ Benchmarks finaux

  ---
Phase 12 : Commit & PR (Semaine 12)

Tâches :
1. ✅ flutter analyze (0 warnings)
2. ✅ flutter test (100% passing)
3. ✅ Commit avec message détaillé
4. ✅ Push vers branche feature/cache-refactoring

  ---
📊 MÉTRIQUES DE SUCCÈS

Avant Refactoring

- CacheManager : 873 lignes
- Testabilité : Difficile (logique entrelacée)
- Maintenabilité : Faible (SRP violé)
- Performance : Bonne (mais difficile à optimiser)

Après Refactoring

- CacheManager : ~200 lignes (orchestrateur)
- 6 DomainCacheServices : ~100-180 lignes chacun
- 1 BalanceComputationEngine : ~150 lignes
- MemoryStore : ~80 lignes
- Total : ~1100 lignes (vs 873) MAIS:
    - ✅ Testabilité : Excellente (chaque classe testable isolément)
    - ✅ Maintenabilité : Excellente (SRP respecté)
    - ✅ Performance : Identique ou meilleure
    - ✅ Extensibilité : Facile d'ajouter de nouveaux domaines

  ---
★ Insight ─────────────────────────────────────
Différences clés avec la proposition de votre ami :
1. Computation Engines : Logique de calcul extraite et testable
2. Services spécialisés : Pas de CacheStore<T> générique inadapté
3. Pattern Sync-First conservé : Pas de régression de performance
4. Injection de dépendances : Services communiquent via stores partagés
5. Migration progressive : Feature flags pour rollback facile
   ─────────────────────────────────────────────────

# Plan détaillé - Refactoring CacheManager

## 📋 TABLE DES MATIÈRES

1. [Vue d'ensemble](#vue-densemble)
2. [Classes à créer](#classes-à-créer)
3. [Spécifications détaillées](#spécifications-détaillées)
4. [Plan de migration](#plan-de-migration)
5. [Tests requis](#tests-requis)
6. [Métriques de validation](#métriques-de-validation)

---

## 1. VUE D'ENSEMBLE

### Objectif

Refactoriser le `CacheManager` (873 lignes) en une architecture modulaire respectant les principes SOLID, tout en **préservant** les performances actuelles et le pattern Sync-First.

### Contraintes à respecter

1. ✅ **Pattern Sync-First** : Lectures synchrones, écritures asynchrones
2. ✅ **Calculs O(n)** : Préserver les algorithmes de calcul de soldes optimisés
3. ✅ **Streams réactifs** : Conserver les BroadcastStreamController
4. ✅ **Fail-fast** : Throw CacheNotInitializedException si cache non initialisé
5. ✅ **Event Bus** : Émettre les événements après chaque modification
6. ✅ **API publique inchangée** : CacheManager garde la même interface

### Architecture cible

```
CacheManager (Facade/Orchestrator - 200 lignes)
    ↓ délègue à
Domain Services (6 services - 80-180 lignes chacun)
    ↓ utilisent
Computation Engines (3 engines - logique pure)
    ↓ stockent dans
Memory Stores (stores génériques clé-valeur)
```

---

## 2. CLASSES À CRÉER

### 2.1 Stores (Couche Infrastructure)

#### `MemoryStore<K, V>`
- **Fichier** : `lib/data/cache/stores/memory_store.dart`
- **Responsabilité** : Stockage clé-valeur générique en RAM avec notifications
- **Lignes** : ~80
- **Pattern** : Observable Store

#### `StreamStore<T>` (optionnel)
- **Fichier** : `lib/data/cache/stores/stream_store.dart`
- **Responsabilité** : Wrapper de StreamController avec gestion auto
- **Lignes** : ~50

### 2.2 Computation Engines (Couche Business Logic)

#### `BalanceComputationEngine`
- **Fichier** : `lib/data/cache/computation_engines/balance_computation_engine.dart`
- **Responsabilité** : Calcul des soldes cumulés et AccountSummary
- **Lignes** : ~250
- **Méthodes clés** :
  - `computeTransactionsWithBalance()`
  - `computeAccountSummary()`
  - `_buildCategoryHierarchy()`

#### `CategoryHierarchyEngine`
- **Fichier** : `lib/data/cache/computation_engines/category_hierarchy_engine.dart`
- **Responsabilité** : Remontée hiérarchie de catégories (level 4 → 1)
- **Lignes** : ~80
- **Méthodes clés** :
  - `buildHierarchy(int deepestCategoryId)`
  - `getParentChain(int categoryId)`

#### `EnrichedDataEngine` (optionnel)
- **Fichier** : `lib/data/cache/computation_engines/enriched_data_engine.dart`
- **Responsabilité** : Enrichissement cross-domaines (Transaction + Category + Counterparty)
- **Lignes** : ~100

### 2.3 Domain Services (Couche Métier)

#### `AccountCacheService`
- **Fichier** : `lib/data/cache/domain_services/account_cache_service.dart`
- **Responsabilité** : Gestion cache des comptes + AccountSummary
- **Lignes** : ~150

#### `TransactionCacheService`
- **Fichier** : `lib/data/cache/domain_services/transaction_cache_service.dart`
- **Responsabilité** : Gestion cache des transactions + TransactionWithBalance
- **Lignes** : ~200

#### `CategoryCacheService`
- **Fichier** : `lib/data/cache/domain_services/category_cache_service.dart`
- **Responsabilité** : Gestion cache des catégories
- **Lignes** : ~100

#### `CounterpartyCacheService`
- **Fichier** : `lib/data/cache/domain_services/counterparty_cache_service.dart`
- **Responsabilité** : Gestion cache des contreparties + recherche
- **Lignes** : ~100

#### `ExchangeRateCacheService`
- **Fichier** : `lib/data/cache/domain_services/exchange_rate_cache_service.dart`
- **Responsabilité** : Gestion cache des taux de change + logique bidirectionnelle
- **Lignes** : ~150

#### `FollowedTransactionCacheService`
- **Fichier** : `lib/data/cache/domain_services/followed_transaction_cache_service.dart`
- **Responsabilité** : Gestion cache des transactions suivies
- **Lignes** : ~100

### 2.4 Orchestrator

#### `CacheManager` (refactorisé)
- **Fichier** : `lib/data/cache/cache_manager.dart`
- **Responsabilité** : Orchestration + API publique unifiée
- **Lignes** : ~200

---

## 3. SPÉCIFICATIONS DÉTAILLÉES

### 3.1 MemoryStore<K, V>

```dart
/// Store mémoire générique thread-safe
/// Pattern: Observable Store
class MemoryStore<K, V> {
  // ═══════════════════════════════════════════════════════════
  // ÉTAT INTERNE
  // ═══════════════════════════════════════════════════════════

  /// Stockage interne (Map privée)
  final Map<K, V> _storage = {};

  /// Stream controller pour notifier les changements
  final StreamController<Map<K, V>> _controller =
      StreamController<Map<K, V>>.broadcast();

  // ═══════════════════════════════════════════════════════════
  // LECTURES SYNCHRONES (O(1) ou O(n))
  // ═══════════════════════════════════════════════════════════

  /// Obtient une valeur par clé
  /// Complexité : O(1)
  /// Retourne null si la clé n'existe pas
  V? get(K key) => _storage[key];

  /// Obtient toutes les valeurs
  /// Complexité : O(n) pour la copie
  /// Retourne une Map immuable (protection)
  Map<K, V> getAll() => Map.unmodifiable(_storage);

  /// Obtient toutes les clés
  /// Complexité : O(n)
  Iterable<K> getKeys() => _storage.keys;

  /// Obtient toutes les valeurs (liste)
  /// Complexité : O(n)
  Iterable<V> getValues() => _storage.values;

  /// Vérifie si une clé existe
  /// Complexité : O(1)
  bool containsKey(K key) => _storage.containsKey(key);

  /// Nombre d'entrées
  /// Complexité : O(1)
  int get length => _storage.length;

  /// Vérifie si le store est vide
  bool get isEmpty => _storage.isEmpty;
  bool get isNotEmpty => _storage.isNotEmpty;

  // ═══════════════════════════════════════════════════════════
  // ÉCRITURES (modifient l'état et notifient)
  // ═══════════════════════════════════════════════════════════

  /// Définit une valeur
  /// Complexité : O(1) + notification O(1)
  void set(K key, V value) {
    _storage[key] = value;
    _notifyListeners();
  }

  /// Définit plusieurs valeurs en batch
  /// Complexité : O(m) où m = nombre d'entrées
  /// ⚠️ Une seule notification à la fin (optimisation)
  void setAll(Map<K, V> entries) {
    _storage.addAll(entries);
    _notifyListeners();
  }

  /// Supprime une valeur
  /// Complexité : O(1) + notification
  V? remove(K key) {
    final removed = _storage.remove(key);
    if (removed != null) {
      _notifyListeners();
    }
    return removed;
  }

  /// Vide complètement le store
  /// Complexité : O(1) + notification
  void clear() {
    if (_storage.isNotEmpty) {
      _storage.clear();
      _notifyListeners();
    }
  }

  /// Met à jour une valeur conditionnellement
  /// Complexité : O(1)
  /// Exemple : store.update(1, (old) => old.copyWith(name: 'New'))
  void update(K key, V Function(V) updater) {
    final existing = _storage[key];
    if (existing != null) {
      _storage[key] = updater(existing);
      _notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // STREAMS RÉACTIFS
  // ═══════════════════════════════════════════════════════════

  /// Stream des changements
  /// Type : BroadcastStream (multiple listeners possibles)
  /// Émet : Map<K, V> complète à chaque changement
  Stream<Map<K, V>> get stream => _controller.stream;

  /// Stream filtré par clé
  /// Émet : Valeur associée à la clé quand elle change
  Stream<V?> watchKey(K key) {
    return _controller.stream.map((map) => map[key]);
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS PRIVÉS
  // ═══════════════════════════════════════════════════════════

  void _notifyListeners() {
    if (!_controller.isClosed) {
      _controller.add(getAll());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════

  /// Ferme le stream et libère les ressources
  void dispose() {
    _controller.close();
    _storage.clear();
  }
}
```

**Tests requis** (fichier `test/data/cache/stores/memory_store_test.dart`) :
```dart
void main() {
  group('MemoryStore', () {
    late MemoryStore<int, String> store;

    setUp(() {
      store = MemoryStore<int, String>();
    });

    tearDown(() {
      store.dispose();
    });

    group('Lectures', () {
      test('get() retourne null si clé inexistante', () {
        expect(store.get(1), isNull);
      });

      test('get() retourne la valeur si clé existe', () {
        store.set(1, 'test');
        expect(store.get(1), 'test');
      });

      test('getAll() retourne Map immuable', () {
        store.set(1, 'a');
        final all = store.getAll();
        expect(() => all[2] = 'b', throwsUnsupportedError);
      });

      test('containsKey() vérifie existence', () {
        expect(store.containsKey(1), false);
        store.set(1, 'test');
        expect(store.containsKey(1), true);
      });

      test('length retourne nombre correct', () {
        expect(store.length, 0);
        store.set(1, 'a');
        expect(store.length, 1);
        store.set(2, 'b');
        expect(store.length, 2);
      });
    });

    group('Écritures', () {
      test('set() stocke la valeur', () {
        store.set(1, 'test');
        expect(store.get(1), 'test');
      });

      test('set() écrase valeur existante', () {
        store.set(1, 'old');
        store.set(1, 'new');
        expect(store.get(1), 'new');
      });

      test('setAll() ajoute plusieurs valeurs', () {
        store.setAll({1: 'a', 2: 'b', 3: 'c'});
        expect(store.length, 3);
        expect(store.get(2), 'b');
      });

      test('remove() supprime la valeur', () {
        store.set(1, 'test');
        final removed = store.remove(1);
        expect(removed, 'test');
        expect(store.get(1), isNull);
      });

      test('clear() vide le store', () {
        store.setAll({1: 'a', 2: 'b'});
        store.clear();
        expect(store.isEmpty, true);
      });

      test('update() modifie valeur existante', () {
        store.set(1, 'old');
        store.update(1, (old) => '$old-updated');
        expect(store.get(1), 'old-updated');
      });

      test('update() ne fait rien si clé inexistante', () {
        store.update(1, (old) => 'new');
        expect(store.get(1), isNull);
      });
    });

    group('Streams', () {
      test('stream émet lors de set()', () async {
        expectLater(
          store.stream,
          emitsInOrder([
            {1: 'test'},
          ]),
        );

        store.set(1, 'test');
      });

      test('stream émet une seule fois lors de setAll()', () async {
        final events = <Map<int, String>>[];
        final subscription = store.stream.listen(events.add);

        store.setAll({1: 'a', 2: 'b', 3: 'c'});

        await Future.delayed(Duration(milliseconds: 10));

        expect(events.length, 1);
        expect(events[0], {1: 'a', 2: 'b', 3: 'c'});

        await subscription.cancel();
      });

      test('stream émet lors de remove()', () async {
        store.set(1, 'test');

        expectLater(
          store.stream.skip(1), // Skip le set initial
          emitsInOrder([
            isEmpty, // après remove
          ]),
        );

        store.remove(1);
      });

      test('watchKey() émet quand clé change', () async {
        expectLater(
          store.watchKey(1),
          emitsInOrder([
            'first',
            'second',
          ]),
        );

        store.set(1, 'first');
        store.set(1, 'second');
      });

      test('watchKey() émet null quand clé supprimée', () async {
        store.set(1, 'test');

        expectLater(
          store.watchKey(1).skip(1),
          emitsInOrder([
            isNull,
          ]),
        );

        store.remove(1);
      });
    });

    group('Lifecycle', () {
      test('dispose() ferme le stream', () async {
        store.dispose();
        expect(store.stream, emitsDone);
      });

      test('dispose() vide le storage', () {
        store.set(1, 'test');
        store.dispose();
        expect(store.isEmpty, true);
      });
    });
  });
}
```

---

### 3.2 BalanceComputationEngine

```dart
import 'package:bankapp/data/models/models.dart';
import 'package:bankapp/domain/entities/entities.dart';
import 'package:bankapp/domain/value_objects/value_objects.dart';

/// Engine de calcul des soldes (logique pure, testable)
///
/// ⚠️ CRITIQUE : Cette classe contient la logique O(n log n) de calcul
/// des soldes cumulés. Elle est extraite du CacheManager pour être
/// testable isolément et réutilisable.
///
/// Pattern : Computation Engine (Pure Function Object)
class BalanceComputationEngine {
  // ═══════════════════════════════════════════════════════════
  // CALCUL TRANSACTIONS WITH BALANCE
  // ═══════════════════════════════════════════════════════════

  /// Calcule les transactions enrichies avec soldes pour un compte
  ///
  /// Algorithme :
  /// 1. Filtrer les transactions du compte (O(n))
  /// 2. Trier par date croissante (O(n log n)) ← CRITIQUE
  /// 3. Calculer solde cumulé transaction par transaction (O(n))
  /// 4. Enrichir avec catégories et contreparties (O(n))
  ///
  /// Complexité totale : O(n log n)
  ///
  /// Paramètres :
  /// - [transactions] : Map complète de TOUTES les transactions
  /// - [account] : Compte pour lequel calculer
  /// - [categories] : Map de toutes les catégories (pour hiérarchie)
  /// - [counterparties] : Map de toutes les contreparties (pour enrichissement)
  ///
  /// Retourne : List<TransactionWithBalance> triée par date croissante
  List<TransactionWithBalance> computeTransactionsWithBalance({
    required Map<int, TransactionModel> transactions,
    required AccountModel account,
    required Map<int, CategoryModel> categories,
    required Map<int, CounterpartyModel> counterparties,
  }) {
    // 1. FILTRAGE : Isoler les transactions du compte
    final accountTransactions = transactions.values
        .where((t) => t.accountId == account.id)
        .toList();

    if (accountTransactions.isEmpty) {
      return [];
    }

    // 2. TRI : Par date CROISSANTE (essentiel pour calcul correct)
    // ⚠️ Ne PAS modifier cet ordre sous peine de soldes incorrects
    accountTransactions.sort((a, b) => a.date.compareTo(b.date));

    // 3. CALCUL : Solde cumulé transaction par transaction
    final result = <TransactionWithBalance>[];
    double currentBalance = account.initialBalance;

    for (final transactionModel in accountTransactions) {
      // 3.1. Calculer montant signé (income = +, expense = -)
      final signedAmount = _calculateSignedAmount(transactionModel);

      // 3.2. Mettre à jour solde cumulé
      currentBalance += signedAmount;

      // 3.3. Construire hiérarchie de catégories
      final categoryHierarchy = _buildCategoryHierarchy(
        transactionModel.deepestCategoryId,
        categories,
      );

      // 3.4. Récupérer contrepartie
      final counterparty = transactionModel.counterpartyId != null
          ? counterparties[transactionModel.counterpartyId!]?.toEntity()
          : null;

      // 3.5. Créer TransactionWithBalance enrichie
      result.add(
        TransactionWithBalance(
          transaction: transactionModel.toEntity(),
          account: account.toEntity(),
          balanceAfter: AccountBalance(
            balance: Money(
              amount: currentBalance,
              currency: account.currency,
            ),
            calculatedAt: DateTime.now(),
          ),
          counterparty: counterparty,
          categories: categoryHierarchy,
        ),
      );
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════
  // CALCUL ACCOUNT SUMMARY
  // ═══════════════════════════════════════════════════════════

  /// Calcule le résumé complet d'un compte
  ///
  /// Calculs effectués :
  /// - Solde actuel (dernier solde calculé)
  /// - Solde confirmé (dernier solde de transaction completed)
  /// - Total income / expenses
  /// - 10 transactions les plus récentes
  /// - Date dernière transaction
  ///
  /// Complexité : O(n) où n = nombre de transactions du compte
  ///
  /// Paramètres :
  /// - [account] : Compte à résumer
  /// - [transactionsWithBalance] : Transactions enrichies (déjà calculées)
  ///
  /// Retourne : AccountSummary complet
  AccountSummary computeAccountSummary({
    required AccountModel account,
    required List<TransactionWithBalance> transactionsWithBalance,
  }) {
    // CAS 1 : Aucune transaction → Retourner summary avec solde initial
    if (transactionsWithBalance.isEmpty) {
      return _createEmptySummary(account);
    }

    // CAS 2 : Calculer totaux income/expenses
    double totalIncome = 0;
    double totalExpenses = 0;

    for (final txWithBalance in transactionsWithBalance) {
      if (txWithBalance.isIncome) {
        totalIncome += txWithBalance.transaction.amount;
      } else {
        totalExpenses += txWithBalance.transaction.amount;
      }
    }

    // 3. Solde actuel = dernier solde calculé
    final currentBalance = transactionsWithBalance.last.balanceAfter;

    // 4. Solde confirmé = dernier solde de transaction completed
    final confirmedTransactions = transactionsWithBalance
        .where((t) => t.transaction.status == TransactionStatus.completed)
        .toList();

    final confirmedBalance = confirmedTransactions.isNotEmpty
        ? confirmedTransactions.last.balanceAfter
        : _createInitialBalance(account);

    // 5. 10 transactions les plus récentes (reverse = plus récent en premier)
    final recentTransactions = transactionsWithBalance.reversed
        .take(10)
        .toList();

    // 6. Construire AccountSummary
    return AccountSummary(
      account: account.toEntity(),
      currentBalance: currentBalance,
      confirmedBalance: confirmedBalance,
      recentTransactions: recentTransactions,
      totalTransactionsCount: transactionsWithBalance.length,
      totalIncome: Money(amount: totalIncome, currency: account.currency),
      totalExpenses: Money(amount: totalExpenses, currency: account.currency),
      lastTransactionDate: transactionsWithBalance.last.transaction.date,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS PRIVÉS
  // ═══════════════════════════════════════════════════════════

  /// Calcule le montant signé d'une transaction
  /// Income = montant positif (+)
  /// Expense = montant négatif (-)
  double _calculateSignedAmount(TransactionModel transaction) {
    return transaction.type == TransactionType.income.name
        ? transaction.amount
        : -transaction.amount;
  }

  /// Construit la hiérarchie complète de catégories depuis la plus profonde
  ///
  /// Remonte la chaîne : Level 4 → Level 3 → Level 2 → Level 1
  ///
  /// Exemple :
  /// - deepestCategoryId = 42 (Level 4: "Restaurant gastronomique")
  /// - Résultat : [Cat42, Cat20, Cat5, Cat1]
  ///   où Cat1 = "Alimentation" (Level 1)
  ///
  /// Complexité : O(depth) où depth ≤ 4
  List<Category> _buildCategoryHierarchy(
    int? deepestCategoryId,
    Map<int, CategoryModel> categories,
  ) {
    if (deepestCategoryId == null) return [];

    final hierarchy = <Category>[];
    int? currentId = deepestCategoryId;

    // Remonter la hiérarchie jusqu'à la racine
    while (currentId != null) {
      final categoryModel = categories[currentId];

      // Si catégorie introuvable, arrêter
      if (categoryModel == null) {
        print('⚠️ Category $currentId not found in hierarchy');
        break;
      }

      // Ajouter à la hiérarchie
      hierarchy.add(categoryModel.toEntity());

      // Remonter au parent
      currentId = categoryModel.parentId;

      // Sécurité : arrêter à level 1 (pas de parent)
      if (categoryModel.level <= 1) break;

      // Sécurité : éviter boucle infinie (max 4 niveaux)
      if (hierarchy.length >= 4) {
        print('⚠️ Category hierarchy depth exceeded 4 levels');
        break;
      }
    }

    return hierarchy;
  }

  /// Crée un AccountSummary vide (compte sans transactions)
  AccountSummary _createEmptySummary(AccountModel account) {
    final initialBalance = _createInitialBalance(account);

    return AccountSummary(
      account: account.toEntity(),
      currentBalance: initialBalance,
      confirmedBalance: initialBalance,
      recentTransactions: [],
      totalTransactionsCount: 0,
      totalIncome: Money(amount: 0, currency: account.currency),
      totalExpenses: Money(amount: 0, currency: account.currency),
      lastTransactionDate: account.creationDate,
    );
  }

  /// Crée un AccountBalance avec le solde initial
  AccountBalance _createInitialBalance(AccountModel account) {
    return AccountBalance(
      balance: Money(
        amount: account.initialBalance,
        currency: account.currency,
      ),
      calculatedAt: DateTime.now(),
    );
  }
}
```

**Tests requis** (fichier `test/data/cache/computation_engines/balance_computation_engine_test.dart`) :
```dart
void main() {
  group('BalanceComputationEngine', () {
    late BalanceComputationEngine engine;

    setUp(() {
      engine = BalanceComputationEngine();
    });

    group('computeTransactionsWithBalance', () {
      test('retourne liste vide si aucune transaction pour le compte', () {
        final account = _createTestAccount(id: 1);
        final transactions = {
          1: _createTestTransaction(id: 1, accountId: 2), // Autre compte
        };

        final result = engine.computeTransactionsWithBalance(
          transactions: transactions,
          account: account,
          categories: {},
          counterparties: {},
        );

        expect(result, isEmpty);
      });

      test('calcule soldes en ordre chronologique', () {
        final account = _createTestAccount(
          id: 1,
          initialBalance: 1000.0,
        );

        final transactions = {
          1: _createTestTransaction(
            id: 1,
            accountId: 1,
            type: TransactionType.expense.name,
            amount: 100.0,
            date: DateTime(2024, 1, 5), // 5 janvier
          ),
          2: _createTestTransaction(
            id: 2,
            accountId: 1,
            type: TransactionType.income.name,
            amount: 500.0,
            date: DateTime(2024, 1, 3), // 3 janvier (AVANT)
          ),
        };

        final result = engine.computeTransactionsWithBalance(
          transactions: transactions,
          account: account,
          categories: {},
          counterparties: {},
        );

        expect(result.length, 2);

        // Transaction 2 doit être AVANT (3 janvier)
        expect(result[0].transaction.id, 2);
        expect(result[0].balanceAfter.balance.amount, 1500.0); // 1000 + 500

        // Transaction 1 ensuite (5 janvier)
        expect(result[1].transaction.id, 1);
        expect(result[1].balanceAfter.balance.amount, 1400.0); // 1500 - 100
      });

      test('enrichit avec hiérarchie de catégories', () {
        final account = _createTestAccount(id: 1);

        final categories = {
          1: _createTestCategory(id: 1, level: 1, name: 'Alimentation'),
          5: _createTestCategory(id: 5, level: 2, parentId: 1, name: 'Restaurant'),
          20: _createTestCategory(id: 20, level: 3, parentId: 5, name: 'Gastronomique'),
        };

        final transactions = {
          1: _createTestTransaction(
            id: 1,
            accountId: 1,
            deepestCategoryId: 20, // Level 3
          ),
        };

        final result = engine.computeTransactionsWithBalance(
          transactions: transactions,
          account: account,
          categories: categories,
          counterparties: {},
        );

        expect(result[0].categories.length, 3);
        expect(result[0].categories[0].id, 20); // Gastronomique
        expect(result[0].categories[1].id, 5);  // Restaurant
        expect(result[0].categories[2].id, 1);  // Alimentation
      });

      test('enrichit avec contrepartie', () {
        final account = _createTestAccount(id: 1);

        final counterparties = {
          42: _createTestCounterparty(id: 42, name: 'Carrefour'),
        };

        final transactions = {
          1: _createTestTransaction(
            id: 1,
            accountId: 1,
            counterpartyId: 42,
          ),
        };

        final result = engine.computeTransactionsWithBalance(
          transactions: transactions,
          account: account,
          categories: {},
          counterparties: counterparties,
        );

        expect(result[0].counterparty, isNotNull);
        expect(result[0].counterparty!.name, 'Carrefour');
      });

      test('gère catégorie manquante sans crash', () {
        final account = _createTestAccount(id: 1);

        final transactions = {
          1: _createTestTransaction(
            id: 1,
            accountId: 1,
            deepestCategoryId: 999, // ID inexistant
          ),
        };

        final result = engine.computeTransactionsWithBalance(
          transactions: transactions,
          account: account,
          categories: {},
          counterparties: {},
        );

        expect(result[0].categories, isEmpty);
      });
    });

    group('computeAccountSummary', () {
      test('retourne summary vide si aucune transaction', () {
        final account = _createTestAccount(
          id: 1,
          initialBalance: 1000.0,
        );

        final result = engine.computeAccountSummary(
          account: account,
          transactionsWithBalance: [],
        );

        expect(result.totalTransactionsCount, 0);
        expect(result.currentBalance.balance.amount, 1000.0);
        expect(result.confirmedBalance.balance.amount, 1000.0);
        expect(result.totalIncome.amount, 0);
        expect(result.totalExpenses.amount, 0);
        expect(result.recentTransactions, isEmpty);
      });

      test('calcule totaux income/expenses correctement', () {
        final account = _createTestAccount(id: 1, initialBalance: 0);

        final txWithBalance = [
          _createTestTxWithBalance(amount: 100, isIncome: true),
          _createTestTxWithBalance(amount: 50, isIncome: false),
          _createTestTxWithBalance(amount: 200, isIncome: true),
          _createTestTxWithBalance(amount: 30, isIncome: false),
        ];

        final result = engine.computeAccountSummary(
          account: account,
          transactionsWithBalance: txWithBalance,
        );

        expect(result.totalIncome.amount, 300.0); // 100 + 200
        expect(result.totalExpenses.amount, 80.0); // 50 + 30
      });

      test('limite à 10 transactions récentes', () {
        final account = _createTestAccount(id: 1);

        final txWithBalance = List.generate(
          20,
          (i) => _createTestTxWithBalance(id: i),
        );

        final result = engine.computeAccountSummary(
          account: account,
          transactionsWithBalance: txWithBalance,
        );

        expect(result.recentTransactions.length, 10);
        // Doit être en ordre inverse (plus récent en premier)
        expect(result.recentTransactions[0].transaction.id, 19);
        expect(result.recentTransactions[9].transaction.id, 10);
      });

      test('calcule solde confirmé correctement', () {
        final account = _createTestAccount(id: 1, initialBalance: 1000);

        final txWithBalance = [
          _createTestTxWithBalance(
            amount: 100,
            isIncome: true,
            status: TransactionStatus.completed,
            balanceAfter: 1100,
          ),
          _createTestTxWithBalance(
            amount: 50,
            isIncome: false,
            status: TransactionStatus.pending, // Non confirmée
            balanceAfter: 1050,
          ),
        ];

        final result = engine.computeAccountSummary(
          account: account,
          transactionsWithBalance: txWithBalance,
        );

        // Solde actuel = dernier solde (1050)
        expect(result.currentBalance.balance.amount, 1050);

        // Solde confirmé = dernier solde completed (1100)
        expect(result.confirmedBalance.balance.amount, 1100);
      });
    });
  });
}

// ═══════════════════════════════════════════════════════════
// HELPERS DE TEST
// ═══════════════════════════════════════════════════════════

AccountModel _createTestAccount({
  required int id,
  double initialBalance = 0,
}) {
  return AccountModel(
    id: id,
    name: 'Test Account $id',
    currency: 'EUR',
    initialBalance: initialBalance,
    creationDate: DateTime(2024, 1, 1),
  );
}

TransactionModel _createTestTransaction({
  required int id,
  required int accountId,
  String type = 'income',
  double amount = 100.0,
  int? counterpartyId,
  int? deepestCategoryId,
  DateTime? date,
}) {
  return TransactionModel(
    id: id,
    accountId: accountId,
    type: type,
    amount: amount,
    currency: 'EUR',
    date: date ?? DateTime(2024, 1, 1),
    counterpartyId: counterpartyId,
    deepestCategoryId: deepestCategoryId,
    status: TransactionStatus.completed.index,
  );
}

CategoryModel _createTestCategory({
  required int id,
  required int level,
  int? parentId,
  String? name,
}) {
  return CategoryModel(
    id: id,
    name: name ?? 'Category $id',
    level: level,
    parentId: parentId,
    iconCodePoint: 0xe000,
    iconFontFamily: 'MaterialIcons',
    color: 0xFF000000,
  );
}

CounterpartyModel _createTestCounterparty({
  required int id,
  required String name,
}) {
  return CounterpartyModel(
    id: id,
    name: name,
    iconCodePoint: 0xe000,
    iconFontFamily: 'MaterialIcons',
  );
}

TransactionWithBalance _createTestTxWithBalance({
  int id = 1,
  double amount = 100,
  bool isIncome = true,
  TransactionStatus status = TransactionStatus.completed,
  double balanceAfter = 0,
}) {
  // ... Créer objet complet TransactionWithBalance
}
```

---

### 3.3 TransactionCacheService

```dart
/// Service de cache pour les transactions
///
/// Responsabilités :
/// 1. Stocker transactions en RAM (via MemoryStore)
/// 2. Calculer transactions enrichies (via BalanceComputationEngine)
/// 3. Fournir streams réactifs
/// 4. Coordonner avec autres domaines (accounts, categories, counterparties)
///
/// Pattern : Domain Service + Reactive Streams
class TransactionCacheService {
  // ═══════════════════════════════════════════════════════════
  // DÉPENDANCES (Injection)
  // ═══════════════════════════════════════════════════════════

  /// Store des transactions brutes
  final MemoryStore<int, TransactionModel> _transactionsStore;

  /// Store des transactions enrichies (par compte)
  /// Clé = accountId, Valeur = List<TransactionWithBalance>
  final MemoryStore<int, List<TransactionWithBalance>> _enrichedStore;

  /// Références aux autres domaines (pour enrichissement cross-domain)
  final MemoryStore<int, AccountModel> _accountsStore;
  final MemoryStore<int, CategoryModel> _categoriesStore;
  final MemoryStore<int, CounterpartyModel> _counterpartiesStore;

  /// Engine de calcul (logique pure)
  final BalanceComputationEngine _computationEngine;

  /// Stream controller pour notifications globales
  final StreamController<List<Transaction>> _transactionsController =
      StreamController<List<Transaction>>.broadcast();

  // ═══════════════════════════════════════════════════════════
  // CONSTRUCTEUR (Dependency Injection)
  // ═══════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════
  // LECTURES SYNCHRONES (Pattern Sync-First)
  // ═══════════════════════════════════════════════════════════

  /// Obtient toutes les transactions (synchrone)
  /// Complexité : O(n)
  List<Transaction> getAllTransactions() {
    return _transactionsStore.getAll().values
        .map((model) => model.toEntity())
        .toList();
  }

  /// Obtient une transaction par ID
  /// Complexité : O(1)
  Transaction? getTransactionById(int id) {
    return _transactionsStore.get(id)?.toEntity();
  }

  /// Obtient les transactions d'un compte (filtrage)
  /// Complexité : O(n)
  List<Transaction> getTransactionsByAccountId(int accountId) {
    return _transactionsStore.getAll().values
        .where((t) => t.accountId == accountId)
        .map((t) => t.toEntity())
        .toList();
  }

  /// Obtient les transactions enrichies pour un compte
  /// Complexité : O(1) - Résultat pré-calculé dans _enrichedStore
  /// ⚠️ Retourne [] si le compte n'a pas été calculé
  List<TransactionWithBalance> getTransactionsWithBalance(int accountId) {
    return _enrichedStore.get(accountId) ?? [];
  }

  // ═══════════════════════════════════════════════════════════
  // ÉCRITURES ASYNCHRONES (avec recalcul automatique)
  // ═══════════════════════════════════════════════════════════

  /// Ajoute une transaction
  ///
  /// Séquence :
  /// 1. Stocker dans _transactionsStore
  /// 2. Recalculer enrichedData pour le compte affecté
  /// 3. Notifier listeners via stream
  ///
  /// Complexité : O(n log n) pour le recalcul
  Future<void> addTransaction(TransactionModel transaction) async {
    // 1. Stocker
    _transactionsStore.set(transaction.id, transaction);

    // 2. Recalculer
    await _recomputeEnrichedData(transaction.accountId);

    // 3. Notifier
    _notifyTransactionsChanged();
  }

  /// Met à jour une transaction
  ///
  /// ⚠️ ATTENTION : Si changement de compte, recalculer 2 comptes :
  /// - Ancien compte (retirer la transaction)
  /// - Nouveau compte (ajouter la transaction)
  Future<void> updateTransaction(TransactionModel transaction) async {
    final oldTransaction = _transactionsStore.get(transaction.id);

    // 1. Mettre à jour
    _transactionsStore.set(transaction.id, transaction);

    // 2. Recalculer compte actuel
    await _recomputeEnrichedData(transaction.accountId);

    // 3. Si changement de compte, recalculer ancien compte aussi
    if (oldTransaction != null &&
        oldTransaction.accountId != transaction.accountId) {
      await _recomputeEnrichedData(oldTransaction.accountId);
    }

    // 4. Notifier
    _notifyTransactionsChanged();
  }

  /// Supprime une transaction
  ///
  /// Séquence :
  /// 1. Récupérer transaction (pour connaître accountId)
  /// 2. Supprimer du store
  /// 3. Recalculer compte affecté
  /// 4. Notifier
  Future<void> removeTransaction(int transactionId) async {
    final transaction = _transactionsStore.get(transactionId);
    if (transaction == null) {
      print('⚠️ Transaction $transactionId not found, cannot remove');
      return;
    }

    // 1-2. Supprimer
    _transactionsStore.remove(transactionId);

    // 3. Recalculer
    await _recomputeEnrichedData(transaction.accountId);

    // 4. Notifier
    _notifyTransactionsChanged();
  }

  // ═══════════════════════════════════════════════════════════
  // CALCUL DES DONNÉES ENRICHIES
  // ═══════════════════════════════════════════════════════════

  /// Recalcule les transactions enrichies pour UN compte
  ///
  /// Utilise BalanceComputationEngine pour déléguer la logique
  ///
  /// Complexité : O(n log n) où n = transactions du compte
  ///
  /// ⚠️ Cette méthode est CRITIQUE pour les performances
  /// Elle ne doit être appelée QUE quand nécessaire
  Future<void> _recomputeEnrichedData(int accountId) async {
    // 1. Récupérer le compte
    final account = _accountsStore.get(accountId);
    if (account == null) {
      print('⚠️ Account $accountId not found, skipping enriched data computation');
      return;
    }

    // 2. Déléguer au computation engine
    final enrichedTransactions = _computationEngine.computeTransactionsWithBalance(
      transactions: _transactionsStore.getAll(),
      account: account,
      categories: _categoriesStore.getAll(),
      counterparties: _counterpartiesStore.getAll(),
    );

    // 3. Stocker le résultat
    _enrichedStore.set(accountId, enrichedTransactions);
  }

  /// Recalcule TOUS les comptes
  ///
  /// ⚠️ Opération lourde : O(n * m log m)
  /// où n = nombre de comptes, m = transactions par compte
  ///
  /// À appeler UNIQUEMENT :
  /// - À l'initialisation
  /// - Après changement global (ex: update de toutes les catégories)
  Future<void> recomputeAllEnrichedData() async {
    final accounts = _accountsStore.getAll();

    for (final account in accounts.values) {
      await _recomputeEnrichedData(account.id);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // STREAMS RÉACTIFS
  // ═══════════════════════════════════════════════════════════

  /// Stream global des transactions
  /// Émet : List<Transaction> à chaque modification
  Stream<List<Transaction>> get transactionsStream =>
      _transactionsController.stream;

  /// Stream des transactions enrichies pour un compte
  /// Émet : List<TransactionWithBalance> à chaque recalcul
  Stream<List<TransactionWithBalance>> watchTransactionsWithBalance(int accountId) {
    return _enrichedStore.watchKey(accountId).map((txList) => txList ?? []);
  }

  void _notifyTransactionsChanged() {
    if (!_transactionsController.isClosed) {
      _transactionsController.add(getAllTransactions());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════

  void dispose() {
    _transactionsController.close();
  }
}
```

---

### 3.4 CacheManager (Refactorisé)

```dart
/// CacheManager - Orchestrateur central (Facade Pattern)
///
/// Responsabilités :
/// 1. Initialiser tous les domain services
/// 2. Fournir API publique unifiée
/// 3. Coordonner interactions inter-domaines
///
/// ⚠️ IMPORTANT : Ce fichier ne contient PLUS de logique métier
/// Toute la logique est déléguée aux services spécialisés
///
/// Taille cible : ~200 lignes (vs 873 avant)
class CacheManager {
  static CacheManager? _instance;
  static CacheManager get instance => _instance ??= CacheManager._();

  CacheManager._();

  // ═══════════════════════════════════════════════════════════
  // STORES BAS NIVEAU
  // ═══════════════════════════════════════════════════════════

  late final MemoryStore<int, AccountModel> _accountsStore;
  late final MemoryStore<int, TransactionModel> _transactionsStore;
  late final MemoryStore<int, CategoryModel> _categoriesStore;
  late final MemoryStore<int, CounterpartyModel> _counterpartiesStore;
  late final MemoryStore<String, ExchangeRate> _exchangeRatesStore;
  late final MemoryStore<int, List<TransactionWithBalance>> _enrichedTransactionsStore;
  late final MemoryStore<int, AccountSummary> _accountSummariesStore;

  // ═══════════════════════════════════════════════════════════
  // DOMAIN SERVICES
  // ═══════════════════════════════════════════════════════════

  late final AccountCacheService _accountService;
  late final TransactionCacheService _transactionService;
  late final CategoryCacheService _categoryService;
  late final CounterpartyCacheService _counterpartyService;
  late final ExchangeRateCacheService _exchangeRateService;
  late final FollowedTransactionCacheService _followedTransactionService;

  // ═══════════════════════════════════════════════════════════
  // COMPUTATION ENGINES
  // ═══════════════════════════════════════════════════════════

  late final BalanceComputationEngine _balanceEngine;

  // ═══════════════════════════════════════════════════════════
  // FLAGS D'INITIALISATION
  // ═══════════════════════════════════════════════════════════

  bool _isInitialized = false;
  bool _isLoading = false;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;

  // ═══════════════════════════════════════════════════════════
  // INITIALISATION
  // ═══════════════════════════════════════════════════════════

  /// Initialise le cache complet
  ///
  /// Séquence stricte :
  /// 1. Créer stores
  /// 2. Créer engines
  /// 3. Créer services (injection dépendances)
  /// 4. Charger données initiales
  /// 5. Calculs initiaux (enrichedData, summaries)
  /// 6. Charger exchange rates (optionnel)
  ///
  /// Complexité totale : O(n log n)
  Future<void> initialize({
    required List<AccountModel> accounts,
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required List<CounterpartyModel> counterparties,
    required List<int> followedTransactionIds,
    ExchangeRateRepository? exchangeRateRepository,
  }) async {
    if (_isInitialized || _isLoading) return;

    _isLoading = true;

    try {
      // PHASE 1 : Stores
      _createStores();

      // PHASE 2 : Engines
      _createEngines();

      // PHASE 3 : Services (DI)
      _createServices(exchangeRateRepository);

      // PHASE 4 : Charger données
      await _loadInitialData(
        accounts: accounts,
        transactions: transactions,
        categories: categories,
        counterparties: counterparties,
        followedTransactionIds: followedTransactionIds,
      );

      // PHASE 5 : Calculs initiaux
      await _performInitialComputations();

      // PHASE 6 : Exchange rates (optionnel)
      if (exchangeRateRepository != null) {
        await _exchangeRateService.loadFromRepository();
      }

      _isInitialized = true;
      _isLoading = false;

      print('✅ CacheManager initialized successfully');
    } catch (e, stackTrace) {
      _isLoading = false;
      print('❌ CacheManager initialization failed: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  void _createStores() {
    _accountsStore = MemoryStore<int, AccountModel>();
    _transactionsStore = MemoryStore<int, TransactionModel>();
    _categoriesStore = MemoryStore<int, CategoryModel>();
    _counterpartiesStore = MemoryStore<int, CounterpartyModel>();
    _exchangeRatesStore = MemoryStore<String, ExchangeRate>();
    _enrichedTransactionsStore = MemoryStore<int, List<TransactionWithBalance>>();
    _accountSummariesStore = MemoryStore<int, AccountSummary>();
  }

  void _createEngines() {
    _balanceEngine = BalanceComputationEngine();
  }

  void _createServices(ExchangeRateRepository? exchangeRateRepository) {
    _accountService = AccountCacheService(
      accountsStore: _accountsStore,
      summariesStore: _accountSummariesStore,
      computationEngine: _balanceEngine,
    );

    _transactionService = TransactionCacheService(
      transactionsStore: _transactionsStore,
      enrichedStore: _enrichedTransactionsStore,
      accountsStore: _accountsStore,
      categoriesStore: _categoriesStore,
      counterpartiesStore: _counterpartiesStore,
      computationEngine: _balanceEngine,
    );

    _categoryService = CategoryCacheService(
      categoriesStore: _categoriesStore,
    );

    _counterpartyService = CounterpartyCacheService(
      counterpartiesStore: _counterpartiesStore,
    );

    _exchangeRateService = ExchangeRateCacheService(
      exchangeRatesStore: _exchangeRatesStore,
      exchangeRateRepository: exchangeRateRepository,
    );

    _followedTransactionService = FollowedTransactionCacheService(
      followedIdsStore: MemoryStore<int, bool>(),
      enrichedTransactionsStore: _enrichedTransactionsStore,
    );
  }

  Future<void> _loadInitialData({
    required List<AccountModel> accounts,
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required List<CounterpartyModel> counterparties,
    required List<int> followedTransactionIds,
  }) async {
    // Charger en batch pour optimiser
    _accountsStore.setAll({for (var a in accounts) a.id: a});
    _transactionsStore.setAll({for (var t in transactions) t.id: t});
    _categoriesStore.setAll({for (var c in categories) c.id: c});
    _counterpartiesStore.setAll({for (var c in counterparties) c.id: c});

    await _followedTransactionService.loadFollowedIds(followedTransactionIds);
  }

  Future<void> _performInitialComputations() async {
    // 1. Transactions enrichies (critique)
    await _transactionService.recomputeAllEnrichedData();

    // 2. Account summaries
    await _accountService.recomputeAllSummaries(
      _enrichedTransactionsStore.getAll(),
    );

    // 3. Followed transactions
    await _followedTransactionService.recomputeFollowedTransactions();
  }

  // ═══════════════════════════════════════════════════════════
  // API PUBLIQUE - DÉLÉGATION PURE
  // ═══════════════════════════════════════════════════════════

  // ACCOUNTS
  List<Account> getAllAccounts() => _accountService.getAllAccounts();
  Account? getAccountById(int id) => _accountService.getAccountById(id);
  AccountSummary? getAccountSummary(int accountId) =>
      _accountService.getAccountSummary(accountId);
  Stream<List<Account>> get accountsStream => _accountService.accountsStream;
  Future<void> addAccount(AccountModel account) =>
      _accountService.addAccount(account);

  // TRANSACTIONS
  List<Transaction> getAllTransactions() =>
      _transactionService.getAllTransactions();
  Transaction? getTransactionById(int id) =>
      _transactionService.getTransactionById(id);
  List<Transaction> getTransactionsByAccountId(int accountId) =>
      _transactionService.getTransactionsByAccountId(accountId);
  List<TransactionWithBalance> getTransactionsWithBalance(int accountId) =>
      _transactionService.getTransactionsWithBalance(accountId);
  Stream<List<Transaction>> get transactionsStream =>
      _transactionService.transactionsStream;
  Future<void> addTransaction(TransactionModel transaction) =>
      _transactionService.addTransaction(transaction);
  Future<void> updateTransaction(TransactionModel transaction) =>
      _transactionService.updateTransaction(transaction);
  Future<void> removeTransaction(int transactionId) =>
      _transactionService.removeTransaction(transactionId);

  // CATEGORIES
  List<Category> getAllCategories() => _categoryService.getAllCategories();
  Stream<List<Category>> get categoriesStream => _categoryService.categoriesStream;
  Future<void> addCategory(CategoryModel category) =>
      _categoryService.addCategory(category);

  // COUNTERPARTIES
  List<Counterparty> getAllCounterparties() =>
      _counterpartyService.getAllCounterparties();
  Counterparty? getCounterpartyById(int id) =>
      _counterpartyService.getCounterpartyById(id);
  List<Counterparty> searchCounterpartiesByName(String query, {int limit = 20}) =>
      _counterpartyService.searchByName(query, limit: limit);
  Stream<List<Counterparty>> get counterpartiesStream =>
      _counterpartyService.counterpartiesStream;
  Future<void> addCounterparty(CounterpartyModel counterparty) =>
      _counterpartyService.addCounterparty(counterparty);

  // EXCHANGE RATES
  ExchangeRate? getExchangeRate(String fromCurrency, String toCurrency) =>
      _exchangeRateService.getExchangeRate(fromCurrency, toCurrency);
  Map<String, ExchangeRate> getAllExchangeRates() =>
      _exchangeRateService.getAllExchangeRates();
  Stream<Map<String, ExchangeRate>> get exchangeRatesStream =>
      _exchangeRateService.exchangeRatesStream;
  Future<void> addExchangeRates(List<ExchangeRateModel> rates) =>
      _exchangeRateService.addExchangeRates(rates);
  Future<void> reloadExchangeRatesFromDatabase() =>
      _exchangeRateService.loadFromRepository();

  // FOLLOWED TRANSACTIONS
  List<TransactionWithBalance> getFollowedTransactionsWithBalance() =>
      _followedTransactionService.getFollowedTransactions();
  List<int> getFollowedTransactionIds() =>
      _followedTransactionService.getFollowedIds();
  bool isTransactionFollowed(int transactionId) =>
      _followedTransactionService.isFollowed(transactionId);
  Stream<List<TransactionWithBalance>> get followedTransactionsStream =>
      _followedTransactionService.followedTransactionsStream;
  Future<void> followTransaction(int transactionId) =>
      _followedTransactionService.followTransaction(transactionId);
  Future<void> unfollowTransaction(int transactionId) =>
      _followedTransactionService.unfollowTransaction(transactionId);

  // ═══════════════════════════════════════════════════════════
  // OPÉRATIONS GLOBALES
  // ═══════════════════════════════════════════════════════════

  /// Invalide et recalcule tout le cache
  /// ⚠️ Opération lourde : À utiliser uniquement si nécessaire
  Future<void> invalidateAll() async {
    if (!_isInitialized) return;

    await _transactionService.recomputeAllEnrichedData();
    await _accountService.recomputeAllSummaries(
      _enrichedTransactionsStore.getAll(),
    );
    await _followedTransactionService.recomputeFollowedTransactions();
  }

  /// Nettoie le cache et libère ressources
  void dispose() {
    _accountService.dispose();
    _transactionService.dispose();
    _categoryService.dispose();
    _counterpartyService.dispose();
    _exchangeRateService.dispose();
    _followedTransactionService.dispose();

    _accountsStore.dispose();
    _transactionsStore.dispose();
    _categoriesStore.dispose();
    _counterpartiesStore.dispose();
    _exchangeRatesStore.dispose();
    _enrichedTransactionsStore.dispose();
    _accountSummariesStore.dispose();

    _isInitialized = false;
    _isLoading = false;
  }
}
```

---

## 4. PLAN DE MIGRATION (12 PHASES)

### Phase 1 : Infrastructure (Semaine 1) ✅ **COMPLÉTÉE**

**Objectif** : Créer fondations sans toucher code existant

**Fichiers créés** :
1. ✅ `lib/data/cache/stores/memory_store.dart` **COMPLÉTÉ** (177 lignes)
2. ✅ `test/data/cache/stores/memory_store_test.dart` **COMPLÉTÉ** (543 lignes, 45 tests passent)
3. ✅ `lib/data/cache/computation_engines/balance_computation_engine.dart` **COMPLÉTÉ** (319 lignes, 0 erreurs analyze)
4. ✅ `test/data/cache/computation_engines/balance_computation_engine_test.dart` **COMPLÉTÉ** (774 lignes, 19 tests passent)

**Validation** : ✅ **RÉUSSIE**
```bash
flutter test test/data/cache/stores/memory_store_test.dart  # 45 tests passent
flutter test test/data/cache/computation_engines/balance_computation_engine_test.dart  # 19 tests passent
flutter analyze  # 0 warnings sur nouveaux fichiers
```

**Critères de succès** :
- ✅ 100% tests passing (64/64)
- ✅ 0 warnings `flutter analyze` sur nouveaux fichiers
- ✅ Code coverage estimé ≥ 95%

---

### Phase 2 : TransactionCacheService (Semaine 2) ✅ **COMPLÉTÉE**

**Objectif** : Premier domain service complet

**Fichiers créés** :
1. ✅ `lib/data/cache/domain_services/transaction_cache_service.dart` **COMPLÉTÉ** (389 lignes)
2. ✅ `test/data/cache/domain_services/transaction_cache_service_test.dart` **COMPLÉTÉ** (721 lignes, 21 tests passent)

**Validation** : ✅ **RÉUSSIE**
```bash
flutter test test/data/cache/domain_services/transaction_cache_service_test.dart  # 21 tests passent
flutter test test/data/cache/  # 85 tests passent (Phase 1 + Phase 2)
flutter analyze lib/data/cache/  # 0 erreurs sur nouveaux fichiers
```

---

### Phase 3 : AccountCacheService (Semaine 2-3) ✅ **COMPLÉTÉE**

**Fichiers créés** :
1. ✅ `lib/data/cache/domain_services/account_cache_service.dart` **COMPLÉTÉ**
2. ✅ `test/data/cache/domain_services/account_cache_service_test.dart` **COMPLÉTÉ** (23 tests passent)

**Validation** : ✅ **RÉUSSIE**
```bash
flutter test test/data/cache/domain_services/account_cache_service_test.dart
# ✅ 23 tests passent (100% success rate!)
```

---

### Phase 4 : Autres Services (Semaine 3) ✅ **COMPLÉTÉE**

**Fichiers créés** :
1. ✅ `lib/data/cache/domain_services/category_cache_service.dart` **COMPLÉTÉ** (204 lignes)
2. ✅ `lib/data/cache/domain_services/counterparty_cache_service.dart` **COMPLÉTÉ** (197 lignes)
3. ✅ `lib/data/cache/domain_services/exchange_rate_cache_service.dart` **COMPLÉTÉ** (281 lignes)
4. ✅ `lib/data/cache/domain_services/followed_transaction_cache_service.dart` **COMPLÉTÉ** (280 lignes)
5. ✅ `lib/data/models/followed_transaction_model.dart` **COMPLÉTÉ** (102 lignes)
6. ✅ `test/data/cache/domain_services/category_cache_service_test.dart` **COMPLÉTÉ** (447 lignes, 30 tests passent)
7. ✅ `test/data/cache/domain_services/counterparty_cache_service_test.dart` **COMPLÉTÉ** (448 lignes, 30 tests passent)
8. ✅ `test/data/cache/domain_services/exchange_rate_cache_service_test.dart` **COMPLÉTÉ** (528 lignes, 35 tests passent)
9. ✅ `test/data/cache/domain_services/followed_transaction_cache_service_test.dart` **COMPLÉTÉ** (498 lignes, 38 tests passent)

**Validation** : ✅ **RÉUSSIE**
```bash
flutter test test/data/cache/domain_services/
# ✅ 241 tests passent (100% success rate !)
# ✅ Phase 1 (64 tests) + Phase 2 (21 tests) + Phase 3 (23 tests) + Phase 4 (133 tests)

flutter analyze lib/data/cache/domain_services/
# ✅ No issues found!
```

**Services créés** :
- **CategoryCacheService** : Gestion hiérarchique des catégories (level, parentId)
  - `getCategoriesByLevel()`, `getRootCategories()`, `getSubCategories()`
- **CounterpartyCacheService** : Gestion des contreparties
  - `searchCounterpartiesByName()` avec recherche case-insensitive
- **ExchangeRateCacheService** : Gestion des taux de change
  - Clé composite String (paire "USD_EUR")
  - `getExchangeRatesFrom()`, `getExchangeRatesTo()`
  - `getValidExchangeRates()`, `removeExpiredExchangeRates()`
- **FollowedTransactionCacheService** : Gestion des transactions suivies
  - Helpers `followTransaction()`, `unfollowTransaction()`
  - Auto-génération d'IDs séquentiels
  - `isTransactionFollowed()`, `getFollowedTransactionIds()`

---

### Phase 5 : CacheManager V2 (Semaine 4) ✅ **COMPLÉTÉE**

**Fichiers créés** :
1. ✅ `lib/data/cache/cache_manager_v2.dart` **COMPLÉTÉ** (551 lignes)
2. ✅ `test/data/cache/cache_manager_v2_test.dart` **COMPLÉTÉ** (520 lignes, 27 tests passent)

**Validation** : ✅ **RÉUSSIE**
```bash
flutter analyze lib/data/cache/cache_manager_v2.dart
# ✅ No issues found! (ran in 2.7s)

flutter test test/data/cache/cache_manager_v2_test.dart
# ✅ 27 tests passent (100% success rate!)
```

**Architecture CacheManagerV2** :
- **Pattern Singleton** avec Dependency Injection
- **Orchestrateur central** coordonnant les 6 domain services
- **Pattern Fail-Fast** : `StateError` si non initialisé
- **API publique** identique à l'ancien CacheManager pour faciliter la migration

**Structure** :
```dart
class CacheManagerV2 {
  // Singleton
  static final CacheManagerV2 instance = CacheManagerV2._();

  // 8 MemoryStores (Accounts, Summaries, Transactions, Categories, etc.)
  late MemoryStore<int, AccountModel> _accountsStore;
  // ...

  // Computation Engine
  late BalanceComputationEngine _computationEngine;

  // 6 Domain Services (DI)
  late AccountCacheService _accountService;
  late TransactionCacheService _transactionService;
  late CategoryCacheService _categoryService;
  late CounterpartyCacheService _counterpartyService;
  late ExchangeRateCacheService _exchangeRateService;
  late FollowedTransactionCacheService _followedTransactionService;

  // Initialisation
  Future<void> initialize({...}) async { ... }

  // API publique (délègue aux services)
  List<Account> getAllAccounts() => _accountService.getAllAccounts();
  Future<void> addTransaction(TransactionModel t) async {
    await _transactionService.addTransaction(t);
    // Orchestration: recalculer le summary du compte
    await _accountService.recomputeSummaryForAccount(...);
  }
}
```

**Corrections apportées pendant le développement** :
- ❌ `getTransactionsWithBalanceByAccountId()` → ✅ `getTransactionsWithBalance()` (5 occurrences)
- ❌ Import `enums.dart` inexistant → ✅ Enums dans `transaction.dart`
- ❌ `TransactionStatus.confirmed` → ✅ `TransactionStatus.completed`
- ❌ `late final` (impossible de réinitialiser) → ✅ `late` (permet réinitialisation)
- ❌ `AccountModel.createdAt` → ✅ `AccountModel.creationDate`
- ❌ `TransactionModel.description` → ✅ `TransactionModel.title`
- ❌ `TransactionModel.categoryId` → ✅ `TransactionModel.deepestCategoryId`
- ❌ `balance` → ✅ `balanceAfter.balance.amount`

**Bugs corrigés pendant les tests** :
- ✅ `setUp()` du groupe "API Transactions Suivies" manquait le type de retour `() =>`
- ✅ Helper `createTransactionModel()` : les montants doivent être **toujours positifs** (le type détermine le signe)
  - Exemple : pour une dépense de 50€, utiliser `amount: 50.0, type: TransactionType.expense` (pas `amount: -50.0`)
  - Cette convention est respectée dans toute l'application : le `BalanceComputationEngine` applique le signe selon le type

---

### Phase 6-8 : Migration Repositories (Semaines 5-7)

**Pattern Feature Flag** :
```dart
class TransactionRepositoryImpl {
  static const bool _useNewCache = false; // Phase 6: false, Phase 8: true

  @override
  List<Transaction> getAllTransactions() {
    if (_useNewCache) {
      return CacheManagerV2.instance.getAllTransactions();
    } else {
      return CacheManager.instance.getAllTransactions();
    }
  }
}
```

**Ordre de migration** :
1. ExchangeRateRepositoryImpl
2. CategoryRepositoryImpl
3. CounterpartyRepositoryImpl
4. AccountRepositoryImpl
5. TransactionRepositoryImpl

---

### Phase 9 : Nettoyage (Semaine 8)

**Tâches** :
1. Renommer `CacheManagerV2` → `CacheManager`
2. Supprimer ancien `CacheManager`
3. Supprimer feature flags
4. Nettoyer imports

---

### Phase 10-12 : Documentation & Optimisation (Semaines 9-10)

**Tâches** :
1. Documenter chaque classe (`///`)
2. Créer diagrammes d'architecture
3. Profiler performances
4. Optimisations finales

---

## 5. TESTS REQUIS

### 5.1 Tests Unitaires (≥ 95% coverage)

**MemoryStore** :
- Lectures : `get()`, `getAll()`, `containsKey()`, `length`
- Écritures : `set()`, `setAll()`, `remove()`, `clear()`, `update()`
- Streams : `stream`, `watchKey()`
- Lifecycle : `dispose()`

**BalanceComputationEngine** :
- Calcul soldes chronologiques
- Enrichissement catégories (hiérarchie)
- Enrichissement contreparties
- Gestion erreurs (catégorie manquante, etc.)
- AccountSummary (totaux, solde confirmé, etc.)

**TransactionCacheService** :
- CRUD complet
- Recalcul automatique après modifications
- Gestion changement de compte
- Streams réactifs

**CacheManager** :
- Initialisation complète
- Délégation correcte aux services
- Gestion erreurs init

### 5.2 Tests d'Intégration

**Scenario 1 : Création transaction**
```dart
test('création transaction recalcule soldes automatiquement', () async {
  // Given
  await cacheManager.initialize(...);

  // When
  await cacheManager.addTransaction(newTransaction);

  // Then
  final txWithBalance = cacheManager.getTransactionsWithBalance(accountId);
  expect(txWithBalance.last.balanceAfter.balance.amount, expectedBalance);
});
```

**Scenario 2 : Changement de compte**
```dart
test('changement de compte recalcule 2 comptes', () async {
  // Given
  final tx = existingTransaction.copyWith(accountId: newAccountId);

  // When
  await cacheManager.updateTransaction(tx);

  // Then
  final oldAccountBalance = cacheManager.getTransactionsWithBalance(oldAccountId);
  final newAccountBalance = cacheManager.getTransactionsWithBalance(newAccountId);
  // Vérifier les deux soldes
});
```

### 5.3 Tests de Performance (Benchmarks)

**Fichier** : `benchmark/cache_performance_benchmark.dart`

```dart
void main() async {
  // Charger 10,000 transactions
  final transactions = generateTestTransactions(10000);

  // Benchmark V1 (ancien)
  final v1Time = await benchmarkCacheManagerV1(transactions);

  // Benchmark V2 (nouveau)
  final v2Time = await benchmarkCacheManagerV2(transactions);

  print('V1 init time: ${v1Time}ms');
  print('V2 init time: ${v2Time}ms');

  assert(v2Time <= v1Time * 1.1, 'Régression de performance détectée!');
}
```

---

## 6. MÉTRIQUES DE VALIDATION

### Avant Refactoring
- **CacheManager** : 873 lignes
- **Testabilité** : Difficile (logique entrelacée)
- **Maintenabilité** : Faible (SRP violé)
- **Complexité cyclomatique** : ~40 (élevée)

### Après Refactoring (Objectifs)
- **CacheManager** : ≤ 200 lignes
- **6 Domain Services** : 80-200 lignes chacun
- **3 Computation Engines** : 80-250 lignes chacun
- **1 MemoryStore** : ~80 lignes
- **Testabilité** : Excellente (chaque classe isolée)
- **Maintenabilité** : Excellente (SRP respecté)
- **Complexité cyclomatique** : ≤ 10 par classe
- **Code coverage** : ≥ 95%
- **Performance** : ≤ 110% du temps initial (tolérance 10%)

### Checklist de Validation Finale

- [ ] `flutter analyze` : 0 warnings
- [ ] `flutter test` : 100% passing
- [ ] Code coverage : ≥ 95%
- [ ] Benchmarks : Pas de régression > 10%
- [ ] Documentation : 100% classes documentées
- [ ] Diagrammes : Architecture à jour
- [ ] Migration : Tous repositories migrés
- [ ] Feature flags : Supprimés
- [ ] Ancien code : Supprimé

---

## 7. NOTES D'IMPLÉMENTATION

### 7.1 Gestion des Erreurs

**Pattern à suivre** :
```dart
// Dans TransactionCacheService
Future<void> addTransaction(TransactionModel transaction) async {
  try {
    _transactionsStore.set(transaction.id, transaction);
    await _recomputeEnrichedData(transaction.accountId);
    _notifyTransactionsChanged();
  } catch (e, stackTrace) {
    // Log mais ne crash pas
    print('⚠️ Failed to add transaction: $e');
    print('Stack: $stackTrace');

    // Rollback
    _transactionsStore.remove(transaction.id);

    // Re-throw pour que le repository puisse gérer
    rethrow;
  }
}
```

### 7.2 Optimisations Potentielles

**Batch Updates** :
```dart
// Futur : Ajouter méthode batch dans TransactionCacheService
Future<void> addTransactionsBatch(List<TransactionModel> transactions) async {
  // 1. Ajouter toutes les transactions
  _transactionsStore.setAll({for (var t in transactions) t.id: t});

  // 2. Identifier comptes affectés
  final affectedAccounts = transactions.map((t) => t.accountId).toSet();

  // 3. Recalculer uniquement les comptes affectés
  for (final accountId in affectedAccounts) {
    await _recomputeEnrichedData(accountId);
  }

  // 4. Une seule notification
  _notifyTransactionsChanged();
}
```

### 7.3 Logging & Debugging

**Pattern de debug** :
```dart
class TransactionCacheService {
  static const bool _debugMode = kDebugMode;

  void _debugLog(String message) {
    if (_debugMode) {
      print('[TransactionCacheService] $message');
    }
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    _debugLog('Adding transaction ${transaction.id}');
    // ...
  }
}
```

---

## 8. DIAGRAMMES D'ARCHITECTURE

### 8.1 Diagramme de Flux (Ajout Transaction)

```
User Action (Add Transaction)
    ↓
Repository.createTransaction()
    ↓
TransactionCacheService.addTransaction()
    ↓
├─→ MemoryStore.set() [Store transaction]
├─→ BalanceComputationEngine.computeTransactionsWithBalance()
│     ├─→ Filtrer transactions du compte
│     ├─→ Trier par date (O(n log n))
│     ├─→ Calculer soldes cumulés (O(n))
│     └─→ Enrichir avec catégories + counterparty
├─→ MemoryStore.set() [Store enriched data]
└─→ StreamController.add() [Notify listeners]
    ↓
ViewModel écoute stream → Update UI
```

### 8.2 Diagramme de Classes (Simplifié)

```
┌─────────────────────────┐
│     CacheManager        │
│   (Orchestrator)        │
└───────────┬─────────────┘
            │ utilise
    ┌───────┴───────────────────────────┐
    ↓                                   ↓
┌──────────────────────┐   ┌──────────────────────────┐
│ TransactionCache     │   │ BalanceComputation       │
│ Service              │──→│ Engine                   │
│                      │   │                          │
│ - addTransaction()   │   │ - computeTxWithBalance() │
│ - updateTransaction()│   │ - computeAccountSummary()│
└──────────┬───────────┘   └──────────────────────────┘
           │ utilise
           ↓
┌────────────────────────┐
│ MemoryStore<K,V>       │
│                        │
│ - get(key)             │
│ - set(key, value)      │
│ - stream               │
└────────────────────────┘
```

---

## CONCLUSION

Ce plan détaillé vous permet de :

1. ✅ **Coder sans contexte** : Chaque spécification est complète
2. ✅ **Tester rigoureusement** : Tests unitaires + intégration + benchmarks
3. ✅ **Migrer progressivement** : Feature flags + validation à chaque phase
4. ✅ **Maintenir la qualité** : SOLID, DRY, KISS respectés
5. ✅ **Préserver les performances** : Pattern Sync-First + Calculs O(n log n) conservés