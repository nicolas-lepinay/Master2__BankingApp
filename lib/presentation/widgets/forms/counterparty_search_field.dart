import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/domain/entities/counterparty.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget de champ de recherche pour les Counterparties
/// Style identique au amount_text_field (transparent, sans bordure)
class CounterpartySearchField extends StatefulWidget {
  final Function(String) onQueryChanged;
  final Function(Counterparty?) onCounterpartySelected;
  final String? hintText;
  final Counterparty? selectedCounterparty;
  final bool isUserTyping; // Pour éviter les loops de mise à jour
  final String? initialText; // Texte initial pour persistance

  const CounterpartySearchField({
    super.key,
    required this.onQueryChanged,
    required this.onCounterpartySelected,
    this.hintText,
    this.selectedCounterparty,
    this.isUserTyping = false,
    this.initialText,
  });

  @override
  State<CounterpartySearchField> createState() =>
      _CounterpartySearchFieldState();
}

class _CounterpartySearchFieldState extends State<CounterpartySearchField> {
  late TextEditingController _controller;
  bool _isUserTyping = false;

  @override
  void initState() {
    super.initState();
    // Priorité : counterparty sélectionné > texte initial > vide
    String initialText = '';
    if (widget.selectedCounterparty != null) {
      initialText = widget.selectedCounterparty!.name;
    } else if (widget.initialText?.isNotEmpty == true) {
      initialText = widget.initialText!;
    }

    _controller = TextEditingController(text: initialText);
  }

  @override
  void didUpdateWidget(CounterpartySearchField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si on détecte qu'un counterparty a été sélectionné programmatiquement,
    // réinitialiser le flag pour permettre la mise à jour
    bool counterpartySelectedProgrammatically =
        widget.selectedCounterparty != oldWidget.selectedCounterparty &&
        widget.selectedCounterparty != null;

    if (counterpartySelectedProgrammatically) {
      _isUserTyping = false;
    }

    // Mettre à jour le texte seulement si ce n'est pas l'utilisateur qui tape
    if (!_isUserTyping) {
      // Calculer le nouveau texte selon la priorité
      String newText = '';
      if (widget.selectedCounterparty != null) {
        newText = widget.selectedCounterparty!.name;
      } else if (widget.initialText?.isNotEmpty == true) {
        newText = widget.initialText!;
      }

      // Mettre à jour seulement si le texte a vraiment changé
      if (_controller.text != newText) {
        _controller.value = _controller.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _isUserTyping = true;
    widget.onQueryChanged(value);

    // Simplification : laisser le widget parent gérer la logique d'auto-sélection
    // Le CounterpartySearchField ne fait que transmettre les changements
  }

  void _onEditingComplete() {
    _isUserTyping = false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;

    return IntrinsicWidth(
      child: TextField(
        controller: _controller,
        onChanged: _onTextChanged,
        onEditingComplete: _onEditingComplete,
        textCapitalization: TextCapitalization.words,
        style: TextStyle(
          fontSize: 48.sp,
          fontWeight: FontWeight.w600,
          color: appTheme.text1,
          height: 1.3,
        ),
        decoration: InputDecoration(
          hintText: 'Amazon',
          hintStyle: TextStyle(
            fontSize: 48.sp,
            fontWeight: FontWeight.w600,
            color: appTheme.text6,
            height: 1.3,
          ),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20.sp),
          isDense: true,
          filled: false,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
      ),
    );
  }
}
