
/// Repository pour la gestion des téléchargements d'images
/// 
/// Ce repository découple la logique de téléchargement d'images du cycle de vie
/// des widgets, permettant des opérations asynchrones en arrière-plan.
abstract class ImageDownloadRepository {
  /// Télécharge une image depuis une URL et la sauvegarde localement
  /// 
  /// [imageUrl] L'URL de l'image à télécharger
  /// [domain] Le domaine associé (pour le nommage du fichier)
  /// 
  /// Retourne le chemin local du fichier téléchargé
  Future<String> downloadAndSaveCounterpartyLogo({
    required String imageUrl,
    required String domain,
  });
  
  /// Met à jour l'icône d'un Counterparty en arrière-plan
  /// 
  /// Cette méthode télécharge l'image et met à jour le Counterparty
  /// de manière asynchrone, sans bloquer l'interface utilisateur.
  /// 
  /// [counterpartyId] L'ID du Counterparty à mettre à jour
  /// [logoUrl] L'URL du logo à télécharger
  /// [domain] Le domaine associé au logo
  Future<void> updateCounterpartyIconBackground({
    required int counterpartyId,
    required String logoUrl,
    required String domain,
  });
}