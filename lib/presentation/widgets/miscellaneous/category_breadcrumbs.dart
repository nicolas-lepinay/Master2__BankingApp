import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/domain/entities/category.dart' as domain;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Mode d'affichage des breadcrumbs
enum CategoryBreadcrumbsMode {
  /// Mode compact : une seule ligne avec ellipsis intelligent
  compact,

  /// Mode complet : multiligne autorisé
  full,
}

/// Widget réutilisable pour afficher les breadcrumbs de catégories
///
/// Supporte deux modes :
/// - Compact : pour les listes, avec gestion intelligente des ellipsis
/// - Full : pour les écrans de création, multiligne autorisé
class CategoryBreadcrumbs extends StatelessWidget {
  final List<domain.Category> breadcrumbs;
  final CategoryBreadcrumbsMode mode;
  final TextStyle? textStyle;
  final Color? chevronColor;
  final double? spacing;
  final int maxCharactersPerLine;

  const CategoryBreadcrumbs({
    super.key,
    required this.breadcrumbs,
    this.mode = CategoryBreadcrumbsMode.compact,
    this.textStyle,
    this.chevronColor,
    this.spacing,
    this.maxCharactersPerLine = 24,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;
    final l10n = AppLocalizations.of(context)!;

    if (breadcrumbs.isEmpty) {
      return const SizedBox.shrink();
    }

    final defaultTextStyle = AppTextStyles.bodySmall.copyWith(
      color: appTheme.text3,
      fontSize: 12.sp,
    );

    final effectiveTextStyle = textStyle ?? defaultTextStyle;
    final effectiveChevronColor =
        chevronColor ?? textStyle?.color ?? appTheme.text5!;
    final effectiveSpacing = spacing ?? 4.w;

    switch (mode) {
      case CategoryBreadcrumbsMode.compact:
        return _buildCompactBreadcrumbs(
          l10n,
          effectiveTextStyle,
          effectiveChevronColor,
          effectiveSpacing,
        );
      case CategoryBreadcrumbsMode.full:
        return _buildFullBreadcrumbs(
          l10n,
          effectiveTextStyle,
          effectiveChevronColor,
          effectiveSpacing,
        );
    }
  }

  /// Construit les breadcrumbs en mode compact avec ellipsis intelligent
  Widget _buildCompactBreadcrumbs(
    AppLocalizations l10n,
    TextStyle textStyle,
    Color chevronColor,
    double spacing,
  ) {
    if (breadcrumbs.length < 2) {
      // Un seul élément, pas besoin d'ellipsis
      return Text(
        breadcrumbs.first.getDisplayName(l10n),
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Prendre les 2 derniers éléments pour les breadcrumbs compacts
    final lastTwo = breadcrumbs.length >= 2
        ? breadcrumbs.sublist(breadcrumbs.length - 2)
        : breadcrumbs;

    final firstLabel = lastTwo[0].getDisplayName(l10n);
    final secondLabel = lastTwo[1].getDisplayName(l10n);

    final truncatedLabels = _applyIntelligentEllipsis(
      firstLabel,
      secondLabel,
      maxCharactersPerLine,
    );

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Flexible(
          child: FittedBox(
            child: Text(
              truncatedLabels.first,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.fade, // Pas d'ellipsis supplémentaire
            ),
          ),
        ),
        SizedBox(width: spacing),
        Icon(
          Icons.chevron_right,
          size: (textStyle.fontSize ?? 12.sp) * 1.2,
          color: chevronColor,
        ),
        SizedBox(width: spacing),
        Flexible(
          child: FittedBox(
            child: Text(
              truncatedLabels.second,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.fade, // Pas d'ellipsis supplémentaire
            ),
          ),
        ),
      ],
    );
  }

  /// Construit les breadcrumbs en mode complet (multiligne)
  Widget _buildFullBreadcrumbs(
    AppLocalizations l10n,
    TextStyle textStyle,
    Color chevronColor,
    double spacing,
  ) {
    final elements = <Widget>[];

    for (int i = 0; i < breadcrumbs.length; i++) {
      // Ajouter le nom de la catégorie
      elements.add(Text(breadcrumbs[i].getDisplayName(l10n), style: textStyle));

      // Ajouter le chevron si ce n'est pas le dernier élément
      if (i < breadcrumbs.length - 1) {
        elements.add(SizedBox(width: spacing));
        elements.add(
          Icon(
            Icons.chevron_right,
            size: (textStyle.fontSize ?? 12.sp) * 1.2,
            color: chevronColor,
          ),
        );
        elements.add(SizedBox(width: spacing));
      }
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: elements,
    );
  }

  /// Applique l'algorithme d'ellipsis intelligent
  ///
  /// Règles selon les spécifications :
  /// 1. Si total ≤ maxChars : pas d'ellipsis
  /// 2. Si un label ≤ maxChars/2 : ellipsis sur l'autre
  /// 3. Si les deux > maxChars/2 : ellipsis équitable (12 chars + "...")
  ({String first, String second}) _applyIntelligentEllipsis(
    String firstLabel,
    String secondLabel,
    int maxChars,
  ) {
    final firstLength = firstLabel.length;
    final secondLength = secondLabel.length;
    final totalLength = firstLength + secondLength;

    // Règle 1 : Si le total tient dans la limite, pas d'ellipsis
    if (totalLength <= maxChars) {
      return (first: firstLabel, second: secondLabel);
    }

    final halfMax = maxChars ~/ 2; // Division entière

    // Règle 2 : Si un label est petit, ellipsis sur l'autre
    if (firstLength <= halfMax) {
      // Premier label petit, abréger le second
      final availableForSecond = maxChars - firstLength;
      final truncatedSecond = _truncateWithEllipsis(
        secondLabel,
        availableForSecond,
      );
      return (first: firstLabel, second: truncatedSecond);
    }

    if (secondLength <= halfMax) {
      // Second label petit, abréger le premier
      final availableForFirst = maxChars - secondLength;
      final truncatedFirst = _truncateWithEllipsis(
        firstLabel,
        availableForFirst,
      );
      return (first: truncatedFirst, second: secondLabel);
    }

    // Règle 3 : Les deux sont grands, ellipsis équitable
    const ellipsisLength = 3; // "..."
    final charsPer = halfMax - ellipsisLength;

    final truncatedFirst = firstLabel.length > charsPer
        ? '${firstLabel.substring(0, charsPer)}...'
        : firstLabel;

    final truncatedSecond = secondLabel.length > charsPer
        ? '${secondLabel.substring(0, charsPer)}...'
        : secondLabel;

    return (first: truncatedFirst, second: truncatedSecond);
  }

  /// Tronque un texte avec ellipsis si nécessaire
  String _truncateWithEllipsis(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }

    // Réserver 3 caractères pour "..."
    final availableChars = maxLength - 3;
    if (availableChars <= 0) {
      return '...';
    }

    return '${text.substring(0, availableChars)}...';
  }
}
