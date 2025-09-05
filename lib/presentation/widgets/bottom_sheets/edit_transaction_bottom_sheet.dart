import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/constants/supported_currencies.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditTransactionBottomSheet extends ConsumerStatefulWidget {
  final int transactionId;

  const EditTransactionBottomSheet({super.key, required this.transactionId});

  @override
  ConsumerState<EditTransactionBottomSheet> createState() =>
      _EditTransactionBottomSheetState();
}

class _EditTransactionBottomSheetState
    extends ConsumerState<EditTransactionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();
  int? _selectedCounterpartyId;

  domain.TransactionType _transactionType = domain.TransactionType.expense;
  String _selectedCurrency = 'EUR';
  int? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();
  domain.TransactionStatus _status = domain.TransactionStatus.completed;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _initializeFromTransaction(
    domain.TransactionWithBalance transactionWithBalance,
  ) {
    if (_isInitialized) return;

    final transaction = transactionWithBalance.transaction;

    _titleController.text = transaction.title ?? '';
    _amountController.text = transaction.amount.toString();
    _commentController.text = transaction.comment ?? '';
    _selectedCounterpartyId = transaction.counterpartyId;
    _transactionType = transaction.type;
    _selectedCurrency = transaction.currency;
    _selectedAccountId = transaction.accountId;
    _selectedDate = transaction.date;
    _status = transaction.status;
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final transactionAsync = ref.watch(
      transactionByIdProvider(widget.transactionId),
    );
    final accounts = ref.watch(accountsProvider);

    final transactionWithBalance = transactionAsync;

    if (transactionWithBalance == null) {
      return const Center(child: Text('Transaction non trouvée'));
    }

    _initializeFromTransaction(transactionWithBalance);

    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.defaultPadding.w,
        right: AppConstants.defaultPadding.w,
        top: AppConstants.defaultPadding.h,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            AppConstants.defaultPadding.h,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardBorderRadius.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          SizedBox(height: AppConstants.defaultPadding.h),

          // Titre
          Text(
            'Modifier la transaction',
            style: AppTextStyles.h5,
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppConstants.largePadding.h),

          // Formulaire
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Sélecteur de compte
                  accounts.isEmpty
                      ? const Text('Aucun compte disponible')
                      : DropdownButtonFormField<int>(
                          initialValue: _selectedAccountId,
                          decoration: const InputDecoration(
                            labelText: 'Compte',
                          ),
                          items: accounts.map((account) {
                            return DropdownMenuItem(
                              value: account.id,
                              child: Text(account.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedAccountId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Veuillez sélectionner un compte';
                            }
                            return null;
                          },
                        ),

                  SizedBox(height: AppConstants.defaultPadding.h),

                  // Tiers (Counterparty)
                  Consumer(
                    builder: (context, ref, child) {
                      final counterpartyState = ref.watch(
                        counterpartyViewModelProvider,
                      );
                      final counterparties = counterpartyState.counterparties;

                      // Charger les contreparties si nécessaire
                      if (counterparties.isEmpty &&
                          !counterpartyState.isLoading) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref
                              .read(counterpartyViewModelProvider.notifier)
                              .loadCounterparties();
                        });
                      }

                      if (counterpartyState.isLoading) {
                        return const CircularProgressIndicator();
                      }

                      return DropdownButtonFormField<int>(
                        initialValue: _selectedCounterpartyId,
                        decoration: InputDecoration(
                          labelText: l10n.counterparty,
                          hintText: 'Sélectionnez un tiers',
                          suffixIcon: const Icon(Icons.business),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Aucun tiers'),
                          ),
                          ...counterparties.map((counterparty) {
                            return DropdownMenuItem<int>(
                              value: counterparty.id,
                              child: Text(counterparty.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCounterpartyId = value;
                          });
                        },
                      );
                    },
                  ),

                  SizedBox(height: AppConstants.defaultPadding.h),

                  // Type de transaction
                  DropdownButtonFormField<domain.TransactionType>(
                    initialValue: _transactionType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: [
                      DropdownMenuItem(
                        value: domain.TransactionType.expense,
                        child: Text(l10n.expense),
                      ),
                      DropdownMenuItem(
                        value: domain.TransactionType.income,
                        child: Text(l10n.income),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _transactionType = value;
                        });
                      }
                    },
                  ),

                  SizedBox(height: AppConstants.defaultPadding.h),

                  // Titre
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: l10n.title,
                      hintText: 'Ex: Abonnement Netflix',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le titre est requis';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: AppConstants.defaultPadding.h),

                  // Montant
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: l10n.amount,
                      hintText: '0.00',
                      suffixText: AppFormatters.getCurrencySymbol(
                        _selectedCurrency,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le montant est requis';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Veuillez entrer un montant valide';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: AppConstants.defaultPadding.h),

                  // Devise
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    decoration: InputDecoration(labelText: l10n.currency),
                    items: SupportedCurrencies.allCodes.map((currency) {
                      final symbol = AppFormatters.getCurrencySymbol(currency);
                      return DropdownMenuItem(
                        value: currency,
                        child: Text('$currency ($symbol)'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCurrency = value;
                        });
                      }
                    },
                  ),

                  SizedBox(height: AppConstants.defaultPadding.h),

                  // Date
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: l10n.date),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppFormatters.formatDateShort(
                              _selectedDate,
                              context,
                            ),
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: AppConstants.defaultPadding.h),

                  // Statut
                  DropdownButtonFormField<domain.TransactionStatus>(
                    initialValue: _status,
                    decoration: InputDecoration(labelText: l10n.status),
                    items: [
                      DropdownMenuItem(
                        value: domain.TransactionStatus.pending,
                        child: Text(
                          AppFormatters.getTransactionStatusLabel(
                            domain.TransactionStatus.pending,
                            context,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: domain.TransactionStatus.completed,
                        child: Text(
                          AppFormatters.getTransactionStatusLabel(
                            domain.TransactionStatus.completed,
                            context,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _status = value;
                        });
                      }
                    },
                  ),

                  SizedBox(height: AppConstants.defaultPadding.h),

                  // Commentaire
                  TextFormField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: l10n.comment,
                      hintText: 'Commentaire optionnel',
                    ),
                    maxLines: 2,
                  ),

                  SizedBox(height: AppConstants.largePadding.h),

                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(l10n.cancel),
                        ),
                      ),

                      SizedBox(width: AppConstants.defaultPadding.w),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateTransaction,
                          child: _isLoading
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.w,
                                  ),
                                )
                              : Text(l10n.save),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _updateTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final transactionViewModel = ref.read(
        transactionViewModelProvider.notifier,
      );

      // Créer la transaction mise à jour avec les nouvelles valeurs
      await transactionViewModel.updateTransaction(
        transactionId: widget.transactionId,
        accountId: _selectedAccountId!,
        type: _transactionType,
        currency: _selectedCurrency,
        amount: double.parse(_amountController.text),
        title: _titleController.text.trim(),
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        date: _selectedDate,
        status: _status,
        counterpartyId: _selectedCounterpartyId,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction modifiée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification: $e'),
            backgroundColor: Colors.red,
          ),
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
}
