import 'package:flutter_test/flutter_test.dart';
import 'package:bankapp/core/constants/supported_currencies.dart';
import 'package:bankapp/core/services/currency_service.dart';
import 'package:bankapp/core/services/currency_conversion_service.dart';
import 'package:bankapp/domain/entities/currency.dart';
import 'package:bankapp/domain/entities/exchange_rate.dart';
import 'package:bankapp/domain/repositories/exchange_rate_repository.dart';
import 'package:bankapp/data/cache/cache_manager.dart';
import 'package:bankapp/data/repositories/exchange_rate_repository_impl.dart';
import 'package:bankapp/data/datasources/local/exchange_rate_local_datasource.dart';
import 'package:bankapp/data/datasources/remote/exchange_rate_remote_datasource.dart';

void main() {
  group('Currency Conversion System Tests', () {
    late CurrencyConversionService conversionService;
    late CacheManager cacheManager;

    setUp(() async {
      cacheManager = CacheManager.instance;
      
      // Create a mock repository since we can't easily test the full database setup
      final mockRepository = MockExchangeRateRepository();
      conversionService = CurrencyConversionService(cacheManager, mockRepository);
    });

    group('SupportedCurrencies Tests', () {
      test('should have all expected currencies', () {
        final currencies = SupportedCurrencies.all;
        
        expect(currencies.length, equals(36));
        
        // Vérifier quelques devises principales
        expect(currencies.any((c) => c.code == 'EUR'), isTrue);
        expect(currencies.any((c) => c.code == 'USD'), isTrue);
        expect(currencies.any((c) => c.code == 'GBP'), isTrue);
        expect(currencies.any((c) => c.code == 'JPY'), isTrue);
        expect(currencies.any((c) => c.code == 'CAD'), isTrue);
        expect(currencies.any((c) => c.code == 'AUD'), isTrue);
        expect(currencies.any((c) => c.code == 'CHF'), isTrue);
        expect(currencies.any((c) => c.code == 'CNY'), isTrue);
        
        // Vérifier quelques nouvelles devises
        expect(currencies.any((c) => c.code == 'HKD'), isTrue);
        expect(currencies.any((c) => c.code == 'SGD'), isTrue);
        expect(currencies.any((c) => c.code == 'KRW'), isTrue);
        expect(currencies.any((c) => c.code == 'INR'), isTrue);
        expect(currencies.any((c) => c.code == 'BRL'), isTrue);
        expect(currencies.any((c) => c.code == 'MXN'), isTrue);
        expect(currencies.any((c) => c.code == 'SEK'), isTrue);
        expect(currencies.any((c) => c.code == 'ZAR'), isTrue);
      });

      test('should separate major and minor currencies correctly', () {
        final majorCurrencies = SupportedCurrencies.major;
        final minorCurrencies = SupportedCurrencies.minor;
        
        expect(majorCurrencies.length, equals(8));
        expect(minorCurrencies.length, equals(28));
        
        // Major currencies should include the top 8 global currencies
        expect(majorCurrencies.any((c) => c.code == 'EUR'), isTrue);
        expect(majorCurrencies.any((c) => c.code == 'USD'), isTrue);
        expect(majorCurrencies.any((c) => c.code == 'GBP'), isTrue);
        expect(majorCurrencies.any((c) => c.code == 'JPY'), isTrue);
        expect(majorCurrencies.any((c) => c.code == 'CAD'), isTrue);
        expect(majorCurrencies.any((c) => c.code == 'AUD'), isTrue);
        expect(majorCurrencies.any((c) => c.code == 'CHF'), isTrue);
        expect(majorCurrencies.any((c) => c.code == 'CNY'), isTrue);
        
        // Minor currencies should include regional currencies
        expect(minorCurrencies.any((c) => c.code == 'HKD'), isTrue);
        expect(minorCurrencies.any((c) => c.code == 'SGD'), isTrue);
        expect(minorCurrencies.any((c) => c.code == 'KRW'), isTrue);
        expect(minorCurrencies.any((c) => c.code == 'INR'), isTrue);
        expect(minorCurrencies.any((c) => c.code == 'BRL'), isTrue);
        expect(minorCurrencies.any((c) => c.code == 'MXN'), isTrue);
      });

      test('should provide correct currency codes', () {
        final majorCodes = SupportedCurrencies.majorCodes;
        final minorCodes = SupportedCurrencies.minorCodes;
        
        expect(majorCodes, containsAll(['EUR', 'USD', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY']));
        expect(minorCodes, containsAll(['HKD', 'SGD', 'KRW', 'INR', 'BRL', 'MXN', 'SEK', 'ZAR']));
      });
    });

    group('CurrencyService Tests', () {
      test('should validate currencies correctly', () {
        expect(CurrencyService.isValidCurrency('EUR'), isTrue);
        expect(CurrencyService.isValidCurrency('USD'), isTrue);
        expect(CurrencyService.isValidCurrency('INVALID'), isFalse);
        expect(CurrencyService.isValidCurrency(''), isFalse);
      });

      test('should retrieve currency by code', () {
        final eurCurrency = CurrencyService.getCurrency('EUR');
        expect(eurCurrency, isNotNull);
        expect(eurCurrency!.code, equals('EUR'));
        expect(eurCurrency.symbol, equals('€'));

        final invalidCurrency = CurrencyService.getCurrency('INVALID');
        expect(invalidCurrency, isNull);
      });

      test('should provide all supported currencies', () {
        final currencies = CurrencyService.getAllCurrencies();
        expect(currencies.length, equals(36));
        
        final currencyCodes = currencies.map((c) => c.code).toList();
        expect(currencyCodes, containsAll(['EUR', 'USD', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'HKD', 'SGD', 'KRW', 'INR', 'BRL', 'MXN', 'SEK', 'ZAR']));
      });
    });

    group('Currency Entity Tests', () {
      test('should format amounts correctly', () {
        final eur = Currency(
          code: 'EUR',
          symbol: '€',
          nameKey: 'currency.eur',
          countryKey: 'country.eurozone',
        );

        expect(eur.formatAmount(1234.56), equals('€1,234.56'));
        expect(eur.formatAmount(0), equals('€0.00'));
        expect(eur.formatAmount(999.999), equals('€1,000.00'));
      });

      test('should compare currencies correctly', () {
        final eur1 = Currency(
          code: 'EUR',
          symbol: '€',
          nameKey: 'currency.eur',
          countryKey: 'country.eurozone',
        );

        final eur2 = Currency(
          code: 'EUR',
          symbol: '€',
          nameKey: 'currency.eur',
          countryKey: 'country.eurozone',
        );

        final usd = Currency(
          code: 'USD',
          symbol: '\$',
          nameKey: 'currency.usd',
          countryKey: 'country.usa',
        );

        expect(eur1 == eur2, isTrue);
        expect(eur1 == usd, isFalse);
        expect(eur1.hashCode == eur2.hashCode, isTrue);
      });
    });

    group('ExchangeRate Entity Tests', () {
      test('should create exchange rate with default expiration', () {
        final rate = ExchangeRate.withDefaultExpiration(
          fromCurrency: 'EUR',
          toCurrency: 'USD',
          rate: 1.2345,
        );

        expect(rate.fromCurrency, equals('EUR'));
        expect(rate.toCurrency, equals('USD'));
        expect(rate.rate, equals(1.2345));
        expect(rate.isValid, isTrue);
      });

      test('should create exchange rate with custom expiration', () {
        final futureTime = DateTime.now().add(const Duration(hours: 2));
        final rate = ExchangeRate.withCustomExpiration(
          fromCurrency: 'GBP',
          toCurrency: 'JPY',
          rate: 150.0,
          expirationDuration: const Duration(hours: 2),
        );

        expect(rate.fromCurrency, equals('GBP'));
        expect(rate.toCurrency, equals('JPY'));
        expect(rate.rate, equals(150.0));
        expect(rate.isValid, isTrue);
        expect(rate.expiresAt.isAfter(futureTime.subtract(const Duration(seconds: 1))), isTrue);
      });

      test('should validate exchange rates correctly', () {
        final validRate = ExchangeRate.withDefaultExpiration(
          fromCurrency: 'EUR',
          toCurrency: 'USD',
          rate: 1.2,
        );

        expect(validRate.isValid, isTrue);

        // Test expired rate
        final expiredRate = ExchangeRate(
          fromCurrency: 'EUR',
          toCurrency: 'USD',
          rate: 1.2,
          lastUpdated: DateTime.now().subtract(const Duration(hours: 25)),
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        expect(expiredRate.isValid, isFalse);
      });

      test('should convert amounts correctly', () {
        final rate = ExchangeRate.withDefaultExpiration(
          fromCurrency: 'EUR',
          toCurrency: 'USD',
          rate: 1.2345,
        );

        expect(rate.convertAmount(100), equals(123.45));
        expect(rate.convertAmount(0), equals(0));
        expect(rate.convertAmount(1), equals(1.2345));
      });

      test('should handle invalid rates in conversion', () {
        expect(() => ExchangeRate.withDefaultExpiration(
          fromCurrency: 'EUR',
          toCurrency: 'USD',
          rate: 0,
        ), throwsArgumentError);

        expect(() => ExchangeRate.withDefaultExpiration(
          fromCurrency: 'EUR',
          toCurrency: 'USD',
          rate: -1,
        ), throwsArgumentError);
      });
    });

    group('CurrencyConversionService Tests', () {
      test('should handle same currency conversion', () async {
        final result = await conversionService.convertAmount(
          amount: 100,
          fromCurrency: 'EUR',
          toCurrency: 'EUR',
        );

        expect(result.isSuccess, isTrue);
        expect(result.convertedAmount, equals(100));
        expect(result.exchangeRate, equals(1.0));
        expect(result.source, equals(ConversionSource.identity));
      });

      test('should validate input parameters', () async {
        // Test negative amount
        final negativeResult = await conversionService.convertAmount(
          amount: -100,
          fromCurrency: 'EUR',
          toCurrency: 'USD',
        );
        expect(negativeResult.isSuccess, isFalse);
        expect(negativeResult.errorMessage, contains('cannot be negative'));

        // Test invalid from currency
        final invalidFromResult = await conversionService.convertAmount(
          amount: 100,
          fromCurrency: 'INVALID',
          toCurrency: 'USD',
        );
        expect(invalidFromResult.isSuccess, isFalse);
        expect(invalidFromResult.errorMessage, contains('not supported'));

        // Test invalid to currency
        final invalidToResult = await conversionService.convertAmount(
          amount: 100,
          fromCurrency: 'EUR',
          toCurrency: 'INVALID',
        );
        expect(invalidToResult.isSuccess, isFalse);
        expect(invalidToResult.errorMessage, contains('not supported'));
      });

      test('should convert amount safely', () async {
        // Test successful conversion (same currency)
        final result = await conversionService.convertAmountSafe(
          amount: 100,
          fromCurrency: 'EUR',
          toCurrency: 'EUR',
        );
        expect(result, equals(100));

        // Test failed conversion
        final failedResult = await conversionService.convertAmountSafe(
          amount: -100,
          fromCurrency: 'EUR',
          toCurrency: 'USD',
        );
        expect(failedResult, isNull);
      });
    });

    group('ConversionResult Tests', () {
      test('should create success result', () {
        final result = ConversionResult.success(
          originalAmount: 100,
          convertedAmount: 123.45,
          fromCurrency: 'EUR',
          toCurrency: 'USD',
          exchangeRate: 1.2345,
          source: ConversionSource.api,
        );

        expect(result.isSuccess, isTrue);
        expect(result.originalAmount, equals(100));
        expect(result.convertedAmount, equals(123.45));
        expect(result.fromCurrency, equals('EUR'));
        expect(result.toCurrency, equals('USD'));
        expect(result.exchangeRate, equals(1.2345));
        expect(result.source, equals(ConversionSource.api));
      });

      test('should create error result', () {
        final result = ConversionResult.error('Test error message');

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, equals('Test error message'));
        expect(result.originalAmount, isNull);
        expect(result.convertedAmount, isNull);
      });

      test('should generate correct display messages', () {
        final successResult = ConversionResult.success(
          originalAmount: 100,
          convertedAmount: 123.45,
          fromCurrency: 'EUR',
          toCurrency: 'USD',
          exchangeRate: 1.2345,
          source: ConversionSource.api,
        );

        final displayMessage = successResult.getDisplayMessage();
        expect(displayMessage, contains('100.00 EUR'));
        expect(displayMessage, contains('123.45 USD'));
        expect(displayMessage, contains('1.2345'));

        final errorResult = ConversionResult.error('Test error');
        expect(errorResult.getDisplayMessage(), equals('Test error'));
      });
    });

    group('ConversionSource Tests', () {
      test('should provide correct descriptions', () {
        expect(ConversionSource.identity.description, equals('Same currency'));
        expect(ConversionSource.cache.description, equals('Cached rate'));
        expect(ConversionSource.api.description, equals('Live rate'));
      });

      test('should indicate reliability correctly', () {
        expect(ConversionSource.identity.isReliable, isTrue);
        expect(ConversionSource.cache.isReliable, isTrue);
        expect(ConversionSource.api.isReliable, isTrue);
      });
    });

    group('Performance Tests', () {
      test('should handle multiple conversions efficiently', () async {
        final stopwatch = Stopwatch()..start();
        
        // Perform multiple same-currency conversions
        for (int i = 0; i < 100; i++) {
          final result = await conversionService.convertAmount(
            amount: 100.0 + i,
            fromCurrency: 'EUR',
            toCurrency: 'EUR',
          );
          expect(result.isSuccess, isTrue);
        }
        
        stopwatch.stop();
        
        // Should complete within reasonable time (less than 1 second)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('should cache currency lookups efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        // Perform multiple currency lookups
        for (int i = 0; i < 1000; i++) {
          final currency = CurrencyService.getCurrency('EUR');
          expect(currency, isNotNull);
        }
        
        stopwatch.stop();
        
        // Should complete very quickly (less than 100ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('Edge Cases', () {
      test('should handle very large amounts', () async {
        final result = await conversionService.convertAmount(
          amount: 999999999.99,
          fromCurrency: 'EUR',
          toCurrency: 'EUR',
        );

        expect(result.isSuccess, isTrue);
        expect(result.convertedAmount, equals(999999999.99));
      });

      test('should handle very small amounts', () async {
        final result = await conversionService.convertAmount(
          amount: 0.01,
          fromCurrency: 'EUR',
          toCurrency: 'EUR',
        );

        expect(result.isSuccess, isTrue);
        expect(result.convertedAmount, equals(0.01));
      });

      test('should handle zero amount', () async {
        final result = await conversionService.convertAmount(
          amount: 0,
          fromCurrency: 'EUR',
          toCurrency: 'EUR',
        );

        expect(result.isSuccess, isTrue);
        expect(result.convertedAmount, equals(0));
      });

      test('should handle currency code case sensitivity', () {
        expect(CurrencyService.isValidCurrency('EUR'), isTrue);
        expect(CurrencyService.isValidCurrency('eur'), isFalse);
        expect(CurrencyService.isValidCurrency('Eur'), isFalse);
      });

      test('should handle empty currency codes', () {
        expect(CurrencyService.isValidCurrency(''), isFalse);
        expect(CurrencyService.getCurrency(''), isNull);
      });
    });

    group('Integration Tests', () {
      test('should validate all currency combinations', () {
        final currencies = SupportedCurrencies.all;
        
        for (final currency in currencies) {
          expect(CurrencyService.isValidCurrency(currency.code), isTrue);
          expect(CurrencyService.getCurrency(currency.code), isNotNull);
        }
      });
    });
  });
}

/// Mock implementation for testing
class MockExchangeRateRepository extends ExchangeRateRepository {
  @override
  Future<double> convertAmount(double amount, String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return amount;
    // Return a mock conversion rate
    return amount * 1.2;
  }

  @override
  Future<ExchangeRate?> getExchangeRate(String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) {
      return ExchangeRate.withDefaultExpiration(
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        rate: 1.0,
      );
    }
    return null;
  }

  @override
  Future<List<ExchangeRate>> getExchangeRates(String baseCurrency) async {
    return [];
  }

  @override
  Future<List<ExchangeRate>> getAllValidRates() async {
    return [];
  }

  @override
  Future<void> updateExchangeRates(String baseCurrency) async {
    // Mock implementation
  }

  @override
  Future<bool> isExchangeRateAvailable(String fromCurrency, String toCurrency) async {
    return fromCurrency == toCurrency;
  }

  @override
  Future<DateTime?> getLastUpdateTime(String fromCurrency, String toCurrency) async {
    return DateTime.now();
  }

  @override
  Future<void> cleanupExpiredRates() async {
    // Mock implementation
  }

  @override
  Future<List<String>> getAvailableBaseCurrencies() async {
    return ['EUR', 'USD', 'GBP', 'JPY'];
  }

  @override
  Future<List<String>> getTargetCurrencies(String baseCurrency) async {
    return ['EUR', 'USD', 'GBP', 'JPY'];
  }

  @override
  Future<bool> isApiAvailable() async {
    return true;
  }

  @override
  Future<Map<String, int>> getCacheStatistics() async {
    return {'total': 0, 'valid': 0, 'expired': 0};
  }
}