# Plan d'Architecture : Uniformisation & Modernisation MVVM

## 📋 Objectifs Globaux

1. **Uniformiser le flux ExchangeRateRepository** : Service → Repository → DataSource + Cache
2. **Implémenter le pattern unifié BaseListViewModel** : Architecture synchrone + Stream pour toutes les entités
3. **Préparer l'infrastructure pour Turso** : Multi-device, sync bidirectionnelle
4. **Garantir une UX optimale** : Données immédiates + réactivité temps réel

---

## 🎯 Vision Architecturale Cible

### Pattern Unifié : "Sync-First with Reactive Updates"

```

              WIDGET (UI)                        
        (observe ViewModel.state)                
,
                   
                   → 
         ViewModel extends BaseListViewModel     
   1. loadCurrentData() → Sync initial           
   2. watchDataStream() → Reactive updates       
,
                   
        4
        →                     →    Commands              Data Access
  (write ops)           (read ops)
                             
        →                     → 
              REPOSITORY                         
   WRITE: Local → Remote → Cache → Stream       
   READ:  Cache (sync) + Stream (reactive)      
,
                   
        4
        →                     →     
 LOCAL              REMOTE           
 DataSource         DataSource       
 (SQLite)           (Firebase/Turso) 
,    ,
                             
        ,
                   →         
           CACHE MANAGER     
           (RAM + Streams)   
         - Sync getters      
         - Reactive streams  
         - _notifyAllStreams 
        
```

### Principes Architecturaux

1. **Single Source of Truth** : Cache = source de vérité en RAM
2. **Offline-First** : Sauvegarde locale immédiate, sync remote en arrière-plan
3. **Reactive by Design** : Streams pour propager les changements automatiquement
4. **Sync-First Pattern** : Données disponibles immédiatement, pas de timing issue
5. **Scalable** : Infrastructure prête pour Turso multi-device

---

##  PARTIE 1 : Uniformisation ExchangeRateRepository

### Problème actuel

```
L FLUX ACTUEL (incohérent)
SmartExchangeRateService
    → CacheManager.updateExchangeRates()
        → Repository.updateExchangeRates()
            → Remote + Local
        → _loadExchangeRates()
        → _notifyAllStreams()

PROBLéME : CacheManager orchestre au lieu du Repository
          → Dépendance circulaire CacheManager → Repository
```

### Solution cible

```
 FLUX CIBLE (cohérent)
SmartExchangeRateService
    → Repository.updateExchangeRates()
        → RemoteDataSource (télécharge)
        → LocalDataSource (sauvegarde SQLite)
        → CacheManager.reloadExchangeRatesFromDatabase()
            → _loadExchangeRates()
            → _notifyAllStreams()

AVANTAGES :
- Service → Repository (logique métier)
- Repository → DataSource + Cache (couches séparées)
- Pas de dépendance circulaire
- Pattern cohérent avec Transactions/Accounts
```

---

##  Phase 1 : CacheManager - Méthode Reload Publique

### Objectif
Créer une méthode publique permettant au Repository de recharger le cache depuis SQLite sans dépendance circulaire.

### Tâches

#### [x] 1.1 - Créer `reloadExchangeRatesFromDatabase()`

**Fichier** : `lib/data/cache/cache_manager.dart`

**Ajouter la méthode** :
```dart
/// Recharge les taux de change depuis la base de données
/// Utilisé par le Repository aprés une mise → jour
/// Pattern cohérent avec addTransaction(), addAccount()
Future<void> reloadExchangeRatesFromDatabase() async {
  if (_exchangeRateRepository == null) {
    print('é CacheManager.reloadExchangeRatesFromDatabase() - No repository available');
    return;
  }

  print('= CacheManager.reloadExchangeRatesFromDatabase() called');

  try {
    // Recharger depuis la BDD via le repository
    await _loadExchangeRates();

    // Notifier tous les streams (pattern unifié)
    _notifyAllStreams();

    print(' CacheManager.reloadExchangeRatesFromDatabase() completed: ${_exchangeRates.length} rates');
  } catch (e) {
    print('L CacheManager.reloadExchangeRatesFromDatabase() failed: $e');
    rethrow;
  }
}
```

**Justification** :
- Méthode publique → Repository peut appeler sans dépendance circulaire
- Réutilise `_loadExchangeRates()` existant
- Pattern cohérent avec `addTransaction()`, `addAccount()`
- Notifie les streams pour réactivité

#### [x] 1.2 - Marquer `updateExchangeRates()` comme deprecated

**Dans le méme fichier, ajouter l'annotation** :
```dart
/// Met → jour les taux de change pour une devise de base
///
/// @Deprecated('Use Repository.updateExchangeRates() instead. This method creates a circular dependency.')
/// Pattern cohérent avec addAccount/addTransaction/etc.
@Deprecated('Use Repository.updateExchangeRates() followed by reloadExchangeRatesFromDatabase()')
Future<void> updateExchangeRates(String baseCurrency) async {
  // ... code existant ...
}
```

**Justification** :
- Prévient l'utilisation future de ce pattern
- Documentation claire de la migration
- Ne casse pas le code existant immédiatement

#### [ ] 1.3 - Tests unitaires Phase 1 (TODO)

**Créer** : `test/cache/cache_manager_exchange_rates_test.dart`

```dart
void main() {
  group('CacheManager.reloadExchangeRatesFromDatabase()', () {
    late CacheManager cacheManager;
    late MockExchangeRateRepository mockRepository;

    setUp(() {
      cacheManager = CacheManager.instance;
      mockRepository = MockExchangeRateRepository();
    });

    test('should reload rates from database and notify streams', () async {
      // Arrange
      final mockRates = [
        ExchangeRate(fromCurrency: 'EUR', toCurrency: 'USD', rate: 1.1),
        ExchangeRate(fromCurrency: 'USD', toCurrency: 'EUR', rate: 0.9),
      ];
      when(mockRepository.getAllRates()).thenAnswer((_) async => mockRates);

      // Act
      await cacheManager.reloadExchangeRatesFromDatabase();

      // Assert
      expect(cacheManager.getAllExchangeRates().length, equals(2));
      verify(mockRepository.getAllRates()).called(1);
    });

    test('should emit stream after reload', () async {
      // Arrange
      final streamEvents = <Map<String, ExchangeRate>>[];
      cacheManager.exchangeRatesStream.listen(streamEvents.add);

      // Act
      await cacheManager.reloadExchangeRatesFromDatabase();

      // Assert
      await Future.delayed(Duration(milliseconds: 100));
      expect(streamEvents.isNotEmpty, isTrue);
    });
  });
}
```

#### [x] 1.4 - Lancer flutter analyze

```bash
flutter analyze
```

**Critère de succès** : Aucune nouvelle erreur introduite ✅

---

##  Phase 2 : Repository - Utiliser la Nouvelle Méthode

### Objectif
Modifier le Repository pour appeler `reloadExchangeRatesFromDatabase()` aprés sauvegarde.

### Tâches

#### [x] 2.1 - Modifier `updateExchangeRates()` dans Repository

**Fichier** : `lib/data/repositories/exchange_rate_repository_impl.dart`

**Remplacer la méthode** :
```dart
@override
Future<void> updateExchangeRates(String baseCurrency) async {
  if (!CurrencyService.isValidCurrency(baseCurrency)) {
    throw UnsupportedCurrencyException('Currency $baseCurrency is not supported');
  }

  try {
    print(' ExchangeRateRepository.updateExchangeRates($baseCurrency) called');

    // 1. Télécharger depuis l'API remote
    final remoteRates = await _remoteDataSource.getExchangeRates(baseCurrency);
    print(' Downloaded ${remoteRates.length} rates for $baseCurrency');

    // 2. Sauvegarder dans la base de données locale
    await _localDataSource.saveExchangeRates(remoteRates);
    print(' Saved ${remoteRates.length} rates to SQLite');

    // 3. Recharger le cache mémoire et notifier les streams
    // Pattern cohérent avec TransactionRepository : BDD → Cache → Stream
    if (_cacheManager.isInitialized) {
      await _cacheManager.reloadExchangeRatesFromDatabase();
      print(' Cache reloaded and streams notified');
    }

    print(' ExchangeRateRepository.updateExchangeRates($baseCurrency) completed');
  } catch (e) {
    print('L ExchangeRateRepository.updateExchangeRates($baseCurrency) failed: $e');
    throw ExchangeRateUpdateException('Failed to update exchange rates: $e');
  }
}
```

**Justification** :
- Pattern cohérent avec `TransactionRepository.updateTransaction()`
- Repository orchestre : Remote → Local → Cache
- Pas de dépendance circulaire (reload uniquement)
- Logs détaillés pour debug

