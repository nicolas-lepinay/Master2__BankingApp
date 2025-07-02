import 'package:intl/intl.dart';
import 'package:flutter/widgets.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';

class AppFormatters {
  // Helper method to get proper locale string from Locale
  static String _getLocaleString(Locale locale) {
    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;

    // Create proper locale string based on language and country
    if (countryCode != null && countryCode.isNotEmpty) {
      return '${languageCode}_${countryCode.toUpperCase()}';
    }

    // Fallback to common locale patterns
    switch (languageCode) {
      case 'fr':
        return 'fr_FR';
      case 'en':
        return 'en_US';
      case 'es':
        return 'es_ES';
      case 'it':
        return 'it_IT';
      case 'de':
        return 'de_DE';
      case 'pt':
        return 'pt_PT';
      case 'ja':
        return 'ja_JP';
      case 'ko':
        return 'ko_KR';
      case 'zh':
        return 'zh_CN';
      case 'ar':
        return 'ar_SA';
      case 'ru':
        return 'ru_RU';
      default:
        return 'en_US'; // Default fallback
    }
  }

  // Number formatters with dynamic locale support
  static String formatCurrency(
    double amount,
    String currency, [
    BuildContext? context,
  ]) {
    final symbol = AppConstants.currencySymbols[currency] ?? currency;

    // Use context locale if available, otherwise default to fr_FR
    String localeString = 'fr_FR';
    if (context != null) {
      final currentLocale = Localizations.localeOf(context);
      localeString = _getLocaleString(currentLocale);
    }

    try {
      final formatter = NumberFormat('#,##0.00', localeString);
      return '${formatter.format(amount)}$symbol';
    } catch (e) {
      // Fallback to basic formatting if locale not supported
      final formatter = NumberFormat('#,##0.00');
      return '${formatter.format(amount)}$symbol';
    }
  }

  static String formatAmount(
    double amount,
    String currency, {
    bool showSign = true,
    BuildContext? context,
  }) {
    final symbol = AppConstants.currencySymbols[currency] ?? currency;

    // Use context locale if available, otherwise default to fr_FR
    String localeString = 'fr_FR';
    if (context != null) {
      final currentLocale = Localizations.localeOf(context);
      localeString = _getLocaleString(currentLocale);
    }

    try {
      final formatter = NumberFormat('#,##0.00', localeString);
      final formattedAmount = formatter.format(amount.abs());

      if (showSign) {
        final sign = amount >= 0 ? '+' : '-';
        return '$sign$formattedAmount$symbol';
      }

      return amount >= 0
          ? '$formattedAmount$symbol'
          : '-$formattedAmount$symbol';
    } catch (e) {
      // Fallback to basic formatting if locale not supported
      final formatter = NumberFormat('#,##0.00');
      final formattedAmount = formatter.format(amount.abs());

      if (showSign) {
        final sign = amount >= 0 ? '+' : '-';
        return '$sign$formattedAmount$symbol';
      }

      return amount >= 0
          ? '$formattedAmount$symbol'
          : '-$formattedAmount$symbol';
    }
  }

  // Date formatters with dynamic localization support
  static String formatDate(DateTime date, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return l10n.today;
    } else if (dateOnly == yesterday) {
      return l10n.yesterday;
    } else if (dateOnly == tomorrow) {
      return l10n.tomorrow;
    } else {
      // Use current context locale dynamically
      final currentLocale = Localizations.localeOf(context);
      final localeString = _getLocaleString(currentLocale);

      try {
        return DateFormat('EEEE d MMMM yyyy', localeString).format(date);
      } catch (e) {
        // Fallback to basic formatting if locale not supported
        return DateFormat('EEEE d MMMM yyyy').format(date);
      }
    }
  }

  // Alternative method without context for simple formatting
  static String formatDateSimple(DateTime date, {String? localeString}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return localeString?.startsWith('fr') == true ? 'Aujourd\'hui' : 'Today';
    } else if (dateOnly == yesterday) {
      return localeString?.startsWith('fr') == true ? 'Hier' : 'Yesterday';
    } else {
      try {
        return DateFormat(
          'EEEE d MMMM yyyy',
          localeString ?? 'en_US',
        ).format(date);
      } catch (e) {
        return DateFormat('EEEE d MMMM yyyy').format(date);
      }
    }
  }

  static String formatDateShort(DateTime date, [BuildContext? context]) {
    if (context != null) {
      final currentLocale = Localizations.localeOf(context);
      final localeString = _getLocaleString(currentLocale);
      try {
        return DateFormat(AppConstants.dateFormat, localeString).format(date);
      } catch (e) {
        return DateFormat(AppConstants.dateFormat).format(date);
      }
    }
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  static String formatDateTime(DateTime date, [BuildContext? context]) {
    if (context != null) {
      final currentLocale = Localizations.localeOf(context);
      final localeString = _getLocaleString(currentLocale);
      try {
        return DateFormat(
          AppConstants.dateTimeFormat,
          localeString,
        ).format(date);
      } catch (e) {
        return DateFormat(AppConstants.dateTimeFormat).format(date);
      }
    }
    return DateFormat(AppConstants.dateTimeFormat).format(date);
  }

  // Transaction type and status helpers with localization
  static String getTransactionTypeLabel(String type, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case AppConstants.transactionTypeDebit:
        return l10n.debit;
      case AppConstants.transactionTypeCredit:
        return l10n.credit;
      default:
        return type;
    }
  }

  static String getTransactionStatusLabel(int status, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case AppConstants.transactionStatusPending:
        return l10n.pending;
      case AppConstants.transactionStatusConfirmed:
        return l10n.confirmed;
      default:
        return l10n.unknown;
    }
  }
}
