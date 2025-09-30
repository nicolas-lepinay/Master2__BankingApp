# Plan Ultra-Détaillé : Migration Exchange Rates vers Architecture A + BaseListViewModel

## 🎯 Objectifs de la Migration

**Problème actuel** : Incohérence architecturale entre Exchange Rates (Event-Driven) et le reste de l'app (State Management)

**Solution cible** :
1. **Harmoniser Exchange Rates** vers Architecture A (State Management synchrone)
2. **Uniformiser CurrencyViewModel** avec BaseListViewModel comme TransactionListViewModel
3. **Éliminer définitivement** les problèmes de timing/abonnement tardif
4. **Créer une cohérence parfaite** dans toute l'app

---

## 📚 Architecture Cible - Cohérence Totale

### **Pattern Unifié : State Management + BaseListViewModel**
```
Toutes les données suivront le même pattern :
├── CacheManager (cache synchrone + getters + _notifyAllStreams)
├── Repository (bridge vers CacheManager)
├── BaseListViewModel (logique commune pagination/filtrage)
├── SpecificViewModel extends BaseListViewModel (TransactionList, Currency, etc.)
└── UI (accès synchrone aux données via ViewModel.state)
```

### **Comparaison Architecture Actuelle vs Cible**

| Composant | AVANT (Event-Driven) | APRÈS (State Management) |
|-----------|----------------------|---------------------------|
| CacheManager | `_exchangeRates` privé, stream uniquement | `getAllExchangeRates()` public + _notifyAllStreams |
| Repository | Stream forwarding | Getters synchrones comme TransactionRepository |
| CurrencyViewModel | Stream subscription complexe | extends BaseListViewModel avec loadAllItems() |
| UI | Timing-dependent | Données toujours disponibles |

---

## 🏗️ Plan d'Implémentation Ultra-Détaillé

### **Phase 1 : Refactoring CacheManager** ⏳

#### **1.1 - Ajouter Getters Synchrones (Pattern Transactions/Accounts)**

**Fichier** : `lib/data/cache/cache_manager.dart`

**Méthodes à ajouter** :
```dart
// === GETTERS SYNCHRONES POUR EXCHANGE RATES ===

/// Obtient tous les taux de change (pattern cohérent avec getAllAccounts)
Map<String, ExchangeRate> getAllExchangeRates() {
  return Map.from(_exchangeRates);
}

/// Obtient un taux de change spécifique
ExchangeRate? getExchangeRate(String fromCurrency, String toCurrency) {
  final directKey = '${fromCurrency}_${toCurrency}';
  final directRate = _exchangeRates[directKey];

  if (directRate != null) {
    return directRate;
  }

  // Logique bidirectionnelle (comme existant)
  final inverseKey = '${toCurrency}_${fromCurrency}';
  final inverseRate = _exchangeRates[inverseKey];

  if (inverseRate != null && inverseRate.rate != 0) {
    return ExchangeRate.withDefaultExpiration(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      rate: 1.0 / inverseRate.rate,
    );
  }

  return null;
}

/// Obtient tous les taux pour une devise de base (comme getTransactionsWithBalance)
List<ExchangeRate> getExchangeRatesForCurrency(String baseCurrency) {
  return _exchangeRates.values
      .where((rate) => rate.fromCurrency == baseCurrency)
      .toList();
}

/// Vérifie si des taux sont disponibles pour une devise
bool hasExchangeRatesForCurrency(String currency) {
  return _exchangeRates.keys.any((key) => key.startsWith('${currency}_'));
}

/// Obtient les devises disponibles (basé sur les taux en cache)
List<String> getAvailableCurrencies() {
  final currencies = <String>{};
  for (final rate in _exchangeRates.values) {
    currencies.add(rate.fromCurrency);
    currencies.add(rate.toCurrency);
  }
  return currencies.toList()..sort();
}
```

#### **1.2 - Intégrer dans _notifyAllStreams() (Pattern Cohérent)**

**Modifier la méthode existante** :
```dart
/// Notifie tous les streams après modifications
void _notifyAllStreams() {
  _accountsController.add(getAllAccounts());
  _transactionsController.add(getAllTransactions());
  _categoriesController.add(getAllCategories());
  _counterpartiesController.add(getAllCounterparties());
  _followedTransactionsController.add(_followedTransactionsWithBalance);

  // AJOUT : Exchange rates avec pattern cohérent
  _exchangeRatesController.add(getAllExchangeRates());
}
```

#### **1.3 - Simplifier updateExchangeRates() (Pattern Transactions)**

**Remplacer la logique complexe par** :
```dart
/// Met à jour les taux de change pour une devise de base
Future<void> updateExchangeRates(String baseCurrency) async {
  if (_exchangeRateRepository == null) return;

  try {
    print('📥 CacheManager.updateExchangeRates($baseCurrency) called');

    // Mise à jour via repository (sauve en BDD)
    await _exchangeRateRepository!.updateExchangeRates(baseCurrency);

    // Recharger le cache mémoire depuis la BDD
    await _loadExchangeRates();

    // Notification unifiée comme addAccount/addTransaction
    _notifyAllStreams();

    print('✅ CacheManager.updateExchangeRates completed: ${_exchangeRates.length} rates');
  } catch (e) {
    print('❌ CacheManager.updateExchangeRates($baseCurrency) failed: $e');
  }
}
```

#### **1.4 - Supprimer Méthodes Spécifiques (Cohérence)**

**Méthodes à supprimer** (remplacées par pattern unifié) :
- `forceSyncFromDatabase()` → Remplacé par _notifyAllStreams standard
- `emitCurrentExchangeRates()` → Plus nécessaire avec getters synchrones

---

**Dernière mise à jour** : 30 Septembre 2025
**Status** : 🎯 **PLAN PRÊT POUR IMPLÉMENTATION**