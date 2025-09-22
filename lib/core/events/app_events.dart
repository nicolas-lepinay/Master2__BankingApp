import 'package:equatable/equatable.dart';

/// Classe de base pour tous les événements de l'application
/// 
/// Cette architecture événementielle permet aux ViewModels de communiquer
/// de manière découplée, remplaçant les chaînes complexes d'invalidation
/// de providers avec _ref.invalidate()
abstract class AppEvent extends Equatable {
  /// Timestamp de création de l'événement
  final DateTime timestamp;
  
  /// Identifiant unique de l'événement pour le debugging
  final String eventId;
  
  const AppEvent({
    required this.timestamp,
    required this.eventId,
  });

  @override
  List<Object?> get props => [eventId, timestamp];
  
  @override
  String toString() => '$runtimeType(id: $eventId, timestamp: $timestamp)';
}

/// Événements globaux de l'application
abstract class GlobalAppEvent extends AppEvent {
  const GlobalAppEvent({
    required super.timestamp,
    required super.eventId,
  });
}

/// Événement de changement de thème
class ThemeChangedEvent extends GlobalAppEvent {
  final String themeName;
  
  const ThemeChangedEvent({
    required this.themeName,
    required super.timestamp,
    required super.eventId,
  });
  
  @override
  List<Object?> get props => [...super.props, themeName];
}

/// Événement de changement de langue
class LocaleChangedEvent extends GlobalAppEvent {
  final String localeCode;
  
  const LocaleChangedEvent({
    required this.localeCode,
    required super.timestamp,
    required super.eventId,
  });
  
  @override
  List<Object?> get props => [...super.props, localeCode];
}

/// Événement d'erreur globale
class GlobalErrorEvent extends GlobalAppEvent {
  final String errorMessage;
  final Object? error;
  final StackTrace? stackTrace;
  final String? context;
  
  const GlobalErrorEvent({
    required this.errorMessage,
    this.error,
    this.stackTrace,
    this.context,
    required super.timestamp,
    required super.eventId,
  });
  
  @override
  List<Object?> get props => [...super.props, errorMessage, error, context];
}

/// Événement de succès d'une opération
class SuccessEvent extends GlobalAppEvent {
  final String message;
  final String? context;
  
  const SuccessEvent({
    required this.message,
    this.context,
    required super.timestamp,
    required super.eventId,
  });
  
  @override
  List<Object?> get props => [...super.props, message, context];
}

/// Factory pour créer des événements avec des IDs uniques
class AppEventFactory {
  static int _counter = 0;
  
  /// Génère un ID unique pour un événement
  static String _generateEventId(String eventType) {
    _counter++;
    return '${eventType}_${DateTime.now().millisecondsSinceEpoch}_$_counter';
  }
  
  /// Crée un événement de changement de thème
  static ThemeChangedEvent createThemeChangedEvent(String themeName) {
    return ThemeChangedEvent(
      themeName: themeName,
      timestamp: DateTime.now(),
      eventId: _generateEventId('THEME_CHANGED'),
    );
  }
  
  /// Crée un événement de changement de langue
  static LocaleChangedEvent createLocaleChangedEvent(String localeCode) {
    return LocaleChangedEvent(
      localeCode: localeCode,
      timestamp: DateTime.now(),
      eventId: _generateEventId('LOCALE_CHANGED'),
    );
  }
  
  /// Crée un événement d'erreur globale
  static GlobalErrorEvent createGlobalErrorEvent({
    required String errorMessage,
    Object? error,
    StackTrace? stackTrace,
    String? context,
  }) {
    return GlobalErrorEvent(
      errorMessage: errorMessage,
      error: error,
      stackTrace: stackTrace,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('GLOBAL_ERROR'),
    );
  }
  
  /// Crée un événement de succès
  static SuccessEvent createSuccessEvent({
    required String message,
    String? context,
  }) {
    return SuccessEvent(
      message: message,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('SUCCESS'),
    );
  }
}