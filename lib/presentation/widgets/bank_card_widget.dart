import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:bankapp/data/database/database.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/utils/card_color_utils.dart';

class BankCardWidget extends StatefulWidget {
  final AccountSummary accountSummary;
  final List<Account> allAccounts; // Nécessaire pour déterminer la couleur
  final Function(double)?
  onBalancePositionChanged; // Callback pour la position Y du solde

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
  bool _isBalanceVisible = true; // Par défaut, le solde est visible
  final GlobalKey _balanceKey =
      GlobalKey(); // Clé pour mesurer la position du solde
  bool _positionAlreadyMeasured =
      false; // Flag pour s'assurer que la position n'est mesurée qu'une fois

  Color get cardColor {
    return CardColorUtils.getCardColor(
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

  void _measureBalancePosition() {
    // Ne mesurer qu'une seule fois au chargement initial
    if (_positionAlreadyMeasured) return;

    final RenderBox? renderBox =
        _balanceKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final bottomOfBalance = position.dy + (renderBox.size.height / 3);

      // Appeler le callback avec la position Y du bas du solde
      widget.onBalancePositionChanged?.call(bottomOfBalance);
      // Marquer comme déjà mesuré
      _positionAlreadyMeasured = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mesurer la position du solde après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureBalancePosition();
    });
    return Container(
      width: double.infinity,
      // Supprimer la hauteur fixe pour que la carte s'adapte à son contenu
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Pattern de points en arrière-plan
          Positioned.fill(child: CustomPaint(painter: DotPatternPainter())),

          // Contenu de la carte avec padding et intrinsicHeight
          IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
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
                          style: cardColor == AppColors.cardGreen
                              ? AppTextStyles.cardAccountNameDark
                              : AppTextStyles.cardAccountName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      if (widget.accountSummary.account.icon != null)
                        SizedBox(width: 30),

                      // Icône du compte (optionnelle)
                      if (widget.accountSummary.account.icon != null)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cardColor == AppColors.cardGreen
                                ? AppColors.darkest.withValues(alpha: 0.2)
                                : AppColors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons
                                .account_balance, // Remplacer par l'icône du compte
                            color: cardColor == AppColors.cardGreen
                                ? AppColors.darkest
                                : AppColors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Solde attendu
                  Text(
                    AppLocalizations.of(context)!.expectedBalance.toUpperCase(),
                    style: AppTextStyles.cardBalanceLabel.copyWith(
                      color: cardColor == AppColors.cardGreen
                          ? AppColors.darkest.withValues(alpha: 0.6)
                          : AppColors.white.withValues(alpha: 0.6),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Montant du solde attendu avec toggle visibility
                  Row(
                    key: _balanceKey, // Ajouter la clé pour mesurer la position
                    children: [
                      Expanded(
                        child: Text(
                          _formatBalanceDisplay(
                            widget.accountSummary.currentBalance,
                          ),
                          style: cardColor == AppColors.cardGreen
                              ? AppTextStyles.cardBalanceAmountDark
                              : AppTextStyles.cardBalanceAmount,
                        ),
                      ),

                      // Bouton pour cacher/afficher le solde
                      GestureDetector(
                        onTap: _toggleBalanceVisibility,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cardColor == AppColors.cardGreen
                                ? AppColors.darkest.withValues(alpha: 0.1)
                                : AppColors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _isBalanceVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: cardColor == AppColors.cardGreen
                                ? AppColors.darkest
                                : AppColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Solde réel (toujours présent, mais peut être caché par le container noir)
                  Text(
                    AppLocalizations.of(context)!.actualBalance.toUpperCase(),
                    style: AppTextStyles.cardBalanceLabel.copyWith(
                      color: cardColor == AppColors.cardGreen
                          ? AppColors.darkest.withValues(alpha: 0.6)
                          : AppColors.white.withValues(alpha: 0.6),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _formatBalanceDisplay(
                      widget.accountSummary.confirmedBalance,
                    ),
                    style: cardColor == AppColors.cardGreen
                        ? AppTextStyles.cardBalanceRealAmountDark
                        : AppTextStyles.cardBalanceRealAmount,
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;

    const double dotSize = 1.7;
    const double spacing = 20.0;

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
