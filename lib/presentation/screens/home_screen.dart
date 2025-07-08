import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/presentation/providers/database_provider.dart';
import 'package:bankapp/presentation/providers/card_swiper_provider.dart';
import 'package:bankapp/presentation/widgets/cards_swiper_widget.dart';
import 'package:bankapp/presentation/widgets/bank_card_widget.dart';
import 'package:bankapp/presentation/widgets/dashed_button.dart';
import 'package:bankapp/presentation/widgets/add_account_bottom_sheet.dart';
import 'package:bankapp/presentation/widgets/draggable_black_container.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/utils/card_color_utils.dart';
import 'package:bankapp/data/database/database.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  bool _shouldPlayCardAnimation = false;
  late AnimationController _containerAnimationController;
  late Animation<double> _containerAnimation;
  double _containerExtent = 0.67; // Position actuelle du container draggable

  @override
  void initState() {
    super.initState();

    // Animation controller pour synchroniser les cartes avec le container
    _containerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _containerAnimation = CurvedAnimation(
      parent: _containerAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _containerAnimationController.dispose();
    super.dispose();
  }

  // Callback appelé quand le container draggable bouge
  void _onContainerDragUpdate(double extent) {
    setState(() {
      _containerExtent = extent;
    });

    // Calculer la position d'animation basée sur l'extent du container
    // extent 0.4 (position normale) = animation à 0.0
    // extent 0.25 (position basse) = animation à 1.0
    final animationValue = ((0.4 - extent) / (0.4 - 0.25)).clamp(0.0, 1.0);
    _containerAnimationController.animateTo(animationValue);

    // Mettre à jour le provider pour la synchronisation
    final isExpanded = extent <= 0.3; // Considéré comme expanded si < 30%
    ref.read(cardsExpandedProvider.notifier).setExpanded(isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserAsync = ref.watch(currentUserProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final selectedCardIndex = ref.watch(selectedCardProvider);
    final isCardsExpanded = ref.watch(cardsExpandedProvider);

    return Scaffold(
      backgroundColor: AppColors.containerLightGray,
      body: SafeArea(
        child: Stack(
          children: [
            // Contenu principal avec header et cartes
            Column(
              children: [
                // Header avec menu hamburger, message de bienvenue et menu more
                _buildHeader(context, l10n, currentUserAsync),

                const SizedBox(height: 40),

                // Card Swiper avec animation synchronisée
                AnimatedBuilder(
                  animation: _containerAnimation,
                  builder: (context, child) {
                    // Calculer le décalage vertical basé sur l'animation
                    // Plus le container descend, plus les cartes descendent aussi
                    final verticalOffset = _containerAnimation.value * 80;

                    return Transform.translate(
                      offset: Offset(0, verticalOffset),
                      child: accountsAsync.when(
                        data: (accounts) {
                          if (accounts.isEmpty) {
                            return _buildEmptyState(context, l10n);
                          }

                          return Column(
                            children: [
                              // Card Swiper Widget
                              CardsSwiperWidget<Account>(
                                cardData: accounts,
                                onCardChange: (index) {
                                  // Mettre à jour la carte sélectionnée
                                  final accountIndex = accounts.indexWhere(
                                    (account) =>
                                        account.id == accounts[index].id,
                                  );
                                  if (accountIndex != -1) {
                                    ref
                                        .read(selectedCardProvider.notifier)
                                        .setSelectedCard(accountIndex);
                                  }
                                },
                                shouldStartCardCollectionAnimation:
                                    _shouldPlayCardAnimation,
                                onCardCollectionAnimationComplete: (value) {
                                  setState(() {
                                    _shouldPlayCardAnimation = value;
                                  });
                                },
                                cardBuilder:
                                    (context, accountIndex, visibleIndex) {
                                      if (accountIndex < 0 ||
                                          accountIndex >= accounts.length) {
                                        return const SizedBox.shrink();
                                      }

                                      final account = accounts[accountIndex];
                                      return Consumer(
                                        builder: (context, ref, child) {
                                          final accountSummaryAsync = ref.watch(
                                            accountSummaryProvider(account.id),
                                          );

                                          return accountSummaryAsync.when(
                                            data: (accountSummary) {
                                              return BankCardWidget(
                                                accountSummary: accountSummary,
                                                allAccounts: accounts,
                                              );
                                            },
                                            loading: () => _buildLoadingCard(
                                              account.id,
                                              accounts,
                                            ),
                                            error: (error, stack) =>
                                                _buildErrorCard(
                                                  account.id,
                                                  accounts,
                                                ),
                                          );
                                        },
                                      );
                                    },
                              ),

                              // Bouton "Ajouter un compte" visible quand expanded
                              AnimatedBuilder(
                                animation: _containerAnimation,
                                builder: (context, child) {
                                  // Calculer l'opacité et l'échelle du bouton
                                  final opacity = _containerAnimation.value;
                                  final scale =
                                      0.8 + (_containerAnimation.value * 0.2);

                                  return opacity > 0.1
                                      ? Opacity(
                                          opacity: opacity,
                                          child: Transform.scale(
                                            scale: scale,
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                top: 20,
                                                left: 20,
                                                right: 20,
                                              ),
                                              child: DashedButton(
                                                text: l10n.addAccount,
                                                icon: Icons.add,
                                                onTap: () {
                                                  _showAddAccountBottomSheet(
                                                    context,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                },
                              ),
                            ],
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text('Erreur: $error'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Container noir draggable
            DraggableBlackContainer(
              onDragUpdate: _onContainerDragUpdate,
              onStatisticsPressed: () {
                // TODO: Navigation vers les statistiques
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Statistiques - À implémenter')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<User> currentUserAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Menu hamburger
          GestureDetector(
            onTap: () {
              // TODO: Ouvrir le menu latéral
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu,
                color: AppColors.textDark,
                size: 20,
              ),
            ),
          ),

          // Message de bienvenue (centré)
          Expanded(
            child: Center(
              child: currentUserAsync.when(
                data: (user) => Text(
                  '${l10n.hello}, ${user.name}',
                  style: AppTextStyles.welcomeMessage,
                ),
                loading: () => Text(
                  '${l10n.hello}...',
                  style: AppTextStyles.welcomeMessage,
                ),
                error: (error, stack) =>
                    Text(l10n.hello, style: AppTextStyles.welcomeMessage),
              ),
            ),
          ),

          // Menu more (3 points)
          GestureDetector(
            onTap: () {
              // TODO: Ouvrir le menu contextuel
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.more_vert,
                color: AppColors.textDark,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
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
            onPressed: () {
              _showAddAccountBottomSheet(context);
            },
            child: Text(l10n.addAccount),
          ),
        ],
      ),
    );
  }

  void _showAddAccountBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddAccountBottomSheet(),
    );
  }

  Widget _buildLoadingCard(int accountId, List<Account> allAccounts) {
    final cardColor = CardColorUtils.getCardColorById(accountId, allAccounts);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      ),
    );
  }

  Widget _buildErrorCard(int accountId, List<Account> allAccounts) {
    final cardColor = CardColorUtils.getCardColorById(accountId, allAccounts);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Center(
        child: Icon(Icons.error_outline, color: AppColors.white, size: 48),
      ),
    );
  }
}
