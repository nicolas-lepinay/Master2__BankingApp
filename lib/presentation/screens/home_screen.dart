import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/presentation/providers/card_swiper_provider.dart';
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/widgets/bottom_sheets/add_account_bottom_sheet.dart';
import 'package:bankapp/presentation/widgets/bottom_sheets/draggable_black_container.dart';
import 'package:bankapp/presentation/widgets/buttons/dashed_button.dart';
import 'package:bankapp/presentation/widgets/carousels/cards_swiper/bank_card_widget.dart';
import 'package:bankapp/presentation/widgets/carousels/cards_swiper/cards_swiper_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;

    return _buildMainScreen(context, l10n, appTheme);
  }

  Widget _buildMainScreen(
    BuildContext context,
    AppLocalizations l10n,
    AppColorsExtended appTheme,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light, //
      ),
      child: Scaffold(
        backgroundColor: AppColors.surfaceLight,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, l10n),
                  SizedBox(height: 40.h),
                  _buildCardsSection(context, l10n),
                ],
              ),
            ),
            DraggableBlackContainer(
              onDragUpdate: _onContainerDragUpdate,
              onStatisticsPressed: () {
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

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final homeState = ref.watch(homeScreenViewModelProvider);
    final welcomeMessage = homeState.welcomeMessage;

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
              final homeViewModel = ref.read(homeScreenViewModelProvider.notifier);
              final homeState = ref.watch(homeScreenViewModelProvider);

              // Initialiser si nécessaire
              if (!homeState.hasAccounts && !homeViewModel.isLoading && !homeViewModel.hasError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  homeViewModel.initialize();
                });
              }

              // Conserver la vérification des erreurs et empty state
              if (homeViewModel.hasError) {
                return _buildErrorState(context, homeViewModel.errorMessage ?? 'Unknown error');
              }

              if (homeViewModel.isLoading) {
                return _buildLoadingState(context);
              }

              if (!homeState.hasAccounts) {
                return _buildEmptyState(context, l10n);
              }

              return _buildAccountCards(context, l10n, homeState.accounts);
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
              final homeViewModel = ref.read(homeScreenViewModelProvider.notifier);
              homeViewModel.selectAccountByIndex(index);
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
            return BankCardWidget(
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
                      vertical: 70.r,
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

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
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
              final homeViewModel = ref.read(homeScreenViewModelProvider.notifier);
              homeViewModel.refresh();
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
