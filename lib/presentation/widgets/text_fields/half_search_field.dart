import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/presentation/widgets/helpers/decorated_input_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HalfSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hintText;
  final Function(String)? onChanged;
  final AppColorsExtended appTheme;
  final TextInputType keyboardType;
  final IconData? iconData;
  final Color? shadowColor;
  final bool isLeftSide;

  const HalfSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.appTheme,
    this.keyboardType = TextInputType.text,
    this.iconData,
    this.isLeftSide = false,
    this.shadowColor = Colors.transparent,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      controller: controller,
      focusNode: focusNode,
      style: AppTextStyles.bodyLarge.copyWith(
        color: appTheme.text3!,
        fontSize: 18,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.searchPlaceholder.copyWith(
          color: appTheme.text5!.withValues(alpha: 0.7),
        ),
        filled: true,
        fillColor: appTheme.background3!,
        enabledBorder: OutlineInputBorder(
          borderRadius: isLeftSide
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
            borderRadius: isLeftSide
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
            color: shadowColor ?? Colors.transparent,
            blurRadius: shadowColor != null ? 18.r : 0.r,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.mediumPadding.r,
          vertical: AppConstants.mediumPadding.r,
        ),
        prefixIcon: isLeftSide && iconData != null
            ? Padding(
                padding: EdgeInsets.only(left: AppConstants.smallPadding.r),
                child: Icon(
                  iconData,
                  color: appTheme.text5!.withValues(alpha: 0.5),
                  size: 26.sp,
                ),
              )
            : null,
        suffixIcon: !isLeftSide && iconData != null
            ? Padding(
                padding: EdgeInsets.only(right: AppConstants.smallPadding.r),
                child: Icon(
                  iconData,
                  color: appTheme.text5!.withValues(alpha: 0.5),
                  size: 26.sp,
                ),
              )
            : null,
      ),
      onChanged: onChanged,
    );
  }
}
