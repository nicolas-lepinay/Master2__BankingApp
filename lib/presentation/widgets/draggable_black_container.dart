import 'package:animate_gradient/animate_gradient.dart';
import 'package:bankapp/presentation/widgets/astroid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/utils/draggable_snap_sizer.dart';
import 'package:bankapp/presentation/providers/database_provider.dart';
import 'package:bankapp/presentation/providers/card_swiper_provider.dart';
import 'package:bankapp/presentation/widgets/perspective_list_view.dart';
import 'package:bankapp/presentation/widgets/perspective_transaction_item.dart';
import 'package:bankapp/presentation/widgets/followed_transactions_carousel.dart';
import 'package:bankapp/presentation/screens/transaction_detail_screen.dart';
import 'package:bankapp/data/database/database.dart';
import 'dart:async';

class DraggableBlackContainer extends ConsumerStatefulWidget {
  final Function(double)? onDragUpdate;
  final VoidCallback? onStatisticsPressed;
  final bool autoSnap;

  const DraggableBlackContainer({
    super.key,
    this.onDragUpdate,
    this.onStatisticsPressed,
    this.autoSnap = false,
  });

  @override
  ConsumerState<DraggableBlackContainer> createState() =>
      _DraggableBlackContainerState();
}

class _DraggableBlackContainerState
    extends ConsumerState<DraggableBlackContainer>
    with TickerProviderStateMixin {
  late DraggableScrollableController _dragController;
  late AnimationController _snapAnimationController;
  late Animation<double> _snapAnimation;

  double _currentExtent = 0.67;
  final double _minChildSize = 0.15;
  double _maxChildSize = 0.84;
  double _initialChildSize = 0.67;

  bool _isDragging = false;
  Timer? _snapTimer;

  @override
  void initState() {
    super.initState();
    _dragController = DraggableScrollableController();

    // Initialiser l'animation controller pour le snap
    _snapAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Calculer les breakpoints dynamiques
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateDynamicBreakpoints();
    });

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

          // Gérer le snap manuel
          if (widget.autoSnap) _handleManualSnap();
        }
      }
    });
  }

  @override
  void dispose() {
    _dragController.dispose();
    _snapAnimationController.dispose();
    _snapTimer?.cancel();
    super.dispose();
  }

  void _calculateDynamicBreakpoints() {
    final screenHeight = MediaQuery.of(context).size.height;
    final snapSizes = DraggableSnapSizer.calculateSnapSizes(screenHeight);

    setState(() {
      _initialChildSize = snapSizes.intermediate;
      _maxChildSize = snapSizes.max;
      _currentExtent = _initialChildSize;
    });
  }

  void _handleManualSnap() {
    // Annuler le timer précédent
    _snapTimer?.cancel();

    // Ne démarrer le timer que si on n'est pas en train de drag
    if (!_isDragging) {
      // Démarrer un nouveau timer pour détecter la fin du drag
      _snapTimer = Timer(const Duration(milliseconds: 300), () {
        if (!_isDragging) {
          _snapToNearestBreakpoint();
        }
      });
    }
  }

  void _snapToNearestBreakpoint() {
    final breakpoints = [_minChildSize, _initialChildSize, _maxChildSize];
    double nearestBreakpoint = breakpoints[0];
    double minDistance = (_currentExtent - breakpoints[0]).abs();

    for (final breakpoint in breakpoints) {
      final distance = (_currentExtent - breakpoint).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearestBreakpoint = breakpoint;
      }
    }

    // Animer vers le breakpoint le plus proche
    if ((_currentExtent - nearestBreakpoint).abs() > 0.01) {
      _animateToBreakpoint(nearestBreakpoint);
    }
  }

  void _animateToBreakpoint(double targetBreakpoint) {
    _snapAnimation = Tween<double>(begin: _currentExtent, end: targetBreakpoint)
        .animate(
          CurvedAnimation(
            parent: _snapAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _snapAnimation.addListener(() {
      if (_dragController.isAttached) {
        _dragController.animateTo(
          _snapAnimation.value,
          duration: const Duration(milliseconds: 1),
          curve: Curves.linear,
        );
      }
    });

    _snapAnimationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        setState(() {
          _isDragging = notification.extent != _currentExtent;
        });
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _dragController,
        initialChildSize: _initialChildSize,
        minChildSize: _minChildSize,
        maxChildSize: _maxChildSize,
        snap: false, // False par défaut (bug si True) --> géré manuellement
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.containerBlack,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                // Handle bar pour indiquer qu'on peut tirer
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Contenu scrollable
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    children: [
                      // Bouton Statistiques
                      _buildStatisticsButton(l10n),

                      const SizedBox(height: 32),

                      // Header Transactions + Voir tout
                      _buildTransactionsHeader(l10n),

                      const SizedBox(height: 16),

                      // Container avec dégradé rose pour la liste des transactions
                      _buildTransactionsContainer(),

                      const SizedBox(height: 32),

                      // Header Transactions suivies + Voir tout
                      _buildFollowedTransactionsHeader(l10n),

                      const SizedBox(height: 16),

                      // Carousel des transactions suivies
                      _buildFollowedTransactionsCarousel(),

                      // Espace pour la navigation bar
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsButton(AppLocalizations l10n) {
    return GestureDetector(
      onTap: widget.onStatisticsPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.containerDarkGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Statistiques', // TODO: Ajouter à l10n
              style: AppTextStyles.statisticsButtonText,
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.arrow_forward,
              color: AppColors.textLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsHeader(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Transactions', // TODO: Ajouter à l10n
          style: AppTextStyles.sectionHeader,
        ),
        GestureDetector(
          onTap: () {
            // TODO: Action "Voir tout" transactions
          },
          child: Text(
            'Voir tout', // TODO: Ajouter à l10n
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsContainer() {
    final selectedCardIndex = ref.watch(selectedCardProvider);
    final accountsAsync = ref.watch(accountsProvider);

    // Configuration centralisée de la liste perspective
    const int perspectiveVisualizedItems = 3; // Nombre d'items visibles
    const double perspectiveItemExtent = 100.0; // Hauteur de chaque item
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

            return Container(
              height: 300, // Hauteur fixe pour la liste avec perspective
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.gradientPinkStart, // #FE68E8
                    AppColors.gradientPinkEnd, // #FBA9ED
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: PerspectiveListView(
                  visualizedItems:
                      perspectiveVisualizedItems, // Utilise la variable
                  itemExtent: perspectiveItemExtent, // Utilise la variable
                  minScale:
                      perspectiveMinScale, // Nouveau paramètre personnalisé
                  initialIndex: _findTodayTransactionIndex(transactions),
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
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
                      transactionWithCounterparty: transactionWithCounterparty,
                      onTap: () => _navigateToTransactionDetail(
                        transactionWithCounterparty.transaction,
                      ),
                    );
                  }).toList(),
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
      height: containerHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.gradientPinkStart, AppColors.gradientPinkEnd],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Text(
          'Aucune transaction',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLoadingTransactionsContainer() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.gradientPinkStart, AppColors.gradientPinkEnd],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.textDark),
      ),
    );
  }

  Widget _buildErrorTransactionsContainer() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.gradientPinkStart, AppColors.gradientPinkEnd],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Text(
          'Erreur de chargement',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
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
              color: AppColors.textLight.withValues(alpha: 0.8),
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