#### [x] 2.2 - Supprimer le commentaire "Ne PAS appeler CacheManager"

**Dans le méme fichier, supprimer** :
```dart
// NOTE: Ne PAS appeler _cacheManager.updateExchangeRates() ici !
// C'est le CacheManager qui appelle ce Repository, pas l'inverse.
// Le CacheManager fera un reload aprés cet appel
```

**Remplacer par** :
```dart
//  Pattern cohérent : Repository → Remote → Local → Cache → Stream
// Le Repository orchestre la mise → jour et recharge le cache
```

#### [ ] 2.3 - Tests unitaires Phase 2 (TODO)

**Créer** : `test/repositories/exchange_rate_repository_test.dart`

```dart
void main() {
  group('ExchangeRateRepository.updateExchangeRates()', () {
    late ExchangeRateRepositoryImpl repository;
    late MockCacheManager mockCacheManager;
    late MockLocalDataSource mockLocalDataSource;
    late MockRemoteDataSource mockRemoteDataSource;

    setUp(() {
      mockCacheManager = MockCacheManager();
      mockLocalDataSource = MockLocalDataSource();
      mockRemoteDataSource = MockRemoteDataSource();

      repository = ExchangeRateRepositoryImpl(
        mockCacheManager,
        mockLocalDataSource,
        mockRemoteDataSource,
      );

      when(mockCacheManager.isInitialized).thenReturn(true);
    });

    test('should download, save to DB, and reload cache', () async {
      // Arrange
      final mockRates = [
        ExchangeRateModel(fromCurrency: 'EUR', toCurrency: 'USD', rate: 1.1),
      ];
      when(mockRemoteDataSource.getExchangeRates('EUR'))
          .thenAnswer((_) async => mockRates);
      when(mockLocalDataSource.saveExchangeRates(any))
          .thenAnswer((_) async => {});
      when(mockCacheManager.reloadExchangeRatesFromDatabase())
          .thenAnswer((_) async => {});

      // Act
      await repository.updateExchangeRates('EUR');

      // Assert
      verify(mockRemoteDataSource.getExchangeRates('EUR')).called(1);
      verify(mockLocalDataSource.saveExchangeRates(mockRates)).called(1);
      verify(mockCacheManager.reloadExchangeRatesFromDatabase()).called(1);
    });

    test('should throw exception if remote download fails', () async {
      // Arrange
      when(mockRemoteDataSource.getExchangeRates('EUR'))
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => repository.updateExchangeRates('EUR'),
        throwsA(isA<ExchangeRateUpdateException>()),
      );
      verifyNever(mockCacheManager.reloadExchangeRatesFromDatabase());
    });
  });
}
```

#### [x] 2.4 - Lancer flutter analyze

```bash
flutter analyze
```

**✅ Completed - No new errors introduced**

---

##  Phase 3 : SmartExchangeRateService - Appeler Repository

### Objectif
Modifier le service pour appeler le Repository au lieu du CacheManager.

### Tâches

#### [x] 3.1 - Modifier `updateExpiredRatesWithTimeout()`

**Fichier** : `lib/core/services/smart_exchange_rate_service.dart`

**Ligne 84-100, remplacer** :
```dart
// AVANT
await _cacheManager
    .updateExchangeRates(currency)
    .timeout(_currencyTimeout);

// APRéS
await _exchangeRateRepository
    .updateExchangeRates(currency)
    .timeout(_currencyTimeout);
```

**Justification** :
- Pattern logique : Service → Repository → DataSource
- Cohérent avec le reste de l'app
- Cache rechargé automatiquement par le Repository

#### [x] 3.2 - Modifier `ensureCurrencyAvailable()`

**Même fichier, ligne 169-173, remplacer** :
```dart
// AVANT
await _cacheManager
    .updateExchangeRates(upperCurrency)
    .timeout(_currencyTimeout);

// APRéS
await _exchangeRateRepository
    .updateExchangeRates(upperCurrency)
    .timeout(_currencyTimeout);
```

#### [x] 3.3 - Modifier `initializeCacheForAccountCurrencies()`

**Même fichier, ligne 297-313, remplacer** :
```dart
// AVANT
await _cacheManager
    .updateExchangeRates(currency)
    .timeout(_currencyTimeout);

// APRéS
await _exchangeRateRepository
    .updateExchangeRates(currency)
    .timeout(_currencyTimeout);
```

**Et mettre → jour le commentaire** :
```dart
// AVANT
// Le CacheManager recharge automatiquement via _loadExchangeRates() et notifie les streams

// APRéS
// Le Repository recharge automatiquement le cache aprés sauvegarde (pattern cohérent)
```

#### [x] 3.4 - Tests d'intégration Phase 3

**Test manuel** :
1. Désinstaller l'app complétement
2. Relancer l'app (premier lancement)
3. Vérifier que les taux s'affichent dans ExchangeRatesBottomSheet
4. Vérifier les logs : Repository → Remote → Local → Cache → Stream

**Critéres de succés** :
-  Taux affichés au premier lancement
-  Logs montrent le flux correct
-  Pas d'erreur dans la console

#### [x] 3.5 - Lancer flutter analyze

```bash
flutter analyze
```

**✅ Completed - All deprecated_member_use warnings for updateExchangeRates() are gone! (437 issues, down from 442)**

---

##  Phase 4 : Cleanup - Supprimer Code Deprecated

### Objectif
Nettoyer le code legacy aprés validation compléte.

### Tâches

#### [ ] 4.1 - Tests de régression complets

**Tests manuels** :
- [ ] Premier lancement (app désinstallée)
- [ ] Redémarrage de l'app
- [ ] Création compte nouvelle devise → taux téléchargés
- [ ] Mode avion → taux expirés affichés + bouton Retry
- [ ] Retry aprés reconnexion → taux mis → jour

**Critéres de succés** : Tous les scénarios fonctionnent

#### [ ] 4.2 - Supprimer `CacheManager.updateExchangeRates()`

**Fichier** : `lib/data/cache/cache_manager.dart`

**Supprimer la méthode compléte** :
```dart 
@Deprecated('Use Repository.updateExchangeRates() followed by reloadExchangeRatesFromDatabase()')
Future<void> updateExchangeRates(String baseCurrency) async {
  // ... supprimer tout le contenu ...
}
```

**Justification** :
- Code deprecated non utilisé
- Pattern unifié en place
- Simplification du CacheManager

#### [ ] 4.3 - Mettre → jour la documentation

**Fichiers → mettre → jour** :
- [ ] `_README.md` : Ajouter section "Architecture unifiée ExchangeRates"
- [ ] `lib/data/cache/cache_manager.dart` : Commenter le pattern
- [ ] `lib/data/repositories/exchange_rate_repository_impl.dart` : Documenter le flux

#### [ ] 4.4 - Flutter analyze final

```bash
flutter analyze
```

**Critére de succés** : Aucune erreur, warnings stables ou réduits

---

##  Phase 4bis : Architecture Exchange Rates Avancée (Recommandations Peer Review)

### 🎯 Objectif

Finaliser l'architecture des Exchange Rates en adoptant les meilleures pratiques identifiées lors de la peer review :
1. **Pattern cohérent** : `Repository → CacheManager.addExchangeRates()` (comme `addTransaction`)
2. **État granulaire** : `ExchangeRatesStatus` enum pour UI conditionnelle
3. **Analyse centralisée** : Méthode dédiée dans `SmartExchangeRateService`
4. **UI propre** : Logique métier dans ViewModel, pas dans Widget

### 📊 Architecture Cible

```
┌─────────────────────────────────────────────────────────┐
│ ExchangeRatesBottomSheet (UI Pure)                      │
│  ↓ Lit state                                            │
│ CurrencyViewModel (Business Logic)                      │
│  ├─ exchangeRatesStatus: ExchangeRatesStatus            │
│  ├─ getExchangeRateForCurrency(String): ExchangeRate?  │
│  └─ retryMissingCurrency(String)                        │
│  ↓ Utilise                                              │
│ SmartExchangeRateService (Orchestration)               │
│  ├─ analyzeExchangeRateStatus()                         │
│  └─ ensureRatesAvailable()                              │
│  ↓ Appelle                                              │
│ ExchangeRateRepository (Data Access)                    │
│  └─ updateExchangeRates() → CacheManager.addExchangeRates()│
└─────────────────────────────────────────────────────────┘
```

### 🔄 Flux de Données Unifié

**Pattern Transactions (existant)** :
```dart
Repository.createTransaction()
  → LocalDataSource.save()
  → CacheManager.addTransaction()  // ✅ Méthode publique
    → _transactions[id] = transaction
    → _transactionsController.add()
```

