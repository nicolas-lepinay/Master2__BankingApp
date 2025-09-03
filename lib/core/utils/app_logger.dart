import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Système de logging professionnel pour tracker les taux de change
/// Logs uniquement en mode debug avec format standardisé
class AppLogger {
  AppLogger._();

  /// Format: [Timestamp] Icon Category | Class.method() → Message
  static void _log(
    LogCategory category,
    String className,
    String methodName,
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Logs uniquement en mode debug
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String().substring(
      11,
      23,
    ); // HH:mm:ss.SSS
    final icon = category.icon;
    final categoryName = category.name;
    final location = '$className.$methodName()';

    final logMessage =
        '[$timestamp] $icon $categoryName  |  $location  →  $message';

    // Utiliser developer.log pour de meilleures performances et intégration DevTools
    developer.log(
      logMessage,
      name: 'ExchangeRates',
      level: level.value,
      error: error,
      stackTrace: stackTrace,
    );

    // Fallback debugPrint pour compatibilité (si DevTools non disponible)
    if (kDebugMode) {
      debugPrint(logMessage);
      // Force print pour IntelliJ debugging
      // ignore: avoid_print
      //print(logMessage);
      if (error != null) {
        debugPrint('  ❌ Error: $error');
        // ignore: avoid_print
        //print('  ❌ Error: $error');
      }
    }
  }

  // ================== FIREBASE FUNCTIONS ==================

  /// Log avant appel Firebase Cloud Function
  static void firebaseCall(
    String className,
    String methodName,
    String baseCurrency, {
    String? reason,
  }) {
    final reasonText = reason != null ? ' ($reason)' : '';
    _log(
      LogCategory.firebaseFunction,
      className,
      methodName,
      'Calling Firebase Function for $baseCurrency$reasonText',
    );
  }

  /// Log succès Firebase Cloud Function
  static void firebaseSuccess(
    String className,
    String methodName,
    String baseCurrency,
    int ratesCount,
    Duration duration, {
    bool cached = false,
  }) {
    final source = cached ? 'cached' : 'fresh';
    _log(
      LogCategory.firebaseFunction,
      className,
      methodName,
      'Firebase success: $ratesCount rates for $baseCurrency ($source, ${duration.inMilliseconds}ms)',
    );
  }

  /// Log échec Firebase Cloud Function
  static void firebaseError(
    String className,
    String methodName,
    String baseCurrency,
    String error,
    Duration duration,
  ) {
    _log(
      LogCategory.firebaseFunction,
      className,
      methodName,
      'Firebase error for $baseCurrency after ${duration.inMilliseconds}ms',
      level: LogLevel.warning,
      error: error,
    );
  }

  // ================== CACHE OPERATIONS ==================

  /// Log lecture cache réussie
  static void cacheHit(
    String className,
    String methodName,
    String fromCurrency,
    String toCurrency, {
    double? rate,
    double? ageHours,
  }) {
    final rateText = rate != null ? ', rate: $rate' : '';
    final ageText = ageHours != null
        ? ', age: ${ageHours.toStringAsFixed(1)}h'
        : '';
    _log(
      LogCategory.cacheHit,
      className,
      methodName,
      'Found $fromCurrency→$toCurrency$rateText$ageText',
    );
  }

  /// Log cache vide/manqué
  static void cacheMiss(
    String className,
    String methodName,
    String fromCurrency,
    String toCurrency, {
    String? reason,
  }) {
    final reasonText = reason != null ? ' ($reason)' : '';
    _log(
      LogCategory.cacheMiss,
      className,
      methodName,
      'Miss $fromCurrency→$toCurrency$reasonText',
      level: LogLevel.warning,
    );
  }

  /// Log mise à jour du cache
  static void cacheUpdate(
    String className,
    String methodName,
    String baseCurrency,
    int ratesCount, {
    DateTime? expiresAt,
  }) {
    final expiresText = expiresAt != null
        ? ', expires: ${expiresAt.toIso8601String().substring(11, 19)}'
        : '';
    _log(
      LogCategory.cacheUpdate,
      className,
      methodName,
      'Saved $ratesCount rates for $baseCurrency$expiresText',
    );
  }

