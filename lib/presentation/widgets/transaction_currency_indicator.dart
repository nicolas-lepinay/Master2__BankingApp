import 'package:bankapp/core/services/currency_service.dart';
import 'package:bankapp/domain/entities/entities.dart';
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget d'indicateur de conversion de devise pour les transactions
class TransactionCurrencyIndicator extends ConsumerWidget {
  final TransactionWithBalance transaction;
  final bool showFullDetails;

  const TransactionCurrencyIndicator({
    super.key,
    required this.transaction,
    this.showFullDetails = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionViewModel = ref.watch(transactionViewModelProvider.notifier);
    
    // Vérifier si la transaction a été convertie
    final isConverted = transactionViewModel.isTransactionConverted(transaction);
    
    if (!isConverted) {
      // Pas de conversion, afficher normalement
      return _buildNormalTransaction(context);
    }

    // Transaction convertie, afficher avec indicateur
    return _buildConvertedTransaction(context, transactionViewModel);
  }

  Widget _buildNormalTransaction(BuildContext context) {
    final currency = CurrencyService.getCurrency(transaction.transaction.currency);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          currency?.formatAmount(transaction.transaction.amount) ?? 
          '${transaction.transaction.amount.toStringAsFixed(2)} ${transaction.transaction.currency}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildConvertedTransaction(BuildContext context, transactionViewModel) {
    final originalCurrency = transactionViewModel.getOriginalCurrency(transaction);
    final originalAmount = transactionViewModel.getOriginalAmount(transaction);
    final accountCurrency = transaction.transaction.currency;
    final accountAmount = transaction.transaction.amount;
    
    final originalCurrencyObj = CurrencyService.getCurrency(originalCurrency);
    final accountCurrencyObj = CurrencyService.getCurrency(accountCurrency);

    if (showFullDetails) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Montant du compte (converti)
          Row(
            children: [
              Text(
                accountCurrencyObj?.formatAmount(accountAmount) ?? 
                '${accountAmount.toStringAsFixed(2)} $accountCurrency',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.currency_exchange,
                      size: 12,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Converti',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Montant original
          Row(
            children: [
              Text(
                'Original: ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                originalCurrencyObj?.formatAmount(originalAmount) ?? 
                '${originalAmount.toStringAsFixed(2)} $originalCurrency',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Affichage compact avec indicateur
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            accountCurrencyObj?.formatAmount(accountAmount) ?? 
            '${accountAmount.toStringAsFixed(2)} $accountCurrency',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Converti depuis ${originalCurrencyObj?.formatAmount(originalAmount) ?? '${originalAmount.toStringAsFixed(2)} $originalCurrency'}',
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.currency_exchange,
                size: 14,
                color: Colors.blue[600],
              ),
            ),
          ),
        ],
      );
    }
  }
}

/// Widget pour afficher les statistiques de conversion
class TransactionConversionStats extends ConsumerWidget {
  const TransactionConversionStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionViewModel = ref.watch(transactionViewModelProvider.notifier);
    final stats = transactionViewModel.getConversionStats();

    if (stats['converted'] == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.currency_exchange,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Conversions de devises',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Transactions converties',
                    '${stats['converted']}',
                    '${stats['percentage']}% du total',
                    Icons.swap_horiz,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total des transactions',
                    '${stats['total']}',
                    '${stats['total'] - stats['converted']} normales',
                    Icons.receipt,
                    Colors.green,
                  ),
                ),
              ],
            ),
            if (stats['currencyDistribution'] != null && 
                (stats['currencyDistribution'] as Map).isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Répartition par devise',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildCurrencyDistribution(
                context,
                stats['currencyDistribution'] as Map<String, int>,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getColorShade(color, 50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getColorShade(color, 200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _getColorShade(color, 600)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getColorShade(color, 600),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getColorShade(color, 700),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: _getColorShade(color, 600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyDistribution(
    BuildContext context,
    Map<String, int> distribution,
  ) {
    return Column(
      children: distribution.entries.map((entry) {
        final currency = CurrencyService.getCurrency(entry.key);
        final count = entry.value;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              if (currency != null) ...[
                Text(
                  currency.symbol,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currency.code,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Helper method to get color shade
  Color _getColorShade(Color color, int shade) {
    if (color == Colors.blue) {
      switch (shade) {
        case 50: return Colors.blue[50]!;
        case 100: return Colors.blue[100]!;
        case 200: return Colors.blue[200]!;
        case 600: return Colors.blue[600]!;
        case 700: return Colors.blue[700]!;
        default: return color;
      }
    } else if (color == Colors.green) {
      switch (shade) {
        case 50: return Colors.green[50]!;
        case 100: return Colors.green[100]!;
        case 200: return Colors.green[200]!;
        case 600: return Colors.green[600]!;
        case 700: return Colors.green[700]!;
        default: return color;
      }
    } else if (color == Colors.grey) {
      switch (shade) {
        case 50: return Colors.grey[50]!;
        case 100: return Colors.grey[100]!;
        case 200: return Colors.grey[200]!;
        case 600: return Colors.grey[600]!;
        case 700: return Colors.grey[700]!;
        default: return color;
      }
    }
    return color;
  }
}