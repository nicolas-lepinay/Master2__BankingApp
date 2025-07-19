import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Service pour appeler les Firebase Cloud Functions
class FirebaseFunctionsService {
  final http.Client _client;

  /// URL de base des Cloud Functions
  static const String _functionsBaseUrl =
      'https://europe-west6-exchange-rate-fetcher-app.cloudfunctions.net';

  /// Timeout pour les requêtes HTTP
  static const Duration _timeout = Duration(seconds: 15);

  FirebaseFunctionsService({http.Client? client})
    : _client = client ?? http.Client();

  /// Récupère les taux de change depuis la Cloud Function
  Future<FirebaseExchangeRatesResponse> getExchangeRates(
    String baseCurrency,
  ) async {
    try {
      final url = Uri.parse('$_functionsBaseUrl/getExchangeRates_v1');

      final requestBody = {'baseCurrency': baseCurrency.toUpperCase()};

      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(_timeout);

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return FirebaseExchangeRatesResponse.fromJson(responseData);
      } else {
        throw FirebaseFunctionException(
          'Firebase Function call failed with status ${response.statusCode}: ${responseData['error'] ?? 'Unknown error'}',
        );
      }
    } on SocketException {
      throw FirebaseFunctionNetworkException(
        'No internet connection available',
      );
    } on http.ClientException catch (e) {
      throw FirebaseFunctionNetworkException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw FirebaseFunctionParseException(
        'Failed to parse response: ${e.message}',
      );
    } catch (e) {
      if (e is FirebaseFunctionBaseException) {
        rethrow;
      }
      throw FirebaseFunctionException('Unexpected error: $e');
    }
  }

  /// Vérifie si les Firebase Functions sont disponibles
  Future<bool> isServiceAvailable() async {
    try {
      final response = await getExchangeRates('USD');
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

/// Réponse de la Cloud Function Firebase
class FirebaseExchangeRatesResponse {
  final bool success;
  final FirebaseExchangeRatesData? data;
  final String? error;
  final bool? cached;
  final String? warning;

  const FirebaseExchangeRatesResponse({
    required this.success,
    this.data,
    this.error,
    this.cached,
    this.warning,
  });

  factory FirebaseExchangeRatesResponse.fromJson(Map<String, dynamic> json) {
    return FirebaseExchangeRatesResponse(
      success: json['success'] as bool,
      data: json['data'] != null
          ? FirebaseExchangeRatesData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
      error: json['error'] as String?,
      cached: json['cached'] as bool?,
      warning: json['warning'] as String?,
    );
  }

  @override
  String toString() {
    return 'FirebaseExchangeRatesResponse(success: $success, cached: $cached, error: $error, warning: $warning)';
  }
}

/// Données des taux de change de la Cloud Function
class FirebaseExchangeRatesData {
  final String baseCurrency;
  final Map<String, double> rates;
  final DateTime lastUpdated;
  final double cacheAge;
  final String source;

  const FirebaseExchangeRatesData({
    required this.baseCurrency,
    required this.rates,
    required this.lastUpdated,
    required this.cacheAge,
    required this.source,
  });

  factory FirebaseExchangeRatesData.fromJson(Map<String, dynamic> json) {
    final ratesMap = json['rates'] as Map<String, dynamic>;
    final rates = <String, double>{};

    for (final entry in ratesMap.entries) {
      rates[entry.key] = (entry.value as num).toDouble();
    }

    return FirebaseExchangeRatesData(
      baseCurrency: json['baseCurrency'] as String,
      rates: rates,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      cacheAge: (json['cacheAge'] as num).toDouble(),
      source: json['source'] as String,
    );
  }

  @override
  String toString() {
    return 'FirebaseExchangeRatesData(baseCurrency: $baseCurrency, ratesCount: ${rates.length}, cacheAge: ${cacheAge}h, source: $source)';
  }
}

/// Exception de base pour les erreurs Firebase Functions
abstract class FirebaseFunctionBaseException implements Exception {
  final String message;

  const FirebaseFunctionBaseException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Exception pour les erreurs de Firebase Functions
class FirebaseFunctionException extends FirebaseFunctionBaseException {
  const FirebaseFunctionException(super.message);
}

/// Exception pour les erreurs de réseau
class FirebaseFunctionNetworkException extends FirebaseFunctionBaseException {
  const FirebaseFunctionNetworkException(super.message);
}

/// Exception pour les erreurs de parsing
class FirebaseFunctionParseException extends FirebaseFunctionBaseException {
  const FirebaseFunctionParseException(super.message);
}
