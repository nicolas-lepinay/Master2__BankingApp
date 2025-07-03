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
          return '$monthName, $day$ordinalSuffix';

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
    bool showSign = false,
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
