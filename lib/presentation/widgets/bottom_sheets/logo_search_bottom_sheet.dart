import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/extensions/color_extensions.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/domain/entities/entities.dart';
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/viewmodels/shared/logo_search_view_model.dart';
import 'package:bankapp/presentation/widgets/helpers/superellipse_clipper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// BottomSheet pour rechercher des logos via l'API Brandfetch
class LogoSearchBottomSheet extends ConsumerStatefulWidget {
  final String initialQuery;
  final BrandLogo? currentlySelectedLogo;
  final Function(BrandLogo?) onLogoSelected;

  const LogoSearchBottomSheet({
    super.key,
    required this.initialQuery,
    required this.onLogoSelected,
    this.currentlySelectedLogo,
  });

  @override
  ConsumerState<LogoSearchBottomSheet> createState() =>
      _LogoSearchBottomSheetState();
}

class _LogoSearchBottomSheetState extends ConsumerState<LogoSearchBottomSheet> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);

    // Initialiser le ViewModel avec la requête
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final logoSearchNotifier = ref.read(logoSearchViewModelProvider.notifier);
      final currentState = ref.read(logoSearchViewModelProvider);

      // Si la query change, nettoyer les anciens résultats
      if (currentState.searchQuery != widget.initialQuery) {
        logoSearchNotifier.clearSearchResults();
      }

      logoSearchNotifier.setInitialQuery(widget.initialQuery);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) currentFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;
    final logoSearchState = ref.watch(logoSearchViewModelProvider);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _dismissKeyboard,
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.backgroundInvert,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.cardBorderRadius.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: AppConstants.defaultPadding.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: appTheme.text5?.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            SizedBox(height: AppConstants.defaultPadding.h),

            // Titre
            _buildTitle(l10n, appTheme),

            SizedBox(height: AppConstants.veryLargePadding.h),

            // Barre de recherche avec bouton
            _buildSearchBar(l10n, appTheme, logoSearchState),

            SizedBox(height: AppConstants.veryLargePadding.h),

            // Contenu principal (résultats ou états)
            Expanded(child: _buildContent(l10n, appTheme, logoSearchState)),

            SizedBox(height: AppConstants.veryLargePadding.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(AppLocalizations l10n, AppColorsExtended appTheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding.w),
      child: Text(
        l10n.findLogo,
        style: AppTextStyles.sectionHeader.copyWith(color: appTheme.textInvert),
      ),
    );
  }

  Widget _buildSearchBar(
    AppLocalizations l10n,
    AppColorsExtended appTheme,
    LogoSearchViewState viewState,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding.w),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.55,
        decoration: BoxDecoration(
          color: appTheme.backgroundInvert!.attenuate(context, 0.02),
          borderRadius: BorderRadius.circular(100.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => ref
                    .read(logoSearchViewModelProvider.notifier)
                    .updateSearchQuery(value),
                style: AppTextStyles.bodyVeryLarge.copyWith(
                  color: appTheme.textInvert,
                ),
                decoration: InputDecoration(
                  hintText: l10n.searchForLogo,
                  hintStyle: TextStyle(
                    fontSize: 16.sp,
                    color: appTheme.text4!.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.only(
                    left: AppConstants.largePadding.w,
                  ),
                ),
              ),
            ),
            // Bouton recherche (loupe)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10.r, vertical: 8.r),
              child: Material(
                color: viewState.searchQuery.trim().isEmpty
                    ? appTheme.text5?.withValues(alpha: 0.2)
                    : appTheme.background1,
                borderRadius: BorderRadius.circular(20.r),
                child: InkWell(
                  onTap:
                      viewState.searchQuery.trim().isEmpty ||
                          viewState.isSearching
                      ? null
                      : () => ref
                            .read(logoSearchViewModelProvider.notifier)
                            .searchLogos(),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    width: 38.r,
                    height: 38.r,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: viewState.isSearching
                        ? SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: CircularProgressIndicator(
                              strokeWidth: 4.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.secondaryPink,
                              ),
                            ),
                          )
                        : Icon(
                            CupertinoIcons.search,
                            color: appTheme.text1,
                            size: 24.sp,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    AppLocalizations l10n,
    AppColorsExtended appTheme,
    LogoSearchViewState viewState,
  ) {
    if (viewState.hasError) {
      return _buildErrorState(l10n, appTheme, viewState);
    }

    if (!viewState.hasResults && !viewState.isSearching) {
      return _buildEmptyState(l10n, appTheme);
    }

    if (!viewState.hasResults && viewState.isSearching) {
      return _buildLoadingState(l10n, appTheme);
    }

    return _buildResultsList(l10n, appTheme, viewState);
  }

  Widget _buildEmptyState(AppLocalizations l10n, AppColorsExtended appTheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.veryLargePadding.w,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.search, size: 64.sp, color: appTheme.text5),
          SizedBox(height: AppConstants.largePadding.h),
          Text(
            l10n.searchLogoHint,
            style: AppTextStyles.bodyVeryLarge.copyWith(color: appTheme.text4),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.veryLargePadding.h * 2),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n, AppColorsExtended appTheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 64.r,
          height: 64.r,
          child: CircularProgressIndicator(
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(appTheme.textInvert!),
          ),
        ),
        SizedBox(height: 120.h),
      ],
    );
  }

  Widget _buildErrorState(
    AppLocalizations l10n,
    AppColorsExtended appTheme,
    LogoSearchViewState viewState,
  ) {
    return Container(
      //color: Colors.red,
      alignment: Alignment.center,
      padding: EdgeInsets.all(AppConstants.defaultPadding.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: appTheme.text6, size: 64.sp),
          SizedBox(height: AppConstants.veryLargePadding.h),
          Text(
            l10n.logoSearchError,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: appTheme.textInvert,
            ),
          ),
          SizedBox(height: AppConstants.smallPadding.h),
          Text(
            viewState.errorMessage ?? l10n.searchError,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: appTheme.text4),
          ),
          SizedBox(height: AppConstants.largePadding.h * 2),
          ElevatedButton(
            onPressed: () =>
                ref.read(logoSearchViewModelProvider.notifier).searchLogos(),
            style: ElevatedButton.styleFrom(
              backgroundColor: appTheme.background1,
              foregroundColor: appTheme.text1,
              padding: EdgeInsets.symmetric(horizontal: 48.sp, vertical: 20.sp),
            ),
            child: Text(l10n.retry),
          ),
          SizedBox(height: AppConstants.largePadding.h * 2),
        ],
      ),
    );
  }

  Widget _buildResultsList(
    AppLocalizations l10n,
    AppColorsExtended appTheme,
    LogoSearchViewState viewState,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        left: AppConstants.defaultPadding.w,
        right: AppConstants.defaultPadding.w,
        bottom: AppConstants.veryLargePadding.h,
      ),
      itemCount: _getItemCount(viewState),
      itemBuilder: (context, index) {
        // Option "Aucun logo" en première position si un logo est déjà sélectionné
        if (widget.currentlySelectedLogo != null && index == 0) {
          return _buildNoLogoOption(l10n, appTheme);
        }

        // Ajuster l'index pour les logos
        final logoIndex = widget.currentlySelectedLogo != null
            ? index - 1
            : index;

        if (logoIndex < viewState.searchResults.length) {
          final logo = viewState.searchResults[logoIndex];
          return _buildLogoItem(logo, appTheme);
        }

        return const SizedBox.shrink();
      },
    );
  }

  int _getItemCount(LogoSearchViewState viewState) {
    int baseCount = viewState.searchResults.length;
    // Ajouter 1 si un logo est déjà sélectionné (pour l'option "Aucun logo")
    return widget.currentlySelectedLogo != null ? baseCount + 1 : baseCount;
  }

  Widget _buildNoLogoOption(AppLocalizations l10n, AppColorsExtended appTheme) {
    return InkWell(
      onTap: () {
        widget.onLogoSelected(null);
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding.w,
          vertical: AppConstants.defaultPadding.h,
        ),
        margin: EdgeInsets.only(bottom: AppConstants.smallPadding.h),
        child: Row(
          children: [
            // Icône dans un squircle
            ClipPath(
              clipper: SuperellipseClipper(n: 2.0),
              child: Container(
                width: 52.r,
                height: 52.r,
                decoration: BoxDecoration(
                  color: appTheme.text2!.withValues(alpha: 0.11),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.not_interested,
                  color: appTheme.textInvert,
                  size: 26.sp,
                ),
              ),
            ),

            SizedBox(width: AppConstants.largePadding.w),

            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.noLogo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w400,
                      color: appTheme.textInvert,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    l10n.removeCurrentLogo,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: appTheme.text4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: AppConstants.largePadding.w),

            // Indicateur de sélection
            Container(
              width: 20.w,
              height: 20.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: appTheme.text4!, width: 2.w),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoItem(BrandLogo logo, AppColorsExtended appTheme) {
    final isSelected = widget.currentlySelectedLogo?.brandId == logo.brandId;

    return InkWell(
      onTap: () {
        widget.onLogoSelected(logo);
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding.w,
          vertical: AppConstants.defaultPadding.h,
        ),
        margin: EdgeInsets.only(bottom: AppConstants.smallPadding.h),
        child: Row(
          children: [
            // Logo dans un squircle
            ClipPath(
              clipper: SuperellipseClipper(n: 2.0),
              child: Container(
                width: 52.r,
                height: 52.r,
                decoration: BoxDecoration(
                  color: appTheme.text2!.withValues(alpha: 0.11),
                ),
                alignment: Alignment.center,
                child: logo.icon.isNotEmpty
                    ? Image.network(
                        logo.icon,
                        width: 52.r,
                        height: 52.r,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderIcon(appTheme);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildPlaceholderIcon(appTheme);
                        },
                      )
                    : _buildPlaceholderIcon(appTheme),
              ),
            ),

            SizedBox(width: AppConstants.largePadding.w),

            // Informations du logo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom de la marque
                  Text(
                    logo.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h5.copyWith(
                      color: appTheme.textInvert,
                    ),
                  ),

                  SizedBox(height: 2.r),

                  // Nom de domaine
                  Text(
                    logo.domain,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: appTheme.text4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: AppConstants.largePadding.w),

            // Indicateur de sélection
            Container(
              width: 20.w,
              height: 20.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: appTheme.text4!, width: 2.w),
                color: isSelected ? appTheme.text4! : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(AppColorsExtended appTheme) {
    return Icon(Icons.error, size: 24.sp, color: appTheme.textInvert);
  }
}
