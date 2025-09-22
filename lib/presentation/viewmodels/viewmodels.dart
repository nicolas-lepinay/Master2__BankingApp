// Exports de tous les ViewModels pour faciliter les imports
// Architecture MVVM organisée par catégorie

// ViewModels temporaires restants (à migrer dans les phases suivantes)
// Ces ViewModels seront refactorisés selon la nouvelle architecture :
// ✅ DONE: account_view_model.dart -> features/account_management_view_model.dart + screens/home_screen_view_model.dart
// ✅ DONE: transaction_view_model.dart -> screens/transaction_list_view_model.dart
// ✅ DONE: search_view_model.dart -> screens/search_results_view_model.dart
// - counterparty_view_model.dart -> peut être éliminé ou intégré
// - followed_transaction_view_model.dart -> à intégrer dans transaction screens

export 'base/base_list_view_model.dart';
// Base ViewModels - Classes de base réutilisables
export 'base/base_view_model.dart';
// UI State - États d'interface utilisateur communs
export 'common/ui_state.dart';
export 'counterparty_view_model.dart';
// Feature ViewModels - ViewModels par fonctionnalité spécifique
export 'features/transaction_creation_view_model.dart';
export 'features/transaction_edit_view_model.dart';
export 'features/transaction_deletion_view_model.dart';
export 'features/account_management_view_model.dart';
export 'followed_transaction_view_model.dart';
export 'screens/home_screen_view_model.dart';
export 'screens/search_results_view_model.dart';
export 'screens/transaction_detail_view_model.dart';
// Screen ViewModels - ViewModels par écran spécifique
export 'screens/transaction_list_view_model.dart';
// Shared ViewModels - ViewModels partagés entre plusieurs écrans
export 'shared/app_view_model.dart';
export 'shared/currency_view_model.dart';
export 'shared/logo_search_view_model.dart';
