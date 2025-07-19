import 'dart:convert';
import 'dart:io';

import 'package:bankapp/core/services/firebase_functions_service.dart';
import 'package:bankapp/data/models/exchange_rate_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Interface pour le DataSource distant des taux de change
abstract class ExchangeRateRemoteDataSource {
  /// Récupère les taux de change depuis l'API
  Future<List<ExchangeRateModel>> getExchangeRates(String baseCurrency);

  /// Récupère un taux de change spécifique
  Future<ExchangeRateModel> getExchangeRate(
    String fromCurrency,
    String toCurrency,
  );

  /// Vérifie si l'API est disponible
  Future<bool> isApiAvailable();
}

/// Implémentation du DataSource distant utilisant Firebase Cloud Functions
class ExchangeRateRemoteDataSourceImpl implements ExchangeRateRemoteDataSource {
  final FirebaseFunctionsService _firebaseFunctionsService;
  final http.Client _client;

  /// URL de base de l'API ExchangeRate-API (fallback uniquement)
  static String get _baseUrl =>
      dotenv.env['EXCHANGE_RATE_API_BASE_URL'] ??
      'https://v6.exchangerate-api.com/v6';

  /// Clé API (fallback uniquement)
  static String get _apiKey => dotenv.env['EXCHANGE_RATE_API_KEY'] ?? '';

  /// Timeout pour les requêtes HTTP
  static const Duration _timeout = Duration(seconds: 10);

  ExchangeRateRemoteDataSourceImpl({
    FirebaseFunctionsService? firebaseFunctionsService,
    http.Client? client,
  }) : _firebaseFunctionsService =
           firebaseFunctionsService ?? FirebaseFunctionsService(),
       _client = client ?? http.Client();

  @override
  Future<List<ExchangeRateModel>> getExchangeRates(String baseCurrency) async {
    try {
      // 1. Essayer Firebase Cloud Functions d'abord
      final firebaseResponse = await _firebaseFunctionsService.getExchangeRates(
        baseCurrency,
      );

      if (firebaseResponse.success && firebaseResponse.data != null) {
        return _parseFirebaseResponse(firebaseResponse.data!, baseCurrency);
      } else {
        throw ExchangeRateApiException(
          'Firebase Function error: ${firebaseResponse.error}',
        );
      }
    } on FirebaseFunctionBaseException catch (e) {
      // 2. En cas d'erreur Firebase, essayer le fallback API directe
      print('Firebase Functions failed, trying direct API fallback: $e');
      return await _getExchangeRatesFromDirectApi(baseCurrency);
    } catch (e) {
      // 3. En cas d'erreur générale, essayer le fallback
      print('General error, trying direct API fallback: $e');
      return await _getExchangeRatesFromDirectApi(baseCurrency);
    }
  }

  /// Fallback : appel direct à l'API (utilisation exceptionnelle)
  Future<List<ExchangeRateModel>> _getExchangeRatesFromDirectApi(
    String baseCurrency,
  ) async {
    try {
      if (_apiKey.isEmpty) {
        throw ExchangeRateApiException(
          'Both Firebase Functions and direct API failed. API key is missing.',
        );
      }

      final url = Uri.parse('$_baseUrl/$_apiKey/latest/$baseCurrency');

      final response = await _client.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return _parseExchangeRatesResponse(data, baseCurrency);
      } else {
        throw ExchangeRateApiException(
          'Direct API request failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } on SocketException {
      throw ExchangeRateNetworkException('No internet connection available');
    } on http.ClientException catch (e) {
      throw ExchangeRateNetworkException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw ExchangeRateParseException(
        'Failed to parse API response: ${e.message}',
      );
    } catch (e) {
      throw ExchangeRateApiException('Unexpected error in direct API: $e');
    }
  }

  @override
  Future<ExchangeRateModel> getExchangeRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    final rates = await getExchangeRates(fromCurrency);

    try {
      return rates.firstWhere((rate) => rate.toCurrency == toCurrency);
    } catch (e) {
      throw ExchangeRateNotFoundException(
        'Exchange rate from $fromCurrency to $toCurrency not found',
      );
    }
  }

  @override
  Future<bool> isApiAvailable() async {
    try {
      if (_apiKey.isEmpty) {
        return false;
      }

      final url = Uri.parse('$_baseUrl/$_apiKey/latest/EUR');
      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Parse la réponse Firebase en liste d'ExchangeRateModel
  List<ExchangeRateModel> _parseFirebaseResponse(
    FirebaseExchangeRatesData data,
    String baseCurrency,
  ) {
    final rates = <ExchangeRateModel>[];

    // Calculer l'expiration basée sur l'âge du cache
    final expiresAt = data.lastUpdated.add(const Duration(hours: 24));

    for (final entry in data.rates.entries) {
      final toCurrency = entry.key;
      final rate = entry.value;

      rates.add(
        ExchangeRateModel(
          fromCurrency: baseCurrency,
          toCurrency: toCurrency,
          rate: rate,
          lastUpdated: data.lastUpdated,
          expiresAt: expiresAt,
        ),
      );
    }

    return rates;
  }

  /// Parse la réponse de l'API en liste d'ExchangeRateModel
  List<ExchangeRateModel> _parseExchangeRatesResponse(
    Map<String, dynamic> data,
    String baseCurrency,
  ) {
    final rates = <ExchangeRateModel>[];

    // Vérifier le résultat
    final result = data['result'] as String?;
    if (result != 'success') {
      throw ExchangeRateParseException(
        'API request failed: ${data['error-type'] ?? 'Unknown error'}',
      );
    }

    final ratesMap = data['conversion_rates'] as Map<String, dynamic>?;

    if (ratesMap == null) {
      throw ExchangeRateParseException(
        'No conversion_rates found in API response',
      );
    }

    // Utiliser le timestamp Unix fourni par l'API (en secondes)
    final timestamp = data['time_last_update_unix'] as int?;
    final lastUpdated = timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
        : DateTime.now();

    // Calculer l'expiration basée sur le prochain update
    final nextUpdateTimestamp = data['time_next_update_unix'] as int?;
    final expiresAt = nextUpdateTimestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(nextUpdateTimestamp * 1000)
        : lastUpdated.add(const Duration(hours: 24)); // Fallback à 24h

    for (final entry in ratesMap.entries) {
      final toCurrency = entry.key;
      final rate = (entry.value as num).toDouble();

      rates.add(
        ExchangeRateModel(
          fromCurrency: baseCurrency,
          toCurrency: toCurrency,
          rate: rate,
          lastUpdated: lastUpdated,
          expiresAt: expiresAt,
        ),
      );
    }

    return rates;
  }

  /// Nettoie les ressources
  void dispose() {
    _client.close();
  }
}

/// Exception de base pour les erreurs de l'API de taux de change
abstract class ExchangeRateApiBaseException implements Exception {
  final String message;

  const ExchangeRateApiBaseException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Exception pour les erreurs de l'API
class ExchangeRateApiException extends ExchangeRateApiBaseException {
  const ExchangeRateApiException(super.message);
}

/// Exception pour les erreurs de réseau
class ExchangeRateNetworkException extends ExchangeRateApiBaseException {
  const ExchangeRateNetworkException(super.message);
}

/// Exception pour les erreurs de parsing
class ExchangeRateParseException extends ExchangeRateApiBaseException {
  const ExchangeRateParseException(super.message);
}

/// Exception quand un taux de change n'est pas trouvé
class ExchangeRateNotFoundException extends ExchangeRateApiBaseException {
  const ExchangeRateNotFoundException(super.message);
}
