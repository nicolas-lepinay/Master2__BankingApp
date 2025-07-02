import 'package:flutter/material.dart';
import 'package:bankapp/data/database/database.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';

class AccountCard extends StatelessWidget {
  final AccountSummary accountSummary;

  const AccountCard({super.key, required this.accountSummary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
      ),
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom du compte
          Text(accountSummary.account.name, style: AppTextStyles.accountName),

          const SizedBox(height: AppConstants.defaultPadding),

          // Solde actuel
          Text(
            AppFormatters.formatCurrency(
              accountSummary.currentBalance,
              accountSummary.account.currency,
            ),
            style: AppTextStyles.accountBalance,
          ),

          const SizedBox(height: AppConstants.largePadding),

          // Ligne avec dépenses et revenus
          Row(
            children: [
              // Dépenses
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.expenses, style: AppTextStyles.sectionHeader),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.formatAmount(
                        -accountSummary.totalExpenses,
                        accountSummary.account.currency,
                        showSign: true,
                      ),
                      style: AppTextStyles.h6.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Séparateur vertical
              Container(
                width: 1,
                height: 40,
                color: AppColors.textLight.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                ),
              ),

              // Revenus
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.incomes, style: AppTextStyles.sectionHeader),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.formatAmount(
                        accountSummary.totalRevenues,
                        accountSummary.account.currency,
                        showSign: true,
                      ),
                      style: AppTextStyles.h6.copyWith(
                        color: AppColors.textLight,
                      ),
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
