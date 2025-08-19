import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/theme/app_colors.dart';
// import 'package:bankapp/data/database/app_database.dart'; // Supprimé avec MVVM
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/screens/transaction_detail_screen.dart';
import 'package:bankapp/presentation/widgets/followed_transaction_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final transactionRepository = ref.watch(transactionRepositoryProvider);
    
    return FutureBuilder<List<domain.TransactionWithBalance>>(
      future: transactionRepository.getFollowedTransactionsWithDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        
        if (snapshot.hasError) {
          print('FollowedTransactionsCarousel Error: ${snapshot.error}');
          return _buildErrorState();
        }
        
        final transactions = snapshot.data ?? [];
        if (transactions.isEmpty) {
          return _buildEmptyState();
        }

        return _buildCarousel(transactions);
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 80.h,
      margin: EdgeInsets.symmetric(
        horizontal: AppConstants.veryLargePadding.r,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.containerDarkGray,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Center(
        child: Text(
          'Aucune transaction suivie',
          style: TextStyle(
            color: AppColors.onSurfaceDark,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 80.h,
      margin: EdgeInsets.symmetric(
        horizontal: AppConstants.veryLargePadding.r,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.containerDarkGray,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.onSurfaceDark,
          strokeWidth: 2.w,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 80.h,
      margin: EdgeInsets.symmetric(
        horizontal: AppConstants.veryLargePadding.r,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.containerDarkGray,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Center(
        child: Text(
          'Erreur de chargement',
          style: TextStyle(
            color: AppColors.onSurfaceDark,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCarousel(List<domain.TransactionWithBalance> transactions) {
    // Limiter à 5 transactions + gérer les points de suspension
    final displayTransactions = transactions.take(5).toList();
    final hasMore = transactions.length >= 3;

    // Initialiser les controllers d'animation si nécessaire
    _initializeAnimationControllers(displayTransactions.length);

    return SizedBox(
      height: 80.h, // Hauteur minimale, mais peut s'étendre si nécessaire
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.veryLargePadding.r,
        ),
        itemCount: displayTransactions.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Dernier item = points de suspension
          if (hasMore && index == displayTransactions.length) {
            return _buildMoreIndicator();
          }

          // Items de transactions avec animation
          final transactionWithBalance = displayTransactions[index];
          return SlideTransition(
            position: _slideAnimations[index],
            child: FollowedTransactionItem(
              transactionWithCounterparty: transactionWithBalance,
              onTap: () => _navigateToTransactionDetail(
                transactionWithBalance.transaction,
              ),
              onIconTap: () => _removeFromFollowed(
                transactionWithBalance.transaction.id,
                index,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoreIndicator() {
    return InkWell(
      onTap: widget.onSeeAllPressed,
      child: Container(
        width: 60.w,
        alignment: Alignment.topCenter,
        padding: EdgeInsets.only(top: 10.0.r),
        child: Text(
          '...',
          style: TextStyle(
            color: AppColors.textLight50,
            fontSize: 26.sp,
            fontWeight: FontWeight.w300,
            //fontWeight: FontWeight.bold,
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

      // Retirer de la base de données via le repository MVVM
      final transactionRepository = ref.read(transactionRepositoryProvider);
      await transactionRepository.unfollowTransaction(transactionId);

      // Rafraîchir l'écran en rechargant la widget
      if (mounted) setState(() {});

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

  void _navigateToTransactionDetail(domain.Transaction transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            TransactionDetailScreen(transactionId: transaction.id),
      ),
    );
  }
}
