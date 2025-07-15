import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/card_color_utils_mvvm.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BankCardWidgetMVVM extends StatefulWidget {
  final domain.AccountSummary accountSummary;
  final List<domain.Account> allAccounts;
  final Function(double)? onBalancePositionChanged;

  const BankCardWidgetMVVM({
    super.key,
    required this.accountSummary,
    required this.allAccounts,
    this.onBalancePositionChanged,
  });

  @override
  State<BankCardWidgetMVVM> createState() => _BankCardWidgetMVVMState();
}

class _BankCardWidgetMVVMState extends State<BankCardWidgetMVVM> {
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
    );
    return _isBalanceVisible ? formattedAmount : '••••••';
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
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(AppConstants.defaultPadding.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, l10n),

          SizedBox(height: AppConstants.defaultPadding.h),

          _buildBalance(context),

          SizedBox(height: AppConstants.defaultPadding.h),

          _buildFooter(context, l10n),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Nom du compte
        Expanded(
          child: Text(
            widget.accountSummary.account.name,
            style: AppTextStyles.h5.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Bouton de visibilité du solde
        GestureDetector(
          onTap: _toggleBalanceVisibility,
          child: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
              color: AppColors.white,
              size: 20.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalance(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Solde actuel
        Row(
          key: _balanceKey,
          children: [
            Expanded(
              child: Text(
                _formatBalanceDisplay(
                  widget.accountSummary.currentBalance.amount,
                ),
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Indicateur de tendance
            if (widget.accountSummary.getBalanceChangePercentage() != 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: widget.accountSummary.getBalanceChangePercentage() > 0
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.accountSummary.getBalanceChangePercentage() > 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: AppColors.white,
                      size: 14.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${widget.accountSummary.getBalanceChangePercentage().toStringAsFixed(1)}%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        SizedBox(height: 8.h),

        // Statistiques rapides
        Row(
          children: [
            _buildStatItem(
              AppLocalizations.of(context)!.incomes,
              widget.accountSummary.totalIncome.amount,
              Colors.green,
            ),
            SizedBox(width: 20.w),
            _buildStatItem(
              AppLocalizations.of(context)!.expenses,
              widget.accountSummary.totalExpenses.amount,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, double amount, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            _formatBalanceDisplay(amount),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Nombre de transactions
        Text(
          '${widget.accountSummary.totalTransactionsCount} transactions',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.white.withValues(alpha: 0.8),
          ),
        ),

        // Devise
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            widget.accountSummary.account.currency,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
