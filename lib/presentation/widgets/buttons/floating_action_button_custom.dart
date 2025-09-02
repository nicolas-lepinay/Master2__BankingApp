import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FloatingActionButtonCustom extends StatelessWidget {
  final String text;
  final String? iconPath;
  final IconData? iconData;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final double margin;

  const FloatingActionButtonCustom({
    super.key,
    required this.text,
    this.iconPath,
    this.iconData,
    this.onPressed,
    this.isEnabled = true,
    this.margin = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;

    return Container(
      margin: EdgeInsets.all(margin),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text),
            if (iconPath != null)
              SvgPicture.asset(
                iconPath!,
                colorFilter: ColorFilter.mode(
                  isEnabled
                      ? appTheme.buttonForeground1!
                      : appTheme.buttonForegroundDisabled!,
                  BlendMode.srcIn,
                ),
                width: 32.sp,
                height: 32.sp,
              )
            else if (iconData != null)
              Icon(iconData, size: 32.sp),
          ],
        ),
      ),
    );
  }
}
