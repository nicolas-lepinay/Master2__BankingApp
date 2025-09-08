import 'package:bankapp/core/extensions/string_extensions.dart';
import 'package:bankapp/domain/entities/entities.dart';
import 'package:bankapp/domain/repositories/counterparty_repository.dart';
import 'package:bankapp/domain/repositories/image_download_repository.dart';
import 'package:bankapp/domain/repositories/transaction_repository.dart';
import 'package:bankapp/presentation/providers/viewmodel_providers.dart';
import 'package:bankapp/presentation/viewmodels/base/base_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// États de création de transaction
enum TransactionCreationStep {
  idle,
  creatingCounterparty,
  downloadingLogo,
  creatingTransaction,
  completed,
}

/// État pour la création de transaction
class TransactionCreationViewState extends BaseViewState {
  final TransactionCreationStep currentStep;
  final bool isCreatingTransaction;
  final bool isCreatingCounterparty;
  final bool isDownloadingLogo;
  final Transaction? createdTransaction;
  final String? error;

  const TransactionCreationViewState({
    this.currentStep = TransactionCreationStep.idle,
    this.isCreatingTransaction = false,
    this.isCreatingCounterparty = false,
    this.isDownloadingLogo = false,
    this.createdTransaction,
    this.error,
  });

  TransactionCreationViewState copyWith({
    TransactionCreationStep? currentStep,
    bool? isCreatingTransaction,
    bool? isCreatingCounterparty,
    bool? isDownloadingLogo,
    Transaction? createdTransaction,
    String? error,
  }) {
    return TransactionCreationViewState(
      currentStep: currentStep ?? this.currentStep,
      isCreatingTransaction:
          isCreatingTransaction ?? this.isCreatingTransaction,
      isCreatingCounterparty:
          isCreatingCounterparty ?? this.isCreatingCounterparty,
      isDownloadingLogo: isDownloadingLogo ?? this.isDownloadingLogo,
      createdTransaction: createdTransaction ?? this.createdTransaction,
      error: error ?? this.error,
    );
  }

  bool get isLoading =>
      currentStep != TransactionCreationStep.idle &&
      currentStep != TransactionCreationStep.completed;

  @override
  String toString() =>
      'TransactionCreationViewState(step: $currentStep, isLoading: $isLoading, error: $error)';
}

