import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/presentation/providers/actions_provider.dart';
import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';

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
            l10n.addAccount,
            style: AppTextStyles.h5,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppConstants.largePadding),

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

                const SizedBox(height: AppConstants.defaultPadding),

                // Solde initial
                TextFormField(
                  controller: _balanceController,
                  decoration: InputDecoration(
                    labelText: l10n.initialBalance,
                    hintText: '0.00',
                    suffixText: AppConstants.currencySymbols[_selectedCurrency],
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

                const SizedBox(height: AppConstants.defaultPadding),

                // Sélecteur de devise
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
                        onPressed: _isLoading ? null : _saveAccount,
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
      final accountActions = ref.read(accountActionsProvider);

      await accountActions.createAccount(
        name: _nameController.text.trim(),
        currency: _selectedCurrency,
        initialBalance: double.parse(_balanceController.text),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
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
