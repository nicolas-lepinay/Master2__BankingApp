import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/presentation/providers/database_provider.dart';
import 'package:bankapp/presentation/providers/card_swiper_provider.dart';
import 'package:bankapp/presentation/providers/transaction_search_provider.dart';
import 'package:bankapp/presentation/widgets/transactions_list.dart';
import 'package:bankapp/presentation/widgets/half_search_field.dart';
import 'package:bankapp/presentation/screens/transaction_detail_screen.dart';
import 'package:bankapp/data/database/database.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FullTransactionsBottomSheet extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const FullTransactionsBottomSheet({super.key, this.onClose});

  @override
  ConsumerState<FullTransactionsBottomSheet> createState() =>
      _FullTransactionsBottomSheetState();
}

class _FullTransactionsBottomSheetState
    extends ConsumerState<FullTransactionsBottomSheet> {
  late DraggableScrollableController _dragController;
  bool _isSearchVisible = false;
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final TextEditingController _keywordController = TextEditingController();
  final FocusNode _keywordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _dragController = DraggableScrollableController();
  }

  @override
  void dispose() {
    _dragController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    _keywordController.dispose();
    _keywordFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _amountController.clear();
        _amountFocusNode.unfocus();
        _keywordController.clear();
        _keywordFocusNode.unfocus();
        // Effacer la recherche quand on ferme la barre
        ref.read(transactionSearchProvider.notifier).clearSearch();
      }
    });
  }

  void _onAmountSearchChanged(String value) {
    ref.read(transactionSearchProvider.notifier).searchByAmount(value);
  }

  void _onKeywordSearchChanged(String value) {
    ref.read(transactionSearchProvider.notifier).searchByKeyword(value);
  }

  void _navigateToTransactionDetail(Transaction transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            TransactionDetailScreen(transactionId: transaction.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDarkMode = brightness == Brightness.dark;

    final selectedCardIndex = ref.watch(selectedCardProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return DraggableScrollableSheet(
      controller: _dragController,
      initialChildSize: 0.86,
      minChildSize: 0.0, // Permettre de fermer complètement
      maxChildSize: 0.86,
      snap: true,
      snapSizes: const [0.72, 0.86],
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.veryLargePadding.r,
          ),
          decoration: BoxDecoration(
            color: appTheme.background2,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                blurRadius: 28.r,
                offset: Offset(0, -4.h),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  //color: Colors.red,
                  height: AppConstants.veryLargePadding * 2,
                  alignment: Alignment.topCenter,
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      l10n.close.toUpperCase(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: appTheme.text4,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ),

              // Header avec titre et icône loupe
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Titre "Transactions" avec police Playfair
                  Text(
                    l10n.transactions,
                    style: AppTextStyles.h2.copyWith(
                      fontFamily: AppTextStyles.playfairFontFamily,
                    ),
                  ),

                  // Icône loupe/fermer
                  GestureDetector(
                    onTap: _toggleSearch,
                    child: Icon(
                      _isSearchVisible
                          ? CupertinoIcons.xmark
                          : CupertinoIcons.search,
                      size: 30.sp,
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppConstants.mediumPadding.r),

              // Barre de recherche animée avec 2 champs
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _isSearchVisible ? 80.h : 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _isSearchVisible ? 1.0 : 0.0,
                  child: Row(
                    children: [
                      // Champ de recherche par montant (gauche)
                      Expanded(
                        child: HalfSearchField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          hintText: l10n.amount.toUpperCase(),
                          appTheme: appTheme,
                          keyboardType: TextInputType.number,
                          iconData: CupertinoIcons.money_dollar,
                          shadowColor: isDarkMode
                              ? null
                              : AppColors.primaryGreen.withValues(alpha: 0.3),
                          isLeftSide: true,
                          onChanged: _onAmountSearchChanged,
                        ),
                      ),

                      // Champ de recherche par mot-clé (droite)
                      Expanded(
                        child: HalfSearchField(
                          controller: _keywordController,
                          focusNode: _keywordFocusNode,
                          hintText: l10n.keyword.toUpperCase(),
                          appTheme: appTheme,
                          iconData: CupertinoIcons.textformat_alt,
                          shadowColor: isDarkMode
                              ? null
                              : AppColors.primaryGreen.withValues(alpha: 0.3),
                          onChanged: _onKeywordSearchChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Espace entre barre de recherche et liste
              _isSearchVisible
                  ? SizedBox(height: AppConstants.largePadding.r)
                  : SizedBox(height: AppConstants.defaultPadding.r),

              // Liste des transactions
              Expanded(
                child: accountsAsync.when(
                  data: (accounts) {
                    if (accounts.isEmpty) {
                      return _buildEmptyState(l10n);
                    }

                    // Récupérer le compte sélectionné
                    final selectedAccount = selectedCardIndex < accounts.length
                        ? accounts[selectedCardIndex]
                        : accounts.first;

                    // Récupérer les transactions avec solde pour le compte sélectionné
                    final transactionsAsync = ref.watch(
                      transactionsWithBalanceProvider(selectedAccount.id),
                    );

                    return transactionsAsync.when(
                      data: (transactions) {
                        if (transactions.isEmpty) {
                          return _buildEmptyTransactionsState(l10n);
                        }

                        // Initialiser le provider de recherche avec les transactions
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref
                              .read(transactionSearchProvider.notifier)
                              .setOriginalTransactions(transactions);
                        });

                        // Écouter l'état de la recherche
                        final searchState = ref.watch(
                          transactionSearchProvider,
                        );
                        final transactionsToDisplay = searchState.isSearchActive
                            ? searchState.filteredTransactions
                            : transactions;

                        if (transactionsToDisplay.isEmpty &&
                            searchState.isSearchActive) {
                          return _buildNoResultsState(l10n, appTheme);
                        }

                        return TransactionsList(
                          transactions: transactionsToDisplay,
                          onTransactionTap: _navigateToTransactionDetail,
                          scrollToToday: !searchState
                              .isSearchActive, // Pas de scroll auto si recherche active
                          accountCurrency: selectedAccount.currency,
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                      error: (error, stack) => _buildErrorState(error),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (error, stack) => _buildErrorState(error),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoResultsState(
    AppLocalizations l10n,
    AppColorsExtended appTheme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppConstants.veryLargePadding.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(Icons.search_off, size: 64.sp, color: appTheme.text6),
          SizedBox(height: 16.h),
          Text(
            'Aucun résultat', // TODO: Ajouter à l10n
            style: AppTextStyles.h5.copyWith(color: appTheme.text5),
          ),
          SizedBox(height: 8.h),
          Text(
            'Essayez de modifier vos critères de recherche', // TODO: Ajouter à l10n
            style: AppTextStyles.bodyMedium.copyWith(color: appTheme.text5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.largePadding.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              'Aucun compte disponible', // TODO: Ajouter à l10n
              style: AppTextStyles.h6.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTransactionsState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.largePadding.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              'Aucune transaction', // TODO: Ajouter à l10n
              style: AppTextStyles.h6.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.largePadding.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              'Erreur de chargement', // TODO: Ajouter à l10n
              style: AppTextStyles.h6.copyWith(color: AppColors.error),
            ),
            SizedBox(height: 8.h),
            Text(
              error.toString(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
