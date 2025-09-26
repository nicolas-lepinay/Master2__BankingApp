import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/domain/entities/category.dart' as domain;
import 'package:bankapp/presentation/widgets/helpers/bordered_squircle.dart';
import 'package:bankapp/presentation/widgets/miscellaneous/category_breadcrumbs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Type d'affichage pour les items de catégorie
enum CategoryItemType {
  /// Item de niveau 1 ou 2 : pas de breadcrumbs
  root,

  /// Item de niveau 3+ : avec breadcrumbs
  subcategory,
}

/// Widget réutilisable pour afficher un item de catégorie dans une liste
///
/// Supporte :
/// - Squircle avec icône (selon GeneratedIconsRegistry)
/// - Breadcrumbs pour sous-catégories (niveau 3+)
/// - État sélectionné avec couleur rose
/// - Chevron conditionnel si sous-catégories existent
/// - Interactions tap/double-tap
class CategoryListItem extends StatelessWidget {
  final domain.Category category;
  final CategoryItemType itemType;
  final List<domain.Category> breadcrumbs;
  final bool isSelected;
  final bool hasSubcategories;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onChevronTap;

  const CategoryListItem({
    super.key,
    required this.category,
    this.itemType = CategoryItemType.root,
    this.breadcrumbs = const [],
    this.isSelected = false,
    this.hasSubcategories = false,
    this.onTap,
    this.onDoubleTap,
    this.onChevronTap,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding.w,
          vertical: AppConstants.verySmallPadding.h,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Squircle avec icône
            _buildIconSquircle(appTheme),

            SizedBox(width: AppConstants.largePadding.w),

            // Contenu principal (nom + breadcrumbs)
            Expanded(child: _buildContent(l10n, appTheme)),

            // Chevron conditionnel
            if (hasSubcategories) _buildChevron(appTheme),
          ],
        ),
      ),
    );
  }

  /// Construit le squircle avec l'icône de la catégorie
  Widget _buildIconSquircle(AppColorsExtended appTheme) {
    return SizedBox(
      width: 50.r,
      height: 50.r,
      child: BorderedSquircle(
        n: 2.9, // Même valeur que exchange_rates_bottom_sheet
        backgroundColor: isSelected
            ? AppColors.primaryPink.withValues(alpha: 0.15)
            : appTheme.background3!,
        border: isSelected
            ? BorderSide(
                color: AppColors.primaryPink.withValues(alpha: 0.5),
                width: 3.0,
              )
            : null, // Pas de bordure si non sélectionné
        child: Align(
          alignment: Alignment.center,
          child: _buildCategoryIcon(appTheme),
        ),
      ),
    );
  }

  /// Construit l'icône de la catégorie
  Widget _buildCategoryIcon(AppColorsExtended appTheme) {
    // ✅ OPTIMISÉ: Accès direct à l'IconData pré-résolu (zéro lookup!)
    final iconData = category.displayIcon;

    // Couleur de l'icône
    final iconColor = isSelected
        ? AppColors.primaryPink
        : (category.iconColor ?? appTheme.text5!);

    return Icon(iconData, size: 26.sp, color: iconColor);
  }

  /// Construit le contenu principal (nom + breadcrumbs)
  Widget _buildContent(AppLocalizations l10n, AppColorsExtended appTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nom de la catégorie
        Text(
          category.getDisplayName(l10n),
          style: AppTextStyles.h4.copyWith(
            color: isSelected ? AppColors.primaryPink : appTheme.text1,
            fontWeight: FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // Breadcrumbs pour sous-catégories (niveau 3+)
        if (itemType == CategoryItemType.subcategory &&
            breadcrumbs.isNotEmpty) ...[
          SizedBox(height: 4.h),
          CategoryBreadcrumbs(
            breadcrumbs: breadcrumbs,
            mode: CategoryBreadcrumbsMode.compact,
            textStyle: AppTextStyles.bodySmall.copyWith(
              color: isSelected
                  ? AppColors.primaryPink.withValues(alpha: 0.5)
                  : appTheme.text5,
              fontSize: 16.sp,
            ),
          ),
        ],
      ],
    );
  }

  /// Construit le chevron pour navigation
  Widget _buildChevron(AppColorsExtended appTheme) {
    return GestureDetector(
      onTap: onChevronTap ?? onDoubleTap, // Fallback sur double-tap
      child: Container(
        //color: Colors.red,
        padding: EdgeInsets.only(top: 8.r, bottom: 8.r, left: 8.r),
        child: Icon(
          CupertinoIcons.chevron_forward,
          size: 26.sp,
          color: isSelected
              ? AppColors.primaryPink.withValues(alpha: 0.4)
              : appTheme.text5,
        ),
      ),
    );
  }

  /// Factory pour créer un item de niveau racine (1-2)
  factory CategoryListItem.root({
    required domain.Category category,
    bool isSelected = false,
    bool hasSubcategories = false,
    VoidCallback? onTap,
    VoidCallback? onDoubleTap,
    VoidCallback? onChevronTap,
  }) {
    return CategoryListItem(
      category: category,
      itemType: CategoryItemType.root,
      breadcrumbs: const [],
      isSelected: isSelected,
      hasSubcategories: hasSubcategories,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onChevronTap: onChevronTap,
    );
  }

  /// Factory pour créer un item de sous-catégorie (3+) avec breadcrumbs
  factory CategoryListItem.subcategory({
    required domain.Category category,
    required List<domain.Category> breadcrumbs,
    bool isSelected = false,
    bool hasSubcategories = false,
    VoidCallback? onTap,
    VoidCallback? onDoubleTap,
    VoidCallback? onChevronTap,
  }) {
    return CategoryListItem(
      category: category,
      itemType: CategoryItemType.subcategory,
      breadcrumbs: breadcrumbs,
      isSelected: isSelected,
      hasSubcategories: hasSubcategories,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onChevronTap: onChevronTap,
    );
  }
}
