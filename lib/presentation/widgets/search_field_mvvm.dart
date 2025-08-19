import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/widgets/helpers/decorated_input_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchFieldMVVM extends ConsumerStatefulWidget {
  final String? hintText;
  final Function(String)? onChanged;
  final TextInputType keyboardType;
  final IconData? iconData;
  final Color? shadowColor;
  final bool isLeftSide;
  final bool showSuggestions;
  final int? accountId; // Pour filtrer les recherches par compte

  const SearchFieldMVVM({
    super.key,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.iconData,
    this.isLeftSide = false,
    this.shadowColor = Colors.transparent,
    this.onChanged,
    this.showSuggestions = true,
    this.accountId,
  });

  @override
  ConsumerState<SearchFieldMVVM> createState() => _SearchFieldMVVMState();
}

class _SearchFieldMVVMState extends ConsumerState<SearchFieldMVVM> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus &&
        _controller.text.isNotEmpty &&
        widget.showSuggestions) {
      _showSuggestionsOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onTextChanged(String query) {
    widget.onChanged?.call(query);

    if (widget.showSuggestions && query.isNotEmpty) {
      // Obtenir les suggestions du SearchViewModel
      final searchViewModel = ref.read(searchViewModelProvider.notifier);
      final suggestions = searchViewModel.getSearchSuggestions(query);

      setState(() {
        _suggestions = suggestions;
      });

      if (_focusNode.hasFocus && suggestions.isNotEmpty) {
        _showSuggestionsOverlay();
      } else {
        _removeOverlay();
      }
    } else {
      _removeOverlay();
    }
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300.w, // Largeur du field
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, 60.h), // Hauteur du field + marge
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              constraints: BoxConstraints(maxHeight: 200.h),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).extension<AppColorsExtended>()!.background1,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: _suggestions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1.h,
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                ),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.search,
                      size: 20.sp,
                      color: AppColors.textSecondary,
                    ),
                    title: Text(suggestion, style: AppTextStyles.bodyMedium),
                    onTap: () {
                      _controller.text = suggestion;
                      widget.onChanged?.call(suggestion);
                      _removeOverlay();
                      _focusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        keyboardType: widget.keyboardType,
        controller: _controller,
        focusNode: _focusNode,
        style: AppTextStyles.bodyLarge.copyWith(
          color: appTheme.text3!,
          fontSize: 18.sp,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText ?? l10n.searchTransactions,
          hintStyle: AppTextStyles.searchPlaceholder.copyWith(
            color: appTheme.text5!.withValues(alpha: 0.7),
          ),
          filled: true,
          fillColor: appTheme.background3,
          enabledBorder: OutlineInputBorder(
            borderRadius: widget.isLeftSide
                ? BorderRadius.only(
                    topLeft: Radius.circular(22.r),
                    bottomLeft: Radius.circular(22.r),
                    topRight: Radius.zero,
                    bottomRight: Radius.zero,
                  )
                : BorderRadius.only(
                    topLeft: Radius.zero,
                    bottomLeft: Radius.zero,
                    topRight: Radius.circular(22.r),
                    bottomRight: Radius.circular(22.r),
                  ),
            borderSide: BorderSide.none,
          ),
          focusedBorder: DecoratedInputBorder(
            child: OutlineInputBorder(
              borderRadius: widget.isLeftSide
                  ? BorderRadius.only(
                      topLeft: Radius.circular(22.r),
                      bottomLeft: Radius.circular(22.r),
                      topRight: Radius.zero,
                      bottomRight: Radius.zero,
                    )
                  : BorderRadius.only(
                      topLeft: Radius.zero,
                      bottomLeft: Radius.zero,
                      topRight: Radius.circular(22.r),
                      bottomRight: Radius.circular(22.r),
                    ),
              borderSide: BorderSide.none,
            ),
            shadow: BoxShadow(
              color: widget.shadowColor ?? Colors.transparent,
              blurRadius: widget.shadowColor != null ? 18.r : 0.r,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppConstants.veryLargePadding.r,
            vertical: AppConstants.mediumPadding.r,
          ),
          prefixIcon: widget.isLeftSide && widget.iconData != null
              ? Padding(
                  padding: EdgeInsets.only(left: AppConstants.mediumPadding.r),
                  child: Icon(
                    widget.iconData,
                    color: appTheme.text5!.withValues(alpha: 0.5),
                    size: 26.sp,
                  ),
                )
              : null,
          suffixIcon: !widget.isLeftSide && widget.iconData != null
              ? Padding(
                  padding: EdgeInsets.only(right: AppConstants.mediumPadding.r),
                  child: Icon(
                    widget.iconData,
                    color: appTheme.text5!.withValues(alpha: 0.5),
                    size: 26.sp,
                  ),
                )
              : _controller.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged?.call('');
                    _removeOverlay();
                  },
                  icon: Icon(
                    Icons.clear,
                    color: appTheme.text5!.withValues(alpha: 0.7),
                    size: 20.sp,
                  ),
                )
              : null,
        ),
        onChanged: _onTextChanged,
        onSubmitted: (value) {
          _removeOverlay();
          _focusNode.unfocus();
        },
      ),
    );
  }
}

