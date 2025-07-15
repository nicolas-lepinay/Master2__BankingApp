import 'package:bankapp/domain/entities/entities.dart';
import 'package:bankapp/domain/repositories/repositories.dart';
import 'package:bankapp/data/cache/cache_manager.dart';
import 'package:bankapp/data/datasources/local/local_datasources.dart';
import 'package:bankapp/data/models/models.dart';

class CounterpartyRepositoryImpl implements CounterpartyRepository {
  final CounterpartyLocalDataSource _localDataSource;
  final CacheManager _cacheManager;

  CounterpartyRepositoryImpl(this._localDataSource, this._cacheManager);

  @override
  Future<List<Counterparty>> getAllCounterparties() async {
    // Si le cache est initialisé, utiliser le cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.getAllCounterparties();
    }
    
    // Sinon, charger depuis la base de données
    final counterpartyModels = await _localDataSource.getAllCounterparties();
    return counterpartyModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Counterparty?> getCounterpartyById(int id) async {
    // Si le cache est initialisé, utiliser le cache
    if (_cacheManager.isInitialized) {
      final allCounterparties = _cacheManager.getAllCounterparties();
      try {
        return allCounterparties.firstWhere((counterparty) => counterparty.id == id);
      } catch (e) {
        return null;
      }
    }
    
    // Sinon, charger depuis la base de données
    final counterpartyModel = await _localDataSource.getCounterpartyById(id);
    return counterpartyModel?.toEntity();
  }

  @override
  Future<List<Counterparty>> searchCounterpartiesByName(String name) async {
    final allCounterparties = await getAllCounterparties();
    final lowerName = name.toLowerCase();
    
    return allCounterparties
        .where((counterparty) => counterparty.name.toLowerCase().contains(lowerName))
        .toList();
  }

  @override
  Future<Counterparty> createCounterparty(Counterparty counterparty) async {
    // Créer le modèle pour la base de données
    final counterpartyModel = CounterpartyModel.fromEntity(counterparty);
    
    // Sauvegarder dans la base de données
    final savedModel = await _localDataSource.createCounterparty(counterpartyModel);
    
    // Mettre à jour le cache si initialisé
    if (_cacheManager.isInitialized) {
      await _cacheManager.invalidateAll(); // Recalculer tout
    }
    
    return savedModel.toEntity();
  }

  @override
  Future<Counterparty> updateCounterparty(Counterparty counterparty) async {
    // Créer le modèle pour la base de données
    final counterpartyModel = CounterpartyModel.fromEntity(counterparty);
    
    // Sauvegarder dans la base de données
    final savedModel = await _localDataSource.updateCounterparty(counterpartyModel);
    
    // Mettre à jour le cache si initialisé
    if (_cacheManager.isInitialized) {
      await _cacheManager.invalidateAll(); // Recalculer tout
    }
    
    return savedModel.toEntity();
  }

  @override
  Future<void> deleteCounterparty(int id) async {
    // Supprimer de la base de données
    await _localDataSource.deleteCounterparty(id);
    
    // Mettre à jour le cache si initialisé
    if (_cacheManager.isInitialized) {
      await _cacheManager.invalidateAll(); // Recalculer tout
    }
  }

  @override
  Future<bool> isUsedInTransactions(int counterpartyId) async {
    // Si le cache est initialisé, vérifier dans le cache
    if (_cacheManager.isInitialized) {
      final allTransactions = _cacheManager.getAllTransactions();
      return allTransactions.any((transaction) => 
          transaction.counterpartyId == counterpartyId);
    }
    
    // Sinon, vérifier dans la base de données
    // Note : Cette implémentation nécessiterait une méthode dans la datasource
    // Pour l'instant, on assume que non
    return false;
  }

  @override
  Future<Map<String, int>> getCounterpartyUsageStats(int counterpartyId) async {
    if (_cacheManager.isInitialized) {
      final allTransactions = _cacheManager.getAllTransactions();
      final counterpartyTransactions = allTransactions
          .where((transaction) => transaction.counterpartyId == counterpartyId)
          .toList();
      
      int incomeCount = 0;
      int expenseCount = 0;
      double totalIncome = 0;
      double totalExpenses = 0;
      
      for (final transaction in counterpartyTransactions) {
        if (transaction.isIncome) {
          incomeCount++;
          totalIncome += transaction.amount;
        } else {
          expenseCount++;
          totalExpenses += transaction.amount;
        }
      }
      
      return {
        'total_transactions': counterpartyTransactions.length,
        'income_count': incomeCount,
        'expense_count': expenseCount,
        'total_income': totalIncome.round(),
        'total_expenses': totalExpenses.round(),
      };
    }
    
    // Fallback : statistiques vides
    return {
      'total_transactions': 0,
      'income_count': 0,
      'expense_count': 0,
      'total_income': 0,
      'total_expenses': 0,
    };
  }

  @override
  Stream<List<Counterparty>> watchAllCounterparties() {
    // Si le cache est initialisé, utiliser le stream du cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.counterpartiesStream;
    }
    
    // Sinon, utiliser le stream de la base de données
    return _localDataSource.watchAllCounterparties()
        .map((models) => models.map((model) => model.toEntity()).toList());
  }

  @override
  Stream<Counterparty?> watchCounterpartyById(int id) {
    // Si le cache est initialisé, utiliser le stream du cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.counterpartiesStream.map((counterparties) {
        try {
          return counterparties.firstWhere((counterparty) => counterparty.id == id);
        } catch (e) {
          return null;
        }
      });
    }
    
    // Sinon, utiliser le stream de la base de données
    return _localDataSource.watchCounterpartyById(id)
        .map((model) => model?.toEntity());
  }
}