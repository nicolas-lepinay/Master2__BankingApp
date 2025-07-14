import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/presentation/providers/database_provider.dart';
import 'package:bankapp/presentation/providers/card_swiper_provider.dart';
import 'package:bankapp/presentation/providers/transaction_search_provider.dart';
import 'package:bankapp/presentation/widgets/perspective_list_view.dart';
import 'package:bankapp/presentation/widgets/perspective_transaction_item.dart';
import 'package:bankapp/presentation/widgets/followed_transactions_carousel.dart';
import 'package:bankapp/presentation/widgets/full_transactions_bottom_sheet.dart';
import 'package:bankapp/presentation/widgets/add_transaction_bottom_sheet.dart';
import 'package:bankapp/presentation/screens/transaction_detail_screen.dart';
import 'package:bankapp/presentation/widgets/dashed_button.dart';
import 'package:bankapp/data/database/database.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DraggableBlackContainer extends ConsumerStatefulWidget {
  final Function(double)? onDragUpdate;
  final VoidCallback? onStatisticsPressed;

  const DraggableBlackContainer({
    super.key,
    this.onDragUpdate,
    this.onStatisticsPressed,
  });

  @override
  ConsumerState<DraggableBlackContainer> createState() =>
      _DraggableBlackContainerState();
}