**Pattern Exchange Rates (après Phase 4bis)** :
```dart
Repository.updateExchangeRates()
  → RemoteDataSource.fetch()
  → LocalDataSource.save()
  → CacheManager.addExchangeRates()  // ✅ Nouveau, cohérent !
    → _exchangeRates[key] = rate
    → _exchangeRatesController.add()
```

---

### 📝 Tâches Détaillées

#### [x] 4bis.1 - Créer `ExchangeRatesStatus` enum

**Fichier** : `lib/presentation/viewmodels/shared/currency_view_model.dart`

**Ajouter l'enum AVANT la classe `CurrencyViewState`** :

```dart
/// Statut global des taux de change pour l'UI
enum ExchangeRatesStatus {
  /// Tous les taux nécessaires sont disponibles et valides
  available,

  /// Tous les taux sont disponibles mais certains sont expirés
  expired,

  /// Certains taux manquent complètement
  partial,

  /// Aucun taux disponible
  unavailable,

  /// Chargement en cours (état transitoire)
  loading,
}
```

**Ajouter le champ dans `CurrencyViewState`** :

```dart
class CurrencyViewState extends BaseListViewState<ExchangeRate> {
  // ... champs existants ...

  /// Statut global des taux de change
  final ExchangeRatesStatus exchangeRatesStatus;

  /// Devises manquantes (pour status = partial)
  final Set<String> missingCurrencies;

  /// Indique si des taux sont expirés (pour status = expired)
  final bool hasExpiredRates;

  const CurrencyViewState({
    // ... paramètres existants ...
    this.exchangeRatesStatus = ExchangeRatesStatus.available,
    this.missingCurrencies = const {},
    this.hasExpiredRates = false,
  });

  @override
  CurrencyViewState copyWith({
    // ... paramètres existants ...
    Defaulted<ExchangeRatesStatus>? exchangeRatesStatus = const Omit(),
    Defaulted<Set<String>>? missingCurrencies = const Omit(),
    Defaulted<bool>? hasExpiredRates = const Omit(),
  }) {
    return CurrencyViewState(
      // ... copying existants ...
      exchangeRatesStatus: exchangeRatesStatus is Omit
          ? this.exchangeRatesStatus
          : exchangeRatesStatus as ExchangeRatesStatus,
      missingCurrencies: missingCurrencies is Omit
          ? this.missingCurrencies
          : missingCurrencies as Set<String>,
      hasExpiredRates: hasExpiredRates is Omit
          ? this.hasExpiredRates
          : hasExpiredRates as bool,
    );
  }
}
```

**Tests unitaires** :

```dart
// test/viewmodels/currency_view_model_test.dart
group('ExchangeRatesStatus', () {
  test('initial state should be available', () {
    final state = CurrencyViewState.initial();
    expect(state.exchangeRatesStatus, ExchangeRatesStatus.available);
  });

  test('copyWith should update status correctly', () {
    final state = CurrencyViewState.initial();
    final updated = state.copyWith(
      exchangeRatesStatus: ExchangeRatesStatus.partial,
      missingCurrencies: {'USD', 'GBP'},
    );

    expect(updated.exchangeRatesStatus, ExchangeRatesStatus.partial);
    expect(updated.missingCurrencies, {'USD', 'GBP'});
  });
});
```

**Exécuter les tests** :
```bash
flutter test test/viewmodels/currency_view_model_test.dart
```

---

#### [ ] 4bis.2 - Créer la méthode d'analyse centralisée

**Fichier** : `lib/core/services/smart_exchange_rate_service.dart`

**Ajouter la classe `ExchangeRateAnalysis`** (après `ExchangeRateUpdateResult`) :

```dart
/// Résultat de l'analyse des taux de change pour un ensemble de devises
class ExchangeRateAnalysis {
  /// Devises analysées
  final Set<String> analyzedCurrencies;

  /// Devises pour lesquelles aucun taux n'est disponible
  final Set<String> missingCurrencies;

  /// Devises qui ont des taux mais tous expirés
  final Set<String> expiredCurrencies;

  /// Devises qui ont au moins un taux valide
  final Set<String> availableCurrencies;

  /// Indique si au moins un taux est expiré
  final bool hasExpiredRates;

  /// Indique si tous les taux nécessaires sont disponibles
  final bool isComplete;

  /// Nombre total de taux analysés
  final int totalRatesCount;

  /// Nombre de taux valides
  final int validRatesCount;

  /// Nombre de taux expirés
  final int expiredRatesCount;

  const ExchangeRateAnalysis({
    required this.analyzedCurrencies,
    required this.missingCurrencies,
    required this.expiredCurrencies,
    required this.availableCurrencies,
    required this.hasExpiredRates,
    required this.isComplete,
    required this.totalRatesCount,
    required this.validRatesCount,
    required this.expiredRatesCount,
  });

  /// Détermine le statut global pour l'UI
  ExchangeRatesStatus get overallStatus {
    if (missingCurrencies.isNotEmpty) {
      return ExchangeRatesStatus.partial;
    }
    if (hasExpiredRates) {
      return ExchangeRatesStatus.expired;
    }
    if (totalRatesCount == 0) {
      return ExchangeRatesStatus.unavailable;
    }
    return ExchangeRatesStatus.available;
  }

  @override
  String toString() {
    return 'ExchangeRateAnalysis('
        'total: $totalRatesCount, '
        'valid: $validRatesCount, '
        'expired: $expiredRatesCount, '
        'missing: ${missingCurrencies.length}, '
        'status: $overallStatus)';
  }
}
```

**Ajouter la méthode d'analyse dans `SmartExchangeRateService`** :

```dart
class SmartExchangeRateService with AppLoggerMixin {
  // ... champs existants ...

  /// Analyse l'état des taux de change pour un ensemble de devises
  ///
  /// Cette méthode vérifie pour chaque paire de devises :
  /// - Si un taux existe dans le cache
  /// - Si le taux est valide ou expiré
  /// - Génère des statistiques détaillées
  ///
  /// Utilisé pour déterminer si une mise à jour API est nécessaire
  ExchangeRateAnalysis analyzeExchangeRateStatus(List<String> currencies) {
    final currencySet = currencies.map((c) => c.toUpperCase()).toSet();

    final missingCurrencies = <String>{};
    final expiredCurrencies = <String>{};
    final availableCurrencies = <String>{};

    int totalRatesCount = 0;
    int validRatesCount = 0;
    int expiredRatesCount = 0;
    bool hasExpiredRates = false;

    // Récupérer tous les taux en cache
    final allRates = _cacheManager.getAllExchangeRates();

    // Analyser chaque paire de devises
    for (final fromCurrency in currencySet) {
      bool hasSomeValidRates = false;
      bool hasSomeExpiredRates = false;
      bool hasNoRates = true;

      for (final toCurrency in currencySet) {
        if (fromCurrency == toCurrency) continue;

        final rate = _cacheManager.getExchangeRate(fromCurrency, toCurrency);

        if (rate != null) {
          hasNoRates = false;
          totalRatesCount++;

          if (rate.isValid) {
            validRatesCount++;
            hasSomeValidRates = true;
          } else {
            expiredRatesCount++;
            hasSomeExpiredRates = true;
            hasExpiredRates = true;
          }
        }
      }

      // Classifier la devise
      if (hasNoRates) {
        missingCurrencies.add(fromCurrency);
      } else if (hasSomeValidRates) {
        availableCurrencies.add(fromCurrency);
        if (hasSomeExpiredRates) {
          expiredCurrencies.add(fromCurrency);
        }
      } else {
        // Seulement des taux expirés
        expiredCurrencies.add(fromCurrency);
      }
    }

    final analysis = ExchangeRateAnalysis(
      analyzedCurrencies: currencySet,
      missingCurrencies: missingCurrencies,
      expiredCurrencies: expiredCurrencies,
      availableCurrencies: availableCurrencies,
      hasExpiredRates: hasExpiredRates,
      isComplete: missingCurrencies.isEmpty,
      totalRatesCount: totalRatesCount,
      validRatesCount: validRatesCount,
      expiredRatesCount: expiredRatesCount,
    );

    logInfo('analyzeExchangeRateStatus', analysis.toString());
    return analysis;
  }

  /// Analyse spécifiquement les devises des comptes utilisateur
  ExchangeRateAnalysis analyzeAccountCurrenciesStatus() {
    final accountCurrencies = getAccountCurrencies();
    return analyzeExchangeRateStatus(accountCurrencies);
  }
}
```

**Tests unitaires** :

