import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/presentation/providers/card_swiper_provider.dart';
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/widgets/add_account_bottom_sheet.dart';
import 'package:bankapp/presentation/widgets/bank_card_widget_mvvm.dart';
import 'package:bankapp/presentation/widgets/cards_swiper_widget.dart';
import 'package:bankapp/presentation/widgets/dashed_button.dart';
import 'package:bankapp/presentation/widgets/draggable_black_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeScreenMVVM extends ConsumerStatefulWidget {
  const HomeScreenMVVM({super.key});

  @override
  ConsumerState<HomeScreenMVVM> createState() => _HomeScreenMVVMState();
}

class _HomeScreenMVVMState extends ConsumerState<HomeScreenMVVM>
    with TickerProviderStateMixin {
  bool _shouldPlayCardAnimation = false;
  late AnimationController _containerAnimationController;
  late Animation<double> _containerAnimation;

  @override
  void initState() {
    super.initState();
    _containerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _containerAnimation = CurvedAnimation(
      parent: _containerAnimationController,
      curve: Curves.easeInOut,
    );
    // Plus besoin d'initialiser l'app ici - fait dans le SplashScreen
  }

  @override
  void dispose() {
    _containerAnimationController.dispose();
    super.dispose();
  }

  // Callback appelé quand le container draggable bouge
  void _onContainerDragUpdate(double extent) {
    // Calculer la position d'animation basée sur l'extent du container
    final minThreshold = 0.25; // Seuil minimum pour l'animation
    final normalPosition = 0.72; // Position normale
    final animationValue =
        ((normalPosition - extent) / (normalPosition - minThreshold)).clamp(
          0.0,
          1.0,
        );
    _containerAnimationController.animateTo(animationValue);

    // Mettre à jour le provider pour la synchronisation
    final isExpanded = extent <= 0.3; // Considéré comme expanded si < 30%
    ref.read(cardsExpandedProvider.notifier).setExpanded(isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildMainScreen(context, l10n).animate().fadeIn(duration: 1000.ms);
  }

  Widget _buildMainScreen(BuildContext context, AppLocalizations l10n) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surfaceLight,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context, l10n),
                  SizedBox(height: 40.h),
                  _buildCardsSection(context, l10n),
                ],
              ),
              DraggableBlackContainer(
                onDragUpdate: _onContainerDragUpdate,
                onStatisticsPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Statistiques - À implémenter'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final welcomeMessage = ref.watch(welcomeMessageProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 16.r),
      child: Column(
        children: [
          // Top row with menu and welcome message
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // TODO: Ouvrir le menu latéral
                },
                child: SizedBox(
                  width: 44.w,
                  height: 44.w,
                  child: Icon(
                    Icons.menu,
                    color: AppColors.textDark100,
                    size: 24.sp,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    welcomeMessage,
                    style: AppTextStyles.welcomeMessage,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Ouvrir le menu contextuel
                },
                child: SizedBox(
                  width: 44.w,
                  height: 44.w,
                  child: Icon(
                    Icons.more_vert,
                    color: AppColors.textDark100,
                    size: 24.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildCardsSection(BuildContext context, AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _containerAnimation,
      builder: (context, child) {
        final verticalOffset = _containerAnimation.value * 80.h;

        return Transform.translate(
          offset: Offset(0, verticalOffset),
          child: Consumer(
            builder: (context, ref, child) {
              final accounts = ref.watch(accountsProvider);
              final accountState = ref.watch(accountViewModelProvider);

              // Conserver la vérification des erreurs et empty state
              if (accountState.hasError) {
                return _buildErrorState(context, accountState.error!);
              }

              if (accounts.isEmpty) {
                return _buildEmptyState(context, l10n);
              }

              return _buildAccountCards(context, l10n, accounts);
            },
          ),
        );
      },
    );
  }

  Widget _buildAccountCards(
    BuildContext context,
    AppLocalizations l10n,
    List<domain.Account> accounts,
  ) {
    return Column(
      children: [
        CardsSwiperWidget<domain.Account>(
          cardData: accounts,
          onCardChange: (index) {
            if (index >= 0 && index < accounts.length) {
              final accountViewModel = ref.read(
                accountViewModelProvider.notifier,
              );
              accountViewModel.selectAccount(accounts[index].id);
              ref.read(selectedCardProvider.notifier).setSelectedCard(index);
            }
          },
          shouldStartCardCollectionAnimation: _shouldPlayCardAnimation,
          onCardCollectionAnimationComplete: (value) {
            setState(() {
              _shouldPlayCardAnimation = value;
            });
          },
          cardBuilder: (context, accountIndex, visibleIndex) {
            if (accountIndex < 0 || accountIndex >= accounts.length) {
              return const SizedBox.shrink();
            }

            final account = accounts[accountIndex];
            return _buildAccountCard(context, account, accounts);
          },
        ),
        _buildAddAccountButton(context, l10n),
      ],
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    domain.Account account,
    List<domain.Account> allAccounts,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        // Utiliser le provider pour obtenir l'AccountSummary spécifique à ce compte
        final accountSummaryAsync = ref.watch(
          accountSummaryByIdProvider(account.id),
        );

        return accountSummaryAsync.when(
          data: (accountSummary) {
            return BankCardWidgetMVVM(
              accountSummary: accountSummary,
              allAccounts: allAccounts,
            );
          },
          loading: () => _buildLoadingCard(account.id, allAccounts),
          error: (error, stack) => _buildErrorCard(account.id, allAccounts),
        );
      },
    );
  }

  Widget _buildAddAccountButton(BuildContext context, AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _containerAnimation,
      builder: (context, child) {
        final opacity = _containerAnimation.value;
        final scale = 0.8 + (_containerAnimation.value * 0.2);

        return opacity > 0.1
            ? Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      vertical: 50.r,
                      horizontal: AppConstants.veryLargePadding.r,
                    ),
                    child: DashedButton(
                      text: l10n.addAccount,
                      icon: Icons.add,
                      onTap: () {
                        _showAddAccountBottomSheet(context);
                      },
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, size: 40.sp, color: AppColors.primary),
          ),
          SizedBox(height: AppConstants.defaultPadding.h),
          Text(l10n.addAccount, style: AppTextStyles.h5),
          SizedBox(height: AppConstants.verySmallPadding.h),
          Text(
            'Appuyez pour créer un nouveau compte',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.largePadding.h),
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

  Widget _buildErrorState(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
          SizedBox(height: 16.h),
          Text('${l10n.error}: $error'),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {
              final accountViewModel = ref.read(
                accountViewModelProvider.notifier,
              );
              accountViewModel.refresh();
            },
            child: Text(l10n.retry),
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

  Widget _buildLoadingCard(int accountId, List<domain.Account> allAccounts) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 30.w),
      padding: EdgeInsets.all(60.r),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(32.r),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      ),
    );
  }

  Widget _buildErrorCard(int accountId, List<domain.Account> allAccounts) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 30.w),
      padding: EdgeInsets.all(60.r),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(32.r),
      ),
      child: Center(
        child: Icon(Icons.error_outline, color: AppColors.white, size: 48.sp),
      ),
    );
  }
}

