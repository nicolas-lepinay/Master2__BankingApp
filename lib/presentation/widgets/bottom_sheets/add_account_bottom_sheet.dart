import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/constants/supported_currencies.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddAccountBottomSheet extends ConsumerStatefulWidget {
  const AddAccountBottomSheet({super.key});

  @override
  ConsumerState<AddAccountBottomSheet> createState() =>
      _AddAccountBottomSheetState();
}

class _AddAccountBottomSheetState extends ConsumerState<AddAccountBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  String _selectedCurrency = 'EUR';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.defaultPadding.w,
        right: AppConstants.defaultPadding.w,
        top: AppConstants.defaultPadding.h,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            AppConstants.largePadding.h * 3,
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
            l10n.addAccount,
            style: AppTextStyles.h5,
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppConstants.largePadding.h),

          // Formulaire
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Nom du compte
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.accountName,
                    hintText: 'Ex: Compte courant BNP',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom du compte est requis';
                    }
                    return null;
                  },
                ),

                SizedBox(height: AppConstants.defaultPadding.h),

                // Solde initial
                TextFormField(
                  controller: _balanceController,
                  decoration: InputDecoration(
                    labelText: l10n.initialBalance,
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
                      return 'Le solde initial est requis';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null) {
                      return 'Veuillez entrer un montant valide';
                    }
                    return null;
                  },
                ),

                SizedBox(height: AppConstants.defaultPadding.h),

                // Sélecteur de devise
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
                        onPressed: _isLoading ? null : _saveAccount,
                        child: _isLoading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.w,
                                ),
                              )
                            : Text(
                                l10n.save,
                                style: TextStyle(fontSize: 20.sp),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final accountManagementViewModel = ref.read(
        accountManagementViewModelProvider.notifier,
      );

      // Utiliser le nouveau ViewModel pour créer le compte
      accountManagementViewModel.updateName(_nameController.text.trim());
      accountManagementViewModel.updateCurrency(_selectedCurrency);
      accountManagementViewModel.updateInitialBalance(
        double.parse(_balanceController.text),
      );

      final success = await accountManagementViewModel.createAccount();

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compte créé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final error =
              ref.read(accountManagementViewModelProvider).validationMessage ??
              'Erreur lors de la création du compte';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création du compte: $e'),
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