```dart
// test/services/smart_exchange_rate_service_test.dart
group('analyzeExchangeRateStatus', () {
  test('should detect missing currencies', () {
    // Setup: Cache vide
    when(mockCacheManager.getAllExchangeRates()).thenReturn({});
    when(mockCacheManager.getExchangeRate(any, any)).thenReturn(null);

    final analysis = service.analyzeExchangeRateStatus(['USD', 'EUR']);

    expect(analysis.missingCurrencies, {'USD', 'EUR'});
    expect(analysis.overallStatus, ExchangeRatesStatus.partial);
  });

  test('should detect expired rates', () {
    // Setup: Taux expirés
    final expiredRate = ExchangeRate(
      fromCurrency: 'USD',
      toCurrency: 'EUR',
      rate: 0.85,
      lastUpdated: DateTime.now().subtract(Duration(hours: 2)),
    );

    when(mockCacheManager.getExchangeRate('USD', 'EUR'))
        .thenReturn(expiredRate);

    final analysis = service.analyzeExchangeRateStatus(['USD', 'EUR']);

    expect(analysis.hasExpiredRates, true);
    expect(analysis.overallStatus, ExchangeRatesStatus.expired);
  });

  test('should report available when all valid', () {
    // Setup: Taux valides
    final validRate = ExchangeRate.withDefaultExpiration(
      fromCurrency: 'USD',
      toCurrency: 'EUR',
      rate: 0.85,
    );

    when(mockCacheManager.getExchangeRate('USD', 'EUR'))
        .thenReturn(validRate);

    final analysis = service.analyzeExchangeRateStatus(['USD', 'EUR']);

    expect(analysis.overallStatus, ExchangeRatesStatus.available);
    expect(analysis.validRatesCount, 1);
  });
});
```

**Exécuter les tests** :
```bash
flutter test test/services/smart_exchange_rate_service_test.dart
```

---

#### [ ] 4bis.3 - Créer `CacheManager.addExchangeRates()`

**Fichier** : `lib/data/cache/cache_manager.dart`

**Ajouter la méthode publique** (inspirée de `addTransaction`) :

```dart
/// Ajoute ou met à jour des taux de change dans le cache
/// Pattern cohérent avec addTransaction, addAccount, etc.
///
/// Cette méthode :
/// 1. Ajoute/met à jour les taux dans _exchangeRates
/// 2. Émet le stream pour notifier les listeners
///
/// Utilisée par ExchangeRateRepository après sauvegarde en DB
Future<void> addExchangeRates(List<ExchangeRate> rates) async {
  if (rates.isEmpty) {
    print('⚠️ CacheManager.addExchangeRates() called with empty list');
    return;
  }

  print('📥 CacheManager.addExchangeRates() - Adding ${rates.length} rates');

  for (final rate in rates) {
    final key = '${rate.fromCurrency}_${rate.toCurrency}';
    _exchangeRates[key] = rate;
  }

  _lastExchangeRateUpdate = DateTime.now();

  // Émettre le stream pour notifier les ViewModels
  _exchangeRatesController.add(Map.from(_exchangeRates));

  print('✅ CacheManager: ${_exchangeRates.length} total rates in cache');
}

/// Ajoute ou met à jour un seul taux de change
/// Utile pour les updates unitaires (retry d'une seule devise)
Future<void> addExchangeRate(ExchangeRate rate) async {
  await addExchangeRates([rate]);
}
```

**Modifier `Repository.updateExchangeRates()`** pour utiliser la nouvelle méthode :

**Fichier** : `lib/data/repositories/exchange_rate_repository_impl.dart`

```dart
@override
Future<void> updateExchangeRates(String baseCurrency) async {
  if (!CurrencyService.isValidCurrency(baseCurrency)) {
    throw UnsupportedCurrencyException('Currency $baseCurrency is not supported');
  }

  try {
    print('📥 ExchangeRateRepository.updateExchangeRates($baseCurrency) called');

    // 1. Télécharger depuis l'API remote
    final remoteRates = await _remoteDataSource.getExchangeRates(baseCurrency);
    print('✓ Downloaded ${remoteRates.length} rates for $baseCurrency');

    // 2. Sauvegarder dans la base de données locale
    await _localDataSource.saveExchangeRates(remoteRates);
    print('✓ Saved ${remoteRates.length} rates to SQLite');

    // 3. Mettre à jour le cache mémoire via méthode publique
    // ✅ Pattern cohérent : Repository → CacheManager.addExchangeRates()
    // (comme Repository → CacheManager.addTransaction)
    if (_cacheManager.isInitialized) {
      final entities = remoteRates.map((model) => model.toEntity()).toList();
      await _cacheManager.addExchangeRates(entities);
      print('✓ Updated cache with ${entities.length} rates');
    }

    print('✅ ExchangeRateRepository.updateExchangeRates($baseCurrency) completed');
  } catch (e) {
    print('❌ ExchangeRateRepository.updateExchangeRates($baseCurrency) failed: $e');
    throw ExchangeRateUpdateException('Failed to update exchange rates: $e');
  }
}
```

**Supprimer les méthodes obsolètes** :

1. **Supprimer `reloadExchangeRatesFromDatabase()`** dans `cache_manager.dart` (plus nécessaire)
2. **Supprimer `getAllRatesFromDatabase()`** dans `exchange_rate_repository.dart` (plus nécessaire)

**Tests unitaires** :

```dart
// test/data/cache/cache_manager_test.dart
group('addExchangeRates', () {
  test('should add rates to cache and emit stream', () async {
    final rates = [
      ExchangeRate.withDefaultExpiration(
        fromCurrency: 'USD',
        toCurrency: 'EUR',
        rate: 0.85,
      ),
      ExchangeRate.withDefaultExpiration(
        fromCurrency: 'USD',
        toCurrency: 'GBP',
        rate: 0.73,
      ),
    ];

    await cacheManager.addExchangeRates(rates);

    final cachedRates = cacheManager.getAllExchangeRates();
    expect(cachedRates.length, 2);
    expect(cachedRates['USD_EUR']?.rate, 0.85);
    expect(cachedRates['USD_GBP']?.rate, 0.73);
  });

  test('should update existing rates', () async {
    // Add initial rate
    await cacheManager.addExchangeRate(
      ExchangeRate.withDefaultExpiration(
        fromCurrency: 'USD',
        toCurrency: 'EUR',
        rate: 0.85,
      ),
    );

    // Update with new rate
    await cacheManager.addExchangeRate(
      ExchangeRate.withDefaultExpiration(
        fromCurrency: 'USD',
        toCurrency: 'EUR',
        rate: 0.90,
      ),
    );

    final rate = cacheManager.getExchangeRate('USD', 'EUR');
    expect(rate?.rate, 0.90);
  });
});
```

**Exécuter les tests** :
```bash
flutter test test/data/cache/cache_manager_test.dart
flutter test test/data/repositories/exchange_rate_repository_test.dart
```

---

#### [ ] 4bis.4 - Ajouter méthodes ViewModel pour UI

**Fichier** : `lib/presentation/viewmodels/shared/currency_view_model.dart`

**Ajouter les méthodes suivantes dans `CurrencyViewModel`** :

