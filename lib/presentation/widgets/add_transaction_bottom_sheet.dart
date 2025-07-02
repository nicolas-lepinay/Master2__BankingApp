import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/presentation/providers/actions_provider.dart';
import 'package:bankapp/presentation/providers/database_provider.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/data/database/database.dart';

class AddTransactionBottomSheet extends ConsumerStatefulWidget {
  final int? accountId;

  const AddTransactionBottomSheet({super.key, this.accountId});

  @override
  ConsumerState<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState
    extends ConsumerState<AddTransactionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();

  String _transactionType = AppConstants.transactionTypeDebit;
  String _selectedCurrency = 'EUR';
  int? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.accountId;
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
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(accountsProvider);

    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.defaultPadding,
        right: AppConstants.defaultPadding,
        top: AppConstants.defaultPadding,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            AppConstants.defaultPadding,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardBorderRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // Titre
          Text(
            l10n.addTransaction,
            style: AppTextStyles.h5,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppConstants.largePadding),

          // Formulaire
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Sélecteur de compte
                  accountsAsync.when(
                    data: (accounts) {
                      if (accounts.isEmpty) {
                        return const Text('Aucun compte disponible');
                      }

                      return DropdownButtonFormField<int>(
                        value: _selectedAccountId,
                        decoration: const InputDecoration(labelText: 'Compte'),
                        items: accounts.map((account) {
                          return DropdownMenuItem(
                            value: account.id,
                            child: Text(account.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAccountId = value;
                            // Mettre à jour la devise par défaut
                            if (value != null) {
                              final selectedAccount = accounts.firstWhere(
                                (a) => a.id == value,
                              );
                              _selectedCurrency = selectedAccount.currency;
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Veuillez sélectionner un compte';
                          }
                          return null;
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => Text('Erreur: $error'),
                  ),

                  const SizedBox(height: AppConstants.defaultPadding),

                  // Type de transaction
                  DropdownButtonFormField<String>(
                    value: _transactionType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: [
                      DropdownMenuItem(
                        value: AppConstants.transactionTypeDebit,
                        child: Text(
                          AppFormatters.getTransactionTypeLabel(
                            AppConstants.transactionTypeDebit,
                            context,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: AppConstants.transactionTypeCredit,
                        child: Text(
                          AppFormatters.getTransactionTypeLabel(
                            AppConstants.transactionTypeCredit,
                            context,
                          ),
                        ),
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

                  const SizedBox(height: AppConstants.defaultPadding),

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

                  const SizedBox(height: AppConstants.defaultPadding),

                  // Montant
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: l10n.amount,
                      hintText: '0.00',
                      suffixText:
                          AppConstants.currencySymbols[_selectedCurrency],
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

                  const SizedBox(height: AppConstants.defaultPadding),

                  // Devise
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: InputDecoration(labelText: l10n.currency),
                    items: AppConstants.supportedCurrencies.map((currency) {
                      final symbol =
                          AppConstants.currencySymbols[currency] ?? currency;
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

                  const SizedBox(height: AppConstants.defaultPadding),

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

                  const SizedBox(height: AppConstants.defaultPadding),

                  // Commentaire
                  TextFormField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: l10n.comment,
                      hintText: 'Commentaire optionnel',
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: AppConstants.largePadding),

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

                      const SizedBox(width: AppConstants.defaultPadding),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveTransaction,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
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

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final transactionActions = ref.read(transactionActionsProvider);

      await transactionActions.createTransaction(
        accountId: _selectedAccountId!,
        transactionType: _transactionType,
        currency: _selectedCurrency,
        amount: double.parse(_amountController.text),
        title: _titleController.text.trim(),
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        date: _selectedDate,
        status: 1, // Confirmé par défaut
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création de la transaction: $e'),
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
