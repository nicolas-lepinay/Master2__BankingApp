import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/domain/entities/category.dart' as domain;
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/widgets/miscellaneous/category_breadcrumbs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Bottom Sheet pour créer une nouvelle catégorie
///
/// Design conforme aux maquettes avec :
/// - Titre "Nouvelle rubrique"
/// - Breadcrumbs complets (multiligne)
/// - TextField pour saisie du nom
/// - Validation avec contraintes unicité
/// - Architecture MVVM avec Event Bus
class CategoryCreationBottomSheet extends ConsumerStatefulWidget {
  final List<domain.Category> parentBreadcrumbs;
  final domain.Category? parentCategory;

  const CategoryCreationBottomSheet({
    super.key,
    required this.parentBreadcrumbs,
    this.parentCategory,
  });

  @override
  ConsumerState<CategoryCreationBottomSheet> createState() =>
      _CategoryCreationBottomSheetState();
}

class _CategoryCreationBottomSheetState
    extends ConsumerState<CategoryCreationBottomSheet> {
  late TextEditingController _nameController;
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _initializeCreation();
  }

  void _initializeCreation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = ref.read(categoryCreationViewModelProvider.notifier);
      viewModel.initializeCreation(
        parentBreadcrumbs: widget.parentBreadcrumbs,
        parentCategory: widget.parentCategory,
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      minChildSize: 0.0,
      maxChildSize: 0.9,
      initialChildSize: 0.6,
      expand: false,
      builder: (context, scrollController) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            decoration: BoxDecoration(
              color: appTheme.background2,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: EdgeInsets.only(top: 8.h),
                  height: 4.h,
                  width: 40.w,
                  decoration: BoxDecoration(
                    color: appTheme.text2,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),

                SizedBox(height: 24.h),

                // Contenu principal
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre
                        _buildTitle(l10n, appTheme),

                        SizedBox(height: 24.h),

                        // Breadcrumbs complets
                        _buildBreadcrumbs(l10n, appTheme),

                        SizedBox(height: 32.h),

                        // Champ de saisie du nom
                        _buildNameField(l10n, appTheme),

                        SizedBox(height: 32.h),

                        // Messages d'erreur/validation
                        _buildValidationMessages(appTheme),

                        SizedBox(height: 120.h), // Espace pour clavier
                      ],
                    ),
                  ),
                ),

                // Bouton de validation
                _buildValidationButton(l10n, appTheme),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construit le titre
  Widget _buildTitle(AppLocalizations l10n, AppColorsExtended appTheme) {
    return Text(
      l10n.newCategory, // TODO: Clé l10n à ajouter
      style: AppTextStyles.sectionHeader.copyWith(
        color: appTheme.text1,
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Construit les breadcrumbs complets
  Widget _buildBreadcrumbs(AppLocalizations l10n, AppColorsExtended appTheme) {
    final viewModel = ref.read(categoryCreationViewModelProvider.notifier);
    final fullBreadcrumbs = viewModel.getFullBreadcrumbs();

    if (fullBreadcrumbs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie parent', // TODO: Clé l10n à ajouter
          style: AppTextStyles.bodyMedium.copyWith(
            color: appTheme.text2,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: appTheme.buttonBackgroundDisabled!.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: appTheme.text5!.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: CategoryBreadcrumbs(
            breadcrumbs: fullBreadcrumbs,
            mode: CategoryBreadcrumbsMode.full, // Mode multiligne
            textStyle: AppTextStyles.bodyMedium.copyWith(
              color: appTheme.text2,
            ),
          ),
        ),
      ],
    );
  }

  /// Construit le champ de saisie du nom
  Widget _buildNameField(AppLocalizations l10n, AppColorsExtended appTheme) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nom de la catégorie', // TODO: Clé l10n à ajouter
          style: AppTextStyles.bodyMedium.copyWith(
            color: appTheme.text1,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          onChanged: (value) {
            ref
                .read(categoryCreationViewModelProvider.notifier)
                .updateCategoryName(value);
          },
          decoration: InputDecoration(
            hintText: 'Ex: Restaurants, Loisirs, etc.',
            hintStyle: TextStyle(
              color: appTheme.text3,
              fontSize: 16.sp,
            ),
            filled: true,
            fillColor: appTheme.buttonBackgroundDisabled!.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: appTheme.text5!.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: appTheme.text5!.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: appTheme.buttonBackground1!,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
          style: TextStyle(
            fontSize: 16.sp,
            color: appTheme.text1,
          ),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  /// Construit les messages de validation
  Widget _buildValidationMessages(AppColorsExtended appTheme) {
    final viewState = ref.watch(categoryCreationViewModelProvider);

    if (viewState.nameError == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              viewState.nameError!,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit le bouton de validation
  Widget _buildValidationButton(AppLocalizations l10n, AppColorsExtended appTheme) {
    final viewState = ref.watch(categoryCreationViewModelProvider);

    return Container(
      padding: EdgeInsets.all(20.r),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: viewState.canCreate ? _createCategory : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: appTheme.buttonBackground1,
            disabledBackgroundColor: appTheme.buttonBackgroundDisabled,
            elevation: 0,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: viewState.isCreating
              ? SizedBox(
                  height: 20.h,
                  width: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: appTheme.textInvert,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_alt,
                      color: viewState.canCreate ? appTheme.textInvert : appTheme.text4,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Créer la catégorie', // TODO: Clé l10n à ajouter
                      style: AppTextStyles.buttonTextLarge.copyWith(
                        color: viewState.canCreate ? appTheme.textInvert : appTheme.text4,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Crée la nouvelle catégorie
  Future<void> _createCategory() async {
    final viewModel = ref.read(categoryCreationViewModelProvider.notifier);
    final success = await viewModel.createCategory();

    if (success && mounted) {
      // Fermer la bottom sheet
      Navigator.of(context).pop();

      // TODO: Optionnel - Afficher un snackbar de succès
      /*
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Catégorie créée avec succès'),
          backgroundColor: appTheme.success,
        ),
      );
      */
    }
    // Si échec, les erreurs sont gérées dans le ViewModel et affichées automatiquement
  }
}