```dart
class CurrencyViewModel extends BaseListViewModel<CurrencyViewState, ExchangeRate> {
  // ... existant ...

  final SmartExchangeRateService? _smartExchangeRateService;

  CurrencyViewModel(
    this._conversionService,
    this._smartExchangeRateService,  // Nouveau paramètre
  ) : super(CurrencyViewState.initial()) {
    _loadAvailableCurrencies();
    _subscribeToExchangeRates();
  }

  /// Analyse les taux de change et met à jour le status
  /// Appelé automatiquement lors des mises à jour du cache
  void _updateExchangeRatesStatus() {
    if (_smartExchangeRateService == null) return;

    // Analyser uniquement les devises des comptes
    final analysis = _smartExchangeRateService!.analyzeAccountCurrenciesStatus();

    state = state.copyWith(
      exchangeRatesStatus: analysis.overallStatus,
      missingCurrencies: analysis.missingCurrencies,
      hasExpiredRates: analysis.hasExpiredRates,
    );

    print('📊 CurrencyViewModel: Exchange rates status updated to ${analysis.overallStatus}');
  }

  /// Obtient le taux de change pour une devise spécifique (méthode helper pour UI)
  /// Gère automatiquement les cas edge (même devise, taux inverse)
  ExchangeRate? getExchangeRateForCurrency(
    String baseCurrency,
    String targetCurrency,
  ) {
    if (baseCurrency == targetCurrency) {
      return ExchangeRate.withDefaultExpiration(
        fromCurrency: baseCurrency,
        toCurrency: targetCurrency,
        rate: 1.0,
      );
    }

    // Essayer taux direct
    final directRate = _conversionService.getExchangeRate(baseCurrency, targetCurrency);
    if (directRate != null) return directRate;

    // Essayer taux inverse
    final inverseRate = _conversionService.getExchangeRate(targetCurrency, baseCurrency);
    if (inverseRate != null && inverseRate.rate != 0) {
      return ExchangeRate(
        fromCurrency: baseCurrency,
        toCurrency: targetCurrency,
        rate: 1.0 / inverseRate.rate,
        lastUpdated: inverseRate.lastUpdated,
      );
    }

    return null;
  }

  /// Vérifie si une devise spécifique a des taux disponibles
  bool isCurrencyAvailable(String currencyCode) {
    final accountCurrencies = _smartExchangeRateService?.getAccountCurrencies() ?? [];

    for (final accountCurrency in accountCurrencies) {
      if (accountCurrency == currencyCode) continue;

      final rate = getExchangeRateForCurrency(accountCurrency, currencyCode);
      if (rate != null && rate.isValid) return true;
    }

    return false;
  }

  /// Retry pour une devise spécifique (appelé par bouton "Réessayer" dans UI)
  /// Version améliorée avec feedback d'état
  @override
  Future<void> retryMissingCurrencyRate(String currency) async {
    if (_smartExchangeRateService == null) return;

    try {
      // Marquer comme en cours de chargement
      final newLoadingStates = Map<String, bool>.from(state.currencyLoadingStates);
      newLoadingStates[currency] = true;

      state = state.copyWith(currencyLoadingStates: newLoadingStates);

      // Tenter la mise à jour via le service
      final result = await _smartExchangeRateService!.ensureCurrencyAvailable(currency);

      // Mettre à jour l'état selon le résultat
      final finalLoadingStates = Map<String, bool>.from(state.currencyLoadingStates);
      final finalErrors = Map<String, String?>.from(state.currencyErrors);

      finalLoadingStates[currency] = false;

      if (result.success) {
        finalErrors.remove(currency);
        print('✅ Currency $currency rates updated successfully');
      } else {
        finalErrors[currency] = result.error ?? 'Échec de mise à jour';
        print('❌ Failed to update currency $currency: ${result.error}');
      }

      state = state.copyWith(
        currencyLoadingStates: finalLoadingStates,
        currencyErrors: finalErrors,
      );

      // Mettre à jour le status global
      _updateExchangeRatesStatus();

    } catch (e) {
      print('❌ Error in retryMissingCurrencyRate for $currency: $e');

      // Marquer l'erreur
      final finalLoadingStates = Map<String, bool>.from(state.currencyLoadingStates);
      final finalErrors = Map<String, String?>.from(state.currencyErrors);

      finalLoadingStates[currency] = false;
      finalErrors[currency] = e.toString();

      state = state.copyWith(
        currencyLoadingStates: finalLoadingStates,
        currencyErrors: finalErrors,
      );
    }
  }
}
```

**Modifier `_subscribeToExchangeRates()` pour appeler `_updateExchangeRatesStatus()`** :

```dart
void _subscribeToExchangeRates() {
  print('🎧 CurrencyViewModel subscribing to exchange rates stream');
  _conversionService.exchangeRatesStream.listen((ratesMap) {
    print('📨 CurrencyViewModel received stream with ${ratesMap.length} rates');

    final ratesList = ratesMap.values.toList();

    state = state.copyWith(
      items: ratesList,
      filteredItems: ratesList,
    );

    // ✅ NOUVEAU : Analyser et mettre à jour le status
    _updateExchangeRatesStatus();

    print('✅ CurrencyViewModel.state updated with ${state.totalExchangeRates} rates');
  });

  // Initialisation synchrone
  final currentRatesMap = _conversionService.getAllExchangeRates();
  final currentRatesList = currentRatesMap.values.toList();

  state = state.copyWith(
    items: currentRatesList,
    filteredItems: currentRatesList,
  );

  // ✅ NOUVEAU : Analyser status initial
  _updateExchangeRatesStatus();

  print('✅ CurrencyViewModel initialized with ${state.totalExchangeRates} rates');
}
```

**Mettre à jour le provider** :

**Fichier** : `lib/presentation/providers/viewmodel_providers.dart`

```dart
final currencyViewModelProvider =
    StateNotifierProvider<CurrencyViewModel, CurrencyViewState>((ref) {
  final conversionService = ref.watch(currencyConversionServiceProvider);
  final smartExchangeRateService = ref.watch(smartExchangeRateServiceProvider);

  return CurrencyViewModel(
    conversionService,
    smartExchangeRateService,  // ✅ Nouveau paramètre
  );
});
```

**Tests unitaires** :

```dart
// test/viewmodels/currency_view_model_test.dart
group('Exchange Rates Status Management', () {
  test('should update status to partial when rates missing', () {
    // Setup: Cache vide
    when(mockSmartService.analyzeAccountCurrenciesStatus())
        .thenReturn(ExchangeRateAnalysis(
          analyzedCurrencies: {'USD', 'EUR'},
          missingCurrencies: {'EUR'},
          expiredCurrencies: {},
          availableCurrencies: {'USD'},
          hasExpiredRates: false,
          isComplete: false,
          totalRatesCount: 1,
          validRatesCount: 1,
          expiredRatesCount: 0,
        ));

    viewModel._updateExchangeRatesStatus();

    expect(viewModel.state.exchangeRatesStatus, ExchangeRatesStatus.partial);
    expect(viewModel.state.missingCurrencies, {'EUR'});
  });

  test('getExchangeRateForCurrency should return inverse rate', () {
    final inverseRate = ExchangeRate.withDefaultExpiration(
      fromCurrency: 'EUR',
      toCurrency: 'USD',
      rate: 1.18,
    );

    when(mockConversionService.getExchangeRate('USD', 'EUR'))
        .thenReturn(null);
    when(mockConversionService.getExchangeRate('EUR', 'USD'))
        .thenReturn(inverseRate);

    final rate = viewModel.getExchangeRateForCurrency('USD', 'EUR');

    expect(rate, isNotNull);
    expect(rate!.rate, closeTo(1.0 / 1.18, 0.01));
  });
});
```

**Exécuter les tests** :
```bash
flutter test test/viewmodels/currency_view_model_test.dart
```

---

#### [ ] 4bis.5 - Refactorer `ExchangeRatesBottomSheet`

**Objectif** : Déplacer toute la logique métier du Widget vers le ViewModel

**Fichier** : `lib/presentation/widgets/bottom_sheets/exchange_rates_bottom_sheet.dart`

**Supprimer les méthodes métier du Widget** :
- `_getExchangeRate()` → Remplacer par `viewModel.getExchangeRateForCurrency()`
- Calcul de `availableCurrencies` → Déléguer au ViewModel
- Logique de filtrage → Utiliser `currencyState` directement

**Nouvelle structure simplifiée** :

