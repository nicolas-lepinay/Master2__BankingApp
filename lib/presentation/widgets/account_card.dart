import 'package:flutter/material.dart';
import 'package:bankapp/data/database/database.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AccountCard extends StatelessWidget {
  final AccountSummary accountSummary;

  const AccountCard({super.key, required this.accountSummary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding.w),
      padding: EdgeInsets.all(AppConstants.largePadding.r),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom du compte
          Text(accountSummary.account.name, style: AppTextStyles.accountName),

          SizedBox(height: AppConstants.defaultPadding.h),

          // Solde actuel
          Text(
            AppFormatters.formatCurrency(
              accountSummary.currentBalance,
              accountSummary.account.currency,
              context,
            ),
            style: AppTextStyles.accountBalance,
          ),

          SizedBox(height: AppConstants.largePadding.h),

          // Ligne avec dépenses et revenus
          Row(
            children: [
              // Dépenses
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dépenses', style: AppTextStyles.sectionHeader),
                    SizedBox(height: 4.h),
                    Text(
                      AppFormatters.formatAmount(
                        -accountSummary.totalExpenses,
                        accountSummary.account.currency,
                        showSign: true,
                        context: context,
                      ),
                      style: AppTextStyles.h6.copyWith(color: AppColors.textLight),
                    ),
                  ],
                ),
              ),

              // Séparateur vertical
              Container(
                width: 1.w,
                height: 40.h,
                color: AppColors.textLight.withOpacity(0.3),
                margin: EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding.w),
              ),

              // Revenus
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revenus', style: AppTextStyles.sectionHeader),
                    SizedBox(height: 4.h),
                    Text(
                      AppFormatters.formatAmount(
                        accountSummary.totalRevenues,
                        accountSummary.account.currency,
                        showSign: true,
                        context: context,
                      ),
                      style: AppTextStyles.h6.copyWith(color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
