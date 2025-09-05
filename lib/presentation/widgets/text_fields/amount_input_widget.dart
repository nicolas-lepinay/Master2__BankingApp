import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/domain/entities/account.dart';
import 'package:bankapp/domain/entities/transaction.dart';
import 'package:bankapp/presentation/widgets/bottom_sheets/exchange_rates_bottom_sheet.dart';
import 'package:bankapp/presentation/widgets/text_fields/amount_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/gradient_colors.dart';

class AmountInputWidget extends ConsumerStatefulWidget {
  final TransactionType transactionType;
  final Account? selectedAccount;
  final Function(String) onAmountChanged;
  final Function(String)? onConvertedAmountChanged;
  final Function(String)? onConversionCurrencyChanged;
  final String? initialAmount;
  final String? convertedAmount;
  final String? conversionCurrency;
  final Function(bool hasFocus)? onFocusChanged;

  const AmountInputWidget({
    super.key,
    required this.transactionType,
    required this.selectedAccount,
    required this.onAmountChanged,
    this.onConvertedAmountChanged,
    this.onConversionCurrencyChanged,
    this.initialAmount,
    this.convertedAmount,
    this.conversionCurrency,
    this.onFocusChanged,
  });

  @override
  ConsumerState<AmountInputWidget> createState() => _AmountInputWidgetV2State();
}

