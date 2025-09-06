import 'dart:convert';
import 'dart:io';

import 'package:bankapp/core/utils/app_logger.dart';
import 'package:bankapp/domain/entities/entities.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service pour rechercher des logos via l'API Brandfetch
class BrandfetchService with AppLoggerMixin {
  final http.Client _client;

  /// URL de base de l'API Brandfetch
  static String get _baseUrl =>
      dotenv.env['BRANDFETCH_API_BASE_URL'] ?? 'https://api.brandfetch.io/v2/search';

  /// Clés d'API Brandfetch (rotation entre les 3)
  static List<String> get _apiKeys => [
        dotenv.env['BRANDFETCH_API_KEY_1'] ?? '',
        dotenv.env['BRANDFETCH_API_KEY_2'] ?? '',
        dotenv.env['BRANDFETCH_API_KEY_3'] ?? '',
      ].where((key) => key.isNotEmpty).toList();

  /// Timeout pour les requêtes HTTP
  static const Duration _timeout = Duration(seconds: 15);

  /// Throttling : délai minimum entre les requêtes
  static const Duration _throttleDuration = Duration(seconds: 3);

  /// Index de la clé API actuelle (pour rotation)
  static int _currentKeyIndex = 0;

  /// Timestamp de la dernière requête (pour throttling)
  static DateTime? _lastRequestTime;

  BrandfetchService({http.Client? client}) : _client = client ?? http.Client();

  /// Recherche des logos par nom/mot-clé
  Future<BrandfetchResponse> searchLogos(String query) async {
    if (query.trim().isEmpty) {
      throw BrandfetchException('Query cannot be empty');
    }

    final startTime = DateTime.now();
    
    // Log début recherche
    logInfo('searchLogos', 'Brandfetch search for: "$query"');

    // Appliquer le throttling
    await _applyThrottling();

    // Essayer avec chaque clé API si nécessaire
    BrandfetchException? lastException;
    
    for (int attempt = 0; attempt < _apiKeys.length; attempt++) {
      try {
        final apiKey = _getNextApiKey();
        final response = await _makeRequest(query, apiKey);
        final duration = DateTime.now().difference(startTime);

        logInfo('searchLogos', 'Brandfetch search success for "$query" (${response.logos.length} results) in ${duration.inMilliseconds}ms');
        
        return response;
      } catch (e) {
        lastException = e is BrandfetchException ? e : BrandfetchException('Search failed: $e');
        logWarning('searchLogos', 'Brandfetch search attempt ${attempt + 1} failed for "$query": $lastException');
        
        // Si ce n'est pas la dernière tentative, continuer
        if (attempt < _apiKeys.length - 1) {
          continue;
        }
      }
    }

    // Toutes les tentatives ont échoué
    final duration = DateTime.now().difference(startTime);
    logError('searchLogos', 'Brandfetch search failed for "$query" after ${_apiKeys.length} attempts in ${duration.inMilliseconds}ms', lastException ?? Exception('All API keys failed'));
    
    throw lastException ?? BrandfetchException('All API keys failed');
  }

  /// Applique le throttling (attente si nécessaire)
  Future<void> _applyThrottling() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _throttleDuration) {
        final waitTime = _throttleDuration - timeSinceLastRequest;
        logInfo('_applyThrottling', 'Brandfetch throttling: waiting ${waitTime.inMilliseconds}ms');
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Obtient la prochaine clé API dans la rotation
  String _getNextApiKey() {
    if (_apiKeys.isEmpty) {
      throw BrandfetchException('No API keys configured');
    }
    
    final apiKey = _apiKeys[_currentKeyIndex];
    _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
    return apiKey;
  }

  /// Effectue la requête HTTP vers l'API Brandfetch
  Future<BrandfetchResponse> _makeRequest(String query, String apiKey) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse('$_baseUrl/$encodedQuery?c=$apiKey');
      
      logInfo('_makeRequest', 'Requesting URL: $url');

      final response = await _client
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'BankApp/1.0',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body) as List<dynamic>;
        final logos = jsonList
            .map((json) => BrandLogo.fromJson(json as Map<String, dynamic>))
            .toList();

        return BrandfetchResponse(success: true, logos: logos);
      } else if (response.statusCode == 401) {
        throw BrandfetchAuthException('Invalid API key');
      } else if (response.statusCode == 429) {
        throw BrandfetchRateLimitException('Rate limit exceeded');
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'Unknown error';
        throw BrandfetchException('HTTP ${response.statusCode}: $errorBody');
      }
    } on SocketException catch (e) {
      throw BrandfetchNetworkException('No internet connection: ${e.message}');
    } on http.ClientException catch (e) {
      throw BrandfetchNetworkException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw BrandfetchParseException('Failed to parse response: ${e.message}');
    }
  }

  /// Vérifie si le service est disponible
  Future<bool> isServiceAvailable() async {
    try {
      final response = await searchLogos('test');
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _client.close();
  }
}

/// Réponse de l'API Brandfetch
class BrandfetchResponse {
  final bool success;
  final List<BrandLogo> logos;
  final String? error;

  const BrandfetchResponse({
    required this.success,
    required this.logos,
    this.error,
  });

  @override
  String toString() {
    return 'BrandfetchResponse(success: $success, logoCount: ${logos.length}, error: $error)';
  }
}

/// Exception de base pour les erreurs Brandfetch
abstract class BrandfetchBaseException implements Exception {
  final String message;

  const BrandfetchBaseException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Exception générique Brandfetch
class BrandfetchException extends BrandfetchBaseException {
  const BrandfetchException(super.message);
}

/// Exception d'authentification
class BrandfetchAuthException extends BrandfetchBaseException {
  const BrandfetchAuthException(super.message);
}

/// Exception de limite de taux
class BrandfetchRateLimitException extends BrandfetchBaseException {
  const BrandfetchRateLimitException(super.message);
}

/// Exception de réseau
class BrandfetchNetworkException extends BrandfetchBaseException {
  const BrandfetchNetworkException(super.message);
}

/// Exception de parsing
class BrandfetchParseException extends BrandfetchBaseException {
  const BrandfetchParseException(super.message);
}