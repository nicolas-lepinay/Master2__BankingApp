import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/extensions/color_extensions.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/image_utils.dart';
import 'package:bankapp/domain/entities/counterparty.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget affichant la liste des Counterparties sous forme de chips
/// avec wrapping et centrage horizontal
class CounterpartyChipsList extends StatelessWidget {
  final List<Counterparty> counterparties;
  final Function(Counterparty) onCounterpartyTap;
  final Counterparty? selectedCounterparty;

  const CounterpartyChipsList({
    super.key,
    required this.counterparties,
    required this.onCounterpartyTap,
    this.selectedCounterparty,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;

    if (counterparties.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 16.h),
      child: Wrap(
        alignment: WrapAlignment.center, // Centrage horizontal des chips
        spacing: 16.r, // Espacement horizontal entre chips
        runSpacing: 16.r, // Espacement vertical entre lignes
        children: counterparties.map((counterparty) {
          final isSelected = selectedCounterparty?.id == counterparty.id;

          return _buildCounterpartyChip(
            context,
            appTheme,
            counterparty,
            isSelected,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCounterpartyChip(
    BuildContext context,
    AppColorsExtended appTheme,
    Counterparty counterparty,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => onCounterpartyTap(counterparty),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.5, // max width
        ),
        padding: EdgeInsets.only(
          top: 6.r,
          bottom: 6.r,
          left: AppConstants.verySmallPadding.r,
          right: AppConstants.defaultPadding.r,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPink.withValues(alpha: 0.15)
              : appTheme.text6!.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(25.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPink.withValues(alpha: 0.4)
                : appTheme.text6!.withValues(alpha: 0.70),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCounterpartyIcon(context, appTheme, counterparty, isSelected),
            SizedBox(width: AppConstants.smallPadding),
            Flexible(
              child: Text(
                counterparty.name,
                style: AppTextStyles.h5.copyWith(
                  color: isSelected ? AppColors.primaryPink : appTheme.text4,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterpartyIcon(
    BuildContext context,
    AppColorsExtended appTheme,
    Counterparty counterparty,
    bool isSelected,
  ) {
    return Container(
      width: 28.r,
      height: 28.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? AppColors.primaryPink.withValues(alpha: 0.20)
            : appTheme.background2!.accentuate(context, 0.05),
      ),
      child: ClipOval(
        child: counterparty.icon != null && counterparty.icon!.isNotEmpty
            ? ImageUtils.buildImageFromPath(
                counterparty.icon!,
                width: 28.r,
                height: 28.r,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorIcon(appTheme, isSelected);
                },
              )
            : _buildPlaceholderIcon(appTheme, isSelected),
      ),
    );
  }

  Widget _buildPlaceholderIcon(AppColorsExtended appTheme, bool isSelected) {
    return Icon(
      CupertinoIcons.question_circle_fill,
      size: 20.sp,
      color: isSelected ? AppColors.primaryPink : appTheme.text4,
    );
  }

  Widget _buildErrorIcon(AppColorsExtended appTheme, bool isSelected) {
    return Icon(
      Icons.error,
      size: 20.sp,
      color: isSelected ? AppColors.primaryPink : appTheme.text4,
    );
  }
}
