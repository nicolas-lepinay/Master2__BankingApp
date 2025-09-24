import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/extensions/color_extensions.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/image_utils.dart';
import 'package:bankapp/data/cache/cache_manager.dart';
import 'package:bankapp/domain/entities/brand_logo.dart';
import 'package:bankapp/domain/entities/counterparty.dart';
import 'package:bankapp/domain/entities/transaction.dart';
import 'package:bankapp/presentation/widgets/bottom_sheets/logo_search_bottom_sheet.dart';
import 'package:bankapp/presentation/widgets/forms/counterparty_search_field.dart';
import 'package:bankapp/presentation/widgets/helpers/superellipse_clipper.dart';
import 'package:bankapp/presentation/widgets/lists/counterparty_chips_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget modulaire réutilisable pour la sélection de Counterparty
/// Utilisable dans le bottom sheet et dans un futur écran standalone
class CounterpartySelectionWidget extends ConsumerStatefulWidget {
  final Function(Counterparty?) onCounterpartySelected;
  final Function(BrandLogo?)
  onLogoSelected; // Callback pour la sélection de logo
  final Function(String)? onSearchTextChanged; // Pour récupérer le texte saisi
  final TransactionType? transactionType; // null pour usage standalone
  final Counterparty? initialSelection;
  final BrandLogo?
  initialSelectedLogo; // Logo initialement sélectionné pour persistance
  final String? initialSearchText; // Texte initial pour persistance navigation
  final bool showCreateButton; // Pour écran standalone futur
  final String? customTitle; // Titre personnalisé pour usage standalone

  const CounterpartySelectionWidget({
    super.key,
    required this.onCounterpartySelected,
    required this.onLogoSelected,
    this.onSearchTextChanged,
    this.transactionType,
    this.initialSelection,
    this.initialSelectedLogo,
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
  BrandLogo? _selectedLogo;

  @override
  void initState() {
    super.initState();
    _selectedCounterparty = widget.initialSelection;
    _selectedLogo = widget.initialSelectedLogo;

    // Initialiser searchQuery : soit le nom du counterparty sélectionné, soit le texte initial
    if (_selectedCounterparty != null) {
      _searchQuery = _selectedCounterparty!.name;
    } else if (widget.initialSearchText?.isNotEmpty == true) {
      _searchQuery = widget.initialSearchText!;
      // Effectuer une recherche initiale si on a du texte mais pas de sélection
      _searchResults = CacheManager.instance.searchCounterpartiesByName(
        _searchQuery,
      );
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
          final isExactMatch =
              query.trim().toLowerCase() ==
              _selectedCounterparty!.name.toLowerCase();
          if (!isExactMatch) {
            _selectedCounterparty = null;
            widget.onCounterpartySelected(null);
          }
        }

        // Réinitialiser le logo si l'utilisateur modifie le texte et qu'un counterparty exact est trouvé
        if (exactMatch != null && _selectedLogo != null) {
          _selectedLogo = null;
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
      // Réinitialiser le logo sélectionné quand un counterparty est sélectionné
      _selectedLogo = null;
      // NE PAS vider _searchResults - maintenir la liste visible avec sélection
    });

    // Notifier la sélection (mettra à jour le TextField via didUpdateWidget)
    widget.onCounterpartySelected(counterparty);

    // Notifier que le logo est désélectionné
    widget.onLogoSelected(null);

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

          SizedBox(height: AppConstants.veryLargePadding.h),

          // Widget Orb ou Icône Counterparty
          _buildOrbOrIcon(appTheme),

          SizedBox(height: AppConstants.defaultPadding.h),

          // Champ de recherche transparent
          CounterpartySearchField(
            onQueryChanged: _onSearchQueryChanged,
            onCounterpartySelected: (counterparty) =>
                _onCounterpartyDeselected(),
            selectedCounterparty: _selectedCounterparty,
            isUserTyping: _isUserTyping,
            initialText:
                _searchQuery, // Passer le texte initial pour persistance
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
      // Afficher l'icône du Counterparty dans un Superellipses
      return Container(
        width: 90.r,
        height: 90.r,
        margin: EdgeInsets.symmetric(vertical: 45.h),
        child: ClipPath(
          clipper: SuperellipseClipper(n: 3.1),
          child: Container(
            color: appTheme.background2!.accentuate(context, 0.05),
            child:
                _selectedCounterparty!.icon != null &&
                    _selectedCounterparty!.icon!.isNotEmpty
                ? ImageUtils.buildImageFromPath(
                    _selectedCounterparty!.icon!,
                    width: 90.r,
                    height: 90.r,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildErrorIcon(appTheme);
                    },
                  )
                : _buildPlaceholderIcon(appTheme),
          ),
        ),
      );
    } else if (_selectedLogo != null) {
      // Afficher le logo sélectionné dans un Superellipse (tappable)
      return GestureDetector(
        onTap: () => _openLogoSearchBottomSheet(),
        child: Container(
          width: 90.r,
          height: 90.r,
          margin: EdgeInsets.symmetric(vertical: 45.h),
          child: ClipPath(
            clipper: SuperellipseClipper(n: 3.1),
            child: Container(
              color: appTheme.backgroundInvert,
              child: _selectedLogo!.icon.isNotEmpty
                  ? Image.network(
                      _selectedLogo!.icon,
                      width: 90.r,
                      height: 90.r,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildErrorIcon(appTheme);
                      },
                    )
                  : _buildPlaceholderIcon(appTheme),
            ),
          ),
        ),
      );
    } else {
      // Afficher le widget Orb animé (tappable si aucun counterparty exact trouvé)
      final shouldShowLogoButton =
          _searchQuery.trim().isNotEmpty &&
          CacheManager.instance.findCounterpartyByExactName(_searchQuery) ==
              null;

      return GestureDetector(
        onTap: shouldShowLogoButton ? () => _openLogoSearchBottomSheet() : null,
        child: SizedBox(
          width: 180.r,
          height: 180.r,
          child: Center(child: Image.asset(appTheme.orbAnimation!)),
        ),
      );
    }
  }

  /// Ouvre la BottomSheet de recherche de logos
  void _openLogoSearchBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context),
          child: DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.0,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return LogoSearchBottomSheet(
                initialQuery: _searchQuery,
                currentlySelectedLogo: _selectedLogo,
                onLogoSelected: _onLogoSelected,
              );
            },
          ),
        );
      },
    );
  }

  /// Callback appelé quand un logo est sélectionné ou désélectionné
  void _onLogoSelected(BrandLogo? logo) {
    setState(() {
      _selectedLogo = logo;
      // Si un logo est sélectionné, s'assurer qu'aucun counterparty n'est sélectionné
      if (logo != null) {
        _selectedCounterparty = null;
        widget.onCounterpartySelected(null);
      }
    });

    // Notifier le parent de la sélection de logo
    widget.onLogoSelected(logo);
  }

  Widget _buildErrorIcon(AppColorsExtended appTheme) {
    return Center(
      child: Icon(Icons.error, size: 48.sp, color: appTheme.text4),
    );
  }

  Widget _buildPlaceholderIcon(AppColorsExtended appTheme) {
    return Center(
      child: Icon(
        CupertinoIcons.question_circle_fill,
        size: 48.sp,
        color: appTheme.text4,
      ),
    );
  }
}
