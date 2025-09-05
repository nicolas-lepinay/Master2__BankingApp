import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/data/cache/cache_manager.dart';
import 'package:bankapp/domain/entities/counterparty.dart';
import 'package:bankapp/domain/entities/transaction.dart';
import 'package:bankapp/presentation/widgets/forms/counterparty_search_field.dart';
import 'package:bankapp/presentation/widgets/helpers/superellipse_clipper.dart';
import 'package:bankapp/presentation/widgets/lists/counterparty_chips_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget modulaire réutilisable pour la sélection de Counterparty
/// Utilisable dans le bottom sheet et dans un futur écran standalone
class CounterpartySelectionWidget extends ConsumerStatefulWidget {
  final Function(Counterparty?) onCounterpartySelected;
  final Function(String)? onSearchTextChanged; // Pour récupérer le texte saisi
  final TransactionType? transactionType; // null pour usage standalone
  final Counterparty? initialSelection;
  final String? initialSearchText; // Texte initial pour persistance navigation
  final bool showCreateButton; // Pour écran standalone futur
  final String? customTitle; // Titre personnalisé pour usage standalone

  const CounterpartySelectionWidget({
    super.key,
    required this.onCounterpartySelected,
    this.onSearchTextChanged,
    this.transactionType,
    this.initialSelection,
    this.initialSearchText,
    this.showCreateButton = false,
    this.customTitle,
  });

  @override
  ConsumerState<CounterpartySelectionWidget> createState() =>
      _CounterpartySelectionWidgetState();
}

