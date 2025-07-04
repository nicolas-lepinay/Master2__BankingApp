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

  // Helper method to get ordinal suffix for numbers (1st, 2nd, 3rd, etc.)
  static String _getOrdinalSuffix(int day, String languageCode) {
    switch (languageCode) {
      case 'en':
        if (day >= 11 && day <= 13) {
          return 'th'; // 11th, 12th, 13th
        }
        switch (day % 10) {
          case 1:
            return 'st'; // 1st, 21st, 31st
          case 2:
            return 'nd'; // 2nd, 22nd
          case 3:
            return 'rd'; // 3rd, 23rd
          default:
            return 'th'; // 4th, 5th, 6th, etc.
        }

      case 'fr':
        return day == 1 ? 'er' : ''; // 1er, 2, 3, 4, etc.

      case 'es':
        return day == 1 ? 'º' : ''; // 1º, 2, 3, 4, etc.

      case 'it':
        return 'º'; // 1º, 2º, 3º, etc.

      case 'de':
        return '.'; // 1., 2., 3., etc.

      case 'pt':
        return 'º'; // 1º, 2º, 3º, etc.

      default:
        return ''; // No suffix for unknown languages
    }
  }

  // Helper method to format date with proper order and ordinales for each language
  static String _formatCurrencyWithLocaleRules(
    double amount,
    String currency,
    String languageCode,
    String localeString,
  ) {
    final symbol = AppConstants.currencySymbols[currency] ?? currency;

    try {
      final formatter = NumberFormat('#,##0.00', localeString);
      final formattedNumber = formatter.format(amount.abs());

      switch (languageCode) {
        case 'en':
          // English: $10.50, £15.75
          return amount >= 0
              ? '$symbol$formattedNumber'
              : '-$symbol$formattedNumber';

        case 'fr':
          // French: 10,50€, 15,75€
          return amount >= 0
              ? '$formattedNumber$symbol'
              : '-$formattedNumber$symbol';

        case 'es':
          // Spanish: 10,50€, $15,75
          if (currency == 'EUR') {
            return amount >= 0
                ? '$formattedNumber$symbol'
                : '-$formattedNumber$symbol';
          } else {
            return amount >= 0
                ? '$symbol$formattedNumber'
                : '-$symbol$formattedNumber';
          }

        case 'it':
          // Italian: 10,50€, $15,75
          if (currency == 'EUR') {
            return amount >= 0
                ? '$formattedNumber$symbol'
                : '-$formattedNumber$symbol';
          } else {
            return amount >= 0
                ? '$symbol$formattedNumber'
                : '-$symbol$formattedNumber';
          }

        case 'de':
          // German: 10,50€, $15,75
          if (currency == 'EUR') {
            return amount >= 0
                ? '$formattedNumber$symbol'
                : '-$formattedNumber$symbol';
          } else {
            return amount >= 0
                ? '$symbol$formattedNumber'
                : '-$symbol$formattedNumber';
          }

        case 'pt':
          // Portuguese: R$ 10,50, $15,75
          if (currency == 'BRL') {
            return amount >= 0
                ? '$symbol $formattedNumber'
                : '-$symbol $formattedNumber';
          } else if (currency == 'EUR') {
            return amount >= 0
                ? '$formattedNumber$symbol'
                : '-$formattedNumber$symbol';
          } else {
            return amount >= 0
                ? '$symbol$formattedNumber'
                : '-$symbol$formattedNumber';
          }

        case 'ja':
          // Japanese: ¥1,050, $10.50
          if (currency == 'JPY') {
            // Yen doesn't use decimals
            final yenFormatter = NumberFormat('#,##0', localeString);
            final yenFormatted = yenFormatter.format(amount.abs());
            return amount >= 0
                ? '$symbol$yenFormatted'
                : '-$symbol$yenFormatted';
          } else {
            return amount >= 0
                ? '$symbol$formattedNumber'
                : '-$symbol$formattedNumber';
          }

        case 'ko':
          // Korean: ₩1,050, $10.50
          if (currency == 'KRW') {
            // Won doesn't use decimals
            final wonFormatter = NumberFormat('#,##0', localeString);
            final wonFormatted = wonFormatter.format(amount.abs());
            return amount >= 0
                ? '$symbol$wonFormatted'
                : '-$symbol$wonFormatted';
          } else {
            return amount >= 0
                ? '$symbol$formattedNumber'
                : '-$symbol$formattedNumber';
          }

        case 'zh':
          // Chinese: ¥10.50, $15.75
          return amount >= 0
              ? '$symbol$formattedNumber'
              : '-$symbol$formattedNumber';

        case 'ar':
          // Arabic: 10.50 ر.س, $15.75
          if (currency == 'SAR') {
            return amount >= 0
                ? '$formattedNumber $symbol'
                : '-$formattedNumber $symbol';
          } else {
            return amount >= 0
                ? '$symbol$formattedNumber'
                : '-$symbol$formattedNumber';
          }

        case 'ru':
          // Russian: 10,50₽, $15.75
          if (currency == 'RUB') {
            return amount >= 0
                ? '$formattedNumber$symbol'
                : '-$formattedNumber$symbol';
          } else {
            return amount >= 0
                ? '$symbol$formattedNumber'
                : '-$symbol$formattedNumber';
          }

        default:
          // Fallback: use English format
          return amount >= 0
              ? '$symbol$formattedNumber'
              : '-$symbol$formattedNumber';
      }
    } catch (e) {
      // Fallback if locale not supported
      final basicFormatter = NumberFormat('#,##0.00');
      final basicFormatted = basicFormatter.format(amount.abs());
      return amount >= 0 ? '$symbol$basicFormatted' : '-$symbol$basicFormatted';
    }
  }

  // Helper method to format amount with sign and proper locale rules
  static String _formatAmountWithSign(
    double amount,
    String currency,
    String languageCode,
    String localeString,
    bool showSign,
  ) {
    final symbol = AppConstants.currencySymbols[currency] ?? currency;

    try {
      final formatter = NumberFormat('#,##0.00', localeString);
      final formattedNumber = formatter.format(amount.abs());

      String result;

      switch (languageCode) {
        case 'en':
          // English: +$10.50, -$15.75
          result = '$symbol$formattedNumber';
          break;

        case 'fr':
        case 'es':
        case 'it':
        case 'de':
          // French/Spanish/Italian/German: +10,50€, -15,75€
          if (currency == 'EUR') {
            result = '$formattedNumber$symbol';
          } else {
            result = '$symbol$formattedNumber';
          }
          break;

        case 'pt':
          // Portuguese: +R$ 10,50, -$15,75
          if (currency == 'BRL') {
            result = '$symbol $formattedNumber';
          } else if (currency == 'EUR') {
            result = '$formattedNumber$symbol';
          } else {
            result = '$symbol$formattedNumber';
          }
          break;

        case 'ja':
          // Japanese: +¥1,050, +$10.50
          if (currency == 'JPY') {
            final yenFormatter = NumberFormat('#,##0', localeString);
            final yenFormatted = yenFormatter.format(amount.abs());
            result = '$symbol$yenFormatted';
          } else {
            result = '$symbol$formattedNumber';
          }
          break;

        case 'ko':
          // Korean: +₩1,050, +$10.50
          if (currency == 'KRW') {
            final wonFormatter = NumberFormat('#,##0', localeString);
            final wonFormatted = wonFormatter.format(amount.abs());
            result = '$symbol$wonFormatted';
          } else {
            result = '$symbol$formattedNumber';
          }
          break;

        case 'zh':
        case 'ar':
        case 'ru':
          // Default format for these languages
          result = currency == 'RUB'
              ? '$formattedNumber$symbol'
              : '$symbol$formattedNumber';
          break;

        default:
          // Fallback: English format
          result = '$symbol$formattedNumber';
          break;
      }

      if (showSign) {
        final sign = amount >= 0 ? '+' : '-';
        return '$sign$result';
      } else {
        return amount >= 0 ? result : '-$result';
      }
    } catch (e) {
      // Fallback if locale not supported
      final basicFormatter = NumberFormat('#,##0.00');
      final basicFormatted = basicFormatter.format(amount.abs());
      final result = '$symbol$basicFormatted';

      if (showSign) {
        final sign = amount >= 0 ? '+' : '-';
        return '$sign$result';
      } else {
        return amount >= 0 ? result : '-$result';
      }
    }
  }

  static String _formatDateWithLocaleRules(
    DateTime date,
    String languageCode,
    String localeString,
  ) {
    final day = date.day;
    final ordinalSuffix = _getOrdinalSuffix(day, languageCode);

    try {
      switch (languageCode) {
        case 'en':
          // English: "July 1st", "July 2nd", "July 3rd", "July 4th"
          final monthFormatter = DateFormat('MMMM', localeString);
          final monthName = monthFormatter.format(date);
          return '$monthName $day$ordinalSuffix';

        case 'fr':
          // French: "1er juillet", "2 juillet", "3 juillet"
          final monthFormatter = DateFormat('MMMM', localeString);
          final monthName = monthFormatter.format(date);
          return '$day$ordinalSuffix $monthName';

        case 'es':
          // Spanish: "1º de julio", "2 de julio"
          final monthFormatter = DateFormat('MMMM', localeString);
          final monthName = monthFormatter.format(date);
          if (day == 1) {
            return '$day$ordinalSuffix de $monthName';
          } else {
            return '$day de $monthName';
          }

        case 'it':
          // Italian: "1º luglio", "2º luglio"
          final monthFormatter = DateFormat('MMMM', localeString);
          final monthName = monthFormatter.format(date);
          return '$day$ordinalSuffix $monthName';

        case 'de':
          // German: "1. Juli", "2. Juli"
          final monthFormatter = DateFormat('MMMM', localeString);
          final monthName = monthFormatter.format(date);
          return '$day$ordinalSuffix $monthName';

        case 'pt':
          // Portuguese: "1º de julho", "2º de julho"
          final monthFormatter = DateFormat('MMMM', localeString);
          final monthName = monthFormatter.format(date);
          return '$day$ordinalSuffix de $monthName';

        case 'ja':
          // Japanese: "7月1日"
          final monthFormatter = DateFormat('M月d日', localeString);
          return monthFormatter.format(date);

        case 'ko':
          // Korean: "7월 1일"
          final monthFormatter = DateFormat('M월 d일', localeString);
          return monthFormatter.format(date);

        case 'zh':
          // Chinese: "7月1日"
          final monthFormatter = DateFormat('M月d日', localeString);
          return monthFormatter.format(date);

        case 'ar':
          // Arabic: "1 يوليو"
          final monthFormatter = DateFormat('d MMMM', localeString);
          return monthFormatter.format(date);

        case 'ru':
          // Russian: "1 июля"
          final monthFormatter = DateFormat('d MMMM', localeString);
          return monthFormatter.format(date);

        default:
          // Fallback: use basic format
          return DateFormat('d MMMM', localeString).format(date);
      }
    } catch (e) {
      // Fallback if locale not supported
      return DateFormat('d MMMM').format(date);
    }
  }

  // Number formatters with dynamic locale support
  static String formatCurrency(
    double amount,
    String currency, [
    BuildContext? context,
  ]) {
    // Use context locale if available, otherwise default to fr_FR
    String localeString = 'fr_FR';
    String languageCode = 'fr';

    if (context != null) {
      final currentLocale = Localizations.localeOf(context);
      localeString = _getLocaleString(currentLocale);
      languageCode = currentLocale.languageCode;
    }

    try {
      // Use NumberFormat.currency which handles locale-specific formatting automatically
      final formatter = NumberFormat.currency(
        locale: localeString,
        symbol: AppConstants.currencySymbols[currency] ?? currency,
        decimalDigits: _getDecimalDigits(currency),
      );
      return formatter.format(amount);
    } catch (e) {
      // Fallback to custom formatting
      return _formatCurrencyWithLocaleRules(
        amount,
        currency,
        languageCode,
        localeString,
      );
    }
  }

  static String formatAmount(
    double amount,
    String currency, {
    bool showSign = true,
    BuildContext? context,
  }) {
    // Use context locale if available, otherwise default to fr_FR
    String localeString = 'fr_FR';
    String languageCode = 'fr';

    if (context != null) {
      final currentLocale = Localizations.localeOf(context);
      localeString = _getLocaleString(currentLocale);
      languageCode = currentLocale.languageCode;
    }

    try {
      // Use NumberFormat.currency for consistent formatting
      final formatter = NumberFormat.currency(
        locale: localeString,
        symbol: AppConstants.currencySymbols[currency] ?? currency,
        decimalDigits: _getDecimalDigits(currency),
      );

      final formattedAmount = formatter.format(amount.abs());

      if (showSign) {
        final sign = amount >= 0 ? '+' : '-';
        return '$sign $formattedAmount';
      } else {
        return amount >= 0 ? formattedAmount : '- $formattedAmount';
      }
    } catch (e) {
      // Fallback to custom formatting
      return _formatAmountWithSign(
        amount,
        currency,
        languageCode,
        localeString,
        showSign,
      );
    }
  }

  // Helper method to get decimal digits for different currencies
  static int _getDecimalDigits(String currency) {
    switch (currency) {
      case 'JPY':
      case 'KRW':
        return 0; // No decimal places for Yen and Won
      default:
        return 2; // Most currencies use 2 decimal places
    }
  }

  // Date formatters with dynamic localization support and proper ordinales
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
      // Use current context locale with proper formatting rules
      final currentLocale = Localizations.localeOf(context);
      final localeString = _getLocaleString(currentLocale);
      final languageCode = currentLocale.languageCode;

      return _formatDateWithLocaleRules(date, languageCode, localeString);
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
      // Extract language code from locale string
      final languageCode = localeString?.split('_').first ?? 'en';
      return _formatDateWithLocaleRules(
        date,
        languageCode,
        localeString ?? 'en_US',
      );
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
