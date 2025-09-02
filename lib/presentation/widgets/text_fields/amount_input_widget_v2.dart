import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/domain/entities/account.dart';
import 'package:bankapp/domain/entities/transaction.dart';
import 'package:bankapp/presentation/widgets/bottom_sheets/exchange_rates_bottom_sheet.dart';
import 'package:bankapp/presentation/widgets/text_fields/amount_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AmountInputWidgetV2 extends ConsumerStatefulWidget {
  final TransactionType transactionType;
  final Account? selectedAccount;
  final Function(String) onAmountChanged;
  final Function(String)? onConvertedAmountChanged;
  final Function(String)? onConversionCurrencyChanged;
  final String? initialAmount;
  final String? convertedAmount;
  final String? conversionCurrency;

  const AmountInputWidgetV2({
    super.key,
    required this.transactionType,
    required this.selectedAccount,
    required this.onAmountChanged,
    this.onConvertedAmountChanged,
    this.onConversionCurrencyChanged,
    this.initialAmount,
    this.convertedAmount,
    this.conversionCurrency,
  });

  @override
  ConsumerState<AmountInputWidgetV2> createState() =>
      _AmountInputWidgetV2State();
}

class _AmountInputWidgetV2State extends ConsumerState<AmountInputWidgetV2> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String _currentAmount = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAmount ?? '');
    _focusNode = FocusNode();
    _currentAmount = widget.initialAmount ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AmountInputWidgetV2 oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si le montant initial a changé depuis l'extérieur, mettre à jour
    if (oldWidget.initialAmount != widget.initialAmount &&
        widget.initialAmount != null &&
        _controller.text != widget.initialAmount) {
      _controller.text = widget.initialAmount!;
      _currentAmount = widget.initialAmount!;
    }
  }

  void _showExchangeRatesBottomSheet() {
    if (widget.selectedAccount == null ||
        widget.onConversionCurrencyChanged == null ||
        (widget.initialAmount?.isEmpty ?? true))
      return;

    final baseCurrency = widget.selectedAccount!.currency;
    final selectedCurrency = widget.conversionCurrency ?? baseCurrency;

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
    );
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
            textColor: AppColors.gradientPinkStart,
            gradient: LinearGradient(
              colors: [AppColors.gradientPinkStart, AppColors.gradientPinkEnd],
            ),
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