class _AmountInputWidgetV2State extends ConsumerState<AmountInputWidget> {
  late TextEditingController _controller;
  String _currentAmount = '';
  bool _mainTextFieldHasFocus = false;
  bool _convertedTextFieldHasFocus = false;
  // Flag pour détecter si une BottomSheet est ouverte
  bool _isBottomSheetOpen = false;
  // Timestamp de fermeture de BottomSheet
  DateTime? _bottomSheetClosedAt;
  // Flag pour interaction utilisateur avec TextField converti
  bool _userIsInteractingWithConverted = false;
  // Empêcher le focus automatique du TextField principal
  bool _preventMainTextFieldAutoFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAmount ?? '');
    _currentAmount = widget.initialAmount ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AmountInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si le montant initial a changé depuis l'extérieur, mettre à jour
    if (oldWidget.initialAmount != widget.initialAmount) {
      final newAmount = widget.initialAmount ?? '';
      if (_controller.text != newAmount) {
        _controller.text = newAmount;
        _currentAmount = newAmount;
      }
    }
  }

  void _onMainTextFieldFocusChange(bool hasFocus) {
    setState(() {
      _mainTextFieldHasFocus = hasFocus;
    });

    // Vérifier si c'est un focus automatique juste après fermeture BottomSheet
    if (_shouldIgnoreAutomaticFocus(hasFocus)) {
      return;
    }
    // Vérifier si l'utilisateur interagit avec le TextField converti
    if (_userIsInteractingWithConverted && hasFocus) {
      return;
    }
    // Empêcher le focus automatique dans certains cas
    if (_preventMainTextFieldAutoFocus && hasFocus) {
      return;
    }

    // Utiliser WidgetsBinding pour s'assurer que le callback est exécuté après la mise à jour du widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleFocusChange();
    });
  }

  void _onConvertedTextFieldFocusChange(bool hasFocus) {
    // Marquer l'interaction utilisateur avec le TextField converti
    if (hasFocus) {
      _userIsInteractingWithConverted = true;
    } else {
      // Délai avant de réinitialiser le flag pour éviter les conflits
      Future.delayed(const Duration(milliseconds: 100), () {
        _userIsInteractingWithConverted = false;
      });
    }

    setState(() {
      _convertedTextFieldHasFocus = hasFocus;
    });

    // Vérifier si c'est un focus automatique juste après fermeture BottomSheet
    if (_shouldIgnoreAutomaticFocus(hasFocus)) {
      return;
    }
    // Utiliser WidgetsBinding pour s'assurer que le callback est exécuté après la mise à jour du widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleFocusChange();
    });
  }

  /// Détermine si un focus doit être ignoré (focus automatique après fermeture BottomSheet)
  bool _shouldIgnoreAutomaticFocus(bool hasFocus) {
    if (!hasFocus || _bottomSheetClosedAt == null) return false;

    final now = DateTime.now();
    final timeSinceBottomSheetClosed = now.difference(_bottomSheetClosedAt!);

    // Ignorer seulement le focus automatique dans les 200ms après fermeture BottomSheet
    final shouldIgnore = timeSinceBottomSheetClosed.inMilliseconds < 200;
    return shouldIgnore;
  }

  void _handleFocusChange() {
    if (widget.onFocusChanged != null) {
      // Si l'un des deux a le focus, signaler true
      // Si aucun des deux n'a le focus, signaler false
      final anyHasFocus = _mainTextFieldHasFocus || _convertedTextFieldHasFocus;
      widget.onFocusChanged!(anyHasFocus);
    }
  }

  void _showExchangeRatesBottomSheet() {
    if (widget.selectedAccount == null ||
        widget.onConversionCurrencyChanged == null ||
        (widget.initialAmount?.isEmpty ?? true))
      return;

    final baseCurrency = widget.selectedAccount!.currency;
    final selectedCurrency = widget.conversionCurrency ?? baseCurrency;

    // Forcer la fermeture du clavier AVANT d'ouvrir la BottomSheets
    _dismissKeyboard();

    setState(() {
      _isBottomSheetOpen = true;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.0,
        maxChildSize: 0.9,
        builder: (context, scrollController) => ExchangeRatesBottomSheet(
          baseCurrency: baseCurrency,
          selectedCurrency: selectedCurrency,
          onCurrencySelected: widget.onConversionCurrencyChanged!,
        ),
      ),
    ).then((_) {
      // Forcer la fermeture du clavier DEUX fois pour s'assurer qu'il reste fermé
      _dismissKeyboard();
      Future.delayed(const Duration(milliseconds: 50), () {
        _dismissKeyboard();
      });

      // Marquer le timestamp de fermeture de la BottomSheet et empêcher l'auto-focus
      setState(() {
        _isBottomSheetOpen = false;
        _bottomSheetClosedAt = DateTime.now();
        _preventMainTextFieldAutoFocus =
            true; // Empêcher le focus automatique temporairement
      });

      // Réinitialiser la prévention après un délai plus long pour être sûr
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (mounted) {
          setState(() {
            _preventMainTextFieldAutoFocus = false;
          });
        }
      });
    });
  }

  void _dismissKeyboard() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    currentFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;
    final l10n = AppLocalizations.of(context)!;

    final accountCurrency = widget.selectedAccount?.currency ?? 'EUR';
    final transactionCurrency = widget.conversionCurrency ?? accountCurrency;
    final displayCurrency = transactionCurrency;
    final isConverted =
        widget.conversionCurrency != null &&
        widget.conversionCurrency != accountCurrency;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section conversion (si active)
        if (isConverted) ...[
          // Montant converti éditable (devise du compte)
          AmountTextField(
            transactionType: widget.transactionType,
            currency: accountCurrency,
            initialAmount: widget.convertedAmount,
            onAmountChanged: widget.onConvertedAmountChanged ?? (_) {},
            textColor: GradientColors.pink.first,
            gradient: LinearGradient(colors: GradientColors.pink),
            onFocusChanged: _onConvertedTextFieldFocusChange,
          ),

          SizedBox(height: AppConstants.defaultPadding.h),

          // Ligne de séparation avec icône swap
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60.w,
                height: 1.h,
                color: appTheme.text5?.withValues(alpha: 0.3),
              ),

              SizedBox(width: AppConstants.smallPadding.w),

              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  //color: const Color(0xFFE91E63), // Rose de la maquette
                ),
                child: RotatedBox(
                  quarterTurns: 1,
                  child: SvgPicture.asset(
                    AppConstants.convertIcon,
                    width: 32.w,
                    height: 32.h,
                    colorFilter: ColorFilter.mode(
                      appTheme.text5!.withValues(alpha: 0.7),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),

              SizedBox(width: AppConstants.smallPadding.w),

              Container(
                width: 60.w,
                height: 1.h,
                color: appTheme.text5?.withValues(alpha: 0.3),
              ),
            ],
          ),

          SizedBox(height: AppConstants.defaultPadding.h),
        ],

        // Montant principal (devise de la transaction)
        AmountTextField(
          transactionType: widget.transactionType,
          currency: transactionCurrency,
          initialAmount: widget.initialAmount,
          onAmountChanged: widget.onAmountChanged,
          textColor: appTheme.text1!,
          onFocusChanged: _onMainTextFieldFocusChange,
        ),

        SizedBox(height: AppConstants.largePadding.r),

        // Bouton devise avec icône swap
        GestureDetector(
          onTap: _showExchangeRatesBottomSheet,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: appTheme.buttonBackgroundDisabled!.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayCurrency,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: appTheme.text5,
                  ),
                ),
                SizedBox(width: AppConstants.defaultPadding.r),
                SvgPicture.asset(
                  AppConstants.convertIcon,
                  width: 20.w,
                  height: 20.h,
                  colorFilter: ColorFilter.mode(
                    appTheme.text5!,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
