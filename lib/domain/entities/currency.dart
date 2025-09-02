import 'package:bankapp/core/extensions/app_localizations_extensions.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:equatable/equatable.dart';

/// Entité représentant une devise
class Currency extends Equatable {
  /// Code ISO de la devise (ex: 'EUR', 'USD', 'GBP')
  final String code;

  /// Symbole de la devise (ex: '€', '$', '£')
  final String symbol;

  /// Clé de localisation pour le nom de la devise
  final String nameKey;

  /// Clé de localisation pour le nom du pays/région
  final String countryKey;

  /// Nombre de décimales pour cette devise (2 pour EUR, 0 pour JPY)
  final int decimalPlaces;

  /// Indique si la devise est active/supportée
  final bool isActive;

  /// Emoji du drapeau (optionnel)
  final String? flagEmoji;

  const Currency({
    required this.code,
    required this.symbol,
    required this.nameKey,
    required this.countryKey,
    this.decimalPlaces = 2,
    this.isActive = true,
    this.flagEmoji,
  });

  /// Obtient le nom localisé de la devise
  String getDisplayName(AppLocalizations l10n) {
    return l10n.getTranslation(nameKey);
  }

  /// Obtient le nom localisé du pays/région
  String getCountryName(AppLocalizations l10n) {
    return l10n.getTranslation(countryKey);
  }

  /// Formate un montant avec le symbole de cette devise
  String formatAmount(double amount) {
    final formattedAmount = _formatNumberWithCommas(amount);

    // Pour l'Euro, symbole avant le montant. Pour USD, symbole après
    if (code == 'EUR') {
      return '$symbol$formattedAmount';
    } else {
      return '$formattedAmount $symbol';
    }
  }

  /// Formate un nombre avec des séparateurs de milliers
  String _formatNumberWithCommas(double amount) {
    final fixedAmount = amount.toStringAsFixed(decimalPlaces);
    final parts = fixedAmount.split('.');
    final wholePart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    // Ajouter des virgules pour les milliers
    String formattedWhole = '';
    for (int i = 0; i < wholePart.length; i++) {
      if (i > 0 && (wholePart.length - i) % 3 == 0) {
        formattedWhole += ',';
      }
      formattedWhole += wholePart[i];
    }

    return decimalPart.isEmpty
        ? formattedWhole
        : '$formattedWhole.$decimalPart';
  }

  /// Formate un montant avec le code de cette devise
  String formatAmountWithCode(double amount) {
    return '${amount.toStringAsFixed(decimalPlaces)} $code';
  }

  /// Obtient l'affichage complet "Code - Nom (Pays)"
  String getFullDisplayName(AppLocalizations l10n) {
    return l10n.getCurrencyFullDisplay(code);
  }

  @override
  List<Object?> get props => [
    code,
    symbol,
    nameKey,
    countryKey,
    decimalPlaces,
    isActive,
    flagEmoji,
  ];

  @override
  bool get stringify => true;
}
