import 'package:bankapp/core/constants/supported_currencies.dart';
import 'package:bankapp/core/extensions/app_localizations_extensions.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/services/currency_conversion_service.dart';
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/widgets/currency_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exemple d'utilisation du système de conversion de devises
class CurrencyConversionExample extends ConsumerStatefulWidget {
  const CurrencyConversionExample({super.key});

  @override
  ConsumerState<CurrencyConversionExample> createState() =>
      _CurrencyConversionExampleState();
}

class _CurrencyConversionExampleState
    extends ConsumerState<CurrencyConversionExample> {
  final TextEditingController _amountController = TextEditingController();
  String? _fromCurrency;
  String? _toCurrency;
  ConversionResult? _lastConversion;
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    _fromCurrency = 'USD';
    _toCurrency = 'EUR';
    _amountController.text = '100.00';
  }

  Future<void> _performConversion() async {
    if (_fromCurrency == null || _toCurrency == null) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() {
      _isConverting = true;
      _lastConversion = null;
    });

    try {
      final conversionService = ref.read(currencyConversionServiceProvider);
      final result = await conversionService.convertAmount(
        amount: amount,
        fromCurrency: _fromCurrency!,
        toCurrency: _toCurrency!,
      );

      setState(() {
        _lastConversion = result;
        _isConverting = false;
      });
    } catch (e) {
      setState(() {
        _isConverting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de conversion: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemple de Conversion de Devises'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Conversion manuelle
            _buildConversionSection(),

            const SizedBox(height: 32),

            // Section 2: Devises supportées
            _buildSupportedCurrenciesSection(),

            const SizedBox(height: 32),

            // Section 3: Statistiques des taux de change
            _buildExchangeRateStatsSection(),

            const SizedBox(height: 32),

            // Section 4: Exemples d'utilisation
            _buildUsageExamplesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conversion de Devises',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Montant à convertir
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.euro),
              ),
              onChanged: (value) {
                // Conversion automatique après un délai
                if (value.isNotEmpty) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted && _amountController.text == value) {
                      _performConversion();
                    }
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Sélecteurs de devises
            Row(
              children: [
                Expanded(
                  child: CurrencySelector(
                    selectedCurrency: _fromCurrency,
                    onCurrencySelected: (currency) {
                      setState(() {
                        _fromCurrency = currency;
                      });
                      _performConversion();
                    },
                    hintText: 'Devise source',
                    showMajorCurrenciesOnly: true,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    setState(() {
                      final temp = _fromCurrency;
                      _fromCurrency = _toCurrency;
                      _toCurrency = temp;
                    });
                    _performConversion();
                  },
                  icon: const Icon(Icons.swap_horiz),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CurrencySelector(
                    selectedCurrency: _toCurrency,
                    onCurrencySelected: (currency) {
                      setState(() {
                        _toCurrency = currency;
                      });
                      _performConversion();
                    },
                    hintText: 'Devise cible',
                    showMajorCurrenciesOnly: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Résultat de la conversion
            if (_isConverting) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (_lastConversion != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _lastConversion!.isSuccess
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _lastConversion!.isSuccess
                        ? Colors.green[200]!
                        : Colors.red[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lastConversion!.isSuccess
                          ? 'Conversion réussie'
                          : 'Erreur de conversion',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _lastConversion!.isSuccess
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_lastConversion!.isSuccess) ...[
                      if (_fromCurrency != null && _toCurrency != null)
                        CurrencyConversionDisplay(
                          amount:
                              double.tryParse(_amountController.text) ?? 0.0,
                          fromCurrency: _fromCurrency!,
                          toCurrency: _toCurrency!,
                        ),
                    ] else ...[
                      Text(
                        _lastConversion!.errorMessage ?? 'Erreur inconnue',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSupportedCurrenciesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Devises Supportées',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Devises principales
            Text(
              'Devises Principales',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SupportedCurrencies.getMajorCurrencies().map((
                currency,
              ) {
                return Chip(
                  avatar: Text(currency.symbol),
                  label: Text(
                    '${currency.code} - ${AppLocalizations.of(context)?.getCurrencyName(currency.code) ?? currency.getLocalizedName()}',
                  ),
                  backgroundColor: Colors.blue[50],
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Devises secondaires
            Text(
              'Devises Secondaires',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SupportedCurrencies.getMinorCurrencies().map((
                currency,
              ) {
                return Chip(
                  avatar: Text(currency.symbol),
                  label: Text(
                    '${currency.code} - ${AppLocalizations.of(context)?.getCurrencyName(currency.code) ?? currency.getLocalizedName()}',
                  ),
                  backgroundColor: Colors.grey[100],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeRateStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques des Taux de Change',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Consumer(
              builder: (context, ref, child) {
                final currencyViewModel = ref.watch(
                  currencyViewModelProvider.notifier,
                );
                final stats = currencyViewModel.getExchangeRateStats();

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Taux en Cache',
                            '${stats['total']}',
                            Icons.storage,
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Taux Valides',
                            '${stats['valid']}',
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Taux Expirés',
                            '${stats['expired']}',
                            Icons.warning,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (stats['lastUpdate'] != null) ...[
                      Row(
                        children: [
                          Icon(Icons.update, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Dernière mise à jour: ${_formatDateTime(stats['lastUpdate'])}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color == Colors.blue
            ? Colors.blue[50]
            : color == Colors.green
            ? Colors.green[50]
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color == Colors.blue
              ? Colors.blue[200]!
              : color == Colors.green
              ? Colors.green[200]!
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color == Colors.blue
                ? Colors.blue[600]
                : color == Colors.green
                ? Colors.green[600]
                : Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color == Colors.blue
                  ? Colors.blue[700]
                  : color == Colors.green
                  ? Colors.green[700]
                  : Colors.grey[700],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color == Colors.blue
                  ? Colors.blue[600]
                  : color == Colors.green
                  ? Colors.green[600]
                  : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageExamplesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exemples d\'Utilisation',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Exemple 1: Conversion simple
            _buildExampleCard(
              'Conversion Simple',
              'Convertir 100 USD en EUR',
              '''
final conversionService = ref.read(currencyConversionServiceProvider);
final result = await conversionService.convertAmount(
  amount: 100.0,
  fromCurrency: 'USD',
  toCurrency: 'EUR',
);

if (result.isSuccess) {
  print('100 USD = \${result.convertedAmount} EUR');
}
''',
            ),

            const SizedBox(height: 16),

            // Exemple 2: Transaction avec conversion
            _buildExampleCard(
              'Transaction avec Conversion',
              'Créer une transaction avec conversion automatique',
              '''
final transactionViewModel = ref.read(transactionViewModelProvider.notifier);
await transactionViewModel.createTransactionWithConversion(
  accountId: accountId,
  type: TransactionType.expense,
  amount: 15.0,
  originalCurrency: 'USD',
  accountCurrency: 'EUR',
  date: DateTime.now(),
  title: 'Achat en voyage',
);
''',
            ),

            const SizedBox(height: 16),

            // Exemple 3: Utilisation des widgets
            _buildExampleCard(
              'Utilisation des Widgets',
              'Sélecteur de devise et affichage de conversion',
              '''
// Sélecteur de devise
CurrencySelector(
  selectedCurrency: selectedCurrency,
  onCurrencySelected: (currency) {
    setState(() {
      selectedCurrency = currency;
    });
  },
  showMajorCurrenciesOnly: true,
);

// Affichage de conversion
CurrencyConversionDisplay(
  amount: 100.0,
  fromCurrency: 'USD',
  toCurrency: 'EUR',
  showRate: true,
);
''',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard(String title, String description, String code) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Jamais';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else {
      return 'Il y a ${difference.inDays} j';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
