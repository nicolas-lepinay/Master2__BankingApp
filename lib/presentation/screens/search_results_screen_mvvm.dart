import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/widgets/lists/transactions_list/transactions_list_mvvm.dart';
import 'package:bankapp/presentation/widgets/text_fields/search_field_mvvm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchResultsScreenMVVM extends ConsumerStatefulWidget {
  final String initialQuery;
  final int? accountId;

  const SearchResultsScreenMVVM({
    super.key,
    this.initialQuery = '',
    this.accountId,
  });

  @override
  ConsumerState<SearchResultsScreenMVVM> createState() =>
      _SearchResultsScreenMVVMState();
}

class _SearchResultsScreenMVVMState
    extends ConsumerState<SearchResultsScreenMVVM> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic> _currentFilters = {};

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;

    // Initialiser la recherche si on a une query initiale
    if (widget.initialQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final searchViewModel = ref.read(searchViewModelProvider.notifier);
    if (widget.accountId != null) {
      searchViewModel.initializeSearch(widget.accountId!);
    }
    searchViewModel.searchByKeyword(query);
  }

  void _applyFilters(Map<String, dynamic> filters) {
    setState(() {
      _currentFilters = filters;
    });
    _performSearch(filters['keyword'] ?? '');
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentFilters = {};
    });
    final searchViewModel = ref.read(searchViewModelProvider.notifier);
    searchViewModel.clearAllFilters();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;
    final searchState = ref.watch(searchViewModelProvider);

    return Scaffold(
      backgroundColor: appTheme.background1,
      appBar: AppBar(
        backgroundColor: appTheme.background1,
        elevation: 0,
        title: Text(
          l10n.searchResults,
          style: AppTextStyles.h4.copyWith(color: appTheme.text1),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios, color: appTheme.text1),
        ),
        actions: [
          if (_currentFilters.isNotEmpty || _searchController.text.isNotEmpty)
            IconButton(
              onPressed: _clearSearch,
              icon: Icon(Icons.clear_all, color: appTheme.text1),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: EdgeInsets.all(16.r),
            child: Column(
              children: [
                AdvancedSearchFieldMVVM(
                  accountId: widget.accountId,
                  onSearchChanged: _performSearch,
                  onFiltersChanged: _applyFilters,
                ),

                // Indicateur de résultats
                if (searchState.hasResults)
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 16.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${searchState.searchResults.length} ${l10n.resultsFound}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (_currentFilters.isNotEmpty) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              l10n.filtered,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Résultats de recherche
          Expanded(
            child: _buildSearchResults(context, l10n, appTheme, searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    AppLocalizations l10n,
    AppColorsExtended appTheme,
    dynamic searchState,
  ) {
    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              searchState.error ?? 'Une erreur est survenue',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (!searchState.hasResults) {
      return _buildEmptyState(l10n, appTheme);
    }

    return TransactionsListMVVM(
      transactions: searchState.searchResults,
      onTransactionTap: (transaction) {
        // TODO: Ouvrir les détails de la transaction
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, AppColorsExtended appTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64.sp,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            _searchController.text.isEmpty
                ? "l10n.enterSearchTerm"
                : "l10n.noResultsFound",
            style: AppTextStyles.h6.copyWith(color: appTheme.text2),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            _searchController.text.isEmpty
                ? "l10n.searchTransactionsHint"
                : "l10n.tryDifferentTerms",
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isNotEmpty) ...[
            SizedBox(height: 24.h),
            _buildSearchSuggestions(l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions(AppLocalizations l10n) {
    final searchViewModel = ref.read(searchViewModelProvider.notifier);
    final suggestions = searchViewModel.getSearchSuggestions('');

    if (suggestions.isEmpty) return const SizedBox();

    return Column(
      children: [
        Text(
          "l10n.searchSuggestions",
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: suggestions.take(5).map((suggestion) {
            return GestureDetector(
              onTap: () {
                _searchController.text = suggestion;
                _performSearch(suggestion);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  suggestion,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
