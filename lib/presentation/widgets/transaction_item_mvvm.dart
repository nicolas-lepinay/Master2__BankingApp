import 'package:flutter/material.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TransactionItemMVVM extends StatelessWidget {
  final domain.TransactionWithBalance transactionWithBalance;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionItemMVVM({
    super.key,
    required this.transactionWithBalance,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;
    final transaction = transactionWithBalance.transaction;
    final isIncome = transactionWithBalance.isIncome;
    final isExpense = transactionWithBalance.isExpense;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppConstants.smallPadding.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône de transaction
            _buildTransactionIcon(context, appTheme),
            
            SizedBox(width: AppConstants.defaultPadding.w),

            // Informations de la transaction
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et montant
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Titre
                      Expanded(
                        child: Text(
                          transactionWithBalance.displayTitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: appTheme.text1,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Montant
                      Text(
                        _formatAmount(transaction.amount, transaction.currency, isIncome),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _getAmountColor(isIncome, isExpense),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 4.h),
                  
                  // Détails et solde
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Détails (catégorie et date)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (transaction.comment != null && transaction.comment!.isNotEmpty)
                              Text(
                                transaction.comment!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: appTheme.text3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              AppFormatters.formatDate(transaction.date, context),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: appTheme.text3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Solde après transaction
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            l10n.balance,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: appTheme.text3,
                            ),
                          ),
                          Text(
                            AppFormatters.formatAmount(
                              transactionWithBalance.balanceAfter.amount,
                              transaction.currency,
                            ),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: appTheme.text2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Indicateur de statut si nécessaire
                  if (transaction.status != domain.TransactionStatus.completed)
                    Container(
                      margin: EdgeInsets.only(top: 4.h),
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _getStatusColor(transaction.status).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        _getStatusText(transaction.status, l10n),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _getStatusColor(transaction.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Menu d'actions
            if (onEdit != null || onDelete != null)
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(l10n.edit),
                        ],
                      ),
                    ),
                  if (onDelete != null)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20.sp, color: Colors.red),
                          SizedBox(width: 8.w),
                          Text(l10n.delete, style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
                child: Padding(
                  padding: EdgeInsets.all(8.r),
                  child: Icon(
                    Icons.more_vert,
                    color: appTheme.text3,
                    size: 20.sp,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionIcon(BuildContext context, AppColorsExtended appTheme) {
    final transaction = transactionWithBalance.transaction;
    final isIncome = transactionWithBalance.isIncome;
    
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: appTheme.background1,
        borderRadius: BorderRadius.circular(50.r),
        border: Border.all(
          color: _getAmountColor(isIncome, transactionWithBalance.isExpense).withValues(alpha: 0.3),
          width: 2.w,
        ),
      ),
      child: Icon(
        _getTransactionIcon(transaction.title),
        color: _getAmountColor(isIncome, transactionWithBalance.isExpense),
        size: 24.sp,
      ),
    );
  }

  IconData _getTransactionIcon(String? title) {
    if (title == null || title.isEmpty) {
      return Icons.swap_horiz;
    }
    
    final lowerTitle = title.toLowerCase();
    
    // Mappage des mots-clés vers des icônes
    if (lowerTitle.contains('salaire') || lowerTitle.contains('paie')) {
      return Icons.work;
    } else if (lowerTitle.contains('restaurant') || lowerTitle.contains('food')) {
      return Icons.restaurant;
    } else if (lowerTitle.contains('supermarché') || lowerTitle.contains('courses')) {
      return Icons.shopping_cart;
    } else if (lowerTitle.contains('essence') || lowerTitle.contains('carburant')) {
      return Icons.local_gas_station;
    } else if (lowerTitle.contains('transport') || lowerTitle.contains('metro')) {
      return Icons.directions_bus;
    } else if (lowerTitle.contains('loyer') || lowerTitle.contains('logement')) {
      return Icons.home;
    } else if (lowerTitle.contains('santé') || lowerTitle.contains('médical')) {
      return Icons.medical_services;
    } else if (lowerTitle.contains('virement') || lowerTitle.contains('transfer')) {
      return Icons.compare_arrows;
    } else if (lowerTitle.contains('retrait') || lowerTitle.contains('atm')) {
      return Icons.atm;
    } else if (lowerTitle.contains('facture') || lowerTitle.contains('bill')) {
      return Icons.receipt;
    } else if (transactionWithBalance.isIncome) {
      return Icons.trending_up;
    } else {
      return Icons.trending_down;
    }
  }

  String _formatAmount(double amount, String currency, bool isIncome) {
    final formattedAmount = AppFormatters.formatAmount(amount, currency);
    return isIncome ? '+$formattedAmount' : '-$formattedAmount';
  }

  Color _getAmountColor(bool isIncome, bool isExpense) {
    if (isIncome) {
      return Colors.green;
    } else if (isExpense) {
      return Colors.red;
    } else {
      return AppColors.textSecondary;
    }
  }

  Color _getStatusColor(domain.TransactionStatus status) {
    switch (status) {
      case domain.TransactionStatus.pending:
        return Colors.orange;
      case domain.TransactionStatus.completed:
        return Colors.green;
      case domain.TransactionStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(domain.TransactionStatus status, AppLocalizations l10n) {
    switch (status) {
      case domain.TransactionStatus.pending:
        return l10n.pending;
      case domain.TransactionStatus.completed:
        return l10n.completed;
      case domain.TransactionStatus.cancelled:
        return l10n.cancelled;
    }
  }
}