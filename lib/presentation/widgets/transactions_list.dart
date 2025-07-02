import 'package:flutter/material.dart';
import 'package:bankapp/data/database/database.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/presentation/widgets/transaction_item.dart';

class TransactionsList extends StatelessWidget {
  final List<TransactionWithBalance> transactions;
  final Function(Transaction)? onTransactionTap;

  const TransactionsList({
    super.key,
    required this.transactions,
    this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.largePadding),
          child: Text('Aucune transaction', style: AppTextStyles.bodyMedium),
        ),
      );
    }

    // Grouper les transactions par date
    final groupedTransactions = _groupTransactionsByDate(transactions);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final group = groupedTransactions[index];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de date
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
              child: Center(
                child: Text(group.dateLabel, style: AppTextStyles.dateHeader),
              ),
            ),

            // Liste des transactions pour cette date
            ...group.transactions.map((transactionWithBalance) {
              return TransactionItem(
                transactionWithBalance: transactionWithBalance,
                onTap: onTransactionTap != null
                    ? () =>
                          onTransactionTap!(transactionWithBalance.transaction)
                    : null,
              );
            }).toList(),

            const SizedBox(height: AppConstants.smallPadding),
          ],
        );
      },
    );
  }

  List<TransactionGroup> _groupTransactionsByDate(
    List<TransactionWithBalance> transactions,
  ) {
    final Map<String, List<TransactionWithBalance>> grouped = {};

    for (final transactionWithBalance in transactions) {
      final date = transactionWithBalance.transaction.date;
      final dateKey = '${date.year}-${date.month}-${date.day}';

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transactionWithBalance);
    }

    // Convertir en liste triée par date (plus récente en premier)
    final List<TransactionGroup> result = [];

    for (final entry in grouped.entries) {
      final date = grouped[entry.key]!.first.transaction.date;
      final dateLabel = AppFormatters.formatDate(date);

      result.add(
        TransactionGroup(
          dateLabel: dateLabel,
          date: date,
          transactions: entry.value,
        ),
      );
    }

    // Trier par date décroissante (plus récent en premier)
    result.sort((a, b) => b.date.compareTo(a.date));

    return result;
  }
}

class TransactionGroup {
  final String dateLabel;
  final DateTime date;
  final List<TransactionWithBalance> transactions;

  TransactionGroup({
    required this.dateLabel,
    required this.date,
    required this.transactions,
  });
}
