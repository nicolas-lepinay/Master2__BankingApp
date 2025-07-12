import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/data/database/database.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/presentation/providers/database_provider.dart';
import 'package:bankapp/presentation/widgets/followed_transaction_item.dart';
import 'package:bankapp/presentation/screens/transaction_detail_screen.dart';

class FollowedTransactionsCarousel extends ConsumerStatefulWidget {
  final VoidCallback? onSeeAllPressed;

  const FollowedTransactionsCarousel({super.key, this.onSeeAllPressed});

  @override
  ConsumerState<FollowedTransactionsCarousel> createState() =>
      _FollowedTransactionsCarouselState();
}

class _FollowedTransactionsCarouselState
    extends ConsumerState<FollowedTransactionsCarousel>
    with TickerProviderStateMixin {
  final List<AnimationController> _animationControllers = [];
  final List<Animation<Offset>> _slideAnimations = [];

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followedTransactionsAsync = ref.watch(followedTransactionsProvider);

    return followedTransactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return _buildEmptyState();
        }

        return _buildCarousel(transactions);
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.containerDarkGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'Aucune transaction suivie',
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.containerDarkGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.textLight,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.containerDarkGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'Erreur de chargement',
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCarousel(List<TransactionWithCounterparty> transactions) {
    // Limiter à 5 transactions + gérer les points de suspension
    final displayTransactions = transactions.take(5).toList();
    final hasMore = transactions.length > 5;

    // Initialiser les controllers d'animation si nécessaire
    _initializeAnimationControllers(displayTransactions.length);

    return SizedBox(
      height: 80, // Hauteur minimale, mais peut s'étendre si nécessaire
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ), // Réduire le padding vertical
        itemCount: displayTransactions.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Dernier item = points de suspension
          if (hasMore && index == displayTransactions.length) {
            return _buildMoreIndicator();
          }

          // Items de transactions avec animation
          final transactionWithCounterparty = displayTransactions[index];
          return SlideTransition(
            position: _slideAnimations[index],
            child: FollowedTransactionItem(
              transactionWithCounterparty: transactionWithCounterparty,
              onTap: () => _navigateToTransactionDetail(
                transactionWithCounterparty.transaction,
              ),
              onStarTap: () => _removeFromFollowed(
                transactionWithCounterparty.transaction.id,
                index,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoreIndicator() {
    return GestureDetector(
      onTap: widget.onSeeAllPressed,
      child: Container(
        width: 60,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.containerDarkGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: const Center(
          child: Text(
            '...',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _initializeAnimationControllers(int count) {
    // Disposer les anciens controllers
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    _animationControllers.clear();
    _slideAnimations.clear();

    // Créer de nouveaux controllers
    for (int i = 0; i < count; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
      _animationControllers.add(controller);

      final slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, 2), // Glisser vers le bas
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
      _slideAnimations.add(slideAnimation);
    }
  }

  Future<void> _removeFromFollowed(int transactionId, int index) async {
    try {
      // Démarrer l'animation de glissement
      await _animationControllers[index].forward();

      // Retirer de la base de données
      final database = ref.read(databaseProvider);
      await database.removeFollowedTransaction(transactionId);

      // Rafraîchir la liste
      ref.invalidate(followedTransactionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction retirée du suivi'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // En cas d'erreur, revenir à la position initiale
      if (mounted) {
        _animationControllers[index].reverse();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
