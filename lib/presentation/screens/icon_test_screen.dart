import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/icons/icon_entry.dart';
import '../../core/l10n/app_localizations.dart';
import '../providers/viewmodel_providers.dart';
import '../viewmodels/screens/icon_test_view_model.dart';

/// Page de test dédiée pour valider la recherche d'icônes
/// 
/// Cette page permet de tester le système de génération d'icônes
/// en fournissant une interface de recherche complète avec architecture MVVM.
class IconTestScreen extends ConsumerStatefulWidget {
  const IconTestScreen({super.key});

  @override
  ConsumerState<IconTestScreen> createState() => _IconTestScreenState();
}

class _IconTestScreenState extends ConsumerState<IconTestScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Affiche les détails d'une icône dans un SnackBar
  void _showIconDetails(IconEntry icon) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon.iconData,
                  color: Colors.white,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'ID: ${icon.id}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text('Nom: ${icon.name}'),
            Text('Catégorie: ${icon.category}'),
            if (icon.style != null) Text('Style: ${icon.style}'),
            if (icon.keywords.isNotEmpty)
              Text('Mots-clés: ${icon.keywords.take(5).join(', ')}'),
          ],
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final iconTestState = ref.watch(iconTestViewModelProvider);
    final iconTestViewModel = ref.read(iconTestViewModelProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Recherche d\'Icônes'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => iconTestViewModel.refresh(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(l10n, iconTestViewModel),
          _buildStatsSection(iconTestState),
          Expanded(
            child: _buildIconGrid(iconTestState),
          ),
        ],
      ),
    );
  }

  /// Section de recherche avec barre de saisie
  Widget _buildSearchSection(AppLocalizations l10n, IconTestViewModel viewModel) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rechercher des icônes',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _searchController,
            onChanged: (query) => viewModel.searchIcons(query),
            decoration: InputDecoration(
              hintText: 'Ex: heart, cœur, home, business...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        viewModel.clearFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          SizedBox(height: 12.h),
          _buildQuickActions(viewModel),
          SizedBox(height: 8.h),
          Text(
            'Recherche dans: nom, catégorie, mots-clés, tags',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Actions rapides (filtres par catégorie)
  Widget _buildQuickActions(IconTestViewModel viewModel) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Populaires', () => viewModel.clearFilters()),
          SizedBox(width: 8.w),
          _buildFilterChip('Essential', () => viewModel.filterByCategory('essential')),
          SizedBox(width: 8.w),
          _buildFilterChip('Business', () => viewModel.filterByCategory('business')),
          SizedBox(width: 8.w),
          _buildFilterChip('Navigation', () => viewModel.filterByCategory('navigation')),
          SizedBox(width: 8.w),
          _buildFilterChip('Communication', () => viewModel.filterByCategory('communication')),
        ],
      ),
    );
  }

  /// Chip de filtre
  Widget _buildFilterChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(fontSize: 12.sp),
      ),
      onPressed: onTap,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
    );
  }

  /// Section des statistiques de recherche
  Widget _buildStatsSection(IconTestViewState state) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Icon(
            _getDisplayTypeIcon(state.displayType),
            size: 16.sp,
            color: _getDisplayTypeColor(state.displayType),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              state.statusMessage,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDisplayTypeIcon(IconDisplayType type) {
    switch (type) {
      case IconDisplayType.popular:
        return Icons.star;
      case IconDisplayType.search:
        return Icons.search;
      case IconDisplayType.category:
        return Icons.category;
      case IconDisplayType.set:
        return Icons.collections;
    }
  }

  Color _getDisplayTypeColor(IconDisplayType type) {
    switch (type) {
      case IconDisplayType.popular:
        return Colors.amber;
      case IconDisplayType.search:
        return Colors.blue;
      case IconDisplayType.category:
        return Colors.green;
      case IconDisplayType.set:
        return Colors.purple;
    }
  }

  /// Grille d'icônes avec état de chargement
  Widget _buildIconGrid(IconTestViewState state) {
    if (state.isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!state.hasIcons) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              state.searchQuery.isEmpty 
                  ? 'Tapez pour rechercher des icônes'
                  : 'Aucune icône trouvée',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => ref.read(iconTestViewModelProvider.notifier).clearFilters(),
              child: const Text('Voir les icônes populaires'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        childAspectRatio: 1,
      ),
      itemCount: state.iconCount,
      itemBuilder: (context, index) {
        final icon = state.icons[index];
        return _buildIconTile(icon);
      },
    );
  }

  /// Tuile individuelle pour une icône
  Widget _buildIconTile(IconEntry icon) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: () => _showIconDetails(icon),
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon.iconData,
                size: 24.sp,
                color: Colors.grey.shade700,
              ),
              SizedBox(height: 4.h),
              Text(
                icon.name,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}