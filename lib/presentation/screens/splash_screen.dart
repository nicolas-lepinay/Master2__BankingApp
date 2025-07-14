import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/presentation/providers/database_provider.dart';
import 'package:bankapp/presentation/screens/main_screen.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialiser la base de données en chargeant les comptes
    await ref.read(accountsProvider.future);

    // Simuler un délai de chargement minimum
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo ou icône de l'app
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppColors.onSurfaceDark,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                Icons.account_balance,
                size: 40.sp,
                color: AppColors.primary,
              ),
            ),

            SizedBox(height: 32.h),

            // Nom de l'app
            Text(
              l10n.appTitle,
              style: AppTextStyles.h2.copyWith(color: AppColors.onSurfaceDark),
            ),

            SizedBox(height: 48.h),

            // Indicateur de chargement
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.onSurfaceDark,
              ),
            ),

            SizedBox(height: 16.h),

            Text(
              l10n.loading,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceDark.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
