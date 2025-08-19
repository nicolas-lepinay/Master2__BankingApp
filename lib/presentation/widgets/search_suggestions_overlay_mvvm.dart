import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/screens/search_results_screen_mvvm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchSuggestionsOverlayMVVM extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final LayerLink layerLink;
  final double overlayWidth;
  final VoidCallback? onSuggestionSelected;
  final int? accountId;

  const SearchSuggestionsOverlayMVVM({
    super.key,
    required this.controller,
    required this.layerLink,
    this.overlayWidth = 300,
    this.onSuggestionSelected,
    this.accountId,
  });

  @override
  ConsumerState<SearchSuggestionsOverlayMVVM> createState() =>
      _SearchSuggestionsOverlayMVVMState();
}

class _SearchSuggestionsOverlayMVVMState
    extends ConsumerState<SearchSuggestionsOverlayMVVM> {
  List<String> _suggestions = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadSuggestions();
  }

  void _loadRecentSearches() {
    // Pour l'instant, utilisons une liste vide
    // TODO: Implémenter la gestion des recherches récentes
    setState(() {
      _recentSearches = [];
    });
  }

  void _loadSuggestions() {
    final query = widget.controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final searchViewModel = ref.read(searchViewModelProvider.notifier);
    final suggestions = searchViewModel.getSearchSuggestions(query);

    setState(() {
      _suggestions = suggestions;
      _isLoading = false;
    });
  }

  void _onSuggestionTap(String suggestion) {
    widget.controller.text = suggestion;
    widget.onSuggestionSelected?.call();

    // TODO: Enregistrer la recherche récente

    // Naviguer vers les résultats de recherche
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchResultsScreenMVVM(
          initialQuery: suggestion,
          accountId: widget.accountId,
        ),
      ),
    );
  }

  void _clearRecentSearches() {
    // TODO: Implémenter la suppression des recherches récentes
    setState(() {
      _recentSearches = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;
    final query = widget.controller.text.trim();

    return CompositedTransformFollower(
      link: widget.layerLink,
      showWhenUnlinked: false,
      offset: Offset(0.0, 60.h),
      child: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(12.r),
        color: appTheme.background1,
        child: Container(
          width: widget.overlayWidth.w,
          constraints: BoxConstraints(maxHeight: 300.h, minHeight: 100.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec titre
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.textSecondary.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      query.isNotEmpty
                          ? "l10n.suggestions"
                          : "l10n.recentSearches",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: appTheme.text2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (query.isEmpty && _recentSearches.isNotEmpty)
                      GestureDetector(
                        onTap: _clearRecentSearches,
                        child: Text(
                          "l10n.clearAll",
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Contenu
              Flexible(child: _buildContent(context, l10n, appTheme, query)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    AppColorsExtended appTheme,
    String query,
  ) {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(20.r),
        child: Center(
          child: SizedBox(
            width: 20.w,
            height: 20.h,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      );
    }

    if (query.isNotEmpty) {
      return _buildSuggestionsList(l10n, appTheme);
    } else {
      return _buildRecentSearchesList(l10n, appTheme);
    }
  }

  Widget _buildSuggestionsList(
    AppLocalizations l10n,
    AppColorsExtended appTheme,
  ) {
    if (_suggestions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 32.sp,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            SizedBox(height: 8.h),
            Text(
              "l10n.noSuggestionsFound",
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: _suggestions.length,
      separatorBuilder: (context, index) => Divider(
        height: 1.h,
        color: AppColors.textSecondary.withValues(alpha: 0.1),
      ),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        final query = widget.controller.text.trim().toLowerCase();

        return ListTile(
          dense: true,
          leading: Icon(
            Icons.search,
            size: 20.sp,
            color: AppColors.textSecondary,
          ),
          title: _buildHighlightedText(suggestion, query, appTheme),
          trailing: Icon(
            Icons.north_west,
            size: 16.sp,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
          onTap: () => _onSuggestionTap(suggestion),
        );
      },
    );
  }

  Widget _buildRecentSearchesList(
    AppLocalizations l10n,
    AppColorsExtended appTheme,
  ) {
    if (_recentSearches.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 32.sp,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            SizedBox(height: 8.h),
            Text(
              "l10n.noRecentSearches",
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: _recentSearches.length,
      separatorBuilder: (context, index) => Divider(
        height: 1.h,
        color: AppColors.textSecondary.withValues(alpha: 0.1),
      ),
      itemBuilder: (context, index) {
        final search = _recentSearches[index];

        return ListTile(
          dense: true,
          leading: Icon(
            Icons.history,
            size: 20.sp,
            color: AppColors.textSecondary,
          ),
          title: Text(
            search,
            style: AppTextStyles.bodyMedium.copyWith(color: appTheme.text3),
          ),
          trailing: GestureDetector(
            onTap: () {
              // TODO: Implémenter la suppression d'une recherche récente
              setState(() {
                _recentSearches.remove(search);
              });
            },
            child: Icon(
              Icons.close,
              size: 16.sp,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          onTap: () => _onSuggestionTap(search),
        );
      },
    );
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    AppColorsExtended appTheme,
  ) {
    if (query.isEmpty) {
      return Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(color: appTheme.text3),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final startIndex = lowerText.indexOf(lowerQuery);

    if (startIndex == -1) {
      return Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(color: appTheme.text3),
      );
    }

    final endIndex = startIndex + query.length;

    return RichText(
      text: TextSpan(
        style: AppTextStyles.bodyMedium.copyWith(color: appTheme.text3),
        children: [
          if (startIndex > 0) TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (endIndex < text.length) TextSpan(text: text.substring(endIndex)),
        ],
      ),
    );
  }
}
