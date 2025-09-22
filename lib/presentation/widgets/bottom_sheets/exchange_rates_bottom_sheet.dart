import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/constants/supported_currencies.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/viewmodels/shared/currency_view_model.dart';
import 'package:bankapp/presentation/widgets/helpers/superellipse_clipper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExchangeRatesBottomSheet extends ConsumerStatefulWidget {
  final String baseCurrency;
  final String selectedCurrency;
  final Function(String) onCurrencySelected;

  const ExchangeRatesBottomSheet({
    super.key,
    required this.baseCurrency,
    required this.selectedCurrency,
    required this.onCurrencySelected,
  });

  @override
  ConsumerState<ExchangeRatesBottomSheet> createState() =>
      _ExchangeRatesBottomSheetState();
}

class _ExchangeRatesBottomSheetState
    extends ConsumerState<ExchangeRatesBottomSheet> {
  @override
  void initState() {
    super.initState();
    // Charger les taux de change si pas déjà fait
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(currencyViewModelProvider.notifier)
          .updateExchangeRates(widget.baseCurrency);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;
    final l10n = AppLocalizations.of(context)!;
    final currencyState = ref.watch(currencyViewModelProvider);

    return Container(
      decoration: BoxDecoration(
        color: appTheme.backgroundInvert,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardBorderRadius.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: AppConstants.defaultPadding.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: appTheme.text5?.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          SizedBox(height: AppConstants.defaultPadding.h),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding.w,
            ),
            child: Text(
              l10n.otherCurrencies,
              style: AppTextStyles.sectionHeader.copyWith(
                color: appTheme.textInvert,
              ),
            ),
          ),

          SizedBox(height: AppConstants.largePadding.h),

          // Option pour revenir à la devise du compte
          if (widget.selectedCurrency != widget.baseCurrency)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding.w,
              ),
              child: _buildCurrencyItem(
                currencyCode: widget.baseCurrency,
                isAccountCurrency: true,
                exchangeRate: 1.0,
                appTheme: appTheme,
                l10n: l10n,
              ),
            ),

          // Liste des devises disponibles
          Flexible(
            child: currencyState.isConversionLoading
                ? _buildLoadingState(appTheme, l10n)
                : currencyState.conversionError != null
                ? _buildErrorState(
                    appTheme,
                    l10n,
                    currencyState.conversionError!,
                  )
                : _buildCurrencyList(appTheme, l10n, currencyState),
          ),

          SizedBox(height: AppConstants.veryLargePadding.h),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppColorsExtended appTheme, AppLocalizations l10n) {
    return Container(
      height: 200.h,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: appTheme.text6, strokeWidth: 2.w),
          SizedBox(height: AppConstants.defaultPadding.h),
          Text(
            l10n.loadingRates,
            style: TextStyle(fontSize: 14.sp, color: appTheme.text5),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    AppColorsExtended appTheme,
    AppLocalizations l10n,
    String error,
  ) {
    return Container(
      //height: 200.h,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: appTheme.text6, size: 32.sp),
          SizedBox(height: AppConstants.veryLargePadding.h),
          Text(
            l10n.connectionError,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: appTheme.textInvert,
            ),
          ),
          SizedBox(height: AppConstants.smallPadding.h),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: appTheme.text4),
          ),
          SizedBox(height: AppConstants.largePadding.h * 2),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(currencyViewModelProvider.notifier)
                  .updateExchangeRates(widget.baseCurrency);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: appTheme.background1,
              foregroundColor: appTheme.text1,
            ),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyList(
    AppColorsExtended appTheme,
    AppLocalizations l10n,
    CurrencyViewState currencyState,
  ) {
    // Obtenir la liste des devises supportées (exclure la devise de base)
    final availableCurrencies = SupportedCurrencies.all
        .where((currency) => currency.code != widget.baseCurrency)
        .toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(), //
      padding: EdgeInsets.only(
        left: AppConstants.defaultPadding.w,
        right: AppConstants.defaultPadding.w,
        bottom: AppConstants.veryLargePadding.h,
      ),
      itemCount: availableCurrencies.length,
      itemBuilder: (context, index) {
        final currency = availableCurrencies[index];
        final exchangeRate = _getExchangeRate(
          currencyState.exchangeRates,
          widget.baseCurrency,
          currency.code,
        );

        return _buildCurrencyItem(
          currencyCode: currency.code,
          isAccountCurrency: false,
          exchangeRate: exchangeRate,
          appTheme: appTheme,
          l10n: l10n,
        );
      },
    );
  }

  Widget _buildCurrencyItem({
    required String currencyCode,
    required bool isAccountCurrency,
    required double exchangeRate,
    required AppColorsExtended appTheme,
    required AppLocalizations l10n,
  }) {
    final currency = SupportedCurrencies.all.firstWhere(
      (c) => c.code == currencyCode,
      orElse: () => SupportedCurrencies.eur,
    );

    final isSelected = currencyCode == widget.selectedCurrency;

    return InkWell(
      onTap: () {
        widget.onCurrencySelected(currencyCode);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding.w,
          vertical: AppConstants.defaultPadding.h,
        ),
        margin: EdgeInsets.only(bottom: AppConstants.smallPadding.h),
        child: Row(
          children: [
            // Symbole de devise dans un squircle
            ClipPath(
              clipper: SuperellipseClipper(n: 2.9),
              child: Container(
                width: 52.r,
                height: 52.r,
                decoration: BoxDecoration(
                  color: appTheme.text2!.withValues(alpha: 0.11),
                  //borderRadius: BorderRadius.circular(16.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  currency.symbol,
                  style: AppTextStyles.h6.copyWith(
                    fontSize: currency.symbol.length < 3 ? 22.sp : 16.sp,
                    color: appTheme.textInvert,
                  ),
                ),
              ),
            ),

            SizedBox(width: AppConstants.largePadding.w),

            // Informations devise
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom de la devise
                  Text(
                    currency.getDisplayName(l10n).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w400,
                      color: appTheme.textInvert,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  // Taux de change
                  Text(
                    isAccountCurrency
                        ? l10n.accountCurrency.toUpperCase()
                        : '1 ${widget.baseCurrency} = ${AppFormatters.formatAmount(exchangeRate, currencyCode, showSign: false, context: context)}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: appTheme.text4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: AppConstants.largePadding.w),

            // Indicateur de sélection
            Container(
              width: 20.w,
              height: 20.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: appTheme.text4!, width: 2.w),
                color: isSelected ? appTheme.text4! : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  double _getExchangeRate(
    Map<String, domain.ExchangeRate> exchangeRates,
    String baseCurrency,
    String targetCurrency,
  ) {
    if (baseCurrency == targetCurrency) return 1.0;

    final rateKey = '${baseCurrency}_$targetCurrency';
    final exchangeRate = exchangeRates[rateKey];

    if (exchangeRate != null) {
      return exchangeRate.rate;
    }

    // Si pas de taux direct, essayer l'inverse
    final inverseRateKey = '${targetCurrency}_$baseCurrency';
    final inverseExchangeRate = exchangeRates[inverseRateKey];

    if (inverseExchangeRate != null && inverseExchangeRate.rate != 0) {
      return 1.0 / inverseExchangeRate.rate;
    }

    return 1.0; // Fallback
  }
}
