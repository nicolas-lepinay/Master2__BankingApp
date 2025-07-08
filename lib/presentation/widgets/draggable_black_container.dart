import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';

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
  double _currentExtent = 0.4; // Position initiale : 40% de l'écran

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
    final screenHeight = MediaQuery.of(context).size.height;

    return DraggableScrollableSheet(
      controller: _dragController,
      initialChildSize: 0.7, // 40% de l'écran initialement
      minChildSize: 0.15, // Minimum 25% (environ 300px sur un écran standard)
      maxChildSize: 0.85, // Maximum 85% de l'écran
      snap: true,
      snapSizes: const [0.15, 0.7, 0.85], // Points d'accroche
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
                  color: AppColors.white.withOpacity(0.3),
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
              color: AppColors.textLight.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsContainer() {
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
      child: const Center(
        child: Text(
          'PerspectiveListView\n(Étape 5)',
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
              color: AppColors.textLight.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowedTransactionsCarousel() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.containerDarkGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'Carousel Transactions Suivies\n(Étape 6)',
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
}
