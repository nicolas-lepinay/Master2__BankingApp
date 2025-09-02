import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/domain/entities/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';

class TransactionTypeToggle extends StatefulWidget {
  final TransactionType initialType;
  final Function(TransactionType) onChanged;
  final double width;
  final double height;
  final double borderRadius;

  const TransactionTypeToggle({
    super.key,
    required this.initialType,
    required this.onChanged,
    this.width = 110.0,
    this.height = 65.0,
    this.borderRadius = 20.0,
  });

  @override
  State<TransactionTypeToggle> createState() => _TransactionTypeToggleState();
}

class _TransactionTypeToggleState extends State<TransactionTypeToggle>
    with TickerProviderStateMixin {
  late TransactionType _currentType;
  late AnimationController _colorController;
  late AnimationController _positionController;
  late AnimationController _rotationController;

  // Couleurs selon spécifications
  static const Color _expenseColor = Color(0xFFFFB2C3); // Rose pour dépense
  static const Color _incomeColor = Color(0xFFB2FFB9); // Vert pour revenu

  late Animation<Color?> _backgroundColorAnimation;
  late Animation<double> _positionAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;

    // Contrôleurs d'animation
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _positionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Animations
    _backgroundColorAnimation =
        ColorTween(
          begin: _currentType == TransactionType.expense
              ? _expenseColor
              : _incomeColor,
          end: _currentType == TransactionType.expense
              ? _expenseColor
              : _incomeColor,
        ).animate(
          CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
        );

    _positionAnimation =
        Tween<double>(
          begin: _currentType == TransactionType.expense ? 0.0 : 0.7,
          end: _currentType == TransactionType.expense ? 0.0 : 0.7,
        ).animate(
          CurvedAnimation(parent: _positionController, curve: Curves.easeInOut),
        );

    _rotationAnimation =
        Tween<double>(
          begin: _currentType == TransactionType.expense ? 0.0 : 1.0,
          end: _currentType == TransactionType.expense ? 0.0 : 1.0,
        ).animate(
          CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _colorController.dispose();
    _positionController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _toggle() {
    final newType = _currentType == TransactionType.expense
        ? TransactionType.income
        : TransactionType.expense;

    setState(() {
      _currentType = newType;
    });

    // Animation de couleur de fond
    _backgroundColorAnimation =
        ColorTween(
          begin: _currentType == TransactionType.income
              ? _expenseColor
              : _incomeColor,
          end: _currentType == TransactionType.expense
              ? _expenseColor
              : _incomeColor,
        ).animate(
          CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
        );

    // Animation de position (0.0 = gauche, 1.0 = droite)
    _positionAnimation =
        Tween<double>(
          begin: _positionAnimation.value,
          end: _currentType == TransactionType.expense ? 0.0 : 0.7,
        ).animate(
          CurvedAnimation(parent: _positionController, curve: Curves.easeInOut),
        );

    // Animation de rotation (0.0 = bas-gauche, 1.0 = haut-droite)
    _rotationAnimation =
        Tween<double>(
          begin: _rotationAnimation.value,
          end: _currentType == TransactionType.expense ? 0.0 : 1.0,
        ).animate(
          CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
        );

    // Démarrer toutes les animations
    _colorController.forward(from: 0.0);
    _positionController.forward(from: 0.0);
    _rotationController.forward(from: 0.0);

    widget.onChanged(_currentType);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;

    return Column(
      children: [
        // Labels et Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Label DÉPENSE
            GestureDetector(
              onTap: _currentType == TransactionType.income ? _toggle : null,
              child: Text(
                l10n.expense.toUpperCase(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: _currentType == TransactionType.expense
                      ? appTheme
                            .text1 // Actif
                      : appTheme.text5, // Inactif
                ),
              ),
            ),

            SizedBox(width: 24.w),

            // Toggle Switch Container
            AnimatedBuilder(
              animation: Listenable.merge([
                _colorController,
                _positionController,
                _rotationController,
              ]),
              builder: (context, child) {
                return GestureDetector(
                  onTap: _toggle,
                  child: Container(
                    width: widget.width.w,
                    height: widget.height.h,
                    decoration: BoxDecoration(
                      color: _backgroundColorAnimation.value,
                      borderRadius: BorderRadius.circular(
                        widget.borderRadius.r,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Carré blanc animé
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          left:
                              _positionAnimation.value *
                                  (widget.width.w - 45.w) +
                              10.w,
                          top: 10.h,
                          child: Container(
                            width: 45.w,
                            height: 45.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                (widget.borderRadius - 3).r,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6.r,
                                  offset: Offset(0, 0.h),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Transform.rotate(
                                angle:
                                    _rotationAnimation.value *
                                    3.14159, // 180° rotation
                                child: SvgPicture.asset(
                                  AppConstants.downLeftArrow,
                                  width: 24.sp,
                                  height: 24.sp,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.dark81,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            SizedBox(width: 24.w),

            // Label REVENU
            GestureDetector(
              onTap: _currentType == TransactionType.expense ? _toggle : null,
              child: Text(
                l10n.income.toUpperCase(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: _currentType == TransactionType.income
                      ? appTheme
                            .text1 // Actif
                      : appTheme.text5, // Inactif
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