/// ViewModel pour la création de transactions avec orchestration complète
///
/// Ce ViewModel préserve intégralement la logique de _validateTransaction
/// tout en respectant l'architecture MVVM
class TransactionCreationViewModel
    extends BaseViewModel<TransactionCreationViewState> {
  final TransactionRepository _transactionRepository;
  final CounterpartyRepository _counterpartyRepository;
  final ImageDownloadRepository _imageDownloadRepository;
  final WidgetRef? _ref;

  TransactionCreationViewModel(
    this._transactionRepository,
    this._counterpartyRepository,
    this._imageDownloadRepository,
    this._ref,
  ) : super(const TransactionCreationViewState());

  /// Orchestrateur principal : reproduit fidèlement la logique de _validateTransaction
  ///
  /// Cette méthode préserve INTÉGRALEMENT la logique existante, notamment :
  /// - La gestion des conversions de devises (amountBeforeConversion, currencyBeforeConversion)
  /// - La création conditionnelle de Counterparty (avec/sans logo)
  /// - Tous les paramètres de transaction existants
  Future<Transaction?> createTransactionWithCounterparty({
    required int accountId,
    required TransactionType type,
    required double amount,
    required String currency,
    required DateTime date,
    required String? title,
    required String? comment,
    required int? selectedCounterpartyId,
    required String? counterpartySearchText,
    required BrandLogo? selectedLogo,
    required List<int> categoryIds,
    required TransactionStatus status,
    required double? amountBeforeConversion,
    required String? currencyBeforeConversion,
  }) async {
    try {
      // Reproduire exactement la logique de _validateTransaction

      int? finalCounterpartyId = selectedCounterpartyId;

      // Gérer la création de Counterparty avec ou sans logo (logique préservée)
      if (selectedCounterpartyId == null) {
        // Cas 1: Logo sélectionné (créer counterparty avec logo téléchargé)
        if (selectedLogo != null &&
            counterpartySearchText != null &&
            counterpartySearchText.trim().isNotEmpty) {
          state = state.copyWith(
            currentStep: TransactionCreationStep.creatingCounterparty,
            isCreatingCounterparty: true,
          );

          finalCounterpartyId = await _createCounterpartyWithLogo(
            selectedLogo,
            counterpartySearchText,
            accountId, // 🆕 Passer accountId pour rechargement après logo
          );
        }
        // Cas 2: Texte saisi mais pas de logo (créer counterparty simple)
        else if (counterpartySearchText != null &&
            counterpartySearchText.trim().isNotEmpty) {
          state = state.copyWith(
            currentStep: TransactionCreationStep.creatingCounterparty,
            isCreatingCounterparty: true,
          );

          finalCounterpartyId = await _createCounterpartyFromText(
            counterpartySearchText,
          );
        }
      }

      // Créer la transaction (logique exactement préservée)
      state = state.copyWith(
        currentStep: TransactionCreationStep.creatingTransaction,
        isCreatingTransaction: true,
        isCreatingCounterparty: false,
      );

      // 🔥 CRÉATION TRANSACTION : Structure identique au TransactionViewModel existant
      final newTransaction = Transaction(
        id: 0, // Sera assigné par la DB
        accountId: accountId,
        counterpartyId: finalCounterpartyId,
        category1Id: categoryIds.isNotEmpty ? categoryIds[0] : null,
        category2Id: categoryIds.length > 1 ? categoryIds[1] : null,
        category3Id: categoryIds.length > 2 ? categoryIds[2] : null,
        category4Id: categoryIds.length > 3 ? categoryIds[3] : null,
        type: type,
        currency: currency,
        amount: amount,
        title: title?.isEmpty == true ? null : title,
        comment: comment?.isEmpty == true ? null : comment,
        date: date,
        status: status,
        // 🔥 PROPRIÉTÉS CRITIQUES préservées intactes
        amountBeforeConversion: amountBeforeConversion,
        currencyBeforeConversion: currencyBeforeConversion,
      );

      final createdTransaction = await _transactionRepository.createTransaction(
        newTransaction,
      );

      // 🆕 L'Event Bus gère automatiquement la réactivité via TransactionCreatedEvent
      if (_ref != null) {
        // Recharger explicitement les transactions pour le compte concerné
        final transactionListViewModel = _ref.read(
          transactionListViewModelProvider.notifier,
        );
        transactionListViewModel.loadTransactionsAroundToday(accountId);
      }

      state = state.copyWith(
        currentStep: TransactionCreationStep.completed,
        isCreatingTransaction: false,
        createdTransaction: createdTransaction,
      );

      return createdTransaction;
    } catch (e) {
      // Gestion d'erreur
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Crée un Counterparty avec téléchargement de logo (logique préservée)
  Future<int?> _createCounterpartyWithLogo(
    BrandLogo logo,
    String userInputText,
    int accountId, // 🆕 Pour rechargement après téléchargement logo
  ) async {
    try {
      // Étape 1: Créer le Counterparty immédiatement sans icône
      final cleanName = userInputText.cleanCounterpartyName();
      final counterpartyToCreate = Counterparty(
        id: 0, // Sera assigné par la DB
        name: cleanName,
        // Pas d'icône pour l'instant - sera mise à jour en arrière-plan
      );

      final newCounterparty = await _counterpartyRepository.createCounterparty(
        counterpartyToCreate,
      );

      // Étape 2: Lancer le téléchargement en arrière-plan (non-bloquant)
      state = state.copyWith(
        currentStep: TransactionCreationStep.downloadingLogo,
        isDownloadingLogo: true,
      );

      // Fire-and-forget : ne bloque pas la création de transaction
      _downloadLogoInBackground(
        counterpartyId: newCounterparty.id,
        logoUrl: logo.icon,
        domain: logo.domain,
        accountId:
            accountId, // 🆕 Passer l'accountId pour rechargement après téléchargement
      );

      return newCounterparty.id;
    } catch (e) {
      // En cas d'erreur de création du Counterparty, fallback sur texte
      return await _createCounterpartyFromText(userInputText);
    }
  }

  /// Télécharge le logo en arrière-plan (découplé du cycle de vie du widget)
  void _downloadLogoInBackground({
    required int counterpartyId,
    required String logoUrl,
    required String domain,
    required int
    accountId, // 🆕 Pour rechargement des transactions après téléchargement
  }) {
    // ✅ Cette méthode survit à la fermeture du widget car elle est dans le ViewModel
    _imageDownloadRepository
        .updateCounterpartyIconBackground(
          counterpartyId: counterpartyId,
          logoUrl: logoUrl,
          domain: domain,
        )
        .then((_) {
          // Succès : mettre à jour l'état
          if (kDebugMode) {
            print(
              'Logo downloaded successfully for counterparty $counterpartyId',
            );
          }
          state = state.copyWith(isDownloadingLogo: false);

          // 🆕 RECHARGEMENT après téléchargement logo pour afficher l'icône
          if (_ref != null) {
            final transactionListViewModel = _ref.read(
              transactionListViewModelProvider.notifier,
            );
            transactionListViewModel.loadTransactionsAroundToday(accountId);
          }
        })
        .catchError((error) {
          // Échec silencieux - le Counterparty reste sans icône
          if (kDebugMode) {
            print(
              'Logo download failed for counterparty $counterpartyId: $error',
            );
          }
          state = state.copyWith(isDownloadingLogo: false);
        });
  }

  /// Crée un Counterparty simple à partir du texte saisi (logique préservée)
  Future<int?> _createCounterpartyFromText(String searchText) async {
    final cleanName = searchText.cleanCounterpartyName();

    // Note: La vérification d'existence devrait idéalement passer par le repository
    // mais pour préserver la compatibilité avec la logique existante...

    final counterpartyToCreate = Counterparty(
      id: 0, // Sera assigné par la DB
      name: cleanName,
    );

    try {
      final newCounterparty = await _counterpartyRepository.createCounterparty(
        counterpartyToCreate,
      );

      return newCounterparty.id;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to create counterparty from text: $e');
      }
      return null;
    }
  }

  /// Réinitialise l'état pour une nouvelle création
  void resetCreationState() {
    state = const TransactionCreationViewState();
  }

  @override
  void resetToInitialState() {
    state = const TransactionCreationViewState();
  }
}
