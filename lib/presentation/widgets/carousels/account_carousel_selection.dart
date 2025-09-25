import 'package:bankapp/core/extensions/color_extensions.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/card_color_utils_mvvm.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/domain/entities/account.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AccountCarouselSelection extends ConsumerStatefulWidget {
  final Account? selectedAccount;
  final Function(Account) onAccountSelected;
  final List<domain.AccountSummary> accountSummaries;
  final double cardSize;
  final double spacing;
  final double viewportFraction;

  const AccountCarouselSelection({
    super.key,
    required this.selectedAccount,
    required this.onAccountSelected,
    required this.accountSummaries,
    this.cardSize = 175.0,
    this.spacing = 14.0,
    this.viewportFraction = 0.45,
  });

  @override
  ConsumerState<AccountCarouselSelection> createState() =>
      _AccountCarouselSelectionState();
}

class _AccountCarouselSelectionState
    extends ConsumerState<AccountCarouselSelection> {
  late ScrollController _scrollController;
  late PageController _pageController;
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pageController = PageController(viewportFraction: widget.viewportFraction);
    // Auto scroll vers l'élément sélectionné après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedAccount();
    });
  }

  @override
  void didUpdateWidget(AccountCarouselSelection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si le compte sélectionné a changé OU si la liste des comptes a changé de taille, scroller vers sa position
    final accountChanged =
        oldWidget.selectedAccount?.id != widget.selectedAccount?.id;
    final accountListChanged =
        oldWidget.accountSummaries.length != widget.accountSummaries.length;

    if (accountChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedAccount();
      });
    } else if (accountListChanged && widget.selectedAccount != null) {
      // Attendre un peu plus longtemps pour être sûr que la liste est stabilisée
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToSelectedAccount();
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _scrollToSelectedAccount() {
    if (widget.accountSummaries.isNotEmpty && widget.selectedAccount != null) {
      final selectedIndex = widget.accountSummaries.indexWhere(
        (summary) => summary.account.id == widget.selectedAccount!.id,
      );

      if (selectedIndex != -1 && _pageController.hasClients) {
        _isAutoScrolling = true;
        _pageController
            .animateToPage(
              selectedIndex,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            )
            .then((_) {
              // Réactiver onPageChanged après la fin de l'animation
              Future.delayed(const Duration(milliseconds: 100), () {
                _isAutoScrolling = false;
              });
            });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;

    // Calculer la dimension finale basée sur la largeur pour garantir un ratio carré
    final effectiveCardSize = widget.cardSize.w;

    return SizedBox(
      height: effectiveCardSize,
      child: widget.accountSummaries.isEmpty
          ? Center(
              child: Text(
                'Aucun compte disponible',
                style: TextStyle(color: appTheme.text2, fontSize: 14.sp),
              ),
            )
          : PageView.builder(
              controller: _pageController,
              itemCount: widget.accountSummaries.length,
              onPageChanged: (index) {
                if (!_isAutoScrolling) {
                  final selectedAccountSummary = widget.accountSummaries[index];

                  if (selectedAccountSummary.account !=
                      widget.selectedAccount) {
                    widget.onAccountSelected(selectedAccountSummary.account);
                  }
                }
              },
              itemBuilder: (context, index) {
                final accountSummary = widget.accountSummaries[index];
                final account = accountSummary.account;
                final isSelected = account.id == widget.selectedAccount?.id;
                final allAccounts = widget.accountSummaries
                    .map((s) => s.account)
                    .toList();

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.spacing.w),
                  child: _buildAccountCard(
                    accountSummary: accountSummary,
                    allAccounts: allAccounts,
                    isSelected: isSelected,
                    appTheme: appTheme,
                    cardSize: effectiveCardSize,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAccountCard({
    required domain.AccountSummary accountSummary,
    required List<Account> allAccounts,
    required bool isSelected,
    required AppColorsExtended appTheme,
    required double cardSize,
  }) {
    // Récupération de la couleur selon les spécifications
    final account = accountSummary.account;
    final cardColor = CardColorUtilsMVVM.getCardColor(account, allAccounts);
    final textColor = cardColor.contrastingTextColor;

    return GestureDetector(
      onTap: () => widget.onAccountSelected(account),
      child: AspectRatio(
        aspectRatio: 1.0, // Force un ratio carré parfait (1:1)
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32.r),
            border: isSelected
                ? Border.all(color: appTheme.text1!, width: 2)
                : null,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isSelected ? cardColor : AppColors.greyCard,
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: appTheme.background1!, width: 5.w),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: cardColor.withValues(alpha: 0.3),
                        blurRadius: 8.r,
                        offset: Offset(0, 4.h),
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: DotPatternPainter(backgroundColor: cardColor),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 14.r,
                    right: 14.r,
                    top: 16.r,
                    bottom: 12.r,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Row avec trou et icône
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Disque simulant un trou
                          Container(
                            width: 22.r,
                            height: 22.r,
                            decoration: BoxDecoration(
                              color: appTheme.background1,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: appTheme.text1!,
                                      width: 6.r,
                                    )
                                  : null,
                            ),
                          ),
                          // Icône du compte
                          Icon(
                            Icons.account_balance,
                            color: isSelected
                                ? textColor
                                : AppColors.textLight100,
                            size: 20.sp,
                          ),
                        ],
                      ),
                      SizedBox(height: 6.r),

                      // Devise du compte
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          account.currency,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? textColor
                                : AppColors.textLight100,
                          ),
                        ),
                      ),

                      // Nom du compte
                      Text(
                        account.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          //fontWeight: FontWeight.w400,
                          color: isSelected
                              ? textColor
                              : AppColors.textLight100,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Solde du compte (solde courant)
                      Text(
                        AppFormatters.formatAmountClean(
                          accountSummary.currentBalance.amount,
                          account.currency,
                          showSign: false,
                          context: context,
                        ),
                        style: AppTextStyles.cardBalanceAmount.copyWith(
                          fontSize: 16.sp,
                          color: isSelected
                              ? textColor
                              : AppColors.textLight100,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
}

// Custom painter pour le pattern de points en arrière-plan
class DotPatternPainter extends CustomPainter {
  final Color backgroundColor;

  DotPatternPainter({required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor.contrastingTextColor.withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;

    final double dotSize = 1.2.r;
    final double spacing = 10.0.w;

    // Dessiner une grille de points
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        // Ajouter un peu de randomness pour un effet plus naturel
        final offsetX = x + (x * 0.05 * (x / size.width));
        final offsetY = y + (y * 0.05 * (y / size.height));

        canvas.drawCircle(Offset(offsetX, offsetY), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
