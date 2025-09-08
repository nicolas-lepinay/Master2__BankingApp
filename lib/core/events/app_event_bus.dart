import 'dart:async';
import 'package:bankapp/core/events/app_events.dart';
import 'package:bankapp/core/events/transaction_events.dart';
import 'package:bankapp/core/events/account_events.dart';
import 'package:bankapp/domain/entities/transaction.dart';
import 'package:flutter/foundation.dart';

/// Bus d'événements centralisé pour l'application
/// 
/// Cette classe implémente le pattern Event Bus pour permettre une communication
/// découplée entre les ViewModels. Elle remplace les chaînes complexes
/// d'invalidation de providers avec _ref.invalidate().
/// 
/// Architecture :
/// - Singleton pattern pour garantir une instance unique
/// - Streams typés pour chaque type d'événement
/// - Filtrage automatique par type
/// - Logging intégré pour debugging
/// - Gestion d'erreur robuste
class AppEventBus {
  static AppEventBus? _instance;
  static AppEventBus get instance => _instance ??= AppEventBus._internal();
  
  AppEventBus._internal() {
    _initializeEventTracking();
  }
  
  /// Stream principal qui reçoit tous les événements
  final StreamController<AppEvent> _mainController = StreamController<AppEvent>.broadcast();
  
  /// Streams typés pour des abonnements optimisés
  late final StreamController<TransactionEvent> _transactionController;
  late final StreamController<AccountEvent> _accountController;
  late final StreamController<GlobalAppEvent> _globalController;
  
  /// Statistiques d'événements (pour debugging et monitoring)
  final Map<String, int> _eventCounts = <String, int>{};
  final List<AppEvent> _recentEvents = <AppEvent>[];
  static const int _maxRecentEvents = 50;
  
  /// Flag pour activer/désactiver le logging
  bool _loggingEnabled = kDebugMode;
  
  void _initializeEventTracking() {
    _transactionController = StreamController<TransactionEvent>.broadcast();
    _accountController = StreamController<AccountEvent>.broadcast();
    _globalController = StreamController<GlobalAppEvent>.broadcast();
    
    // Écouteur principal pour distribuer les événements dans les streams typés
    _mainController.stream.listen(_distributeEvent, onError: _handleStreamError);
  }
  
  /// Distribue un événement vers le stream approprié selon son type
  void _distributeEvent(AppEvent event) {
    try {
      // Mettre à jour les statistiques
      _updateEventStats(event);
      
      // Ajouter à l'historique récent
      _addToRecentEvents(event);
      
      // Log en mode debug
      if (_loggingEnabled) {
        _logEvent(event);
      }
      
      // Distribution vers les streams typés
      switch (event) {
        case TransactionEvent transactionEvent:
          _transactionController.add(transactionEvent);
          break;
        case AccountEvent accountEvent:
          _accountController.add(accountEvent);
          break;
        case GlobalAppEvent globalEvent:
          _globalController.add(globalEvent);
          break;
        default:
          if (kDebugMode) {
            print('⚠️ AppEventBus: Unknown event type: ${event.runtimeType}');
          }
      }
    } catch (e, stackTrace) {
      _handleEventDistributionError(event, e, stackTrace);
    }
  }
  
  /// Met à jour les statistiques d'événements
  void _updateEventStats(AppEvent event) {
    final eventType = event.runtimeType.toString();
    _eventCounts[eventType] = (_eventCounts[eventType] ?? 0) + 1;
  }
  
  /// Ajoute un événement à l'historique récent (FIFO)
  void _addToRecentEvents(AppEvent event) {
    _recentEvents.add(event);
    if (_recentEvents.length > _maxRecentEvents) {
      _recentEvents.removeAt(0);
    }
  }
  
  /// Log un événement en mode debug
  void _logEvent(AppEvent event) {
    final timestamp = event.timestamp.toIso8601String().split('T')[1].substring(0, 12);
    print('🔔 EventBus [$timestamp] ${event.runtimeType}: ${event.eventId}');
  }
  
  /// Gère les erreurs de distribution d'événements
  void _handleEventDistributionError(AppEvent event, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      print('❌ EventBus: Error distributing event ${event.runtimeType}: $error');
      print('StackTrace: $stackTrace');
    }
    
    // Créer un événement d'erreur global
    final errorEvent = AppEventFactory.createGlobalErrorEvent(
      errorMessage: 'Event distribution failed: $error',
      error: error,
      stackTrace: stackTrace,
      context: 'EventBus.distributeEvent',
    );
    
