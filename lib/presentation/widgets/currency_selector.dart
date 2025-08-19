import 'package:bankapp/core/extensions/app_localizations_extensions.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/services/currency_conversion_service.dart';
import 'package:bankapp/core/services/currency_service.dart';
import 'package:bankapp/domain/entities/currency.dart';
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget de sélection de devise
class CurrencySelector extends ConsumerWidget {
  final String? selectedCurrency;
  final ValueChanged<String?> onCurrencySelected;
  final bool showMajorCurrenciesOnly;
  final String? hintText;
  final bool enabled;

  const CurrencySelector({
    super.key,
    this.selectedCurrency,
    required this.onCurrencySelected,
    this.showMajorCurrenciesOnly = false,
    this.hintText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyState = ref.watch(currencyViewModelProvider);
    final currencyViewModel = ref.watch(currencyViewModelProvider.notifier);

    final availableCurrencies = showMajorCurrenciesOnly
        ? currencyViewModel.getMajorCurrencies()
        : currencyState.availableCurrencies;

    return DropdownButtonFormField<String>(
      value: selectedCurrency,
      onChanged: enabled ? onCurrencySelected : null,
      decoration: InputDecoration(
        labelText: hintText ?? 'Devise',
        border: const OutlineInputBorder(),
        enabled: enabled,
      ),
      items: availableCurrencies.map((Currency currency) {
        return DropdownMenuItem<String>(
          value: currency.code,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currency.symbol,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(currency.code),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppLocalizations.of(
                        context,
                      )?.getCurrencyName(currency.code) ??
                      currency.getLocalizedName(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez sélectionner une devise';
        }
        if (!CurrencyService.isValidCurrency(value)) {
          return 'Devise non supportée';
        }
        return null;
      },
    );
  }
}

/// Widget de sélection de devise avec recherche
class CurrencySearchSelector extends ConsumerStatefulWidget {
  final String? selectedCurrency;
  final ValueChanged<String?> onCurrencySelected;
  final bool showMajorCurrenciesOnly;
  final String? hintText;
  final bool enabled;

  const CurrencySearchSelector({
    super.key,
    this.selectedCurrency,
    required this.onCurrencySelected,
    this.showMajorCurrenciesOnly = false,
    this.hintText,
    this.enabled = true,
  });

  @override
  ConsumerState<CurrencySearchSelector> createState() =>
      _CurrencySearchSelectorState();
}

class _CurrencySearchSelectorState
    extends ConsumerState<CurrencySearchSelector> {
  final TextEditingController _controller = TextEditingController();
  List<Currency> _filteredCurrencies = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _updateSelectedCurrency();
  }

  @override
  void didUpdateWidget(CurrencySearchSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCurrency != widget.selectedCurrency) {
      _updateSelectedCurrency();
    }
  }

  void _updateSelectedCurrency() {
    if (widget.selectedCurrency != null) {
      final currency = CurrencyService.getCurrency(widget.selectedCurrency!);
      if (currency != null) {
        _controller.text = '${currency.symbol} ${currency.code}';
      }
    } else {
      _controller.clear();
    }
  }

  void _filterCurrencies(String query) {
    final currencyState = ref.read(currencyViewModelProvider);
    final currencyViewModel = ref.read(currencyViewModelProvider.notifier);

    final availableCurrencies = widget.showMajorCurrenciesOnly
        ? currencyViewModel.getMajorCurrencies()
        : currencyState.availableCurrencies;

    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = availableCurrencies;
      } else {
        _filteredCurrencies = availableCurrencies.where((currency) {
          final searchTerm = query.toLowerCase();
          final l10n = AppLocalizations.of(context);
          final currencyName =
              l10n?.getCurrencyName(currency.code) ??
              currency.getLocalizedName();
          return currency.code.toLowerCase().contains(searchTerm) ||
              currencyName.toLowerCase().contains(searchTerm);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          enabled: widget.enabled,
          readOnly: true,
          decoration: InputDecoration(
            labelText: widget.hintText ?? 'Devise',
            border: const OutlineInputBorder(),
            suffixIcon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            enabled: widget.enabled,
          ),
          onTap: widget.enabled
              ? () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                  if (_isExpanded) {
                    _filterCurrencies('');
                  }
                }
              : null,
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Rechercher une devise...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: _filterCurrencies,
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _filteredCurrencies.length,
                    itemBuilder: (context, index) {
                      final currency = _filteredCurrencies[index];
                      final isSelected =
                          widget.selectedCurrency == currency.code;

                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        leading: Text(
                          currency.symbol,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        title: Text(currency.code),
                        subtitle: Text(
                          AppLocalizations.of(
                                context,
                              )?.getCurrencyName(currency.code) ??
                              currency.getLocalizedName(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        onTap: () {
                          widget.onCurrencySelected(currency.code);
                          _controller.text =
                              '${currency.symbol} ${currency.code}';
                          setState(() {
                            _isExpanded = false;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Widget d'affichage de conversion de devise
class CurrencyConversionDisplay extends ConsumerWidget {
  final double amount;
  final String fromCurrency;
  final String toCurrency;
  final bool showRate;

  const CurrencyConversionDisplay({
    super.key,
    required this.amount,
    required this.fromCurrency,
    required this.toCurrency,
    this.showRate = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyViewModel = ref.watch(currencyViewModelProvider.notifier);
    final conversionService = ref.watch(currencyConversionServiceProvider);

    return FutureBuilder<ConversionResult>(
      future: conversionService.convertAmount(
        amount: amount,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Conversion en cours...'),
            ],
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Text(
            'Erreur de conversion',
            style: TextStyle(color: Colors.red[600]),
          );
        }

        final result = snapshot.data!;
        if (!result.isSuccess) {
          return Text(
            'Conversion impossible',
            style: TextStyle(color: Colors.red[600]),
          );
        }

        final fromCurrencyObj = CurrencyService.getCurrency(fromCurrency);
        final toCurrencyObj = CurrencyService.getCurrency(toCurrency);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  fromCurrencyObj?.formatAmount(amount) ??
                      '${amount.toStringAsFixed(2)} $fromCurrency',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16),
                const SizedBox(width: 8),
                Text(
                  toCurrencyObj?.formatAmount(result.convertedAmount!) ??
                      '${result.convertedAmount!.toStringAsFixed(2)} $toCurrency',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (showRate && result.exchangeRate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Taux: 1 $fromCurrency = ${result.exchangeRate!.toStringAsFixed(4)} $toCurrency',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (result.lastUpdated != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Mis à jour: ${_formatDate(result.lastUpdated!)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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
}
