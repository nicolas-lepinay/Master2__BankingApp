import 'package:intl/intl.dart';
import 'package:bankapp/core/constants/app_constants.dart';

class AppFormatters {
  // Number formatters
  static String formatCurrency(double amount, String currency) {
    final symbol = AppConstants.currencySymbols[currency] ?? currency;
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    return '${formatter.format(amount)}$symbol';
  }

  static String formatAmount(
    double amount,
    String currency, {
    bool showSign = false,
  }) {
    final symbol = AppConstants.currencySymbols[currency] ?? currency;
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    final formattedAmount = formatter.format(amount.abs());

    if (showSign) {
      final sign = amount >= 0 ? '+' : '-';
      return '$sign$formattedAmount$symbol';
    }

    return amount >= 0 ? '$formattedAmount$symbol' : '-$formattedAmount$symbol';
  }

  // Date formatters
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Aujourd\'hui';
    } else if (dateOnly == yesterday) {
      return 'Hier';
    } else {
      return DateFormat('d MMMM yyyy', 'fr_FR').format(date);
    }
  }

  static String formatDateShort(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat(AppConstants.dateTimeFormat).format(date);
  }

  // Transaction type helpers
  static String getTransactionTypeLabel(String type) {
    switch (type) {
      case AppConstants.transactionTypeDebit:
        return 'Débit';
      case AppConstants.transactionTypeCredit:
        return 'Crédit';
      default:
        return type;
    }
  }

  static String getTransactionStatusLabel(int status) {
    switch (status) {
      case AppConstants.transactionStatusPending:
        return 'En attente';
      case AppConstants.transactionStatusConfirmed:
        return 'Confirmé';
      default:
        return 'Inconnu';
    }
  }
}