  /// Log nettoyage du cache
  static void cacheCleanup(
    String className,
    String methodName,
    int deletedCount,
  ) {
    _log(
      LogCategory.cacheUpdate,
      className,
      methodName,
      'Cleaned up $deletedCount expired rates',
    );
  }

  // ================== SMART OPERATIONS ==================

  /// Log détection devise locale
  static void localeDetected(
    String className,
    String methodName,
    String countryCode,
    String currency,
  ) {
    _log(
      LogCategory.smartLogic,
      className,
      methodName,
      'Detected locale: $countryCode → $currency',
    );
  }

  /// Log stratégie de mise à jour
  static void updateStrategy(
    String className,
    String methodName,
    String strategy,
    List<String> currencies,
  ) {
    _log(
      LogCategory.smartLogic,
      className,
      methodName,
      'Strategy: $strategy for ${currencies.join(", ")} (${currencies.length} currencies)',
    );
  }

  /// Log timeout ou abandon
  static void timeout(
    String className,
    String methodName,
    Duration duration,
    String reason,
  ) {
    _log(
      LogCategory.smartLogic,
      className,
      methodName,
      'Timeout after ${duration.inMilliseconds}ms: $reason',
      level: LogLevel.warning,
    );
  }

  // ================== APP LIFECYCLE ==================

  /// Log initialisation app
  static void appInit(
    String className,
    String methodName,
    String step,
    double progress,
  ) {
    _log(
      LogCategory.appLifecycle,
      className,
      methodName,
      '$step (${(progress * 100).toStringAsFixed(0)}%)',
    );
  }

  /// Log création de compte
  static void accountCreated(
    String className,
    String methodName,
    String accountName,
    String currency,
  ) {
    _log(
      LogCategory.appLifecycle,
      className,
      methodName,
      'Account created: "$accountName" ($currency)',
    );
  }

  // ================== STATISTICS ==================

  /// Log statistiques globales
  static void statistics(
    String className,
    String methodName,
    Map<String, dynamic> stats,
  ) {
    final statsText = stats.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
    _log(LogCategory.statistics, className, methodName, 'Stats: $statsText');
  }

  /// Log quotas Firebase
  static void quota(
    String className,
    String methodName,
    int callsThisMonth,
    int maxCalls,
  ) {
    final percentage = ((callsThisMonth / maxCalls) * 100).toStringAsFixed(1);
    _log(
      LogCategory.statistics,
      className,
      methodName,
      'Firebase quota: $callsThisMonth/$maxCalls ($percentage%)',
      level: callsThisMonth > maxCalls * 0.8 ? LogLevel.warning : LogLevel.info,
    );
  }

  // ================== GENERIC METHODS ==================

  /// Log d'information générale
  static void info(String className, String methodName, String message) {
    _log(LogCategory.info, className, methodName, message);
  }

  /// Log d'avertissement
  static void warning(
    String className,
    String methodName,
    String message, {
    Object? error,
  }) {
    _log(
      LogCategory.info,
      className,
      methodName,
      message,
      level: LogLevel.warning,
      error: error,
    );
  }