    // Éviter la récursion en envoyant directement au stream global
    _globalController.add(errorEvent);
  }
  
  /// Gère les erreurs de stream
  void _handleStreamError(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      print('❌ EventBus: Stream error: $error');
      print('StackTrace: $stackTrace');
    }
  }
  
  // ============================================================================
  // API PUBLIQUE - PUBLICATION D'ÉVÉNEMENTS
  // ============================================================================
  
  /// Publie un événement sur le bus
  /// 
  /// L'événement sera automatiquement distribué vers les streams appropriés
  /// et les abonnés recevront la notification
  void fire(AppEvent event) {
    if (_mainController.isClosed) {
      if (kDebugMode) {
        print('⚠️ EventBus: Cannot fire event, bus is closed: ${event.runtimeType}');
      }
      return;
    }
    
    try {
      _mainController.add(event);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ EventBus: Error firing event ${event.runtimeType}: $e');
        print('StackTrace: $stackTrace');
      }
    }
  }
  
  // ============================================================================
  // API PUBLIQUE - ABONNEMENT AUX ÉVÉNEMENTS
  // ============================================================================
  
  /// Stream de tous les événements (utilisé rarement)
  Stream<AppEvent> get allEvents => _mainController.stream;
  
  /// Stream de tous les événements de transactions
  Stream<TransactionEvent> get transactionEvents => _transactionController.stream;
  
  /// Stream de tous les événements de comptes
  Stream<AccountEvent> get accountEvents => _accountController.stream;
  
  /// Stream de tous les événements globaux de l'app
  Stream<GlobalAppEvent> get globalEvents => _globalController.stream;
  
  /// Stream filtré par type d'événement spécifique
  /// 
  /// Usage: AppEventBus.instance.on() pour TransactionCreatedEvent
  Stream<T> on<T extends AppEvent>() {
    return _mainController.stream
        .where((event) => event is T)
        .cast<T>();
  }
  
  /// Stream filtré pour les événements de transaction d'un compte spécifique
  Stream<TransactionEvent> transactionEventsForAccount(int accountId) {
    return _transactionController.stream
        .where((event) => event.accountId == accountId);
  }
  
  /// Stream filtré pour les événements de compte spécifique
  Stream<AccountEvent> accountEventsForAccount(int accountId) {
    return _accountController.stream
        .where((event) => event.accountId == accountId);
  }
  
  // ============================================================================
  // API PUBLIQUE - MONITORING ET DEBUGGING
  // ============================================================================
  
  /// Active/désactive le logging des événements
  void setLoggingEnabled(bool enabled) {
    _loggingEnabled = enabled;
  }
  
  /// Retourne les statistiques d'événements
  Map<String, int> getEventStats() => Map.unmodifiable(_eventCounts);
  
  /// Retourne les événements récents
  List<AppEvent> getRecentEvents() => List.unmodifiable(_recentEvents);
  
  /// Efface les statistiques et l'historique
  void clearStats() {
    _eventCounts.clear();
    _recentEvents.clear();
  }
  
  /// Retourne le nombre total d'événements traités
  int get totalEventCount => _eventCounts.values.fold(0, (sum, count) => sum + count);
  
  /// Vérifie si le bus est actif
  bool get isActive => !_mainController.isClosed;
  
  // ============================================================================
  // GESTION DU CYCLE DE VIE
  // ============================================================================
  
  /// Ferme tous les streams (appelé lors de la fermeture de l'app)
  Future<void> dispose() async {
    await _mainController.close();
    await _transactionController.close();
    await _accountController.close();
    await _globalController.close();
    
    _eventCounts.clear();
    _recentEvents.clear();
    
    if (kDebugMode) {
      print('🔕 EventBus disposed');
    }
  }
  
  /// Reset complet du bus (utilisé principalement pour les tests)
  Future<void> reset() async {
    await dispose();
    _instance = null;
    // Une nouvelle instance sera créée au prochain appel à .instance
  }
}

/// Extension pour faciliter l'utilisation de l'Event Bus
extension AppEventBusExtension on AppEventBus {
  /// Raccourci pour publier un événement de création de transaction
  void fireTransactionCreated(Transaction transaction, int accountId, {String? context}) {
    fire(TransactionEventFactory.createTransactionCreatedEvent(
      transaction: transaction,
      accountId: accountId,
      context: context,
    ));
  }
  
  /// Raccourci pour publier un événement de sélection de compte
  void fireAccountSelected(int accountId, {int? previousAccountId, String? context}) {
    fire(AccountEventFactory.createAccountSelectedEvent(
      accountId: accountId,
      previousAccountId: previousAccountId,
      context: context,
    ));
  }
  
  /// Raccourci pour publier un événement d'erreur globale
  void fireGlobalError(String errorMessage, {Object? error, StackTrace? stackTrace, String? context}) {
    fire(AppEventFactory.createGlobalErrorEvent(
      errorMessage: errorMessage,
      error: error,
      stackTrace: stackTrace,
      context: context,
    ));
  }
}

