import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/screens/transaction_detail_screen.dart';
import 'package:bankapp/presentation/widgets/lists/transactions_list/transactions_list.dart';
import 'package:bankapp/presentation/widgets/text_fields/half_search_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Fonctions de conversion supprimées car plus nécessaires avec MVVM
  // TransactionViewModel fournit directement les domain.TransactionWithBalance

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
        ref.read(transactionListViewModelProvider.notifier).clearSearch();
      }
    });
  }

  void _onAmountSearchChanged(String value) {
    if (value.isNotEmpty) {
      final double? amount = double.tryParse(value);
      ref.read(transactionListViewModelProvider.notifier).filterByAmount(amount, null);
    } else {
      ref.read(transactionListViewModelProvider.notifier).clearFilters();
    }
  }

  void _onKeywordSearchChanged(String value) {
    ref.read(transactionListViewModelProvider.notifier).updateSearchQuery(value);
  }

  void _dismissKeyboard() {
    // Alternativement, on peut aussi utiliser :
    // FocusManager.instance.primaryFocus?.unfocus();
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) currentFocus.unfocus();
  }

  void _navigateToTransactionDetail(domain.Transaction transaction) {
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

    final homeScreenViewModel = ref.watch(homeScreenViewModelProvider);
    final accounts = homeScreenViewModel.accounts;

    return DraggableScrollableSheet(
      controller: _dragController,
      initialChildSize: 0.89,
      minChildSize: 0.0, // Permettre de fermer complètement
      maxChildSize: 0.89,
      snap: true,
      snapSizes: const [0.72, 0.89],
      builder: (context, scrollController) {
        return GestureDetector(
          // Détecter les taps en dehors des TextFields
          onTap: _dismissKeyboard,
          // Permettre aux enfants de recevoir les événements
          behavior: HitTestBehavior.opaque,
          child: Container(
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
                  child: accounts.isEmpty
                      ? _buildEmptyState(l10n)
                      : Builder(
                          builder: (context) {
                            // Récupérer le compte sélectionné
                            final selectedAccount = homeScreenViewModel.selectedAccount ?? accounts.first;

                            // Récupérer les transactions via TransactionListViewModel (MVVM)
                            final transactionListViewModel = ref.watch(transactionListViewModelProvider);
                            final transactions = transactionListViewModel.items;

                            // Vérifier si des transactions sont chargées pour ce compte
                            final bool hasTransactionsForAccount =
                                transactionListViewModel.selectedAccountId ==
                                    selectedAccount.id &&
                                transactions.isNotEmpty;

                            // Charger les transactions si nécessaire
                            if (transactionListViewModel.selectedAccountId !=
                                selectedAccount.id) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ref
                                    .read(transactionListViewModelProvider.notifier)
                                    .loadTransactionsForAccount(selectedAccount.id);
                              });
                            }

                            if (transactionListViewModel.isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (transactionListViewModel.hasError) {
                              return Center(
                                child: Text(
                                  'Erreur lors du chargement des transactions',
                                ),
                              );
                            }

                            if (!hasTransactionsForAccount) {
                              return _buildEmptyTransactionsState(l10n);
                            }

                            // Les transactions sont déjà gérées par TransactionListViewModel

                            // Utiliser les transactions du ViewModel (déjà filtrées)
                            final transactionsToDisplay = transactions;
                            final isSearchActive = transactionListViewModel.isFiltered;

                            if (transactionsToDisplay.isEmpty && isSearchActive) {
                              return _buildNoResultsState(l10n, appTheme);
                            }

                            return TransactionsList(
                              transactions: transactionsToDisplay,
                              onTransactionTap: _navigateToTransactionDetail,
                              scrollToToday: !isSearchActive, // Pas de scroll auto si recherche active
                              accountCurrency: selectedAccount.currency,
                            );
                          },
                        ),
                ),
              ],
            ),
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

  // _buildErrorState supprimé car géré directement dans le ViewModel
}