  /// Log d'erreur
  static void error(
    String className,
    String methodName,
    String message,
    Object error, {
    StackTrace? stackTrace,
  }) {
    _log(
      LogCategory.info,
      className,
      methodName,
      message,
      level: LogLevel.error,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Catégories de logs avec icônes pour identification visuelle
enum LogCategory {
  firebaseFunction('🔥', 'FirebaseFunction'),
  cacheHit('✅', 'CacheHit'),
  cacheMiss('❌', 'CacheMiss'),
  cacheUpdate('📦', 'CacheUpdate'),
  smartLogic('🧠', 'SmartLogic'),
  appLifecycle('📱', 'AppLifecycle'),
  statistics('📊', 'Statistics'),
  info('ℹ️', 'Info');

  const LogCategory(this.icon, this.name);
  final String icon;
  final String name;
}

/// Niveaux de logs
enum LogLevel {
  info(800),
  warning(900),
  error(1000);

  const LogLevel(this.value);
  final int value;
}

/// Mixin pour faciliter l'utilisation dans les classes
mixin AppLoggerMixin {
  /// Nom de la classe pour les logs
  String get _className => runtimeType.toString();

  /// Log appel Firebase
  void logFirebaseCall(String method, String currency, {String? reason}) {
    AppLogger.firebaseCall(_className, method, currency, reason: reason);
  }

  /// Log succès Firebase
  void logFirebaseSuccess(
    String method,
    String currency,
    int count,
    Duration duration, {
    bool cached = false,
  }) {
    AppLogger.firebaseSuccess(
      _className,
      method,
      currency,
      count,
      duration,
      cached: cached,
    );
  }

  /// Log erreur Firebase
  void logFirebaseError(
    String method,
    String currency,
    String error,
    Duration duration,
  ) {
    AppLogger.firebaseError(_className, method, currency, error, duration);
  }

  /// Log cache hit
  void logCacheHit(
    String method,
    String from,
    String to, {
    double? rate,
    double? age,
  }) {
    AppLogger.cacheHit(_className, method, from, to, rate: rate, ageHours: age);
  }

  /// Log cache miss
  void logCacheMiss(String method, String from, String to, {String? reason}) {
    AppLogger.cacheMiss(_className, method, from, to, reason: reason);
  }

  /// Log mise à jour cache
  void logCacheUpdate(
    String method,
    String currency,
    int count, {
    DateTime? expires,
  }) {
    AppLogger.cacheUpdate(
      _className,
      method,
      currency,
      count,
      expiresAt: expires,
    );
  }

  /// Log info générale
  void logInfo(String method, String message) {
    AppLogger.info(_className, method, message);
  }

  /// Log warning
  void logWarning(String method, String message, {Object? error}) {
    AppLogger.warning(_className, method, message, error: error);
  }

  /// Log error
  void logError(
    String method,
    String message,
    Object error, {
    StackTrace? stackTrace,
  }) {
    AppLogger.error(_className, method, message, error, stackTrace: stackTrace);
  }
}

/// Extension pour faciliter l'utilisation dans les classes
extension AppLoggerExtension on Object {
  /// Nom de la classe pour les logs
  String get _className => runtimeType.toString();

  /// Log appel Firebase
  void logFirebaseCall(String method, String currency, {String? reason}) {
    AppLogger.firebaseCall(_className, method, currency, reason: reason);
  }

  /// Log succès Firebase
  void logFirebaseSuccess(
    String method,
    String currency,
    int count,
    Duration duration, {
    bool cached = false,
  }) {
    AppLogger.firebaseSuccess(
      _className,
      method,
      currency,
      count,
      duration,
      cached: cached,
    );
  }

  /// Log erreur Firebase
  void logFirebaseError(
    String method,
    String currency,
    String error,
    Duration duration,
  ) {
    AppLogger.firebaseError(_className, method, currency, error, duration);
  }

  /// Log cache hit
  void logCacheHit(
    String method,
    String from,
    String to, {
    double? rate,
    double? age,
  }) {
    AppLogger.cacheHit(_className, method, from, to, rate: rate, ageHours: age);
  }

  /// Log cache miss
  void logCacheMiss(String method, String from, String to, {String? reason}) {
    AppLogger.cacheMiss(_className, method, from, to, reason: reason);
  }

  /// Log mise à jour cache
  void logCacheUpdate(
    String method,
    String currency,
    int count, {
    DateTime? expires,
  }) {
    AppLogger.cacheUpdate(
      _className,
      method,
      currency,
      count,
      expiresAt: expires,
    );
  }

  /// Log info générale
  void logInfo(String method, String message) {
    AppLogger.info(_className, method, message);
  }

  /// Log warning
  void logWarning(String method, String message, {Object? error}) {
    AppLogger.warning(_className, method, message, error: error);
  }

  /// Log error
  void logError(
    String method,
    String message,
    Object error, {
    StackTrace? stackTrace,
  }) {
    AppLogger.error(_className, method, message, error, stackTrace: stackTrace);
  }
}
