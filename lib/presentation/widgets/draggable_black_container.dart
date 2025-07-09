import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/utils/draggable_snap_sizer.dart';
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
  ConsumerState<DraggableBlackContainer> createState() => _DraggableBlackContainerState();
}

class _DraggableBlackContainerState extends ConsumerState<DraggableBlackContainer>
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
    _snapAnimation = Tween<double>(
      begin: _currentExtent,
      end: targetBreakpoint,
    ).animate(CurvedAnimation(parent: _snapAnimationController, curve: Curves.easeInOut));

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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            const Icon(Icons.arrow_forward, color: AppColors.textLight, size: 20),
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
          style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w600),
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
              color: AppColors.textLight.withValues(alpha: 0.8),
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
          style: TextStyle(color: AppColors.textLight, fontSize: 14, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
