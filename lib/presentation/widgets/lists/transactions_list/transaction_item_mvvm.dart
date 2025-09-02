import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TransactionItemMVVM extends StatelessWidget {
  final domain.TransactionWithBalance transactionWithBalance;
  final VoidCallback? onTap;

  const TransactionItemMVVM({
    super.key,
    required this.transactionWithBalance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;
    final transaction = transactionWithBalance.transaction;
    final isDebit = transactionWithBalance.isExpense;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppConstants.smallPadding.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône de catégorie (carré blanc pour l'instant)
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: appTheme.background1,
                borderRadius: BorderRadius.circular(50.r),
              ),
              child: Icon(
                _getTransactionIcon(transaction.title),
                color: appTheme.text3,
                size: 24.sp,
              ),
            ),

            SizedBox(width: AppConstants.defaultPadding.w),

            // Informations de la transaction
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre/nom du tiers
                  Text(
                    transaction.title ?? 'Transaction',
                    style: AppTextStyles.transactionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 2.h),

                  // Commentaire
                  if (transaction.comment?.isNotEmpty == true) ...[
                    Text(
                      transaction.comment!,
                      style: AppTextStyles.transactionDescription.copyWith(
                        color: appTheme.text4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    Text(
                      "Catégorie...",
                      style: AppTextStyles.transactionDescription.copyWith(
                        color: appTheme.text4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(width: AppConstants.defaultPadding.w),

            // Montant et solde
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Montant de la transaction
                Text(
                  AppFormatters.formatAmountClean(
                    isDebit ? -transaction.amount : transaction.amount,
                    transaction.currency,
                    context: context,
                  ),
                  style: AppTextStyles.h4.copyWith(
                    color: appTheme.text1,
                    //color: isDebit ? appTheme.text1 : appTheme.textCredit,
                    fontFamily: AppTextStyles.robotoFontFamily,
                  ),
                ),

                // Solde après transaction
                Text(
                  AppFormatters.formatCurrency(
                    transactionWithBalance.balanceAfter.balance.amount,
                    transaction.currency,
                    context,
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontFamily: AppTextStyles.robotoFontFamily,
                    fontWeight: FontWeight.w500,
                    color:
                        transactionWithBalance.balanceAfter.balance.amount < 0
                        ? appTheme.textDebit
                        : appTheme.text4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTransactionIcon(String? title) {
    if (title == null) return Icons.payment;

    final titleLower = title.toLowerCase();

    if (titleLower.contains('netflix')) return Icons.tv;
    if (titleLower.contains('spotify')) return Icons.music_note;
    if (titleLower.contains('restaurant') || titleLower.contains('food'))
      return Icons.restaurant;
    if (titleLower.contains('gas') || titleLower.contains('essence'))
      return Icons.local_gas_station;
    if (titleLower.contains('shopping') || titleLower.contains('achat'))
      return Icons.shopping_cart;
    if (titleLower.contains('salary') || titleLower.contains('salaire'))
      return Icons.work;
    if (titleLower.contains('bank') || titleLower.contains('banque'))
      return Icons.account_balance;

    return Icons.payment;
  }
}
