import 'package:flutter/material.dart';
import 'package:bankapp/data/database/database.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/presentation/widgets/transaction_item.dart';

class TransactionsList extends StatefulWidget {
  final List<TransactionWithBalance> transactions;
  final Function(Transaction)? onTransactionTap;
  final bool scrollToToday;

  const TransactionsList({
    super.key,
    required this.transactions,
    this.onTransactionTap,
    this.scrollToToday = false,
  });

  @override
  State<TransactionsList> createState() => _TransactionsListState();
}

class _TransactionsListState extends State<TransactionsList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TransactionsList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si les transactions ont changé et qu'on doit scroller vers aujourd'hui
    if (widget.scrollToToday &&
        widget.transactions != oldWidget.transactions &&
        widget.transactions.isNotEmpty) {
      _scrollToTodayAfterBuild();
    }
  }

  void _scrollToTodayAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  void _scrollToToday() {
    if (!mounted || widget.transactions.isEmpty) return;

    final groupedTransactions = _groupTransactionsByDate(
      widget.transactions,
      context,
    );
    if (groupedTransactions.isEmpty) return;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    // Trouver l'index du groupe de transactions le plus proche d'aujourd'hui
    int closestIndex = 0;
    Duration smallestDifference = Duration.zero;

    for (int i = 0; i < groupedTransactions.length; i++) {
      final groupDate = groupedTransactions[i].date;
      final groupDateOnly = DateTime(
        groupDate.year,
        groupDate.month,
        groupDate.day,
      );
      final difference = todayOnly.difference(groupDateOnly).abs();

      if (i == 0 || difference < smallestDifference) {
        smallestDifference = difference;
        closestIndex = i;
      }
    }

    // Calculer la position approximative pour scroller
    // Chaque groupe a approximativement: 40px pour le header + (nombre de transactions * 80px)
    double targetOffset = 0;

    for (int i = 0; i < closestIndex; i++) {
      final group = groupedTransactions[i];
      targetOffset += 40; // Header de date
      targetOffset +=
          group.transactions.length * 80; // Environ 80px par transaction
      targetOffset += 8; // Spacing entre les groupes
    }

    // S'assurer que l'offset est dans les limites du scroll
    if (_scrollController.hasClients) {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      targetOffset = targetOffset.clamp(0.0, maxScrollExtent);

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.largePadding),
          child: Text('Aucune transaction', style: AppTextStyles.bodyMedium),
        ),
      );
    }

    // Grouper les transactions par date
    final groupedTransactions = _groupTransactionsByDate(
      widget.transactions,
      context,
    );

    // Scroller vers aujourd'hui après la construction si nécessaire
    if (widget.scrollToToday) {
      _scrollToTodayAfterBuild();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 100), // Espace pour la bottom nav
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
                onTap: widget.onTransactionTap != null
                    ? () => widget.onTransactionTap!(
                        transactionWithBalance.transaction,
                      )
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
    BuildContext context,
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
      final dateLabel = AppFormatters.formatDate(date, context);

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
