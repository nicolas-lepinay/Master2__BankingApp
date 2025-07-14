import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/presentation/providers/database_provider.dart';
import 'package:bankapp/presentation/providers/card_swiper_provider.dart';
import 'package:bankapp/presentation/widgets/perspective_list_view.dart';
import 'package:bankapp/presentation/widgets/perspective_transaction_item.dart';
import 'package:bankapp/presentation/widgets/followed_transactions_carousel.dart';
import 'package:bankapp/presentation/widgets/full_transactions_bottom_sheet.dart';
import 'package:bankapp/presentation/screens/transaction_detail_screen.dart';
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
            color: AppColors.containerBlack,
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
                          _buildTransactionsContainer(),
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
                    SizedBox(height: 100.h),
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
        foregroundColor: AppColors.ultraLight,
        backgroundColor: AppColors.buttonLight,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Statistiques"),
          Icon(
            CupertinoIcons.arrow_up_right,
            color: AppColors.ultraLight,
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
            'Transactions', // TODO: Ajouter à l10n
            style: AppTextStyles.sectionHeader,
          ),
          Text(
            'Voir tout', // TODO: Ajouter à l10n
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceDark.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsContainer() {
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
          return _buildEmptyTransactionsContainer();
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
              return _buildEmptyTransactionsContainer();
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

  Widget _buildEmptyTransactionsContainer() {
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
          'Aucune transaction',
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

  Widget _buildFollowedTransactionsHeader(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Transactions suivies', // TODO: Ajouter à l10n
          style: AppTextStyles.sectionHeader,
        ),
        GestureDetector(
          onTap: () {
            // TODO: Action "Voir tout" transactions suivies
          },
          child: Text(
            'Voir tout', // TODO: Ajouter à l10n
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceDark.withValues(alpha: 0.8),
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

  /// Provider pour récupérer les transactions centrées autour d'aujourd'hui
  /// (Utilise la nouvelle méthode de la base de données)
  static final transactionsAroundTodayProvider =
      FutureProvider.family<List<TransactionWithCounterparty>, int>((
        ref,
        accountId,
      ) async {
        final database = ref.read(databaseProvider);
        return database.getTransactionsAroundToday(accountId);
      });
}
