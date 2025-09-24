import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget réutilisable pour la barre de recherche de catégories
///
/// Design identique à LogoSearchBottomSheet mais adapté pour les catégories
/// TODO: Fonctionnalité de recherche à implémenter ultérieurement
class CategorySearchBar extends StatefulWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final bool enabled;

  const CategorySearchBar({
    super.key,
    this.hintText,
    this.onChanged,
    this.controller,
    this.enabled = true,
  });

  @override
  State<CategorySearchBar> createState() => _CategorySearchBarState();
}

class _CategorySearchBarState extends State<CategorySearchBar> {
  late TextEditingController _controller;
  bool _isControllerOwned = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _isControllerOwned = true;
    }
  }

  @override
  void dispose() {
    if (_isControllerOwned) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding.w),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.85, // Un peu plus large pour les catégories
        decoration: BoxDecoration(
          color: appTheme.background2!.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(100.r),
          border: Border.all(
            color: appTheme.text5!.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                onChanged: widget.onChanged,
                style: AppTextStyles.bodyVeryLarge.copyWith(
                  color: widget.enabled ? appTheme.text1 : appTheme.text3,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText ?? l10n.searchCategory, // TODO: Clé l10n à ajouter
                  hintStyle: TextStyle(
                    fontSize: 16.sp,
                    color: appTheme.text4,
                  ),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.only(
                    left: AppConstants.largePadding.w,
                    right: AppConstants.mediumPadding.w,
                    top: AppConstants.mediumPadding.h,
                    bottom: AppConstants.mediumPadding.h,
                  ),
                ),
              ),
            ),
            // Icône de recherche
            Padding(
              padding: EdgeInsets.only(right: AppConstants.largePadding.w),
              child: Icon(
                Icons.search,
                color: widget.enabled ? appTheme.text3 : appTheme.text4,
                size: 20.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension pour simplifier l'utilisation avec TODO pour recherche future
extension CategorySearchBarTODO on CategorySearchBar {
  /// TODO: Méthode pour implémenter la recherche de catégories
  ///
  /// Cette méthode devra être développée pour :
  /// - Filtrer les catégories par nom
  /// - Rechercher dans les breadcrumbs
  /// - Gérer la recherche hiérarchique
  /// - Intégrer avec CategorySelectionViewModel
  void implementSearch() {
    // TODO: Implémentation future de la recherche
    // 1. Debounce input pour performance
    // 2. Filtrage intelligent des catégories
    // 3. Highlight des résultats
    // 4. Navigation directe vers catégorie trouvée
  }
}