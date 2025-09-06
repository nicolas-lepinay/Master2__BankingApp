import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/constants/gradient_colors.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/utils/formatters.dart';
import 'package:bankapp/core/utils/image_utils.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/presentation/widgets/helpers/superellipse_clipper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PerspectiveTransactionItem extends StatelessWidget {
  final domain.TransactionWithBalance transactionWithCounterparty;
  final VoidCallback? onTap;

  const PerspectiveTransactionItem({
    super.key,
    required this.transactionWithCounterparty,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final transaction = transactionWithCounterparty.transaction;
    final counterparty = transactionWithCounterparty.counterparty;
    final isExpense = transactionWithCounterparty.isExpense;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppConstants.mediumPadding.r,
          vertical: 4.r,
        ),
        padding: EdgeInsets.symmetric(horizontal: AppConstants.largePadding.r),
        decoration: BoxDecoration(
          color: AppColors.transactionItemBg,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: GradientColors.pink.first.withValues(alpha: 0.35),
              blurRadius: 10.r,
              offset: Offset(0, -8.0.r), // Ombre vers le haut
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icône du tiers/catégorie dans un cercle
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: GradientColors.pink.first.withValues(alpha: 0.35),
                    blurRadius: 6.r,
                    offset: Offset(0, 4.r),
                  ),
                ],
              ),
              child: ClipPath(
                clipper: SuperellipseClipper(n: 2.0),
                child:
                    counterparty?.icon != null && counterparty!.icon!.isNotEmpty
                    ? ImageUtils.buildImageFromPath(
                        counterparty.icon!,
                        width: 38.w,
                        height: 38.w,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderIcon();
                        },
                      )
                    : _buildPlaceholderIcon(),
              ),
            ),

            SizedBox(width: AppConstants.largePadding.r),
            // Informations de la transaction
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nom du tiers ou titre de la transaction
                  Text(
                    _getTransactionDisplayName(transactionWithCounterparty),
                    style: AppTextStyles.transactionNamePerspective,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 2.r),
                  // Date de la transaction
                  Text(
                    AppFormatters.formatDate(
                      transaction.date,
                      context,
                    ).toUpperCase(),
                    style: AppTextStyles.transactionCategoryPerspective,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(width: AppConstants.defaultPadding.r),
            // Montant de la transaction
            Text(
              AppFormatters.formatAmountClean(
                isExpense ? -transaction.amount : transaction.amount,
                transaction.currency,
                showSign: true,
                context: context,
              ),
              style: AppTextStyles.transactionAmountPerspective,
            ),
          ],
        ),
      ),
    );
  }

  /// Récupère le nom à afficher pour la transaction
  String _getTransactionDisplayName(domain.TransactionWithBalance transaction) {
    // Priorité 1: Nom du tiers
    if (transaction.counterparty?.name != null) {
      return transaction.counterparty!.name;
    }

    // Priorité 2: Titre de la transaction
    if (transaction.transaction.title?.isNotEmpty == true) {
      return transaction.transaction.title!;
    }

    // Priorité 3: Type de transaction par défaut
    return transaction.isExpense ? 'Dépense' : 'Revenu';
  }

  /// Widget placeholder quand il n'y a pas d'icône
  Widget _buildPlaceholderIcon() {
    return Icon(
      CupertinoIcons.question_circle_fill,
      color: AppColors.textDark25,
      size: 22.sp,
    );
  }
}
