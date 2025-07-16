import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddTransactionBottomSheetMVVM extends ConsumerStatefulWidget {
  final int? accountId; // Optionnel pour permettre sélection
  final domain.Transaction? transactionToEdit;

  const AddTransactionBottomSheetMVVM({
    super.key,
    this.accountId, // Plus obligatoire
    this.transactionToEdit,
  });

  @override
  ConsumerState<AddTransactionBottomSheetMVVM> createState() =>
      _AddTransactionBottomSheetMVVMState();
}

class _AddTransactionBottomSheetMVVMState
    extends ConsumerState<AddTransactionBottomSheetMVVM> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();

  domain.TransactionType _selectedType = domain.TransactionType.expense;
  domain.TransactionStatus _selectedStatus = domain.TransactionStatus.completed;
  DateTime _selectedDate = DateTime.now();
  int? _selectedCounterpartyId;
  List<int> _selectedCategoryIds = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final transaction = widget.transactionToEdit;
    if (transaction != null) {
      _titleController.text = transaction.title ?? '';
      _amountController.text = transaction.amount.toString();
      _commentController.text = transaction.comment ?? '';
      _selectedType = transaction.type;
      _selectedStatus = transaction.status;
      _selectedDate = transaction.date;
      _selectedCounterpartyId = transaction.counterpartyId;
      _selectedCategoryIds = transaction.categoryIds;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.r),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeSelector(),
                    SizedBox(height: 20.h),
                    _buildTitleField(),
                    SizedBox(height: 16.h),
                    _buildAmountField(),
                    SizedBox(height: 16.h),
                    _buildDateField(),
                    SizedBox(height: 16.h),
                    _buildCounterpartyField(),
                    SizedBox(height: 16.h),
                    _buildCategoryField(),
                    SizedBox(height: 16.h),
                    _buildCommentField(),
                    SizedBox(height: 16.h),
                    _buildStatusField(),
                    SizedBox(height: 24.h),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.transactionToEdit != null
                ? 'Modifier la transaction'
                : 'Nouvelle transaction',
            style: AppTextStyles.h5,
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, size: 24.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de transaction',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(
                'Revenus',
                domain.TransactionType.income,
                Icons.trending_up,
                Colors.green,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildTypeOption(
                'Dépense',
                domain.TransactionType.expense,
                Icons.trending_down,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption(
    String label,
    domain.TransactionType type,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? color
                : AppColors.textSecondary.withValues(alpha: 0.2),
            width: 2.w,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondary,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Titre',
        hintText: 'Ex: Supermarché, Salaire...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Le titre est requis';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Montant',
        hintText: '0.00',
        suffixText: 'EUR',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Le montant est requis';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Montant invalide';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20.sp),
            SizedBox(width: 12.w),
            Text(
              'Date: ${AppFormatters.formatDate(_selectedDate, context)}',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterpartyField() {
    return Consumer(
      builder: (context, ref, child) {
        final counterparties = ref.watch(counterpartyRepositoryProvider);

        return FutureBuilder<List<domain.Counterparty>>(
          future: counterparties.getAllCounterparties(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                padding: EdgeInsets.all(16.r),
                child: const CircularProgressIndicator(),
              );
            }

            final counterpartyList = snapshot.data!;

            return DropdownButtonFormField<int>(
              value: _selectedCounterpartyId,
              decoration: InputDecoration(
                labelText: 'Contrepartie (optionnel)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('Aucune')),
                ...counterpartyList.map(
                  (counterparty) => DropdownMenuItem<int>(
                    value: counterparty.id,
                    child: Text(counterparty.name),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCounterpartyId = value;
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryField() {
    return Consumer(
      builder: (context, ref, child) {
        final categories = ref.watch(categoryRepositoryProvider);

        return FutureBuilder<List<domain.Category>>(
          future: categories.getAllCategories(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                padding: EdgeInsets.all(16.r),
                child: const CircularProgressIndicator(),
              );
            }

            final categoryList = snapshot.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catégories (optionnel)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: categoryList.map((category) {
                    final isSelected = _selectedCategoryIds.contains(
                      category.id,
                    );

                    return FilterChip(
                      label: Text(category.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategoryIds.add(category.id);
                          } else {
                            _selectedCategoryIds.remove(category.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCommentField() {
    return TextFormField(
      controller: _commentController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Commentaire (optionnel)',
        hintText: 'Ajouter une note...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  Widget _buildStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statut',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<domain.TransactionStatus>(
          value: _selectedStatus,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          items: [
            DropdownMenuItem<domain.TransactionStatus>(
              value: domain.TransactionStatus.pending,
              child: Text(_getStatusLabel(domain.TransactionStatus.pending)),
            ),
            DropdownMenuItem<domain.TransactionStatus>(
              value: domain.TransactionStatus.completed,
              child: Text(_getStatusLabel(domain.TransactionStatus.completed)),
            ),
            DropdownMenuItem<domain.TransactionStatus>(
              value: domain.TransactionStatus.cancelled,
              child: Text(_getStatusLabel(domain.TransactionStatus.cancelled)),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedStatus = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveTransaction,
            child: _isLoading
                ? const CircularProgressIndicator()
                : Text(
                    widget.transactionToEdit != null ? 'Modifier' : 'Ajouter',
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final transactionViewModel = ref.read(
        transactionViewModelProvider.notifier,
      );
      final selectedAccount = ref.read(selectedAccountProvider);

      if (selectedAccount == null) {
        throw Exception('Aucun compte sélectionné');
      }

      if (widget.transactionToEdit != null) {
        await transactionViewModel.updateTransaction(
          transactionId: widget.transactionToEdit!.id,
          accountId: selectedAccount.id,
          type: _selectedType,
          amount: amount,
          currency: selectedAccount.currency,
          date: _selectedDate,
          title: _titleController.text.trim(),
          comment: _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : null,
          counterpartyId: _selectedCounterpartyId,
          categoryIds: _selectedCategoryIds,
          status: _selectedStatus,
        );
      } else {
        await transactionViewModel.createTransaction(
          accountId: selectedAccount.id,
          type: _selectedType,
          amount: amount,
          currency: selectedAccount.currency,
          date: _selectedDate,
          title: _titleController.text.trim(),
          comment: _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : null,
          counterpartyId: _selectedCounterpartyId,
          categoryIds: _selectedCategoryIds,
          status: _selectedStatus,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.transactionToEdit != null
                  ? 'Transaction modifiée avec succès'
                  : 'Transaction ajoutée avec succès',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getStatusLabel(domain.TransactionStatus status) {
    switch (status) {
      case domain.TransactionStatus.pending:
        return 'En attente';
      case domain.TransactionStatus.completed:
        return 'Terminé';
      case domain.TransactionStatus.cancelled:
        return 'Annulé';
    }
  }
}
