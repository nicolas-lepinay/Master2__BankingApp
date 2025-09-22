import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/constants/supported_currencies.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/viewmodels/features/transaction_edit_view_model.dart';
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
  
  bool _isInitialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    if (_isInitialized) return;

    final editViewModel = ref.read(transactionEditViewModelProvider(widget.transactionId).notifier);
    
    _titleController.text = editViewModel.currentTitle ?? '';
    _amountController.text = editViewModel.currentAmount?.toString() ?? '';
    _commentController.text = editViewModel.currentComment ?? '';
    
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final editViewModelProvider = transactionEditViewModelProvider(widget.transactionId);
    final editViewModel = ref.watch(editViewModelProvider.notifier);
    final editState = ref.watch(editViewModelProvider);
    final homeScreenViewModel = ref.watch(homeScreenViewModelProvider);
    final accounts = homeScreenViewModel.accounts;

    // Initialiser le ViewModel au premier build
    if (!editState.hasTransaction && !editViewModel.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        editViewModel.initialize();
      });
    }

    // Si pas de transaction chargée, afficher loading ou erreur
    if (!editState.hasTransaction) {
      if (editViewModel.hasError) {
        return Center(child: Text('Erreur: ${editViewModel.errorMessage ?? "Transaction non trouvée"}'));
      }
      return const Center(child: CircularProgressIndicator());
    }

    _initializeControllers();

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
                          initialValue: editViewModel.currentAccountId,
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
                            if (value != null) {
                              editViewModel.updateAccount(value);
                            }
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
                        initialValue: editViewModel.currentCounterpartyId,
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
                          editViewModel.updateCounterparty(value);
                        },
                      );
                    },
                  ),

                  SizedBox(height: AppConstants.defaultPadding.h),

                  // Type de transaction
                  DropdownButtonFormField<domain.TransactionType>(
                    initialValue: editViewModel.currentType,
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
                        editViewModel.updateType(value);
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
                      errorText: editState.validationMessage?.contains('titre') == true 
                          ? editState.validationMessage : null,
                    ),
                    onChanged: (value) {
                      editViewModel.updateTitle(value);
                    },
                    validator: (value) {
                      final validationResult = editViewModel.validateTransaction();
                      if (validationResult?.contains('titre') == true) {
                        return validationResult;
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
                        editViewModel.currentCurrency ?? 'EUR',
                      ),
                      errorText: editState.validationMessage?.contains('montant') == true 
                          ? editState.validationMessage : null,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (value) {
                      final amount = double.tryParse(value);
                      if (amount != null) {
                        editViewModel.updateAmount(amount);
                      }
                    },
                    validator: (value) {
                      final validationResult = editViewModel.validateTransaction();
                      if (validationResult?.contains('montant') == true) {
                        return validationResult;
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: AppConstants.defaultPadding.h),

                  // Devise
                  DropdownButtonFormField<String>(
                    initialValue: editViewModel.currentCurrency,
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
                        editViewModel.updateCurrency(value);
                      }
                    },
                  ),

                  SizedBox(height: AppConstants.defaultPadding.h),

                  // Date
                  InkWell(
                    onTap: () => _selectDate(editViewModel),
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: l10n.date),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppFormatters.formatDateShort(
                              editViewModel.currentDate ?? DateTime.now(),
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
                    initialValue: editViewModel.currentStatus,
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
                        editViewModel.updateStatus(value);
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
                    onChanged: (value) {
                      editViewModel.updateComment(value);
                    },
                  ),

                  SizedBox(height: AppConstants.largePadding.h),

                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: editState.isUpdating
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(l10n.cancel),
                        ),
                      ),

                      SizedBox(width: AppConstants.defaultPadding.w),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: editState.isUpdating || !editState.canSave
                              ? null 
                              : () => _updateTransaction(editViewModel),
                          child: editState.isUpdating
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

  Future<void> _selectDate(TransactionEditViewModel editViewModel) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: editViewModel.currentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      editViewModel.updateDate(pickedDate);
    }
  }

  Future<void> _updateTransaction(TransactionEditViewModel editViewModel) async {
    // Valider avant de sauvegarder
    final validationResult = editViewModel.validateTransaction();
    if (validationResult != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationResult),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final success = await editViewModel.saveTransaction();
      
      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction modifiée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la modification'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    }
  }
}
