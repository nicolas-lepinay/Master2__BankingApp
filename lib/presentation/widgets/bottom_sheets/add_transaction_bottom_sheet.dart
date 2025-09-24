import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/domain/entities/account.dart';
import 'package:bankapp/domain/entities/brand_logo.dart';
import 'package:bankapp/domain/entities/counterparty.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/entities/transaction.dart';
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/widgets/buttons/floating_action_button_custom.dart';
import 'package:bankapp/presentation/widgets/buttons/transaction_type_toggle.dart';
import 'package:bankapp/presentation/widgets/carousels/account_carousel_selection.dart';
import 'package:bankapp/presentation/widgets/forms/category_selection_widget.dart';
import 'package:bankapp/presentation/widgets/forms/counterparty_selection_widget.dart';
import 'package:bankapp/presentation/widgets/page_indicators.dart';
import 'package:bankapp/presentation/widgets/text_fields/amount_input_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddTransactionBottomSheet extends ConsumerStatefulWidget {
  const AddTransactionBottomSheet({super.key});

  @override
  ConsumerState<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheet();
}

class _AddTransactionBottomSheet
    extends ConsumerState<AddTransactionBottomSheet>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late ScrollController _scrollController;
  int _currentPageIndex = 0;
  final double _initialBottomPadding = 220;
  late double _bottomPadding = _initialBottomPadding;
  final int _totalPages = 4;

  // État de validation du formulaire - Nouvelle sémantique
  String _transactionAmount =
      ''; // Montant saisi par utilisateur (dans devise sélectionnée)
  String _convertedAmount = ''; // Montant converti (dans devise du compte)
  String _targetCurrency =
      ''; // Devise sélectionnée par utilisateur (initialisée avec devise du compte)
  TransactionType _transactionType = TransactionType.expense;
  Account? _selectedAccount;

  // Champs de la page 2 (optionnels)
  DateTime _selectedDate = DateTime.now();
  String _transactionTitle = '';
  String _transactionComment = '';
  Counterparty? _selectedCounterparty;
  String _counterpartySearchText =
      ''; // Texte saisi dans le TextField counterparty

  // Champs de la page 2 (catégorie)
  domain.Category? _selectedCategory;

  // Champs de la page 3 (optionnels)
  List<int> _selectedCategoryIds = [];
  TransactionStatus _selectedStatus = TransactionStatus.pending;
  BrandLogo? _selectedLogo; // Logo sélectionné pour nouveau counterparty

  bool get _isFormValid {
    if (_selectedAccount == null) return false;

    // Si pas de conversion : seul le montant original doit être rempli
    if (!_hasConversion) {
      return _transactionAmount.isNotEmpty;
    }

    // Si conversion : les deux montants doivent être remplis
    return _transactionAmount.isNotEmpty && _convertedAmount.isNotEmpty;
  }

  // Helpers pour la nouvelle sémantique
  bool get _hasConversion =>
      _selectedAccount != null && _targetCurrency != _selectedAccount!.currency;

  String get _finalAmountForTransaction {
    if (_hasConversion) {
      // Si conversion nécessaire, OBLIGATOIRE d'avoir le montant converti
      return _convertedAmount.isNotEmpty ? _convertedAmount : '';
    } else {
      // Si pas de conversion, utiliser le montant direct
      return _transactionAmount;
    }
  }

  // Utilisation de _convertedAmount pour éviter le warning
  String get displayConvertedAmount =>
      _convertedAmount.isEmpty ? '' : _convertedAmount;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.1);
    _scrollController = ScrollController();
    _initializeDefaultAccount();
  }

  void _initializeDefaultAccount() {
    // Récupérer le compte sélectionné depuis home_screen.dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeScreenViewModel = ref.read(homeScreenViewModelProvider);
      final selectedAccount = homeScreenViewModel.selectedAccount;
      final accounts = homeScreenViewModel.accounts;

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
    _scrollController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  /// Gérer les changements de focus des TextFields pour auto-scroll
  Future<void> _onTextFieldFocusChanged(bool hasFocus) async {
    if (hasFocus) {
      setState(() {
        _bottomPadding = 435;
      });
      _scrollToBottom();
    } else {
      // Attendre un peu avant de scroller vers le début pour laisser le temps au clavier de se fermer
      Future.delayed(const Duration(milliseconds: 200), () {
        _scrollToInitialPosition();
      });

      // Attendre un peu pour éviter une animation "juttered"
      Future.delayed(const Duration(milliseconds: 600), () {
        setState(() {
          _bottomPadding = _initialBottomPadding;
        });
      });
    }
  }

  /// Auto-scroll vers le haut pour s'assurer que les TextFields soient visibles
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Attendre un peu que le clavier apparaisse
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          // Utiliser viewInsets.bottom pour calculer précisément la hauteur du clavier
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          final screenHeight = MediaQuery.of(context).size.height;

          // On veut que les champs soient visibles au-dessus du clavier avec un peu de marge
          final targetPosition = keyboardHeight > 0
              ? (screenHeight - keyboardHeight) *
                    0.3 // 30% de l'espace disponible au-dessus du clavier
              : screenHeight * 0.15; // Fallback si pas de clavier détecté

          _scrollController.animateTo(
            targetPosition.clamp(
              0.0,
              _scrollController.position.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  /// Retour à la position initiale quand le clavier se ferme
  void _scrollToInitialPosition() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, // Retour au tout début
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onAmountChanged(String amount) {
    setState(() {
      _transactionAmount = amount;

      // Si le montant original est vide, vider le montant converti
      if (amount.isEmpty) {
        _convertedAmount = '';
      } else if (_selectedAccount != null &&
          _selectedAccount!.currency != _targetCurrency) {
        // Déclencher la conversion en temps réel
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
        });
      }
    } catch (e) {
      setState(() {
        _convertedAmount = '';
      });
    }
  }

  Future<void> _validateTransaction() async {
    if (!_isFormValid) return;

    // Créer transaction avec nouvelle sémantique
    final finalAmount = double.tryParse(_finalAmountForTransaction);
    if (finalAmount == null) return;

    try {
      // ✅ ARCHITECTURE MVVM : Widget → ViewModel (pas Repository directement)
      // 🆕 Utiliser le nouveau provider avec WidgetRef pour l'invalidation des providers
      final transactionCreationViewModel = ref.read(
        transactionCreationViewModelProvider(ref).notifier,
      );

      // 🔥 LOGIQUE PRÉSERVÉE INTACTE : Tous les paramètres identiques
      await transactionCreationViewModel.createTransactionWithCounterparty(
        accountId: _selectedAccount!.id,
        type: _transactionType,
        amount: finalAmount,
        currency: _selectedAccount!.currency,
        date: _selectedDate,
        title: _transactionTitle.isEmpty ? null : _transactionTitle,
        comment: _transactionComment.isEmpty ? null : _transactionComment,
        selectedCounterpartyId: _selectedCounterparty?.id,
        counterpartySearchText: _counterpartySearchText.trim().isEmpty
            ? null
            : _counterpartySearchText,
        selectedLogo: _selectedLogo,
        categoryIds: _selectedCategory != null ? [_selectedCategory!.id] : [],
        status: _selectedStatus,
        // 🔥 PROPRIÉTÉS CRITIQUES : Conversion de devises préservées
        amountBeforeConversion: _hasConversion
            ? double.tryParse(_transactionAmount)
            : null,
        currencyBeforeConversion: _hasConversion ? _targetCurrency : null,
      );

      // Fermer la bottomsheet après sauvegarde réussie
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // TODO: Afficher un message d'erreur à l'utilisateur
      // Pour l'instant, fermer quand même la bottomsheet
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // ✅ Fonctions supprimées : logique déplacée dans TransactionCreationViewModel
  // - _createCounterpartyWithLogo() → TransactionCreationViewModel._createCounterpartyWithLogo()
  // - _downloadLogoInBackground() → ImageDownloadRepository.updateCounterpartyIconBackground()
  // - _createCounterpartyFromText() → TransactionCreationViewModel._createCounterpartyFromText()

  void _dismissKeyboard() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) currentFocus.unfocus();
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
        return GestureDetector(
          onTap: _dismissKeyboard,
          child: Container(
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
                      child: PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.horizontal,
                        onPageChanged: _onPageChanged,
                        itemCount: 4,
                        itemBuilder: (BuildContext context, int index) {
                          return FractionallySizedBox(
                            widthFactor: 1 / _pageController.viewportFraction,
                            child: _buildPageContent(index),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Bouton flottant en bas (par-dessus PageView)
                Positioned(
                  bottom: 60.h,
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
          ),
        );
      },
    );
  }

  Widget _buildAmountPage() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.only(top: 20.h, bottom: _bottomPadding.h),
      child: Column(
        children: [
          SizedBox(height: 10.h),

          // Toggle Switch DÉPENSE/REVENU
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.veryLargePadding.sp,
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

          SizedBox(height: 50.h),

          // Account Carousel avec Consumer pour récupérer les AccountSummary
          Consumer(
            builder: (context, ref, child) {
              final homeScreenViewModel = ref.watch(
                homeScreenViewModelProvider,
              );
              final accounts = homeScreenViewModel.accounts;

              // 🎯 ARCHITECTURE UNIFORME : Utiliser AccountCardsViewModel comme HomeScreen
              final cardsState = ref.watch(accountCardsViewModelProvider);

              // Vérifier si tous les AccountSummary sont chargés
              final accountSummaries = accounts
                  .map((account) => cardsState.getAccountSummary(account.id))
                  .where((summary) => summary != null)
                  .cast<domain.AccountSummary>()
                  .toList();

              // Si pas tous les comptes ont leur résumé chargé, afficher le chargement
              if (accountSummaries.length < accounts.length) {
                return SizedBox(
                  height: 175.0.h,
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              return AccountCarouselSelection(
                selectedAccount: _selectedAccount,
                onAccountSelected: (Account account) {
                  setState(() {
                    _selectedAccount = account;
                    // Reset de la devise et de la conversion lors du changement de compte
                    _targetCurrency = account.currency;
                    _convertedAmount = '';
                    // Note: _transactionAmount reste inchangé pour préserver la saisie utilisateur
                  });
                },
                accountSummaries: accountSummaries,
                cardSize:
                    175, //(MediaQuery.sizeOf(context).width * AppConstants.accountCarouselViewport) - (AppConstants.accountCarouselSpacing * 2),
                spacing: AppConstants.accountCarouselSpacing,
                viewportFraction: AppConstants.accountCarouselViewport,
              );
            },
          ),

          _targetCurrency != _selectedAccount?.currency
              ? SizedBox(height: 60.h)
              : SizedBox(height: 120.h),

          // Widget Amount Input avec callback pour auto-scroll
          AmountInputWidget(
            transactionType: _transactionType,
            selectedAccount: _selectedAccount,
            onAmountChanged: _onAmountChanged,
            onConvertedAmountChanged: _onConvertedAmountChanged,
            onConversionCurrencyChanged: _onConversionCurrencyChanged,
            initialAmount: _transactionAmount,
            convertedAmount: _convertedAmount,
            conversionCurrency: _targetCurrency != _selectedAccount?.currency
                ? _targetCurrency
                : null,
            onFocusChanged:
                _onTextFieldFocusChanged, // Auto-scroll et retour position initiale
          ),
        ],
      ),
    );
  }

  Widget _buildCounterpartyPage() {
    return CounterpartySelectionWidget(
      transactionType: _transactionType,
      initialSelectedLogo: _selectedLogo,
      onCounterpartySelected: (counterparty) {
        setState(() {
          _selectedCounterparty = counterparty;
          // Réinitialiser le logo sélectionné si un counterparty est sélectionné
          if (counterparty != null) {
            _selectedLogo = null;
          }
        });
      },
      onLogoSelected: (logo) {
        setState(() {
          _selectedLogo = logo;
          // Réinitialiser la sélection de counterparty si un logo est sélectionné
          if (logo != null) {
            _selectedCounterparty = null;
          }
        });
      },
      onSearchTextChanged: (text) {
        setState(() {
          _counterpartySearchText = text;
        });
      },
      initialSelection: _selectedCounterparty,
      initialSearchText: _counterpartySearchText.isNotEmpty
          ? _counterpartySearchText
          : null,
    );
  }

  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return _buildAmountPage();
      case 1:
        return _buildCounterpartyPage();
      case 2:
        return _buildCategoryPage();
      case 3:
        return _buildOthersPage();
      default:
        return Container();
    }
  }

  Widget _buildCategoryPage() {
    final l10n = AppLocalizations.of(context)!;

    return CategorySelectionWidget(
      title: l10n.category,
      initialSelection: _selectedCategory,
      onCategorySelected: (domain.Category? category) {
        setState(() {
          _selectedCategory = category;
        });
      },
      showTitle: true,
      showSearchBar: true,
      height: double.infinity,
    );
  }

  Widget _buildOthersPage() {
    final l10n = AppLocalizations.of(context)!;
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de section
          Text(
            l10n.transactionDetails,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: appTheme.text1,
            ),
          ),
          SizedBox(height: 16.h),

          Text(
            'Champs optionnels',
            style: TextStyle(fontSize: 14.sp, color: appTheme.text3),
          ),
          SizedBox(height: 24.h),

          // Champ Date
          _buildDateField(),
          SizedBox(height: 20.h),

          // Champ Titre
          _buildTitleField(),
          SizedBox(height: 20.h),

          // Champ Commentaire
          _buildCommentField(),
          SizedBox(height: 20.h),

          // Champ Statut
          _buildStatusField(),
          SizedBox(height: 200.h), // Espace pour le bouton flottant
        ],
      ),
    );
  }

  Widget _buildDateField() {
    final l10n = AppLocalizations.of(context)!;
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.date,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: appTheme.text1,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) {
              setState(() {
                _selectedDate = date;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: appTheme.buttonBackgroundDisabled!.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: appTheme.text5!.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              AppFormatters.formatDate(_selectedDate, context),
              style: TextStyle(fontSize: 16.sp, color: appTheme.text1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    final l10n = AppLocalizations.of(context)!;
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: appTheme.text1,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          onChanged: (value) {
            setState(() {
              _transactionTitle = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Ex: Achat supermarché',
            hintStyle: TextStyle(color: appTheme.text3, fontSize: 16.sp),
            filled: true,
            fillColor: appTheme.buttonBackgroundDisabled!.withValues(
              alpha: 0.1,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: appTheme.text5!.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: appTheme.text5!.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: appTheme.buttonBackground1!,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
          style: TextStyle(fontSize: 16.sp, color: appTheme.text1),
        ),
      ],
    );
  }

  Widget _buildCommentField() {
    final l10n = AppLocalizations.of(context)!;
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.comment,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: appTheme.text1,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          onChanged: (value) {
            setState(() {
              _transactionComment = value;
            });
          },
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Notes supplémentaires...',
            hintStyle: TextStyle(color: appTheme.text3, fontSize: 16.sp),
            filled: true,
            fillColor: appTheme.buttonBackgroundDisabled!.withValues(
              alpha: 0.1,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: appTheme.text5!.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: appTheme.text5!.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: appTheme.buttonBackground1!,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
          style: TextStyle(fontSize: 16.sp, color: appTheme.text1),
        ),
      ],
    );
  }

  Widget _buildStatusField() {
    final l10n = AppLocalizations.of(context)!;
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.status,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: appTheme.text1,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildStatusOption(
                'Terminée',
                TransactionStatus.completed,
                Colors.green,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatusOption(
                'En attente',
                TransactionStatus.pending,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusOption(
    String label,
    TransactionStatus status,
    Color color,
  ) {
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;
    final isSelected = _selectedStatus == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : appTheme.buttonBackgroundDisabled!.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color : appTheme.text5!.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? color : appTheme.text2,
            ),
          ),
        ),
      ),
    );
  }
}