/// Widget de recherche avancée avec filtres
class AdvancedSearchFieldMVVM extends ConsumerStatefulWidget {
  final int? accountId;
  final Function(String)? onSearchChanged;
  final Function(Map<String, dynamic>)? onFiltersChanged;

  const AdvancedSearchFieldMVVM({
    super.key,
    this.accountId,
    this.onSearchChanged,
    this.onFiltersChanged,
  });

  @override
  ConsumerState<AdvancedSearchFieldMVVM> createState() =>
      _AdvancedSearchFieldMVVMState();
}

class _AdvancedSearchFieldMVVMState
    extends ConsumerState<AdvancedSearchFieldMVVM> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  // Filtres
  double? _minAmount;
  double? _maxAmount;
  int? _selectedCategoryId;
  int? _selectedCounterpartyId;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final filters = <String, dynamic>{
      'keyword': _searchController.text,
      'minAmount': _minAmount,
      'maxAmount': _maxAmount,
      'categoryId': _selectedCategoryId,
      'counterpartyId': _selectedCounterpartyId,
      'dateRange': _dateRange,
    };

    widget.onFiltersChanged?.call(filters);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _minAmount = null;
      _maxAmount = null;
      _selectedCategoryId = null;
      _selectedCounterpartyId = null;
      _dateRange = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;

    return Column(
      children: [
        // Barre de recherche principale
        Row(
          children: [
            Expanded(
              child: SearchFieldMVVM(
                hintText: l10n.searchTransactions,
                iconData: Icons.search,
                accountId: widget.accountId,
                onChanged: (query) {
                  widget.onSearchChanged?.call(query);
                },
              ),
            ),
            SizedBox(width: 8.w),
            IconButton(
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
              icon: Icon(
                _showFilters ? Icons.filter_list_off : Icons.filter_list,
                color: _showFilters
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),

        // Filtres avancés
        if (_showFilters) ...[
          SizedBox(height: 16.h),
          _buildFiltersSection(context, l10n, appTheme),
        ],
      ],
    );
  }

  Widget _buildFiltersSection(
    BuildContext context,
    AppLocalizations l10n,
    AppColorsExtended appTheme,
  ) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: appTheme.background1,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "l10n.filters",
                style: AppTextStyles.h6.copyWith(color: appTheme.text1),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: Text("l10n.clearAll"),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Filtres de montant
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: "l10n.minAmount",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _minAmount = double.tryParse(value);
                    _applyFilters();
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: "l10n.maxAmount",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _maxAmount = double.tryParse(value);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Sélection de période
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDateRange: _dateRange,
                    );
                    if (picked != null) {
                      setState(() {
                        _dateRange = picked;
                      });
                      _applyFilters();
                    }
                  },
                  icon: Icon(Icons.date_range),
                  label: Text(
                    _dateRange != null
                        ? '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}'
                        : "l10n.selectPeriod",
                  ),
                ),
              ),
              if (_dateRange != null)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _dateRange = null;
                    });
                    _applyFilters();
                  },
                  icon: Icon(Icons.clear),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