class _CounterpartySelectionWidgetState
    extends ConsumerState<CounterpartySelectionWidget> {
  String _searchQuery = '';
  List<Counterparty> _searchResults = [];
  Counterparty? _selectedCounterparty;
  bool _isUserTyping = false;

  @override
  void initState() {
    super.initState();
    _selectedCounterparty = widget.initialSelection;
    
    // Initialiser searchQuery : soit le nom du counterparty sélectionné, soit le texte initial
    if (_selectedCounterparty != null) {
      _searchQuery = _selectedCounterparty!.name;
    } else if (widget.initialSearchText?.isNotEmpty == true) {
      _searchQuery = widget.initialSearchText!;
      // Effectuer une recherche initiale si on a du texte mais pas de sélection
      _searchResults = CacheManager.instance.searchCounterpartiesByName(_searchQuery);
    }
  }

  void _onSearchQueryChanged(String query) {
    setState(() {
      _searchQuery = query;
      _isUserTyping = true;

      if (query.trim().isEmpty) {
        _searchResults = [];
      } else {
        // Seulement mettre à jour les résultats si c'est une vraie recherche utilisateur
        // (pas une mise à jour programmatique depuis chip selection)
        _searchResults = CacheManager.instance.searchCounterpartiesByName(
          query,
        );

        // Vérifier si un counterparty exact existe pour auto-sélection
        final exactMatch = CacheManager.instance.findCounterpartyByExactName(
          query,
        );
        if (exactMatch != null && _selectedCounterparty?.id != exactMatch.id) {
          // Sélection automatique si match exact trouvé
          _selectedCounterparty = exactMatch;
          widget.onCounterpartySelected(exactMatch);
        } else if (exactMatch == null && _selectedCounterparty != null) {
          // Désélectionner si plus de match exact ET si l'utilisateur tape vraiment
          final isExactMatch = query.trim().toLowerCase() == 
              _selectedCounterparty!.name.toLowerCase();
          if (!isExactMatch) {
            _selectedCounterparty = null;
            widget.onCounterpartySelected(null);
          }
        }
      }
    });

    // Notifier le parent du changement de texte
    widget.onSearchTextChanged?.call(query);
  }

  void _onCounterpartyTapped(Counterparty counterparty) {
    // Spécification : ne pas permettre de désélectionner en tapant sur la chip déjà sélectionnée
    if (_selectedCounterparty?.id == counterparty.id) {
      return; // Ignorer le tap sur une chip déjà sélectionnée
    }

    setState(() {
      _selectedCounterparty = counterparty;
      _searchQuery = counterparty.name;
      _isUserTyping = false; // Important : marquer comme non-utilisateur
      // NE PAS vider _searchResults - maintenir la liste visible avec sélection
    });

    // Notifier la sélection (mettra à jour le TextField via didUpdateWidget)
    widget.onCounterpartySelected(counterparty);

    // Notifier le changement de texte pour synchroniser
    widget.onSearchTextChanged?.call(counterparty.name);
  }

  void _onCounterpartyDeselected() {
    setState(() {
      _selectedCounterparty = null;
    });
    widget.onCounterpartySelected(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 60.h, bottom: 200.h),
      child: Column(
        children: [
          //SizedBox(height: 60.h),

          // Titre contextuel ("Payé à..." / "Reçu de..." ou titre personnalisé)
          if (widget.customTitle != null || widget.transactionType != null)
            _buildTitle(l10n, appTheme),

          SizedBox(height: 20.h),

          // Widget Orb ou Icône Counterparty
          _buildOrbOrIcon(appTheme),

          //SizedBox(height: 20.h),

          // Champ de recherche transparent
          CounterpartySearchField(
            onQueryChanged: _onSearchQueryChanged,
            onCounterpartySelected: (counterparty) =>
                _onCounterpartyDeselected(),
            selectedCounterparty: _selectedCounterparty,
            isUserTyping: _isUserTyping,
            initialText: _searchQuery, // Passer le texte initial pour persistance
          ),

          SizedBox(height: 40.h),

          // Liste des chips de résultats
          CounterpartyChipsList(
            counterparties: _searchResults,
            onCounterpartyTap: _onCounterpartyTapped,
            selectedCounterparty: _selectedCounterparty,
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(AppLocalizations l10n, AppColorsExtended appTheme) {
    String title;

    if (widget.customTitle != null) {
      title = widget.customTitle!;
    } else if (widget.transactionType == TransactionType.expense) {
      title = l10n.paidTo; // Utilisation directe temporaire
    } else if (widget.transactionType == TransactionType.income) {
      title = l10n.receivedFrom; // Utilisation directe temporaire
    } else {
      title = "..."; // Utilisation directe temporaire
    }

    return Text(
      title,
      style: AppTextStyles.h1.copyWith(
        color: appTheme.text2,
        fontFamily: AppTextStyles.playfairFontFamily,
        fontSize: 36.sp,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildOrbOrIcon(AppColorsExtended appTheme) {
    if (_selectedCounterparty != null) {
      // Afficher l'icône du Counterparty dans un Superellipse
      return Container(
        width: 90.r,
        height: 90.r,
        margin: EdgeInsets.symmetric(vertical: 45.h),
        child: ClipPath(
          clipper: SuperellipseClipper(n: 3.1),
          child: Container(
            color: appTheme.backgroundInvert,
            child:
                _selectedCounterparty!.icon != null &&
                    _selectedCounterparty!.icon!.isNotEmpty
                ? Image.network(
                    _selectedCounterparty!.icon!,
                    width: 90.r,
                    height: 90.r,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderIcon(appTheme);
                    },
                  )
                : _buildPlaceholderIcon(appTheme),
          ),
        ),
      );
    } else {
      // Afficher le widget Orb animé
      return SizedBox(
        width: 180.r,
        height: 180.r,
        child: Center(child: Image.asset(appTheme.orbAnimation!)),
      );
    }
  }

  Widget _buildPlaceholderIcon(AppColorsExtended appTheme) {
    return Center(
      child: Icon(Icons.person, size: 60.sp, color: appTheme.text3),
    );
  }

  Widget _buildOrbLoadingWidget() {
    return SizedBox(
      width: 120.r,
      height: 120.r,
      child: Center(child: Image.asset(AppConstants.orbStatic)),
    );
  }
}