class _DraggableBlackContainerState
    extends ConsumerState<DraggableBlackContainer> {
  late DraggableScrollableController _dragController;
  double _currentExtent = 0.72; // Position initiale

  @override
  void initState() {
    super.initState();
    _dragController = DraggableScrollableController();

    // Écouter les changements de position
    _dragController.addListener(() {
      if (_dragController.isAttached) {
        final newExtent = _dragController.size;
        if (newExtent != _currentExtent) {
          setState(() {
            _currentExtent = newExtent;
          });
          // Notifier le parent du changement pour animer les cartes
          widget.onDragUpdate?.call(newExtent);
        }
      }
    });
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    //final screenHeight = MediaQuery.of(context).size.height;

    return DraggableScrollableSheet(
      controller: _dragController,
      initialChildSize: 0.72,
      minChildSize: 0.17,
      maxChildSize: 0.86,
      snap: true,
      snapSizes: const [0.17, 0.72, 0.86], // Points d'accroche
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceBrightDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(38.r)),
          ),
          child: Column(
            children: [
              // Handle bar pour indiquer qu'on peut tirer
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 30,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // Contenu scrollable
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: 0, //28.r,
                    vertical: 16.r,
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsetsGeometry.symmetric(
                        horizontal: AppConstants.veryLargePadding.r,
                      ),
                      child: Column(
                        children: [
                          // Bouton Statistiques
                          _buildStatisticsButton(l10n),
                          SizedBox(height: 32.h),
                          // Header Transactions + Voir tout
                          _buildTransactionsHeader(l10n),
                          SizedBox(height: 16.h),
                          // Container avec dégradé rose pour la liste des transactions
                          _buildTransactionsContainer(l10n),
                          SizedBox(height: 32.h),
                          // Header Transactions suivies + Voir tout
                          _buildFollowedTransactionsHeader(l10n),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
                    // Carousel des transactions suivies
                    _buildFollowedTransactionsCarousel(),
                    // Espace pour la navigation bar
                    SizedBox(height: 150.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsButton(AppLocalizations l10n) {
    return ElevatedButton(
      onPressed: widget.onStatisticsPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.textLight100,
        backgroundColor: AppColors.surfaceDimDark,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Statistiques"),
          Icon(
            CupertinoIcons.arrow_up_right,
            color: AppColors.textLight100,
            size: 32.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsHeader(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _showFullTransactionsBottomSheet,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.transactions,
            style: AppTextStyles.sectionHeader.copyWith(
              color: AppColors.textLight100,
            ),
          ),
          Text(
            l10n.seeAll,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsContainer(AppLocalizations l10n) {
    final selectedCardIndex = ref.watch(selectedCardProvider);
    final accountsAsync = ref.watch(accountsProvider);

    // Configuration centralisée de la liste perspective
    const int perspectiveVisualizedItems = 3; // Nombre d'items visibles
    const double perspectiveItemExtent = 95.0; // Hauteur de chaque item
    const double perspectiveMinScale = 0.85; // Échelle des items arrière
    const double containerHeight = 260.0; // Hauteur du container rose

    return accountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) {
          return _buildEmptyTransactionsContainer(
            onAddTransaction: _showAddTransactionBottomSheet,
            l10n: l10n,
          );
        }

        // Récupérer le compte sélectionné
        final selectedAccount = selectedCardIndex < accounts.length
            ? accounts[selectedCardIndex]
            : accounts.first;

        // Récupérer les transactions centrées autour d'aujourd'hui pour le compte sélectionné
        final transactionsAsync = ref.watch(
          transactionsAroundTodayProvider(selectedAccount.id),
        );

        return transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return _buildEmptyTransactionsContainer(
                onAddTransaction: _showAddTransactionBottomSheet,
                l10n: l10n,
              );
            }

            // Les transactions sont déjà limitées à 50 (25 passées + 25 futures)
            // et centrées autour d'aujourd'hui par la méthode de base de données

            return GestureDetector(
              onTap: _showFullTransactionsBottomSheet,
              child: Container(
                height: containerHeight.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.gradientPinkStart, // #FE68E8
                      AppColors.gradientPinkEnd, // #FBA9ED
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28.r),
                  child: PerspectiveListView(
                    visualizedItems:
                        perspectiveVisualizedItems, // Utilise la variable
                    itemExtent: perspectiveItemExtent.h, // Utilise la variable
                    minScale:
                        perspectiveMinScale, // Nouveau paramètre personnalisé
                    initialIndex: _findTodayTransactionIndex(transactions),
                    padding: EdgeInsets.only(top: 20.r, bottom: 20.r),
                    onTapFrontItem: (index) {
                      if (index != null && index < transactions.length) {
                        _navigateToTransactionDetail(
                          transactions[index].transaction,
                        );
                      }
                    },
                    onChangeFrontItem: (index) {
                      // Callback quand la transaction au premier plan change
                    },
                    children: transactions.map((transactionWithCounterparty) {
                      return PerspectiveTransactionItem(
                        transactionWithCounterparty:
                            transactionWithCounterparty,
                        onTap: () => _navigateToTransactionDetail(
                          transactionWithCounterparty.transaction,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
          loading: () => _buildLoadingTransactionsContainer(),
          error: (error, stack) => _buildErrorTransactionsContainer(),
        );
      },
      loading: () => _buildLoadingTransactionsContainer(),
      error: (error, stack) => _buildErrorTransactionsContainer(),
    );
  }

  Widget _buildEmptyTransactionsContainer({
    required VoidCallback onAddTransaction,
    required AppLocalizations l10n,
  }) {
    const double containerHeight = 260.0;

    // Nombre total d'éléments dans la ListView, y compris l'en-tête
    const int headerItemCount = 1;
    const int dashedButtonCount = 8;
    const int totalItemCount = headerItemCount + dashedButtonCount;
    const double startOpacity = 1.0;
    const double endOpacity = 0.2;

    return Container(
      height: containerHeight.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.gradientPinkStart, AppColors.gradientPinkEnd],
        ),
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: ListView.builder(
        controller: ScrollController(),
        padding: EdgeInsets.only(
          top: AppConstants.largePadding,
          left: AppConstants.veryLargePadding,
          right: AppConstants.veryLargePadding,
        ),
        itemCount: totalItemCount,
        itemBuilder: (BuildContext context, int index) {
          // Logique pour l'en-tête (icône et texte)
          if (index == 0) {
            return Column(
              children: [
                // Icône
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBrightLight.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.textLight100,
                    size: 28.sp,
                  ),
                ),

                SizedBox(height: AppConstants.defaultPadding.r),

                // Texte principal
                Text(
                  l10n.noTransactions,
                  style: AppTextStyles.h5.copyWith(
                    color: AppColors.textLight100,
                    fontFamily: AppTextStyles.playfairFontFamily,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppConstants.verySmallPadding.r),

                // Texte secondaire
                Text(
                  l10n.startAddingTransactions,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textLight100.withValues(alpha: 0.8),
                    fontSize: 15.sp,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppConstants.largePadding.r),
              ],
            );
          }

          // Logique pour les DashedButtons
          // L'index des boutons commence après l'en-tête
          final int buttonIndex = index - headerItemCount;

          // Calcul de l'opacité basé sur l'index du bouton
          final double factor = buttonIndex / (dashedButtonCount - 1);
          final double opacity =
              startOpacity - (startOpacity - endOpacity) * factor;

          return Container(
            margin: EdgeInsets.only(bottom: AppConstants.veryLargePadding),
            child: Opacity(
              opacity: opacity,
              child: DashedButton(
                text: l10n.addTransaction,
                icon: Icons.add,
                textStyle: AppTextStyles.buttonText.copyWith(fontSize: 18.sp),
                dashColor: Colors.white,
                onTap: onAddTransaction,
              ),
            ),
          );
        },
      ),
    ) /*Container(
      height: containerHeight.h,
      padding: EdgeInsets.symmetric(horizontal: AppConstants.veryLargePadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.gradientPinkStart, AppColors.gradientPinkEnd],
        ),
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône
            Container(
              width: 60.w,
              height: 60.h,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: AppColors.textLight100,
                size: 28.sp,
              ),
            ),

            SizedBox(height: 16.h),

            // Texte principal
            Text(
              'Aucune transaction',
              style: TextStyle(
                color: AppColors.textLight100,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 8.h),

            // Texte secondaire
            Text(
              'Commencez par ajouter votre première transaction',
              style: TextStyle(
                color: AppColors.textLight100.withValues(alpha: 0.7),
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20.h),

            // Bouton "Ajouter une transaction"
            if (onAddTransaction != null)
              DashedButton(
                text: "Ajouter une transaction".toUpperCase(),
                icon: Icons.add,
                textStyle: AppTextStyles.buttonText.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                dashColor: Colors.white.withValues(alpha: 1),
                verticalPadding: AppConstants.smallPadding,
                horizontalPadding: AppConstants.defaultPadding,
                borderRadius: 16,
                onTap: onAddTransaction,
              ),
          ],
        ),
      ),
    )*/;
  }

  Widget _buildLoadingTransactionsContainer() {
    const double containerHeight = 260.0; // Hauteur du container rose

    return Container(
      height: containerHeight.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.gradientPinkStart, AppColors.gradientPinkEnd],
        ),
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.onSurfaceLight),
      ),
    );
  }

  Widget _buildErrorTransactionsContainer() {
    const double containerHeight = 260.0; // Hauteur du container rose

    return Container(
      height: containerHeight.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.gradientPinkStart, AppColors.gradientPinkEnd],
        ),
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Center(
        child: Text(
          'Erreur de chargement',
          style: TextStyle(
            color: AppColors.onSurfaceLight,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Trouve l'index de la transaction la plus proche d'aujourd'hui
  int _findTodayTransactionIndex(
    List<TransactionWithCounterparty> transactions,
  ) {
    if (transactions.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int closestIndex = 0;
    Duration smallestDifference = Duration.zero;

    for (int i = 0; i < transactions.length; i++) {
      final transactionDate = transactions[i].transaction.date;
      final transactionDateOnly = DateTime(
        transactionDate.year,
        transactionDate.month,
        transactionDate.day,
      );
      final difference = today.difference(transactionDateOnly).abs();

      if (i == 0 || difference < smallestDifference) {
        smallestDifference = difference;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  void _showFullTransactionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const FullTransactionsBottomSheet(),
    ).then((_) {
      // Reset de la recherche quand la BottomSheet se ferme, après 1 seconde
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          ref.read(transactionSearchProvider.notifier).clearSearch();
        });
      }
    });
  }

  void _showAddTransactionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const AddTransactionBottomSheet(),
    ).then((_) {
      // Invalider les providers liés aux transactions après fermeture
      if (mounted) {
        ref.invalidate(accountSummaryProvider);
        ref.invalidate(transactionsWithBalanceProvider);
        ref.invalidate(transactionsAroundTodayProvider);
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

  Widget _buildFollowedTransactionsHeader(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.followedTransactions,
          style: AppTextStyles.sectionHeader.copyWith(
            color: AppColors.textLight100,
          ),
        ),
        GestureDetector(
          onTap: () {
            // TODO: Action "Voir tout" transactions suivies
          },
          child: Text(
            l10n.seeAll,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowedTransactionsCarousel() {
    return FollowedTransactionsCarousel(
      onSeeAllPressed: () {
        // TODO: Navigation vers la liste complète des transactions suivies
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Voir toutes les transactions suivies - À implémenter',
            ),
            backgroundColor: Colors.blue,
          ),
        );
      },
    );
  }
}