```dart
class _ExchangeRatesBottomSheetState extends ConsumerState<ExchangeRatesBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;
    final l10n = AppLocalizations.of(context)!;
    final currencyState = ref.watch(currencyViewModelProvider);
    final viewModel = ref.read(currencyViewModelProvider.notifier);

    return Container(
      // ... design inchangé ...
      child: Column(
        children: [
          // Handle bar, Header (inchangés)

          // Option devise du compte (inchangée)

          // Liste des devises - LOGIQUE DÉLÉGUÉE AU VIEWMODEL
          Flexible(
            child: _buildCurrencyListFromState(
              appTheme,
              l10n,
              currencyState,
              viewModel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyListFromState(
    AppColorsExtended appTheme,
    AppLocalizations l10n,
    CurrencyViewState currencyState,
    CurrencyViewModel viewModel,
  ) {
    // ✅ AMÉLIORÉ : Utiliser le status pour afficher le bon widget
    switch (currencyState.exchangeRatesStatus) {
      case ExchangeRatesStatus.unavailable:
        return _buildEmptyCacheState(appTheme, l10n);

      case ExchangeRatesStatus.loading:
        return _buildLoadingState(appTheme, l10n);

      default:
        return _buildCurrencyList(appTheme, l10n, currencyState, viewModel);
    }
  }

  Widget _buildCurrencyList(
    AppColorsExtended appTheme,
    AppLocalizations l10n,
    CurrencyViewState currencyState,
    CurrencyViewModel viewModel,
  ) {
    // ✅ SIMPLIFIÉ : Liste des devises (exclure devise de base)
    final availableCurrencies = SupportedCurrencies.all
        .where((currency) => currency.code != widget.baseCurrency)
        .toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        left: AppConstants.defaultPadding.w,
        right: AppConstants.defaultPadding.w,
        bottom: AppConstants.veryLargePadding.h,
      ),
      itemCount: availableCurrencies.length,
      itemBuilder: (context, index) {
        final currency = availableCurrencies[index];

        // ✅ DÉLÉGUÉ AU VIEWMODEL : Récupérer les données
        final isLoading = currencyState.isCurrencyLoading(currency.code);
        final hasError = currencyState.hasCurrencyError(currency.code);
        final exchangeRate = viewModel.getExchangeRateForCurrency(
          widget.baseCurrency,
          currency.code,
        );

        // UI conditionnelle selon l'état
        if (isLoading) {
          return _buildLoadingCurrencyItem(currency, appTheme, l10n);
        }

        if (hasError || exchangeRate == null) {
          return _buildErrorCurrencyItem(currency, appTheme, l10n, viewModel);
        }

        return _buildCurrencyItem(
          currencyCode: currency.code,
          isAccountCurrency: false,
          exchangeRate: exchangeRate.rate,
          isExpired: exchangeRate.isExpired,  // ✅ NOUVEAU : Indicateur visuel
          appTheme: appTheme,
          l10n: l10n,
        );
      },
    );
  }

  // ✅ AMÉLIORÉ : Afficher indicateur si expiré
  Widget _buildCurrencyItem({
    required String currencyCode,
    required bool isAccountCurrency,
    required double exchangeRate,
    bool isExpired = false,  // Nouveau paramètre
    required AppColorsExtended appTheme,
    required AppLocalizations l10n,
  }) {
    final currency = SupportedCurrencies.all.firstWhere(
      (c) => c.code == currencyCode,
      orElse: () => SupportedCurrencies.eur,
    );

    final isSelected = currencyCode == widget.selectedCurrency;

    return InkWell(
      onTap: () {
        widget.onCurrencySelected(currencyCode);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding.w,
          vertical: AppConstants.defaultPadding.h,
        ),
        margin: EdgeInsets.only(bottom: AppConstants.smallPadding.h),
        // ✅ NOUVEAU : Bordure orange si expiré
        decoration: isExpired
            ? BoxDecoration(
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8.r),
              )
            : null,
        child: Row(
          children: [
            // Symbole devise (inchangé)
            ClipPath(/* ... */),

            SizedBox(width: AppConstants.largePadding.w),

            // Informations devise
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom devise (inchangé)
                  Text(/* ... */),

                  SizedBox(height: 4.h),

                  // Taux + indicateur expiré
                  Row(
                    children: [
                      Text(
                        isAccountCurrency
                            ? l10n.accountCurrency.toUpperCase()
                            : '1 ${widget.baseCurrency} = ${AppFormatters.formatAmount(exchangeRate, currencyCode, showSign: false, context: context)}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: isExpired ? Colors.orange : appTheme.text4,
                        ),
                      ),
                      // ✅ NOUVEAU : Badge "Expiré" si besoin
                      if (isExpired) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'Expiré',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: AppConstants.largePadding.w),

            // Indicateur sélection (inchangé)
            Container(/* ... */),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCurrencyItem(
    Currency currency,
    AppColorsExtended appTheme,
    AppLocalizations l10n,
    CurrencyViewModel viewModel,  // ✅ Recevoir le ViewModel
  ) {
    return Container(
      // ... design inchangé ...
      child: Row(
        children: [
          // Icône, nom (inchangés)

          // ✅ MODIFIÉ : Bouton retry appelle le ViewModel
          InkWell(
            onTap: () {
              viewModel.retryMissingCurrencyRate(currency.code);
            },
            child: Container(/* ... */),
          ),
        ],
      ),
    );
  }

  // Supprimer complètement _getExchangeRate() - plus nécessaire !
}
```

**Tests d'intégration UI** :

```dart
// test/widgets/exchange_rates_bottom_sheet_test.dart
void main() {
  group('ExchangeRatesBottomSheet', () {
    testWidgets('should display currencies from ViewModel', (tester) async {
      // Setup mock state
      when(mockCurrencyViewModel.state).thenReturn(
        CurrencyViewState(
          items: [mockExchangeRate],
          exchangeRatesStatus: ExchangeRatesStatus.available,
        ),
      );

      await tester.pumpWidget(createTestWidget());

      expect(find.text('EUR'), findsOneWidget);
      expect(find.text('Expiré'), findsNothing);
    });

    testWidgets('should show expired badge when rate is expired', (tester) async {
      final expiredRate = ExchangeRate(
        fromCurrency: 'USD',
        toCurrency: 'EUR',
        rate: 0.85,
        lastUpdated: DateTime.now().subtract(Duration(hours: 2)),
      );

      when(mockCurrencyViewModel.getExchangeRateForCurrency('USD', 'EUR'))
          .thenReturn(expiredRate);

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Expiré'), findsOneWidget);
    });

    testWidgets('should call viewModel retry on button tap', (tester) async {
      when(mockCurrencyViewModel.state).thenReturn(
        CurrencyViewState(
          exchangeRatesStatus: ExchangeRatesStatus.partial,
          currencyErrors: {'EUR': 'No rate'},
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text(l10n.retry));

      verify(mockCurrencyViewModel.retryMissingCurrencyRate('EUR')).called(1);
    });
  });
}
```

**Exécuter les tests** :
```bash
flutter test test/widgets/exchange_rates_bottom_sheet_test.dart
```

---

#### [ ] 4bis.6 - Tests d'intégration complets Phase 4bis

**Tests manuels** :

1. **Scénario : Cache vide (premier lancement)** :
   - Désinstaller l'app
   - Relancer → `exchangeRatesStatus` devrait être `unavailable` puis `available`
   - Vérifier widget "Aucun taux disponible" puis liste normale

2. **Scénario : Taux expirés** :
   - Modifier temporairement `ExchangeRate.expirationDuration` à 1 seconde
   - Attendre expiration → `exchangeRatesStatus` devrait passer à `expired`
   - Vérifier badges "Expiré" affichés

3. **Scénario : Devise manquante** :
   - Créer un compte avec devise rare (ex: JPY)
   - Si taux manquants → `exchangeRatesStatus` = `partial`
   - Vérifier bouton "Réessayer" fonctionne

4. **Scénario : Retry réussi** :
   - Cliquer "Réessayer" sur une devise
   - Vérifier spinner puis disparition de l'erreur
   - `exchangeRatesStatus` devrait passer à `available`

**Commandes de test** :

```bash
# Tests unitaires complets
flutter test test/viewmodels/currency_view_model_test.dart
flutter test test/services/smart_exchange_rate_service_test.dart
flutter test test/data/cache/cache_manager_test.dart

# Tests d'intégration
flutter test test/widgets/exchange_rates_bottom_sheet_test.dart

# Analyse statique
flutter analyze
```

**Critères de succès** :
- ✅ Tous les tests unitaires passent
- ✅ Aucune erreur `flutter analyze`
- ✅ Les 4 scénarios manuels fonctionnent
- ✅ Pas de régression dans les features existantes

---

#### [ ] 4bis.7 - Documentation et cleanup

**Mettre à jour `_README.md`** :

```markdown
## Phase 4bis : Architecture Exchange Rates Avancée (✅ Completed)

### Améliorations apportées

1. **ExchangeRatesStatus enum** : État granulaire pour UI conditionnelle
   - `available` : Tous les taux valides
   - `expired` : Taux disponibles mais expirés
   - `partial` : Certains taux manquants
   - `unavailable` : Aucun taux

2. **Analyse centralisée** : `SmartExchangeRateService.analyzeExchangeRateStatus()`
   - Génère `ExchangeRateAnalysis` avec statistiques détaillées
   - Détermine automatiquement le `ExchangeRatesStatus`

3. **Pattern cohérent** : `Repository → CacheManager.addExchangeRates()`
   - Aligné avec `addTransaction`, `addAccount`, etc.
   - Suppression de `reloadExchangeRatesFromDatabase()` et `getAllRatesFromDatabase()`

4. **UI propre** : Logique métier déplacée dans `CurrencyViewModel`
   - `getExchangeRateForCurrency()` : Gère taux directs et inverses
   - `retryMissingCurrencyRate()` : Retry avec feedback d'état
   - Widget purement déclaratif

### Architecture finale

```
┌─────────────────────────────────────────────────────────┐
│ ExchangeRatesBottomSheet (UI)                           │
│  ↓                                                       │
│ CurrencyViewModel (Business Logic)                      │
│  ├─ exchangeRatesStatus: ExchangeRatesStatus            │
│  ├─ getExchangeRateForCurrency()                        │
│  └─ retryMissingCurrencyRate()                          │
│  ↓                                                       │
│ SmartExchangeRateService (Orchestration)               │
│  ├─ analyzeExchangeRateStatus()                         │
│  └─ ensureRatesAvailable()                              │
│  ↓                                                       │
│ ExchangeRateRepository                                  │
│  └─ updateExchangeRates() → CacheManager.addExchangeRates()│
└─────────────────────────────────────────────────────────┘
```

### Tests

- ✅ Tests unitaires : 15+ nouveaux tests
- ✅ Tests d'intégration UI : 5 scénarios
- ✅ Tests manuels : 4 scénarios critiques
```

