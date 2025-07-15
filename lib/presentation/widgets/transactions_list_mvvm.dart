import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/presentation/widgets/transaction_item_mvvm.dart';
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TransactionsListMVVM extends ConsumerStatefulWidget {
  final List<domain.TransactionWithBalance> transactions;
  final Function(domain.Transaction)? onTransactionTap;
  final Function(domain.Transaction)? onTransactionEdit;
  final Function(domain.Transaction)? onTransactionDelete;
  final bool scrollToToday;
  final String? accountCurrency;
  final bool showPagination;
  final bool showSearch;

  const TransactionsListMVVM({
    super.key,
    required this.transactions,
    this.onTransactionTap,
    this.onTransactionEdit,
    this.onTransactionDelete,
    this.scrollToToday = false,
    this.accountCurrency,
    this.showPagination = false,
    this.showSearch = false,
  });

  @override
  ConsumerState<TransactionsListMVVM> createState() => _TransactionsListMVVMState();
}

class _TransactionsListMVVMState extends ConsumerState<TransactionsListMVVM> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _areHeadersExpanded = true;
  bool _hasScrolledToToday = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TransactionsListMVVM oldWidget) {
    super.didUpdateWidget(oldWidget);

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
      _hasScrolledToToday = true;
    });
  }

  void _scrollToToday() {
    if (widget.transactions.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    double targetOffset = 0;
    double currentOffset = 0;
    
    final groupedTransactions = _groupTransactionsByDate(widget.transactions);
    
    for (final entry in groupedTransactions.entries) {
      final date = entry.key;
      final transactions = entry.value;
      
      // Hauteur du header de date
      currentOffset += 60.h;
      
      if (date.isAtSameMomentAs(today)) {
        targetOffset = currentOffset - 100.h; // Offset pour centrer
        break;
      }
      
      // Hauteur des transactions de cette date
      if (_areHeadersExpanded) {
        currentOffset += transactions.length * 80.h; // Hauteur approximative par transaction
      }
    }
    
    if (targetOffset > 0) {
      _scrollController.animateTo(
        targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Map<DateTime, List<domain.TransactionWithBalance>> _groupTransactionsByDate(
    List<domain.TransactionWithBalance> transactions,
  ) {
    final Map<DateTime, List<domain.TransactionWithBalance>> grouped = {};
    
    for (final transaction in transactions) {
      final date = DateTime(
        transaction.transaction.date.year,
        transaction.transaction.date.month,
        transaction.transaction.date.day,
      );
      
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(transaction);
    }
    
    return grouped;
  }

  double _calculateDayTotal(List<domain.TransactionWithBalance> transactions) {
    return transactions.fold(0.0, (sum, tx) {
      return sum + (tx.isIncome ? tx.transaction.amount : -tx.transaction.amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;
    
    if (widget.transactions.isEmpty) {
      return _buildEmptyState(context, appTheme);
    }

    return Column(
      children: [
        // Barre de recherche si activée
        if (widget.showSearch)
          _buildSearchBar(context, appTheme),
        
        // Statistiques rapides
        _buildQuickStats(context, appTheme),
        
        // Liste des transactions
        Expanded(
          child: _buildTransactionsList(context, appTheme),
        ),
        
        // Pagination si activée
        if (widget.showPagination)
          _buildPaginationControls(context, appTheme),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, AppColorsExtended appTheme) {
    return Container(
      margin: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: appTheme.background1,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher une transaction...',
          prefixIcon: Icon(Icons.search, color: appTheme.text3),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
        onChanged: (query) {
          final transactionViewModel = ref.read(transactionViewModelProvider.notifier);
          transactionViewModel.searchTransactions(query);
        },
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, AppColorsExtended appTheme) {
    final incomeTotal = widget.transactions
        .where((tx) => tx.isIncome)
        .fold(0.0, (sum, tx) => sum + tx.transaction.amount);
    
    final expenseTotal = widget.transactions
        .where((tx) => tx.isExpense)
        .fold(0.0, (sum, tx) => sum + tx.transaction.amount);
    
    final netAmount = incomeTotal - expenseTotal;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: appTheme.background1,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Revenus',
              incomeTotal,
              Colors.green,
              widget.accountCurrency ?? 'EUR',
            ),
          ),
          Container(
            width: 1.w,
            height: 30.h,
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _buildStatItem(
              'Dépenses',
              expenseTotal,
              Colors.red,
              widget.accountCurrency ?? 'EUR',
            ),
          ),
          Container(
            width: 1.w,
            height: 30.h,
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _buildStatItem(
              'Net',
              netAmount,
              netAmount >= 0 ? Colors.green : Colors.red,
              widget.accountCurrency ?? 'EUR',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double amount, Color color, String currency) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          AppFormatters.formatAmount(amount, currency),
          style: AppTextStyles.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(BuildContext context, AppColorsExtended appTheme) {
    final groupedTransactions = _groupTransactionsByDate(widget.transactions);
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Plus récent en premier

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final transactions = groupedTransactions[date]!;
        final dayTotal = _calculateDayTotal(transactions);
        
        return _buildDateGroup(context, appTheme, date, transactions, dayTotal);
      },
    );
  }

  Widget _buildDateGroup(
    BuildContext context,
    AppColorsExtended appTheme,
    DateTime date,
    List<domain.TransactionWithBalance> transactions,
    double dayTotal,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la date
        _buildDateHeader(context, appTheme, date, dayTotal),
        
        // Transactions de la journée
        if (_areHeadersExpanded)
          ...transactions.map(
            (transaction) => TransactionItemMVVM(
              transactionWithBalance: transaction,
              onTap: () => widget.onTransactionTap?.call(transaction.transaction),
              onEdit: () => widget.onTransactionEdit?.call(transaction.transaction),
              onDelete: () => widget.onTransactionDelete?.call(transaction.transaction),
            ),
          ),
        
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildDateHeader(
    BuildContext context,
    AppColorsExtended appTheme,
    DateTime date,
    double dayTotal,
  ) {
    final isToday = _isToday(date);
    final isYesterday = _isYesterday(date);
    
    String dateText;
    if (isToday) {
      dateText = 'Aujourd\'hui';
    } else if (isYesterday) {
      dateText = 'Hier';
    } else {
      dateText = AppFormatters.formatDate(date, context);
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _areHeadersExpanded = !_areHeadersExpanded;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: isToday ? AppColors.primary.withValues(alpha: 0.1) : appTheme.background1,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isToday ? AppColors.primary.withValues(alpha: 0.3) : AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _areHeadersExpanded ? Icons.expand_less : Icons.expand_more,
              color: appTheme.text3,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              dateText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: appTheme.text1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              AppFormatters.formatAmount(dayTotal, widget.accountCurrency ?? 'EUR'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: dayTotal >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context, AppColorsExtended appTheme) {
    return Consumer(
      builder: (context, ref, child) {
        final transactionState = ref.watch(transactionViewModelProvider);
        final transactionViewModel = ref.read(transactionViewModelProvider.notifier);
        
        return Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: appTheme.background1,
            border: Border(top: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Bouton précédent
              ElevatedButton.icon(
                onPressed: transactionState.hasPreviousPage
                    ? () => transactionViewModel.previousPage()
                    : null,
                icon: Icon(Icons.chevron_left, size: 18.sp),
                label: const Text('Précédent'),
              ),
              
              // Indicateur de page
              Text(
                'Page ${transactionState.currentPage + 1} sur ${transactionState.totalPages}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: appTheme.text2,
                ),
              ),
              
              // Bouton suivant
              ElevatedButton.icon(
                onPressed: transactionState.hasNextPage
                    ? () => transactionViewModel.nextPage()
                    : null,
                icon: Icon(Icons.chevron_right, size: 18.sp),
                label: const Text('Suivant'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColorsExtended appTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64.sp,
            color: appTheme.text3,
          ),
          SizedBox(height: 16.h),
          Text(
            'Aucune transaction',
            style: AppTextStyles.h5.copyWith(
              color: appTheme.text2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Les transactions de ce compte apparaîtront ici',
            style: AppTextStyles.bodyMedium.copyWith(
              color: appTheme.text3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}