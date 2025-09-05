import 'package:bankapp/core/extensions/color_extensions.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/card_color_utils_mvvm.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BankCardWidget extends StatefulWidget {
  final domain.AccountSummary accountSummary;
  final List<domain.Account> allAccounts;
  final Function(double)? onBalancePositionChanged;

  const BankCardWidget({
    super.key,
    required this.accountSummary,
    required this.allAccounts,
    this.onBalancePositionChanged,
  });

  @override
  State<BankCardWidget> createState() => _BankCardWidgetState();
}

class _BankCardWidgetState extends State<BankCardWidget> {
  bool _isBalanceVisible = true;
  final GlobalKey _balanceKey = GlobalKey();
  bool _positionAlreadyMeasured = false;

  Color get cardColor {
    return CardColorUtilsMVVM.getCardColor(
      widget.accountSummary.account,
      widget.allAccounts,
    );
  }

  void _toggleBalanceVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  String _formatBalanceDisplay(double amount) {
    String formattedAmount = AppFormatters.formatAmountClean(
      amount,
      widget.accountSummary.account.currency,
      showSign: false,
      context: context,
    );
    if (_isBalanceVisible) {
      return formattedAmount;
    } else {
      // Masquer avec des points
      return '•' * formattedAmount.length;
    }
  }

  @override
  void initState() {
    super.initState();

    // Mesurer la position du solde après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureBalancePosition();
    });
  }

  void _measureBalancePosition() {
    if (!_positionAlreadyMeasured &&
        widget.onBalancePositionChanged != null &&
        _balanceKey.currentContext != null) {
      final RenderBox renderBox =
          _balanceKey.currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      widget.onBalancePositionChanged!(position.dy);
      _positionAlreadyMeasured = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Supprimer la hauteur fixe pour que la carte s'adapte à son contenu
      margin: EdgeInsets.symmetric(horizontal: 30.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Pattern de points en arrière-plan
          Positioned.fill(
            child: CustomPaint(
              painter: DotPatternPainter(backgroundColor: cardColor),
            ),
          ),

          // Contenu de la carte avec padding et intrinsicHeight
          IntrinsicHeight(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:
                    MainAxisSize.min, // Important pour la hauteur adaptative
                children: [
                  // Header avec nom du compte et icône
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.accountSummary.account.name,
                          style: AppTextStyles.cardAccountName.copyWith(
                            color: cardColor.contrastingTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      if (widget.accountSummary.account.icon != null)
                        SizedBox(width: 30.w),

                      // Icône du compte (optionnelle)
                      if (widget.accountSummary.account.icon != null)
                        Container(
                          width: 40.w,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: cardColor.contrastingTextColor.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons
                                .account_balance, // Remplacer par l'icône du compte
                            color: cardColor.contrastingTextColor,
                            size: 20.sp,
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // Solde attendu
                  Text(
                    AppLocalizations.of(context)!.expectedBalance.toUpperCase(),
                    style: AppTextStyles.cardBalanceLabel.copyWith(
                      color: cardColor.contrastingTextColor.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Montant du solde attendu avec toggle visibility
                  Row(
                    key: _balanceKey, // Ajouter la clé pour mesurer la position
                    children: [
                      Expanded(
                        child: Text(
                          _formatBalanceDisplay(
                            widget.accountSummary.currentBalance.amount,
                          ),
                          style: AppTextStyles.cardBalanceAmount.copyWith(
                            color: cardColor.contrastingTextColor,
                          ),
                        ),
                      ),

                      // Bouton pour cacher/afficher le solde
                      GestureDetector(
                        onTap: _toggleBalanceVisibility,
                        child: Container(
                          width: 40.w,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: cardColor.contrastingTextColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Icon(
                            _isBalanceVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: cardColor.contrastingTextColor,
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10.h),

                  // Solde réel (toujours présent, mais peut être caché par le container noir)
                  Text(
                    AppLocalizations.of(context)!.actualBalance.toUpperCase(),
                    style: AppTextStyles.cardBalanceLabel.copyWith(
                      color: cardColor.contrastingTextColor.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),

                  SizedBox(height: 8.h),

                  Text(
                    _formatBalanceDisplay(
                      widget.accountSummary.confirmedBalance.amount,
                    ),
                    style: AppTextStyles.cardBalanceRealAmount.copyWith(
                      color: cardColor.contrastingTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

    final double dotSize = 1.7.r;
    final double spacing = 20.0.w;

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
