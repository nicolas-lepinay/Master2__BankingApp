import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/presentation/providers/database_provider.dart';
import 'package:bankapp/presentation/providers/card_swiper_provider.dart';
import 'package:bankapp/presentation/widgets/transactions_list.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _dragController = DraggableScrollableController();
  }

  @override
  void dispose() {
    _dragController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchFocusNode.unfocus();
      } else {
        // Focus sur la barre de recherche quand elle apparaît
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      }
    });
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
    final selectedCardIndex = ref.watch(selectedCardProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return DraggableScrollableSheet(
      //controller: _dragController,
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
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20.r,
                offset: Offset(0, -4.h),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar pour indiquer qu'on peut tirer
              Container(
                margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                width: 30.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // Header avec titre et icône loupe
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Titre "Transactions" avec police Playfair
                  Text(
                    'Transactions', // TODO: Ajouter à l10n
                    style: AppTextStyles.sectionHeaderMediumDark,
                  ),

                  // Icône loupe/fermer
                  GestureDetector(
                    onTap: _toggleSearch,
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: AppColors.containerLightGray,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        _isSearchVisible ? Icons.close : Icons.search,
                        color: AppColors.textDark,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppConstants.mediumPadding.r),

              // Barre de recherche animée
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _isSearchVisible ? 60.h : 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _isSearchVisible ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.containerLightGray,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText:
                            'Saisir un montant, un nom, etc.', // TODO: Ajouter à l10n
                        hintStyle: AppTextStyles.searchPlaceholder,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 16.h,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textGray,
                          size: 20.sp,
                        ),
                      ),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDark,
                      ),
                      onChanged: (value) {
                        // TODO: Implémenter la logique de recherche dans ÉTAPE 3
                      },
                    ),
                  ),
                ),
              ),

              // Espace entre barre de recherche et liste
              if (_isSearchVisible)
                SizedBox(height: AppConstants.largePadding.r),

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

                        return TransactionsList(
                          transactions: transactions,
                          onTransactionTap: _navigateToTransactionDetail,
                          scrollToToday: true, // Auto-scroll vers aujourd'hui
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
