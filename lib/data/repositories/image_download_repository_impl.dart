import 'package:bankapp/core/services/image_download_service.dart';
import 'package:bankapp/data/cache/cache_manager.dart';
import 'package:bankapp/data/models/models.dart';
import 'package:bankapp/domain/repositories/counterparty_repository.dart';
import 'package:bankapp/domain/repositories/image_download_repository.dart';
import 'package:flutter/foundation.dart';

/// Implémentation du repository de téléchargement d'images
///
/// Cette implémentation respecte l'architecture MVVM en découplant
/// la logique de téléchargement du cycle de vie des widgets.
class ImageDownloadRepositoryImpl implements ImageDownloadRepository {
  final ImageDownloadService _imageDownloadService;
  final CounterpartyRepository _counterpartyRepository;

  ImageDownloadRepositoryImpl(
    this._imageDownloadService,
    this._counterpartyRepository,
  );

  @override
  Future<String> downloadAndSaveCounterpartyLogo({
    required String imageUrl,
    required String domain,
  }) async {
    try {
      return await _imageDownloadService.downloadAndSaveLogo(
        imageUrl: imageUrl,
        domain: domain,
      );
    } catch (e) {
      throw Exception('Failed to download logo: $e');
    }
  }

  @override
  Future<void> updateCounterpartyIconBackground({
    required int counterpartyId,
    required String logoUrl,
    required String domain,
  }) async {
    try {
      // Étape 1: Télécharger l'image
      final localImagePath = await downloadAndSaveCounterpartyLogo(
        imageUrl: logoUrl,
        domain: domain,
      );

      // Étape 2: Récupérer le Counterparty existant via repository (architecture MVVM)
      final existingCounterparty = await _counterpartyRepository
          .getCounterpartyById(counterpartyId);

      if (existingCounterparty == null) {
        throw Exception('Counterparty not found: $counterpartyId');
      }

      // Étape 3: Mettre à jour avec l'icône
      final updatedCounterparty = existingCounterparty.copyWith(
        icon: localImagePath,
      );

      await _counterpartyRepository.updateCounterparty(updatedCounterparty);
    } catch (e) {
      // Log l'erreur mais ne pas faire échouer l'opération principale
      // Le Counterparty reste simplement sans icône
      if (kDebugMode) {
        print('Failed to update counterparty icon: $e');
      }
      rethrow; // Le ViewModel peut décider de gérer ou ignorer l'erreur
    }
  }
}
