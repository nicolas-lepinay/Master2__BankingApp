import 'package:bankapp/presentation/widgets/dashed_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/presentation/providers/database_provider.dart';
import 'package:bankapp/presentation/providers/card_swiper_provider.dart';
import 'package:bankapp/presentation/widgets/cards_swiper_widget.dart';
import 'package:bankapp/presentation/widgets/bank_card_widget.dart';
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
  double? _balanceBottomPosition; // Position Y du bas du solde

  @override
  void initState() {
    super.initState();

    // Animation controller pour le container noir
    _containerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
                //Container(color: Colors.cyanAccent, height: 247.33, width: double.infinity),
                // Header avec menu hamburger, message de bienvenue et menu more
                _buildHeader(context, l10n, currentUserAsync),

                const SizedBox(height: 40),

                // Card Swiper (maintenant avec animation)
                AnimatedBuilder(
                  animation: _containerAnimation,
                  builder: (context, child) {
                    // Calculer le décalage vertical basé sur l'animation
                    final verticalOffset = _containerAnimation.value;

                    return Transform.translate(
                      offset: Offset(0, verticalOffset),
                      child: accountsAsync.when(
                        data: (accounts) {
                          if (accounts.isEmpty) {
                            return _buildEmptyState(context, l10n);
                          }

                          return Column(
                            children: [
                              // Card Swiper Widget avec hauteur adaptative
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
                                cardBuilder: (context, accountIndex, visibleIndex) {
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
                                            allAccounts:
                                                accounts, // Passer tous les comptes
                                            onBalancePositionChanged:
                                                (position) {
                                                  setState(() {
                                                    _balanceBottomPosition =
                                                        position;
                                                  });
                                                },
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

                              const SizedBox(height: 20),

                              // Bouton temporaire pour tester l'animation du container
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_containerAnimationController
                                        .isCompleted) {
                                      _containerAnimationController.reverse();
                                      ref
                                          .read(cardsExpandedProvider.notifier)
                                          .setExpanded(false);
                                    } else {
                                      _containerAnimationController.forward();
                                      ref
                                          .read(cardsExpandedProvider.notifier)
                                          .setExpanded(true);
                                    }
                                  },
                                  child: Text(
                                    isCardsExpanded
                                        ? 'Remonter le container'
                                        : 'Descendre le container',
                                  ),
                                ),
                              ),

                              // Bouton "Ajouter un compte" en mode expanded
                              if (isCardsExpanded) ...[
                                const SizedBox(height: 20),
                                _buildAddAccountButton(context, l10n),
                              ],
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

            // Container noir positionné en bas avec animation
            AnimatedBuilder(
              animation: _containerAnimation,
              builder: (context, child) {
                // Calculer la position dynamiquement basée sur la position du solde
                final screenHeight = MediaQuery.of(context).size.height;
                double containerTop;

                if (_balanceBottomPosition != null) {
                  // Position normale : juste en dessous du solde avec un petit offset
                  // Réduire l'offset pour le Samsung Galaxy Z Flip 6
                  final normalTop = _balanceBottomPosition! + 0;
                  // Position expanded : descendre pour révéler les cartes complètes
                  final expandedOffset = _containerAnimation.value * 100;
                  containerTop = normalTop + expandedOffset;
                } else {
                  // Fallback si la position n'est pas encore mesurée
                  containerTop =
                      screenHeight * 0.4 + (_containerAnimation.value * 100);
                }

                return Positioned(
                  left: 0,
                  right: 0,
                  top: containerTop,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.containerBlack,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Container noir\n(Étape suivante)',
                        style: TextStyle(color: AppColors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
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
              // TODO: Ouvrir l'écran d'ajout de compte
            },
            child: Text(l10n.addAccount),
          ),
        ],
      ),
    );
  }

  Widget _buildAddAccountButton(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: DashedButtonWidget(
        onTap: () {
          // TODO: Ouvrir l'écran d'ajout de compte
        },
        icon: Icons.add,
        text: l10n.addAccount,
      ),
    );
  }

  Widget _buildLoadingCard(int accountId, List<Account> allAccounts) {
    // Utiliser l'utilitaire pour obtenir la couleur correcte
    final cardColor = CardColorUtils.getCardColorById(accountId, allAccounts);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(60), // Padding pour une taille minimale
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
    // Utiliser l'utilitaire pour obtenir la couleur correcte
    final cardColor = CardColorUtils.getCardColorById(accountId, allAccounts);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(60), // Padding pour une taille minimale
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