/*
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/presentation/providers/card_swiper_provider.dart';
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/viewmodels/viewmodels.dart';
import 'package:bankapp/presentation/widgets/add_account_bottom_sheet.dart';
import 'package:bankapp/presentation/widgets/bank_card_widget_mvvm.dart';
import 'package:bankapp/presentation/widgets/cards_swiper_widget.dart';
import 'package:bankapp/presentation/widgets/dashed_button.dart';
import 'package:bankapp/presentation/widgets/draggable_black_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeScreenMVVM extends ConsumerStatefulWidget {
  const HomeScreenMVVM({super.key});

  @override
  ConsumerState<HomeScreenMVVM> createState() => _HomeScreenMVVMState();
}

class _HomeScreenMVVMState extends ConsumerState<HomeScreenMVVM>
    with TickerProviderStateMixin {
  bool _shouldPlayCardAnimation = false;
  late AnimationController _containerAnimationController;
  late Animation<double> _containerAnimation;
  double _containerExtent = 0.67; // Position actuelle du container draggable

  @override
  void initState() {
    super.initState();
    _containerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _containerAnimation = CurvedAnimation(
      parent: _containerAnimationController,
      curve: Curves.easeInOut,
    );

    // Initialiser l'application au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _containerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final appViewModel = ref.read(appViewModelProvider.notifier);
    await appViewModel.initializeApp();
  }

  // Callback appelé quand le container draggable bouge
  void _onContainerDragUpdate(double extent) {
    setState(() {
      _containerExtent = extent;
    });

    // Calculer la position d'animation basée sur l'extent du container
    // Utiliser des valeurs dynamiques au lieu de valeurs codées en dur
    final minThreshold = 0.25; // Seuil minimum pour l'animation
    final normalPosition =
        0.65; // Position normale (peut être ajustée dynamiquement)
    final animationValue =
        ((normalPosition - extent) / (normalPosition - minThreshold)).clamp(
          0.0,
          1.0,
        );
    _containerAnimationController.animateTo(animationValue);

    // Mettre à jour le provider pour la synchronisation
    final isExpanded = extent <= 0.3; // Considéré comme expanded si < 30%
    ref.read(cardsExpandedProvider.notifier).setExpanded(isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Écouter l'état de l'application
    final appState = ref.watch(appViewModelProvider);
    final isAppReady = ref.watch(isAppReadyProvider);

    // Si l'application n'est pas encore initialisée, afficher l'écran de chargement
    if (!isAppReady) {
      return _buildLoadingScreen(context, appState);
    }

    // Si l'application est prête, afficher l'écran principal
    return _buildMainScreen(context, l10n);
  }

  Widget _buildLoadingScreen(BuildContext context, AppViewState appState) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surfaceLight,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo ou icône de l'application
                Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 40.sp,
                    color: AppColors.white,
                  ),
                ),

                SizedBox(height: 32.h),

                // Message de bienvenue
                Text(
                  appState.welcomeMessage,
                  style: AppTextStyles.h4,
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 24.h),

                // Indicateur de progression
                if (appState.isLoading)
                  Column(
                    children: [
                      SizedBox(
                        width: 200.w,
                        child: LinearProgressIndicator(
                          value: appState.initializationProgress,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.2,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      if (appState.currentStep != null)
                        Text(
                          appState.currentStep!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),

                // Affichage des erreurs
                if (appState.hasError)
                  Container(
                    margin: EdgeInsets.only(top: 24.h),
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 24.sp,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          appState.error!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: () {
                            final appViewModel = ref.read(
                              appViewModelProvider.notifier,
                            );
                            appViewModel.initializeApp();
                          },
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainScreen(BuildContext context, AppLocalizations l10n) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surfaceLight,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context, l10n),
                  SizedBox(height: 40.h),
                  _buildCardsSection(context, l10n),
                ],
              ),
              DraggableBlackContainer(
                onDragUpdate: _onContainerDragUpdate,
                onStatisticsPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Statistiques - À implémenter'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final welcomeMessage = ref.watch(welcomeMessageProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 16.r),
      child: Column(
        children: [
          // Top row with menu and welcome message
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // TODO: Ouvrir le menu latéral
                },
                child: SizedBox(
                  width: 44.w,
                  height: 44.w,
                  child: Icon(
                    Icons.menu,
                    color: AppColors.textDark100,
                    size: 24.sp,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    welcomeMessage,
                    style: AppTextStyles.welcomeMessage,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Ouvrir le menu contextuel
                },
                child: SizedBox(
                  width: 44.w,
                  height: 44.w,
                  child: Icon(
                    Icons.more_vert,
                    color: AppColors.textDark100,
                    size: 24.sp,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildCardsSection(BuildContext context, AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _containerAnimation,
      builder: (context, child) {
        final verticalOffset = _containerAnimation.value * 80.h;

        return Transform.translate(
          offset: Offset(0, verticalOffset),
          child: Consumer(
            builder: (context, ref, child) {
              final accounts = ref.watch(accountsProvider);

              return Column(
                children: [
                  // Card Swiper Widget - copie exacte de home_screen_v1
                  CardsSwiperWidget<domain.Account>(
                    cardData: accounts,
                    onCardChange: (index) {
                      // Mettre à jour la carte sélectionnée
                      final accountIndex = accounts.indexWhere(
                        (account) => account.id == accounts[index].id,
                      );
                      if (accountIndex != -1) {
                        ref
                            .read(selectedCardProvider.notifier)
                            .setSelectedCard(accountIndex);
                        // Sélectionner aussi le compte dans le viewmodel
                        final accountViewModel = ref.read(
                          accountViewModelProvider.notifier,
                        );
                        accountViewModel.selectAccount(accounts[index].id);
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
                      if (accountIndex < 0 || accountIndex >= accounts.length) {
                        return const SizedBox.shrink();
                      }

                      final account = accounts[accountIndex];
                      return Consumer(
                        builder: (context, ref, child) {
                          final accountSummaryAsync = ref.watch(
                            accountSummaryByIdProvider(account.id),
                          );

                          return accountSummaryAsync.when(
                            data: (accountSummary) {
                              return BankCardWidgetMVVM(
                                accountSummary: accountSummary,
                                allAccounts: accounts,
                              );
                            },
                            loading: () => _buildLoadingCard(account.id, accounts),
                            error: (error, stack) => _buildErrorCard(account.id, accounts),
                          );
                        },
                      );
                    },
                  ),

                  // Bouton "Ajouter un compte" visible quand expanded - copie exacte
                  AnimatedBuilder(
                    animation: _containerAnimation,
                    builder: (context, child) {
                      // Calculer l'opacité et l'échelle du bouton
                      final opacity = _containerAnimation.value;
                      final scale = 0.8 + (_containerAnimation.value * 0.2);

                      return opacity > 0.1
                          ? Opacity(
                              opacity: opacity,
                              child: Transform.scale(
                                scale: scale,
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                    vertical: 50.r,
                                    horizontal: AppConstants.veryLargePadding.r,
                                  ),
                                  child: DashedButton(
                                    text: l10n.addAccount,
                                    icon: Icons.add,
                                    onTap: () {
                                      _showAddAccountBottomSheet(context);
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
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, size: 40.sp, color: AppColors.primary),
          ),
          SizedBox(height: AppConstants.defaultPadding.h),
          Text(l10n.addAccount, style: AppTextStyles.h5),
          SizedBox(height: AppConstants.verySmallPadding.h),
          Text(
            'Appuyez pour créer un nouveau compte',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.largePadding.h),
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

  Widget _buildErrorState(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
          SizedBox(height: 16.h),
          Text('${l10n.error}: $error'),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {
              final accountViewModel = ref.read(
                accountViewModelProvider.notifier,
              );
              accountViewModel.refresh();
            },
            child: Text(l10n.retry),
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

  Widget _buildLoadingCard(int accountId, List<domain.Account> allAccounts) {
    // Utiliser les mêmes utilitaires que dans home_screen_v1
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 30.w),
      padding: EdgeInsets.all(60.r),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(32.r),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      ),
    );
  }

  Widget _buildErrorCard(int accountId, List<domain.Account> allAccounts) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 30.w),
      padding: EdgeInsets.all(60.r),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(32.r),
      ),
      child: Center(
        child: Icon(Icons.error_outline, color: AppColors.white, size: 48.sp),
      ),
    );
  }
}
*/
