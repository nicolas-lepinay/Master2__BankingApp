class AppConstants {
  // Transaction types
  static const String transactionTypeDebit = 'DEBIT';
  static const String transactionTypeCredit = 'CREDIT';

  // Transaction status
  static const int transactionStatusPending = 0;
  static const int transactionStatusConfirmed = 1;

  // Supported currencies
  static const List<String> supportedCurrencies = [
    'EUR',
    'USD',
    'GBP',
    'JPY',
    'CHF',
    'CAD',
    'AUD',
  ];

  // Currency symbols
  static const Map<String, String> currencySymbols = {
    'EUR': '€',
    'USD': '\$',
    'GBP': '£',
    'JPY': '¥',
    'CHF': 'CHF',
    'CAD': 'CAD',
    'AUD': 'AUD',
  };

  // Date formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Database
  static const String databaseName = 'bankapp.db';

  // UI Constants
  static const double cardBorderRadius = 16.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
