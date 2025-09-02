import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/presentation/widgets/lists/transactions_list/transaction_item_mvvm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TransactionsListMVVM extends StatefulWidget {
  final List<domain.TransactionWithBalance> transactions;
  final Function(domain.Transaction)? onTransactionTap;
  final bool scrollToToday;
  final String? accountCurrency;

  const TransactionsListMVVM({
    super.key,
    required this.transactions,
    this.onTransactionTap,
    this.scrollToToday = false,
    this.accountCurrency,
  });

  @override
  State<TransactionsListMVVM> createState() => _TransactionsListMVVMState();
}

class _TransactionsListMVVMState extends State<TransactionsListMVVM> {
  final ScrollController _scrollController = ScrollController();
  bool _areHeadersExpanded = true; // Tous les headers sont expanded par défaut
  bool _hasScrolledToToday = false; // Flag pour éviter les scrolls répétés

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TransactionsListMVVM oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si les transactions ont changé et qu'on doit scroller vers aujourd'hui
    // ET qu'on ne l'a pas encore fait
    if (widget.scrollToToday &&
        !_hasScrolledToToday &&
        widget.transactions != oldWidget.transactions &&
        widget.transactions.isNotEmpty) {
      _scrollToTodayAfterBuild();
    }
  }

  void _scrollToTodayAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
      _hasScrolledToToday = true; // Marquer comme fait
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
      targetOffset += 50.h; // Header de date
      targetOffset +=
          group.transactions.length * 80.h; // Environ 80px par transaction
      targetOffset += 8.h; // Spacing entre les groupes
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

  void _toggleAllHeaders() {
    setState(() {
      _areHeadersExpanded = !_areHeadersExpanded;
    });
  }

  // Calculer les totaux pour une date donnée
  Map<String, double> _calculateDayTotals(
    List<domain.TransactionWithBalance> dayTransactions,
  ) {
    double totalExpenses = 0.0;
    double totalRevenues = 0.0;

    for (final transactionWithBalance in dayTransactions) {
      final transaction = transactionWithBalance.transaction;
      final amount = transaction.amount;

      if (transactionWithBalance.isExpense) {
        totalExpenses += amount;
      } else {
        totalRevenues += amount;
      }
    }
    return {'expenses': totalExpenses, 'revenues': totalRevenues};
  }

  // Formater le montant net
  String _formatNetAmount(
    Map<String, double> dayTotals,
    List<domain.TransactionWithBalance> dayTransactions,
  ) {
    final totalExpenses = dayTotals['expenses'] ?? 0.0;
    final totalRevenues = dayTotals['revenues'] ?? 0.0;
    final netAmount = totalRevenues - totalExpenses;

    // Priorité : devise du compte > devise de la première transaction > EUR par défaut
    final currency =
        widget.accountCurrency ??
        (dayTransactions.isNotEmpty
            ? dayTransactions.first.transaction.currency
            : 'EUR');

    return AppFormatters.formatAmountClean(
      netAmount,
      currency,
      showSign: true,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.largePadding.r),
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
    // ET seulement si on ne l'a pas encore fait
    if (widget.scrollToToday && !_hasScrolledToToday) {
      _scrollToTodayAfterBuild();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(bottom: 100.h), // Espace pour la bottom nav
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final group = groupedTransactions[index];
        final dayTotals = _calculateDayTotals(group.transactions);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de date animé avec glissement
            _buildAnimatedDateHeader(
              group.dateLabel,
              _areHeadersExpanded, // Utiliser l'état global
              dayTotals,
              group.transactions, // Passer les transactions du groupe
            ),
            SizedBox(height: AppConstants.verySmallPadding.h / 4),
            // Liste des transactions pour cette date
            ...group.transactions.map((transactionWithBalance) {
              return TransactionItemMVVM(
                transactionWithBalance: transactionWithBalance,
                onTap: widget.onTransactionTap != null
                    ? () => widget.onTransactionTap!(
                        transactionWithBalance.transaction,
                      )
                    : null,
              );
            }),
            SizedBox(height: AppConstants.largePadding.h),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedDateHeader(
    String dateLabel,
    bool isExpanded,
    Map<String, double> dayTotals,
    List<domain.TransactionWithBalance> dayTransactions, // Nouveau paramètre
  ) {
    return GestureDetector(
      onTap: _toggleAllHeaders, // Toggle tous les headers
      child: SizedBox(
        //height: 30.h, // Hauteur fixe pour éviter les sauts
        child: Stack(
          children: [
            // Date - Animation de glissement du centre vers la gauche
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: isExpanded ? Alignment.centerLeft : Alignment.center,
              child: Text(
                dateLabel.toUpperCase(),
                style: AppTextStyles.dateHeader.copyWith(
                  color: Theme.of(
                    context,
                  ).extension<AppColorsExtended>()!.text3,
                ),
              ),
            ),

            // Total - Animation d'apparition depuis la droite
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: isExpanded ? 0 : -100.w, // -100 pour cacher complètement
              top: 0,
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                opacity: isExpanded ? 1.0 : 0.0,
                child: Text(
                  _formatNetAmount(dayTotals, dayTransactions),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontStyle: FontStyle.italic,
                    fontFamily: AppTextStyles.robotoFontFamily,
                    color: Theme.of(
                      context,
                    ).extension<AppColorsExtended>()!.text4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TransactionGroup> _groupTransactionsByDate(
    List<domain.TransactionWithBalance> transactions,
    BuildContext context,
  ) {
    final Map<String, List<domain.TransactionWithBalance>> grouped = {};

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

      // Trier les transactions de ce groupe par date (plus récente en premier)
      entry.value.sort(
        (a, b) => b.transaction.date.compareTo(a.transaction.date),
      );

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
  final List<domain.TransactionWithBalance> transactions;

  TransactionGroup({
    required this.dateLabel,
    required this.date,
    required this.transactions,
  });
}