**Supprimer code deprecated** :

1. Dans `cache_manager.dart` : Méthode `updateExchangeRates()` marquée `@Deprecated`
2. Dans `exchange_rate_repository.dart` : Méthodes obsolètes

**Flutter analyze final** :

```bash
flutter analyze
```

---

### 🎯 Récapitulatif Phase 4bis

#### Fichiers modifiés

1. ✅ `lib/presentation/viewmodels/shared/currency_view_model.dart`
   - Ajout `ExchangeRatesStatus` enum
   - Nouveaux champs dans `CurrencyViewState`
   - Méthodes `_updateExchangeRatesStatus()`, `getExchangeRateForCurrency()`, etc.

2. ✅ `lib/core/services/smart_exchange_rate_service.dart`
   - Classe `ExchangeRateAnalysis`
   - Méthode `analyzeExchangeRateStatus()`

3. ✅ `lib/data/cache/cache_manager.dart`
   - Méthode `addExchangeRates()`
   - Méthode `addExchangeRate()`
   - Suppression méthodes obsolètes

4. ✅ `lib/data/repositories/exchange_rate_repository_impl.dart`
   - Modification `updateExchangeRates()` pour utiliser `addExchangeRates()`
   - Suppression appels à `reloadExchangeRatesFromDatabase()`

5. ✅ `lib/domain/repositories/exchange_rate_repository.dart`
   - Suppression `getAllRatesFromDatabase()`

6. ✅ `lib/presentation/widgets/bottom_sheets/exchange_rates_bottom_sheet.dart`
   - Refactoring complet : logique → ViewModel
   - Suppression `_getExchangeRate()`
   - Widgets conditionnels selon `ExchangeRatesStatus`

7. ✅ `lib/presentation/providers/viewmodel_providers.dart`
   - Ajout `smartExchangeRateService` au `CurrencyViewModel`

#### Tests ajoutés

- `test/viewmodels/currency_view_model_test.dart` : +8 tests
- `test/services/smart_exchange_rate_service_test.dart` : +5 tests
- `test/data/cache/cache_manager_test.dart` : +3 tests
- `test/widgets/exchange_rates_bottom_sheet_test.dart` : +4 tests

#### Métriques de succès

- ✅ Pattern cohérent avec Transactions/Accounts/Categories
- ✅ UI conditionnelle selon `ExchangeRatesStatus`
- ✅ Logique métier centralisée dans ViewModel
- ✅ Code testable et maintenable
- ✅ Aucune régression fonctionnelle

---

##  PARTIE 2 : Pattern Unifié BaseListViewModel + Streams

### Vision

Tous les ViewModels suivent le méme pattern :
1. **Sync-First** : `loadCurrentData()` → données immédiates
2. **Reactive Updates** : `watchDataStream()` → mises → jour automatiques
3. **BaseListViewModel** : Logique commune (pagination, filtrage, etc.)

### Architecture

```dart
abstract class BaseListViewModel<S extends BaseListViewState<T>, T> {
  // Méthodes abstraites → implémenter
  List<T> loadCurrentData();
  Stream<List<T>> watchDataStream();

  // Logique commune
  void initialize() {
    // 1. Sync-First : Charger les données actuelles
    final current = loadCurrentData();
    state = updateStateWithItems(current);

    // 2. Reactive : S'abonner aux mises → jour
    _subscription = watchDataStream().listen((updates) {
      state = updateStateWithItems(updates);
    });
  }

  // Méthodes communes : pagination, filtrage, recherche, etc.
}
```

---

##  Phase 5 : BaseListViewModel - Extension pour Sync-First

### Objectif
étendre BaseListViewModel pour supporter le pattern Sync-First + Reactive.

### Tâches

#### [ ] 5.1 - Ajouter méthodes abstraites → BaseListViewModel

**Fichier** : `lib/presentation/viewmodels/base/base_list_view_model.dart`

**Ajouter les méthodes abstraites** :
```dart
abstract class BaseListViewModel<S extends BaseListViewState<T>, T>
    extends StateNotifier<S> {

  StreamSubscription<List<T>>? _dataSubscription;

  BaseListViewModel(super.initialState);

  // === MéTHODES ABSTRAITES POUR SYNC-FIRST PATTERN ===

  /// Charge les données actuelles de maniére synchrone
  /// Utilisé pour l'initialisation immédiate
  /// Exemple : return _cacheManager.getAllTransactions();
  List<T> loadCurrentData();

  /// Retourne un stream des données pour la réactivité
  /// Utilisé pour les mises → jour automatiques
  /// Exemple : return _cacheManager.transactionsStream;
  Stream<List<T>> watchDataStream();

  // === INITIALISATION AVEC SYNC-FIRST PATTERN ===

  /// Initialise le ViewModel avec le pattern Sync-First
  /// 1. Charge les données synchrones (immédiat)
  /// 2. S'abonne au stream pour les mises → jour (réactif)
  void initialize() {
    print('= ${runtimeType}.initialize() - Sync-First pattern');

    // 1. SYNC-FIRST : Charger les données actuelles (immédiat)
    try {
      final currentData = loadCurrentData();
      print(' ${runtimeType} loaded ${currentData.length} items synchronously');

      state = setItems(currentData);
    } catch (e) {
      print('L ${runtimeType}.loadCurrentData() failed: $e');
      state = setError('Failed to load initial data: $e');
    }

    // 2. REACTIVE : S'abonner aux mises → jour futures
    _dataSubscription = watchDataStream().listen(
      (updatedData) {
        print(' ${runtimeType} received stream update: ${updatedData.length} items');
        state = setItems(updatedData);
      },
      onError: (error) {
        print('L ${runtimeType} stream error: $error');
        state = setError('Stream error: $error');
      },
    );

    print(' ${runtimeType} subscribed to data stream');
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  // Méthodes existantes : applySearchFilter, setError, etc.
  // ...
}
```

**Justification** :
- Pattern Sync-First résout le problème de timing
- Stream pour réactivité automatique
- Logs détaillés pour debug
- Gestion erreurs robuste

#### [ ] 5.2 - Implémenter dans CurrencyViewModel

**Fichier** : `lib/presentation/viewmodels/shared/currency_view_model.dart`

**Implémenter les méthodes abstraites** :
```dart
class CurrencyViewModel extends BaseListViewModel<CurrencyViewState, ExchangeRate> {
  final CurrencyConversionService _conversionService;

  CurrencyViewModel(this._conversionService) : super(CurrencyViewState.initial()) {
    // Initialiser avec le pattern Sync-First
    initialize();
  }

  // === IMPLéMENTATION SYNC-FIRST PATTERN ===

  @override
  List<ExchangeRate> loadCurrentData() {
    // Lecture synchrone depuis le cache
    final ratesMap = _conversionService.getAllExchangeRates();
    return ratesMap.values.toList();
  }

  @override
  Stream<List<ExchangeRate>> watchDataStream() {
    // Stream des mises → jour
    return _conversionService.exchangeRatesStream.map(
      (ratesMap) => ratesMap.values.toList(),
    );
  }

  // Le reste du code existant (méthodes business logic)
  // ...
}
```

**Justification** :
- Implémentation simple et claire
- Réutilise CurrencyConversionService existant
- Pas de duplication de code
- Pattern cohérent avec BaseListViewModel

#### [ ] 5.3 - Supprimer l'ancienne logique `_subscribeToExchangeRates()`

**Dans le méme fichier, supprimer** :
```dart
void _subscribeToExchangeRates() {
  // ... ancien code → supprimer ...
}
```

**Justification** :
- Logique maintenant dans BaseListViewModel.initialize()
- évite la duplication
- Code plus maintenable

#### [ ] 5.4 - Tests unitaires Phase 5

**Fichier** : `test/viewmodels/currency_view_model_test.dart`

```dart
void main() {
  group('CurrencyViewModel with Sync-First pattern', () {
    late CurrencyViewModel viewModel;
    late MockCurrencyConversionService mockService;

    setUp(() {
      mockService = MockCurrencyConversionService();

      // Mock données initiales
      when(mockService.getAllExchangeRates()).thenReturn({
        'EUR_USD': ExchangeRate(fromCurrency: 'EUR', toCurrency: 'USD', rate: 1.1),
      });

      // Mock stream
      final controller = StreamController<Map<String, ExchangeRate>>.broadcast();
      when(mockService.exchangeRatesStream).thenAnswer((_) => controller.stream);

      viewModel = CurrencyViewModel(mockService);
    });

    test('should load data synchronously on initialization', () {
      // Assert
      expect(viewModel.state.items.length, equals(1));
      expect(viewModel.state.items.first.fromCurrency, equals('EUR'));
    });

    test('should update when stream emits new data', () async {
      // Arrange
      final streamController = StreamController<Map<String, ExchangeRate>>.broadcast();
      when(mockService.exchangeRatesStream).thenAnswer((_) => streamController.stream);

      final newViewModel = CurrencyViewModel(mockService);

      // Act
      streamController.add({
        'EUR_USD': ExchangeRate(fromCurrency: 'EUR', toCurrency: 'USD', rate: 1.2),
        'USD_EUR': ExchangeRate(fromCurrency: 'USD', toCurrency: 'EUR', rate: 0.83),
      });

      await Future.delayed(Duration(milliseconds: 100));

      // Assert
      expect(newViewModel.state.items.length, equals(2));
    });
  });
}
```

