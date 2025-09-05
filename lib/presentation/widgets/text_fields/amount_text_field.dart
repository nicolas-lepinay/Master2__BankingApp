import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/domain/entities/transaction.dart';
import 'package:bankapp/presentation/widgets/helpers/gradient_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AmountTextField extends StatefulWidget {
  final TransactionType transactionType;
  final String currency;
  final String? initialAmount;
  final Function(String) onAmountChanged;
  final Color textColor;
  final Gradient? gradient;
  final bool enabled;
  final Function(bool hasFocus)? onFocusChanged;

  const AmountTextField({
    super.key,
    required this.transactionType,
    required this.currency,
    required this.onAmountChanged,
    this.initialAmount,
    this.textColor = Colors.black,
    this.gradient,
    this.enabled = true,
    this.onFocusChanged,
  });

  @override
  State<AmountTextField> createState() => _AmountTextFieldState();
}

class _AmountTextFieldState extends State<AmountTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAmount ?? '');
    _focusNode = FocusNode();

    // Ajouter listener pour détecter les changements de focus
    _focusNode.addListener(() {
      print('🎯 AmountTextField FocusNode - hasFocus: ${_focusNode.hasFocus}');
      if (widget.onFocusChanged != null) {
        widget.onFocusChanged!(_focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AmountTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si le montant initial a changé depuis l'extérieur, mettre à jour
    if (oldWidget.initialAmount != widget.initialAmount) {
      final newAmount = widget.initialAmount ?? '';
      if (_controller.text != newAmount) {
        _controller.text = newAmount;
      }
    }
  }

  void _onAmountChanged(String value) {
    widget.onAmountChanged(value);
  }

  String _getTransactionSign() {
    return widget.transactionType == TransactionType.expense ? '-' : '+';
  }

  Widget _buildCurrencySymbol({
    required String currencySymbol,
    required Color color,
  }) {
    return Text(
      currencySymbol,
      style: AppTextStyles.h1.copyWith(
        fontSize: 44.sp,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sign = _getTransactionSign();
    final currencySymbol = AppFormatters.getCurrencySymbol(widget.currency);
    final isSymbolLeft = AppFormatters.isCurrencySymbolLeft(
      widget.currency,
      context,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Signe de la transaction
        Text(
          sign,
          style: TextStyle(
            fontSize: 48.sp,
            fontWeight: FontWeight.w600,
            color: widget.gradient != null
                ? widget.gradient!.colors.first
                : widget.textColor,
            height: 1.0,
          ),
        ),

        SizedBox(width: 14.w),

        // Symbole de devise à gauche si nécessaire
        if (isSymbolLeft) ...[
          _buildCurrencySymbol(
            currencySymbol: currencySymbol,
            color: widget.gradient != null
                ? widget.gradient!.colors.first
                : widget.textColor,
          ),
          SizedBox(width: 10.w),
        ],

        // TextField pour le montant
        Flexible(
          child: IntrinsicWidth(
            child: GradientWidget(
              gradient: widget.gradient,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onAmountChanged,
                enabled: widget.enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                style: TextStyle(
                  fontSize: 48.sp,
                  fontWeight: FontWeight.w600,
                  color: widget.textColor,
                  height: 1.0,
                ),
                decoration: InputDecoration(
                  hintText: '10',
                  hintStyle: TextStyle(
                    fontSize: 48.sp,
                    fontWeight: FontWeight.w600,
                    color: widget.textColor.withValues(alpha: 0.15),
                    height: 1.0,
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  filled: false,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),
        ),

        // Symbole de devise à droite si nécessaire
        if (!isSymbolLeft) ...[
          SizedBox(width: 10.w),
          _buildCurrencySymbol(
            currencySymbol: currencySymbol,
            color: widget.gradient != null
                ? widget.gradient!.colors.last
                : widget.textColor,
          ),
        ],
      ],
    );
  }
}
