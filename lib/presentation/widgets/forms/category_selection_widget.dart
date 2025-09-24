import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/domain/entities/category.dart' as domain;
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/viewmodels/features/category_selection_view_model.dart';
import 'package:bankapp/presentation/widgets/bottom_sheets/category_creation_bottom_sheet.dart';
import 'package:bankapp/presentation/widgets/buttons/dashed_button.dart';
import 'package:bankapp/presentation/widgets/lists/category_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Callback pour la sélection d'une catégorie
typedef OnCategorySelected = void Function(domain.Category? category);

/// Widget réutilisable pour la sélection hiérarchique de catégories
///
/// Fonctionnalités :
/// - Navigation hiérarchique avec AnimatedSwitcher
/// - Sélection par tap (toggle)
/// - Navigation par double-tap ou chevron
/// - Création de nouvelles catégories
/// - Architecture MVVM avec Event Bus
/// - Complètement réutilisable
class CategorySelectionWidget extends ConsumerStatefulWidget {
  final String? title;
  final domain.Category? initialSelection;
  final OnCategorySelected? onCategorySelected;
  final bool showTitle;
  final bool showSearchBar;
  final double? height;

  const CategorySelectionWidget({
    super.key,
    this.title,
    this.initialSelection,
    this.onCategorySelected,
    this.showTitle = true,
    this.showSearchBar = true,
    this.height,
  });

  @override
  ConsumerState<CategorySelectionWidget> createState() =>
      _CategorySelectionWidgetState();
}

