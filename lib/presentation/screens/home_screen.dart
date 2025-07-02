import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/presentation/providers/database_provider.dart';
import 'package:bankapp/presentation/providers/navigation_provider.dart';
import 'package:bankapp/presentation/widgets/account_card.dart';
import 'package:bankapp/presentation/widgets/transactions_list.dart';
import 'package:bankapp/presentation/widgets/add_account_bottom_sheet.dart';
import 'package:bankapp/presentation/screens/transaction_detail_screen.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/data/database/database.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final currentPageIndex = ref.watch(pageViewProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: accountsAsync.when(
        data: (accounts) {
          final totalPages = accounts.length + 1; // +1 pour la page d'ajout

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: AppConstants.defaultPadding),

                // Indicateurs de pages (dots)
                _buildPageIndicators(totalPages, currentPageIndex),

                const SizedBox(height: AppConstants.largePadding),

                // PageView avec les comptes
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      ref.read(pageViewProvider.notifier).setPageIndex(index);
                    },
                    itemCount: totalPages,
                    itemBuilder: (context, index) {
                      // Dernière page = page d'ajout de compte
                      if (index == accounts.length) {
                        return _buildAddAccountPage();
                      }

                      // Pages de comptes
                      final account = accounts[index];
                      return _buildAccountPage(account);
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildPageIndicators(int totalPages, int currentPage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppColors.primary
                : AppColors.textSecondary.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  Widget _buildAccountPage(Account account) {
    return Consumer(
      builder: (context, ref, child) {
        final accountSummaryAsync = ref.watch(
          accountSummaryProvider(account.id),
        );
        final transactionsAsync = ref.watch(
          transactionsWithBalanceProvider(account.id),
        );

        return accountSummaryAsync.when(
          data: (accountSummary) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Carte du compte
                  AccountCard(accountSummary: accountSummary),

                  const SizedBox(height: AppConstants.largePadding),

                  // Liste des transactions
                  transactionsAsync.when(
                    data: (transactions) {
                      return TransactionsList(
                        transactions: transactions,
                        onTransactionTap: (transaction) {
                          _navigateToTransactionDetail(transaction);
                        },
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppConstants.largePadding),
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Padding(
                      padding: const EdgeInsets.all(AppConstants.largePadding),
                      child: Text('Erreur: $error'),
                    ),
                  ),

                  const SizedBox(height: 100), // Espace pour la bottom nav
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Erreur: $error')),
        );
      },
    );
  }

  Widget _buildAddAccountPage() {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 40, color: AppColors.primary),
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          Text(l10n.addAccount, style: AppTextStyles.h5),

          const SizedBox(height: AppConstants.smallPadding),

          Text(
            'Appuyez pour créer un nouveau compte',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppConstants.largePadding),

          ElevatedButton(
            onPressed: _showAddAccountBottomSheet,
            child: Text(l10n.addAccount),
          ),
        ],
      ),
    );
  }

  void _showAddAccountBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddAccountBottomSheet(),
    );
  }

  void _navigateToTransactionDetail(Transaction transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            TransactionDetailScreen(transactionId: transaction.id),
      ),
    );
  }
}
