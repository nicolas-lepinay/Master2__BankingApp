import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/domain/entities/account.dart';
import 'package:bankapp/domain/entities/transaction.dart';
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/widgets/buttons/floating_action_button_custom.dart';
import 'package:bankapp/presentation/widgets/buttons/transaction_type_toggle.dart';
import 'package:bankapp/presentation/widgets/carousels/account_carousel_selection.dart';
import 'package:bankapp/presentation/widgets/page_indicators.dart';
import 'package:bankapp/presentation/widgets/text_fields/amount_input_widget_v2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddTransactionBottomSheetMvvmV2 extends ConsumerStatefulWidget {
  const AddTransactionBottomSheetMvvmV2({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => const AddTransactionBottomSheetMvvmV2(),
    );
  }

  @override
  ConsumerState<AddTransactionBottomSheetMvvmV2> createState() =>
      _AddTransactionBottomSheetMvvmV2State();
}

class _AddTransactionBottomSheetMvvmV2State
    extends ConsumerState<AddTransactionBottomSheetMvvmV2>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPageIndex = 0;
  final int _totalPages = 2;

  // État de validation du formulaire
  String _transactionAmount = '';
  String _convertedAmount = '';
  String _targetCurrency =
      ''; // Devise cible pour conversion (initialisée avec la devise du compte)
  bool _isLoadingConversion = false;
  TransactionType _transactionType = TransactionType.expense;
  Account? _selectedAccount;
  bool get _isFormValid =>
      _transactionAmount.isNotEmpty && _selectedAccount != null;

  // Utilisation de _convertedAmount pour éviter le warning
  String get displayConvertedAmount =>
      _convertedAmount.isEmpty ? '' : _convertedAmount;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeDefaultAccount();
  }

  void _initializeDefaultAccount() {
    // Récupérer le compte sélectionné depuis home_screen_mvvm.dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedAccount = ref.read(selectedAccountProvider);
      final accounts = ref.read(accountsProvider);

      if (selectedAccount != null) {
        // Utiliser le compte sélectionné dans le HomeScreen
        setState(() {
          _selectedAccount = selectedAccount;
          _targetCurrency =
              selectedAccount.currency; // Initialiser avec la devise du compte
        });
      } else if (accounts.isNotEmpty) {
        // Fallback: sélectionner le premier compte disponible
        setState(() {
          _selectedAccount = accounts.first;
          _targetCurrency =
              accounts.first.currency; // Initialiser avec la devise du compte
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  void _onAmountChanged(String amount) {
    setState(() {
      _transactionAmount = amount;
      // TODO: Déclencher la conversion en temps réel
      if (amount.isNotEmpty &&
          _selectedAccount != null &&
          _selectedAccount!.currency != _targetCurrency) {
        _performCurrencyConversion(amount);
      } else {
        _convertedAmount = '';
      }
    });
  }

  void _onConversionCurrencyChanged(String currency) {
    setState(() {
      _targetCurrency = currency;
    });
    // Déclencher la conversion si un montant existe
    if (_transactionAmount.isNotEmpty) {
      _performCurrencyConversion(_transactionAmount);
    }
  }

  void _onConvertedAmountChanged(String amount) {
    setState(() {
      _convertedAmount = amount;
    });
  }

  Future<void> _performCurrencyConversion(String amount) async {
    if (amount.isEmpty || _selectedAccount == null) return;

    setState(() {
      _isLoadingConversion = true;
    });

    try {
      final parsedAmount = double.tryParse(amount);
      if (parsedAmount == null) return;

      // Utiliser le CurrencyViewModel pour la conversion
      final currencyViewModel = ref.read(currencyViewModelProvider.notifier);

      // Convertir de la devise de transaction vers la devise du compte
      await currencyViewModel.convertAmount(
        amount: parsedAmount,
        fromCurrency: _targetCurrency, // De la devise de transaction
        toCurrency: _selectedAccount!.currency, // Vers la devise du compte
      );

      // Récupérer le résultat de la conversion
      final currencyState = ref.read(currencyViewModelProvider);

      if (currencyState.lastConversion != null &&
          currencyState.lastConversion!.isSuccess &&
          currencyState.lastConversion!.convertedAmount != null) {
        setState(() {
          _convertedAmount = currencyState.lastConversion!.convertedAmount!
              .toStringAsFixed(2);
          _isLoadingConversion = false;
        });
      } else {
        // Fallback sur un calcul simple si le service échoue
        final exchangeRateKey =
            '${_targetCurrency}_${_selectedAccount!.currency}';
        final exchangeRate = currencyState.exchangeRates[exchangeRateKey];

        double conversionRate = 1.0;
        if (exchangeRate != null) {
          conversionRate = exchangeRate.rate;
        } else {
          // Taux de conversion par défaut pour les devises communes (INVERSER)
          if (_targetCurrency == 'EUR' && _selectedAccount!.currency == 'USD') {
            conversionRate = 1.1;
          } else if (_targetCurrency == 'USD' &&
              _selectedAccount!.currency == 'EUR') {
            conversionRate = 0.91;
          }
        }

        final convertedValue = parsedAmount * conversionRate;
        setState(() {
          _convertedAmount = convertedValue.toStringAsFixed(2);
          _isLoadingConversion = false;
        });
      }
    } catch (e) {
      setState(() {
        _convertedAmount = '';
        _isLoadingConversion = false;
      });
    }
  }

  void _validateTransaction() {
    // TODO: Implémenter la validation et création de transaction
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      minChildSize: 0.0, // Fermeture complète
      maxChildSize: 0.89, // Hauteur maximale selon specs
      initialChildSize: 0.89,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: appTheme.background2,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Stack(
            children: [
              // Contenu principal avec PageView
              Column(
                children: [
                  // Handle pour drag
                  /*
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: appTheme.text2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  */
                  SizedBox(height: 24.h),

                  // PageIndicators
                  PageIndicators(
                    currentIndex: _currentPageIndex,
                    totalPages: _totalPages,
                  ),
                  SizedBox(height: 24.h),

                  // PageView qui prend toute la hauteur disponible
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      onPageChanged: _onPageChanged,
                      children: [
                        // Page 1 - Transaction Details (selon maquette)
                        _buildPage1(),
                        // Page 2 - Additional Fields (minimaliste)
                        _buildPage2(),
                      ],
                    ),
                  ),
                ],
              ),

              // Bouton flottant en bas (par-dessus PageView)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: FloatingActionButtonCustom(
                  text: l10n.validateTransaction,
                  iconData: CupertinoIcons.checkmark_alt,
                  margin: 32.sp,
                  isEnabled: _isFormValid,
                  onPressed: _isFormValid ? _validateTransaction : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPage1() {
    final l10n = AppLocalizations.of(context)!;
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(height: 10.h),
        //const Spacer(),

        // Toggle Switch DÉPENSE/REVENU
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.largePadding.sp * 2,
          ),
          child: TransactionTypeToggle(
            initialType: _transactionType,
            onChanged: (TransactionType newType) {
              setState(() {
                _transactionType = newType;
              });
            },
          ),
        ),

        //SizedBox(height: 60.h),
        const Spacer(),

        // Account Carousel avec Consumer pour récupérer les AccountSummary
        Consumer(
          builder: (context, ref, child) {
            final accounts = ref.watch(accountsProvider);
            final accountSummariesAsync = accounts
                .map(
                  (account) =>
                      ref.watch(accountSummaryByIdProvider(account.id)),
                )
                .toList();

            // Vérifier si tous les AccountSummary sont chargés
            final allLoaded = accountSummariesAsync.every(
              (async) => async.hasValue,
            );

            if (!allLoaded) {
              // Afficher un indicateur de chargement pendant que les données se chargent
              return SizedBox(
                height: 175.0.h,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            // Extraire toutes les données chargées
            final accountSummaries = accountSummariesAsync
                .map((async) => async.value!)
                .toList();

            return AccountCarouselSelection(
              selectedAccount: _selectedAccount,
              onAccountSelected: (Account account) {
                setState(() {
                  _selectedAccount = account;
                  // Reset de la devise et de la conversion lors du changement de compte
                  _targetCurrency = account.currency;
                  _convertedAmount = '';
                });
              },
              accountSummaries: accountSummaries,
              cardSize: 175.0,
              spacing: 14.0,
            );
          },
        ),

        // Spacer pour centrer verticalement la section montant
        const Spacer(flex: 2),

        // Widget Amount Input
        AmountInputWidgetV2(
          transactionType: _transactionType,
          selectedAccount: _selectedAccount,
          onAmountChanged: _onAmountChanged,
          onConvertedAmountChanged: _onConvertedAmountChanged,
          onConversionCurrencyChanged: _onConversionCurrencyChanged,
          initialAmount: _transactionAmount.isEmpty ? null : _transactionAmount,
          convertedAmount: _convertedAmount.isNotEmpty
              ? _convertedAmount
              : null,
          conversionCurrency: _targetCurrency != _selectedAccount?.currency
              ? _targetCurrency
              : null,
        ),

        // Spacer pour centrer verticalement la section montant
        const Spacer(flex: 4),
      ],
    );
  }

  Widget _buildPage2() {
    final l10n = AppLocalizations.of(context)!;
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Page ${_currentPageIndex + 1} - ${l10n.transactionDetails}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: appTheme.text1,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${l10n.date}, ${l10n.counterparty}, ${l10n.category}',
            style: TextStyle(fontSize: 16, color: appTheme.text2),
          ),
          const SizedBox(height: 20),
          Text(
            'Total pages: $_totalPages',
            style: TextStyle(fontSize: 12, color: appTheme.text3),
          ),
        ],
      ),
    );
  }
}