class _CategorySelectionWidgetState
    extends ConsumerState<CategorySelectionWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isNavigatingForward = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeEventListeners();
    _loadInitialData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  /// Initialise les écouteurs d'événements
  void _initializeEventListeners() {
    // Écouter les événements de sélection de catégories si nécessaire
    // Pour l'instant, pas d'événement spécifique à écouter dans ce widget
    // La réactivité est gérée via le Provider categorySelectionViewModelProvider
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = ref.read(categorySelectionViewModelProvider.notifier);
      viewModel.loadCategories();

      // Sélectionner la catégorie initiale si fournie
      if (widget.initialSelection != null) {
        viewModel.toggleCategorySelection(widget.initialSelection!);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;
    final l10n = AppLocalizations.of(context)!;
    final viewState = ref.watch(categorySelectionViewModelProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        height: widget.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppConstants.veryLargePadding.h),

            // Titre statique "Rubrique" (toujours affiché si showTitle)
            if (widget.showTitle) ...[
              _buildTitle(l10n, appTheme),
              SizedBox(height: AppConstants.largePadding.h * 2),
            ],

            // Barre de recherche avec nouveau style (toujours sous "Rubrique")
            if (widget.showSearchBar) ...[
              _buildSearchBar(l10n, appTheme),
              SizedBox(height: AppConstants.largePadding.h * 2),
            ],

            // Titre de navigation avec flèche back (mode subcategoryDetail uniquement)
            _buildNavigationTitle(l10n, appTheme, viewState),
            if (viewState.isSubcategoryDetail) SizedBox(height: 16.h),

            // Contenu principal avec gestion des états et AnimatedSwitcher
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                transitionBuilder: (child, animation) {
                  // Animation slide selon la direction de navigation
                  final offset = _isNavigatingForward
                      ? Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        )
                      : Tween<Offset>(
                          begin: const Offset(-1.0, 0.0),
                          end: Offset.zero,
                        );

                  return SlideTransition(
                    position: offset.animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: child,
                  );
                },
                child: Container(
                  key: ValueKey(
                    '${viewState.displayMode}_${viewState.currentLevel}_${viewState.currentParent?.id}',
                  ),
                  child: _buildContent(viewState, l10n, appTheme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit le titre statique centré "Rubrique"
  Widget _buildTitle(AppLocalizations l10n, AppColorsExtended appTheme) {
    return Center(
      child: Text(
        l10n.category, // "Rubrique" - statique, pas de navigation
        style: AppTextStyles.h1.copyWith(
          color: appTheme.text2,
          fontFamily: AppTextStyles.playfairFontFamily,
          fontSize: 36.sp,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  /// Construit le titre de navigation avec flèche back (mode subcategoryDetail)
  Widget _buildNavigationTitle(
    AppLocalizations l10n,
    AppColorsExtended appTheme,
    CategorySelectionViewState viewState,
  ) {
    if (!viewState.isSubcategoryDetail || viewState.currentParent == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _navigateBack,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.arrow_back, size: 28.sp, color: appTheme.text2),
          SizedBox(width: AppConstants.defaultPadding.w),
          Expanded(
            child: Text(
              viewState.currentParent!.getDisplayName(l10n),
              style: AppTextStyles.h2.copyWith(
                color: appTheme.text2,
                fontFamily: AppTextStyles.playfairFontFamily,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la barre de recherche (style LogoSearchBottomSheet)
  Widget _buildSearchBar(AppLocalizations l10n, AppColorsExtended appTheme) {
    return Center(
      child: Container(
        //width: MediaQuery.sizeOf(context).width * 0.55,
        decoration: BoxDecoration(
          color: appTheme.text5?.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(100.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                //enabled: false, // Désactivé pour l'instant
                style: AppTextStyles.bodyVeryLarge.copyWith(
                  color: appTheme.text2,
                ),
                decoration: InputDecoration(
                  hintText: l10n.searchCategory,
                  hintStyle: TextStyle(
                    fontSize: 18.sp,
                    color: appTheme.text4!.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.only(
                    left: AppConstants.veryLargePadding.w,
                  ),
                ),
              ),
            ),
            // Icône de recherche
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10.r, vertical: 8.r),
              child: Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: appTheme.background2!,
                  borderRadius: BorderRadius.circular(100.r),
                ),
                child: Icon(
                  CupertinoIcons.search,
                  color: appTheme.text1,
                  size: 24.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit le contenu principal avec gestion des états
  Widget _buildContent(
    CategorySelectionViewState viewState,
    AppLocalizations l10n,
    AppColorsExtended appTheme,
  ) {
    if (viewState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              '${l10n.error}: ${viewState.error}',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(categorySelectionViewModelProvider.notifier)
                    .loadCategories();
              },
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    // Affichage selon le mode
    if (viewState.isRootOverview) {
      return _buildRootOverview(viewState, l10n, appTheme);
    } else {
      return _buildSubcategoryDetail(viewState, l10n, appTheme);
    }
  }

  /// Construit la vue d'ensemble (niveau 1+2 simultanés)
  Widget _buildRootOverview(
    CategorySelectionViewState viewState,
    AppLocalizations l10n,
    AppColorsExtended appTheme,
  ) {
    if (viewState.categoryGroups.isEmpty) {
      return _buildEmptyState(l10n, appTheme);
    }

    return ListView(
      padding: EdgeInsets.only(bottom: 150.h),
      children: [
        // Construire chaque groupe de catégories
        ...viewState.categoryGroups.expand(
          (group) => [
            // Titre de section (niveau 1) - non cliquable
            _buildSectionTitle(group.parentCategory, l10n, appTheme),
            SizedBox(height: 16.h),

            // Sous-catégories niveau 2
            ...group.subcategories.map(
              (subcategory) =>
                  _buildSubcategoryItem(subcategory, viewState, l10n),
            ),

            // Bouton "Ajouter une rubrique" pour ce groupe
            SizedBox(height: 16.h),
            _buildAddCategoryButton(group.parentCategory, l10n, appTheme),
            SizedBox(height: 32.h), // Espace entre groupes
          ],
        ),

        SizedBox(height: 80.h), // Espace final
      ],
    );
  }

  /// Construit le titre de section pour les catégories niveau 1
  Widget _buildSectionTitle(
    domain.Category parentCategory,
    AppLocalizations l10n,
    AppColorsExtended appTheme,
  ) {
    return Text(
      parentCategory.getDisplayName(l10n),
      style: AppTextStyles.h2.copyWith(
        color: appTheme.text2,
        fontFamily: AppTextStyles.playfairFontFamily,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Construit un item de sous-catégorie niveau 2
  Widget _buildSubcategoryItem(
    domain.Category subcategory,
    CategorySelectionViewState viewState,
    AppLocalizations l10n,
  ) {
    final isSelected = viewState.selectedCategory?.id == subcategory.id;

    return CategoryListItem.root(
      category: subcategory,
      isSelected: isSelected,
      hasSubcategories: true, // Toujours true selon nouvelles specs
      onTap: () => _onCategoryTap(subcategory),
      onDoubleTap: () => _onCategoryDoubleTap(subcategory),
      onChevronTap: () => _onCategoryDoubleTap(subcategory),
    );
  }

  /// Construit la vue détail d'une sous-catégorie (niveau 3+)
  Widget _buildSubcategoryDetail(
    CategorySelectionViewState viewState,
    AppLocalizations l10n,
    AppColorsExtended appTheme,
  ) {
    return ListView(
      padding: EdgeInsets.only(bottom: 150.h),
      children: [
        // Liste des catégories niveau 3+
        ...viewState.currentLevelCategories.map(
          (category) => _buildDetailCategoryItem(category, viewState, l10n),
        ),

        // Bouton d'ajout de catégorie
        SizedBox(height: 16.h),
        _buildAddCategoryButton(viewState.currentParent, l10n, appTheme),
        SizedBox(height: 80.h),
      ],
    );
  }

  /// Construit un item de catégorie en mode détail (niveau 3+)
  Widget _buildDetailCategoryItem(
    domain.Category category,
    CategorySelectionViewState viewState,
    AppLocalizations l10n,
  ) {
    final viewModel = ref.read(categorySelectionViewModelProvider.notifier);
    final isSelected = viewState.selectedCategory?.id == category.id;
    final breadcrumbs = viewModel.getCurrentBreadcrumbs();

    return CategoryListItem.subcategory(
      category: category,
      breadcrumbs: breadcrumbs,
      isSelected: isSelected,
      hasSubcategories: true, // Toujours true selon nouvelles specs
      onTap: () => _onCategoryTap(category),
      onDoubleTap: () => _onCategoryDoubleTap(category),
      onChevronTap: () => _onCategoryDoubleTap(category),
    );
  }

  /// Construit l'état vide
  Widget _buildEmptyState(AppLocalizations l10n, AppColorsExtended appTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 64.sp, color: appTheme.text3),
          SizedBox(height: 16.h),
          Text(
            'Aucune catégorie trouvée',
            style: AppTextStyles.bodyMedium.copyWith(color: appTheme.text3),
          ),
        ],
      ),
    );
  }

  /// Construit le bouton d'ajout de catégorie
  Widget _buildAddCategoryButton(
    domain.Category? parentCategory,
    AppLocalizations l10n,
    AppColorsExtended appTheme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding.w),
      child: DashedButton(
        text: l10n.addCategory,
        icon: Icons.add,
        dashColor: appTheme.text5!.withValues(alpha: 0.80),
        textStyle: AppTextStyles.buttonTextMedium,
        verticalPadding: AppConstants.defaultPadding,
        onTap: () => _showCreateCategoryBottomSheet(parentCategory, l10n),
      ),
    );
  }

  /// Gère le tap simple (sélection/désélection)
  void _onCategoryTap(domain.Category category) {
    final viewModel = ref.read(categorySelectionViewModelProvider.notifier);
    viewModel.toggleCategorySelection(category);

    // Notifier le parent du changement de sélection
    final newSelection = ref
        .read(categorySelectionViewModelProvider)
        .selectedCategory;
    widget.onCategorySelected?.call(newSelection);
  }

  /// Gère le double-tap (navigation vers sous-catégories)
  void _onCategoryDoubleTap(domain.Category category) {
    _isNavigatingForward = true; // Navigation vers l'avant
    final viewModel = ref.read(categorySelectionViewModelProvider.notifier);
    viewModel.navigateToSubcategories(category);
  }

  /// Navigation retour
  void _navigateBack() {
    _isNavigatingForward = false; // Navigation vers l'arrière
    final viewModel = ref.read(categorySelectionViewModelProvider.notifier);
    viewModel.navigateBack();
  }

  /// Affiche la bottom sheet de création de catégorie
  void _showCreateCategoryBottomSheet(
    domain.Category? parentCategory,
    AppLocalizations l10n,
  ) {
    final viewModel = ref.read(categorySelectionViewModelProvider.notifier);
    final viewState = ref.read(categorySelectionViewModelProvider);

    // Construire les breadcrumbs SANS inclure la catégorie parent elle-même
    List<domain.Category> breadcrumbs = [];

    if (parentCategory != null) {
      if (viewState.isRootOverview) {
        // En mode overview : pas de breadcrumbs pour niveau 2
        breadcrumbs = [];
      } else {
        // En mode detail : breadcrumbs = ancêtres du parent actuel (sans le parent)
        breadcrumbs = viewModel
            .getCurrentBreadcrumbs()
            .where((cat) => cat.id != parentCategory.id)
            .toList();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryCreationBottomSheet(
        parentBreadcrumbs: breadcrumbs,
        parentCategory: parentCategory,
      ),
    );
  }
}