#### [ ] 5.5 - Lancer flutter analyze

```bash
flutter analyze
```

---

##  Phase 6 (Futur) : Migration Transactions vers BaseListViewModel

### Objectif
Appliquer le méme pattern → TransactionListViewModel pour cohérence.

### Tâches

#### [ ] 6.1 - Implémenter loadCurrentData() dans TransactionListViewModel

**Fichier** : `lib/presentation/viewmodels/features/transaction/transaction_list_view_model.dart`

```dart
@override
List<Transaction> loadCurrentData() {
  // Lecture synchrone depuis le repository
  return _repository.getAllTransactions(_accountId);
}

@override
Stream<List<Transaction>> watchDataStream() {
  // Stream des mises → jour
  return _repository.watchTransactions(_accountId);
}
```

#### [ ] 6.2 - Ajouter watchTransactions() au Repository

**Fichier** : `lib/data/repositories/transaction_repository_impl.dart`

```dart
@override
Stream<List<Transaction>> watchTransactions(int accountId) {
  // Si le cache est initialisé, utiliser le stream du cache
  if (_cacheManager.isInitialized) {
    return _cacheManager.transactionsStream.map((allTransactions) {
      return allTransactions.where((tx) => tx.accountId == accountId).toList();
    });
  }

  // Sinon, utiliser le stream de la base de données
  return _localDataSource.watchTransactions(accountId).map(
    (models) => models.map((model) => model.toEntity()).toList(),
  );
}
```

#### [ ] 6.3 - Tests Phase 6

**Tests manuels** :
- [ ] Créer une transaction → liste se met → jour automatiquement
- [ ] Modifier une transaction → liste se met → jour
- [ ] Supprimer une transaction → liste se met → jour

#### [ ] 6.4 - Lancer flutter analyze

---

##  Phase 7 (Futur) : Infrastructure Turso Multi-Device

### Objectif
Préparer l'infrastructure pour la synchronisation multi-device avec Turso.

### Architecture

```

          DEVICE 1 (Phone)                        
                                                  
  Widget → ViewModel → Repository → Stream       
                           →                      
                    Local SQLite                  
                           →                      
                    Remote Turso          

                                          
                                           Sync
                                          

          DEVICE 2 (Tablet)                       
                                                  
  Widget → ViewModel → Repository → Stream       
                           →                      
                    Local SQLite                  
                           →                      
                    Remote Turso →         

```

### Tâches

#### [ ] 7.1 - Créer l'interface RemoteDataSource

**Fichier** : `lib/data/datasources/remote/remote_datasource.dart`

```dart
abstract class RemoteTransactionDataSource {
  Future<List<TransactionModel>> getAllTransactions();
  Future<TransactionModel> createTransaction(TransactionModel transaction);
  Future<TransactionModel> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(int id);

  /// Stream des changements depuis le serveur
  Stream<List<TransactionModel>> watchTransactions();
}
```

#### [ ] 7.2 - Implémenter TursoDataSource : plus tard (attendre implémentation Turso)

**Fichier** : `lib/data/datasources/remote/turso_datasource.dart`

```dart
class TursoTransactionDataSource implements RemoteTransactionDataSource {
  final TursoClient _client;

  TursoTransactionDataSource(this._client);

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    final result = await _client.execute(
      'SELECT * FROM transactions WHERE user_id = ?',
      [_getCurrentUserId()],
    );
    return result.rows.map((row) => TransactionModel.fromJson(row)).toList();
  }

  @override
  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final result = await _client.execute(
      'INSERT INTO transactions (...) VALUES (...) RETURNING *',
      [...],
    );
    return TransactionModel.fromJson(result.rows.first);
  }

  @override
  Stream<List<TransactionModel>> watchTransactions() {
    // Polling ou WebSocket selon implémentation Turso
    return Stream.periodic(Duration(seconds: 30), (_) async {
      return await getAllTransactions();
    }).asyncMap((future) => future);
  }
}
```

#### [ ] 7.3 - Créer SmartSyncService : plus tard (attendre implémentation Turso)

**Fichier** : `lib/core/services/smart_sync_service.dart`

```dart
class SmartSyncService {
  final LocalDataSource _localDataSource;
  final RemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  /// Sync local → remote en arriére-plan
  Future<void> syncPendingChanges() async {
    // Récupérer les transactions non synchronisées
    final pending = await _localDataSource.getPendingSync();

    for (final transaction in pending) {
      try {
        // Envoyer vers Turso
        await _remoteDataSource.createTransaction(transaction);

        // Marquer comme synchronisé
        await _localDataSource.markAsSynced(transaction.id);
      } catch (e) {
        print('Failed to sync transaction ${transaction.id}: $e');
        // Retry plus tard
      }
    }
  }

  /// écoute les changements remote et merge avec local
  void listenToRemoteChanges() {
    _remoteDataSource.watchTransactions().listen((remoteTransactions) async {
      for (final remoteTx in remoteTransactions) {
        // Vérifier si existe en local
        final localTx = await _localDataSource.getTransactionById(remoteTx.id);

        if (localTx == null) {
          // Nouvelle transaction depuis autre device
          await _localDataSource.createTransaction(remoteTx);
        } else if (remoteTx.updatedAt.isAfter(localTx.updatedAt)) {
          // Transaction mise → jour depuis autre device
          await _localDataSource.updateTransaction(remoteTx);
        }
      }

      // Recharger le cache
      await _cacheManager.reloadTransactions();
      // Stream notifié → UI se met → jour automatiquement
    });
  }
}
```

#### [ ] 7.4 - Tests d'intégration Turso : plus tard (attendre implémentation Turso)

**Tests manuels** :
- [ ] Créer transaction sur Device 1 → apparaét sur Device 2
- [ ] Modifier transaction sur Device 2 → mise → jour sur Device 1
- [ ] Conflit : résolution last-write-wins

---

##  Métriques de Succés

### Phase 1-4 : ExchangeRates Uniformisation

- [ ]  Flux cohérent : Service → Repository → DataSource + Cache
- [ ]  Pas de dépendance circulaire
- [ ]  Taux affichés au premier lancement
- [ ]  Tests unitaires passent
- [ ]  Flutter analyze sans nouvelles erreurs

### Phase 5 : BaseListViewModel Sync-First

- [ ]  CurrencyViewModel utilise BaseListViewModel
- [ ]  Données immédiates (pas de timing issue)
- [ ]  Réactivité via streams
- [ ]  Tests unitaires passent

### Phase 6 : Migration Transactions

- [ ]  TransactionListViewModel utilise BaseListViewModel
- [ ]  Méme pattern que CurrencyViewModel
- [ ]  Réactivité automatique create/update/delete

### Phase 7 : Infrastructure Turso : plus tard (attendre implémentation Turso)

- [ ]  RemoteDataSource interface définie
- [ ]  TursoDataSource implémenté
- [ ]  SmartSyncService fonctionnel
- [ ]  Tests multi-device passent

---

##  Documentation

### Fichiers → mettre → jour

- [ ] `_README.md` : Section "Architecture unifiée MVVM"
- [ ] `lib/presentation/viewmodels/base/base_list_view_model.dart` : Documenter le pattern Sync-First
- [ ] `lib/data/cache/cache_manager.dart` : Documenter les méthodes reload
- [ ] `lib/data/repositories/exchange_rate_repository_impl.dart` : Documenter le flux

### Diagrammes → créer

- [ ] Diagramme de séquence : Service → Repository → Cache → Stream
- [ ] Diagramme d'architecture : Pattern Sync-First
- [ ] Diagramme multi-device : Turso sync

---

##  Prochaines Sessions

**Session 1** : Phases 1-4 (Uniformisation ExchangeRates)
**Session 2** : Phase 5 (BaseListViewModel Sync-First)
**Session 3** : Phase 6 (Migration Transactions)
**Session 4** : Phase 7 (Infrastructure Turso)

---

**Derniére mise → jour** : 30 Septembre 2025
**Status** :  **PLAN PRéT POUR IMPLéMENTATION**