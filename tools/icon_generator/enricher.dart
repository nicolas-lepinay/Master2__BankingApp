/// Enrichisseur de métadonnées pour les icônes
/// 
/// Ce module transforme les icônes parsées en ajoutant des métadonnées
/// intelligentes : catégories, mots-clés, synonymes, traductions françaises.
library;

import 'models.dart';

/// Enrichisseur principal pour ajouter des métadonnées aux icônes
class IconMetadataEnricher {
  
  /// Enrichit les icônes parsées avec des métadonnées
  List<EnrichedIcon> enrichIcons(List<ParsedIcon> parsedIcons) {
    print('🔍 Enrichissement de ${parsedIcons.length} icônes...');
    
    final enrichedIcons = <EnrichedIcon>[];
    
    for (final icon in parsedIcons) {
      final enriched = _enrichSingleIcon(icon);
      enrichedIcons.add(enriched);
    }
    
    print('✅ ${enrichedIcons.length} icônes enrichies');
    return enrichedIcons;
  }

  /// Enrichit une seule icône avec toutes les métadonnées
  EnrichedIcon _enrichSingleIcon(ParsedIcon icon) {
    final cleanName = _cleanIconName(icon.name);
    final category = _inferCategory(icon.name, icon.className);
    final keywords = _generateKeywords(icon.name, icon.className);
    final style = _extractStyle(icon.name);
    final tags = _generateTags(icon.name);
    
    return EnrichedIcon(
      id: '${icon.className.toLowerCase()}_${icon.name}',
      name: cleanName,
      category: category,
      keywords: keywords,
      style: style,
      tags: tags,
      className: icon.className,
      fieldName: icon.name,
      codePoint: icon.codePoint,
      fontFamily: icon.fontFamily,
    );
  }

  /// Nettoie le nom de l'icône pour l'affichage
  String _cleanIconName(String name) {
    // "heart_fill" -> "heart"
    // "user_solid" -> "user"
    return name
        .replaceAll(RegExp(r'_(fill|outline|solid|regular|bold|light|line)$'), '')
        .replaceAll('_', '-');
  }

  /// Infère la catégorie depuis le nom et la classe
  String _inferCategory(String iconName, String className) {
    // Dictionnaire de mots-clés -> catégories
    const categoryKeywords = {
      'essential': [
        'heart', 'star', 'home', 'house', 'user', 'person', 'search', 'find',
        'bookmark', 'favorite', 'like', 'love', 'plus', 'add', 'minus', 'remove',
        'circle', 'square', 'triangle', 'diamond'
      ],
      'business': [
        'briefcase', 'chart', 'graph', 'dollar', 'euro', 'money', 'cash',
        'bank', 'credit', 'card', 'wallet', 'business', 'office', 'building',
        'company', 'corporate', 'finance', 'financial', 'investment'
      ],
      'tech': [
        'laptop', 'computer', 'mobile', 'phone', 'wifi', 'internet', 'code',
        'programming', 'database', 'server', 'cloud', 'api', 'git', 'github',
        'terminal', 'console', 'monitor', 'screen', 'device', 'hardware'
      ],
      'communication': [
        'email', 'mail', 'message', 'chat', 'conversation', 'talk', 'call',
        'telephone', 'contact', 'send', 'receive', 'notification', 'bell',
        'alert', 'announcement', 'broadcast'
      ],
      'transport': [
        'car', 'vehicle', 'plane', 'airplane', 'flight', 'train', 'subway',
        'bike', 'bicycle', 'motorcycle', 'bus', 'truck', 'ship', 'boat',
        'taxi', 'uber', 'transport', 'travel', 'journey'
      ],
      'media': [
        'play', 'pause', 'stop', 'music', 'audio', 'video', 'camera', 'photo',
        'image', 'picture', 'film', 'movie', 'record', 'microphone', 'speaker',
        'volume', 'sound', 'media', 'player'
      ],
      'navigation': [
        'menu', 'navigation', 'arrow', 'up', 'down', 'left', 'right', 'back',
        'forward', 'next', 'previous', 'close', 'x', 'cancel', 'exit',
        'expand', 'collapse', 'hamburger'
      ],
      'tools': [
        'settings', 'config', 'gear', 'tool', 'wrench', 'hammer', 'screwdriver',
        'repair', 'fix', 'maintenance', 'utility', 'options', 'preferences',
        'customize', 'adjust'
      ],
      'social': [
        'share', 'social', 'facebook', 'twitter', 'instagram', 'linkedin',
        'youtube', 'tiktok', 'whatsapp', 'telegram', 'discord', 'reddit',
        'snapchat', 'pinterest'
      ],
      'files': [
        'file', 'folder', 'document', 'pdf', 'text', 'doc', 'excel', 'csv',
        'download', 'upload', 'save', 'open', 'import', 'export', 'archive',
        'zip', 'attachment'
      ],
      'health': [
        'medical', 'health', 'hospital', 'doctor', 'nurse', 'medicine',
        'pill', 'pharmacy', 'cross', 'ambulance', 'heartbeat', 'pulse',
        'stethoscope', 'thermometer'
      ],
      'weather': [
        'sun', 'moon', 'cloud', 'rain', 'snow', 'wind', 'storm', 'thunder',
        'lightning', 'weather', 'temperature', 'hot', 'cold'
      ],
      'shopping': [
        'shop', 'store', 'cart', 'basket', 'bag', 'shopping', 'buy', 'sell',
        'price', 'tag', 'barcode', 'receipt', 'payment', 'checkout'
      ],
      'security': [
        'lock', 'unlock', 'key', 'password', 'security', 'shield', 'protect',
        'safe', 'vault', 'guard', 'privacy', 'fingerprint', 'eye', 'visible'
      ]
    };

    final lowerName = iconName.toLowerCase();
    
    // Recherche par mots-clés exacts
    for (final entry in categoryKeywords.entries) {
      if (entry.value.any((keyword) => lowerName.contains(keyword))) {
        return entry.key;
      }
    }

    // Catégorie par défaut basée sur le set d'icônes
    return _getDefaultCategoryForSet(className);
  }

  /// Obtient la catégorie par défaut pour un set d'icônes
  String _getDefaultCategoryForSet(String className) {
    switch (className.toLowerCase()) {
      case 'bootstrap':
      case 'heroicons':
      case 'teenyicons':
        return 'essential';
      case 'fontawesome':
      case 'lineawesome':
        return 'general';
      case 'antdesign':
      case 'clarity':
        return 'business';
      case 'boxicons':
      case 'evaicons':
        return 'interface';
      case 'iconsax':
      case 'mingcute':
        return 'modern';
      case 'ionicons':
        return 'mobile';
      case 'octicons':
        return 'tech';
      case 'pixelarticons':
        return 'gaming';
      case 'zondicons':
        return 'minimal';
      default:
        return 'other';
    }
  }

  /// Génère des mots-clés de recherche complets
  List<String> _generateKeywords(String iconName, String className) {
    final keywords = <String>{};

    // 1. Décomposition du nom
    keywords.addAll(iconName.split('_').where((part) => part.isNotEmpty));

    // 2. Nom nettoyé
    final cleanName = _cleanIconName(iconName);
    keywords.add(cleanName);

    // 3. Synonymes anglais
    keywords.addAll(_getSynonyms(iconName));

    // 4. Traductions françaises
    keywords.addAll(_getFrenchTranslations(iconName));

    // 5. Nom du set d'icônes
    keywords.add(className.toLowerCase());

    // 6. Variantes d'écriture
    keywords.addAll(_generateVariants(iconName));

    return keywords.where((k) => k.length > 1).toList();
  }

  /// Génère des variantes d'écriture pour un nom d'icône
  List<String> _generateVariants(String iconName) {
    final variants = <String>[];
    
    // snake_case -> kebab-case
    variants.add(iconName.replaceAll('_', '-'));
    
    // snake_case -> camelCase
    final parts = iconName.split('_');
    if (parts.length > 1) {
      final camelCase = parts.first + parts.skip(1).map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join();
      variants.add(camelCase);
    }
    
    return variants;
  }

  /// Dictionnaire de synonymes anglais
  List<String> _getSynonyms(String iconName) {
    const synonyms = {
      'heart': ['love', 'like', 'favorite', 'romance'],
      'user': ['person', 'profile', 'account', 'avatar'],
      'home': ['house', 'building', 'residence'],
      'search': ['find', 'look', 'magnifier', 'lens'],
      'money': ['cash', 'dollar', 'finance', 'currency'],
      'phone': ['mobile', 'cell', 'telephone', 'call'],
      'email': ['mail', 'message', 'envelope'],
      'settings': ['config', 'gear', 'options', 'preferences'],
      'close': ['x', 'cancel', 'exit', 'dismiss'],
      'add': ['plus', 'new', 'create', 'insert'],
      'remove': ['delete', 'minus', 'trash', 'bin'],
      'edit': ['modify', 'change', 'update', 'pencil'],
      'save': ['store', 'keep', 'preserve'],
      'share': ['send', 'distribute', 'publish'],
      'download': ['get', 'fetch', 'retrieve'],
      'upload': ['send', 'post', 'submit'],
      'lock': ['secure', 'protect', 'private'],
      'unlock': ['open', 'access', 'public'],
      'view': ['see', 'look', 'show', 'display'],
      'hide': ['conceal', 'invisible', 'secret'],
    };

    final lowerName = iconName.toLowerCase();
    final result = <String>[];
    
    for (final entry in synonyms.entries) {
      if (lowerName.contains(entry.key)) {
        result.addAll(entry.value);
      }
    }
    
    return result;
  }

  /// Dictionnaire de traductions françaises
  List<String> _getFrenchTranslations(String iconName) {
    const translations = {
      'heart': ['cœur', 'coeur', 'amour'],
      'user': ['utilisateur', 'profil', 'compte'],
      'home': ['maison', 'accueil', 'domicile'],
      'search': ['recherche', 'chercher', 'trouver'],
      'money': ['argent', 'finance', 'monnaie'],
      'phone': ['téléphone', 'appel', 'mobile'],
      'email': ['courriel', 'message', 'mail'],
      'settings': ['paramètres', 'configuration', 'réglages'],
      'close': ['fermer', 'annuler', 'quitter'],
      'add': ['ajouter', 'nouveau', 'créer'],
      'remove': ['supprimer', 'enlever', 'effacer'],
      'edit': ['éditer', 'modifier', 'changer'],
      'save': ['sauvegarder', 'enregistrer', 'garder'],
      'share': ['partager', 'envoyer', 'distribuer'],
      'download': ['télécharger', 'récupérer'],
      'upload': ['envoyer', 'téléverser'],
      'lock': ['verrouiller', 'sécuriser', 'protéger'],
      'unlock': ['déverrouiller', 'ouvrir', 'accéder'],
      'view': ['voir', 'afficher', 'regarder'],
      'hide': ['cacher', 'masquer', 'invisible'],
      'file': ['fichier', 'document'],
      'folder': ['dossier', 'répertoire'],
      'image': ['image', 'photo', 'picture'],
      'video': ['vidéo', 'film'],
      'music': ['musique', 'audio', 'son'],
    };

    final lowerName = iconName.toLowerCase();
    final result = <String>[];
    
    for (final entry in translations.entries) {
      if (lowerName.contains(entry.key)) {
        result.addAll(entry.value);
      }
    }
    
    return result;
  }

  /// Extrait le style de l'icône depuis son nom
  String? _extractStyle(String iconName) {
    final stylePatterns = {
      'fill': RegExp(r'_(fill|filled)$'),
      'outline': RegExp(r'_(outline|outlined|line)$'),
      'solid': RegExp(r'_(solid|bold)$'),
      'regular': RegExp(r'_(regular|normal)$'),
      'light': RegExp(r'_(light|thin)$'),
    };

    for (final entry in stylePatterns.entries) {
      if (entry.value.hasMatch(iconName)) {
        return entry.key;
      }
    }

    return null; // Style par défaut
  }

  /// Génère des tags additionnels pour l'icône
  List<String> _generateTags(String iconName) {
    final tags = <String>[];
    
    // Tags basés sur les patterns communs
    if (iconName.contains('arrow')) tags.add('direction');
    if (iconName.contains('circle') || iconName.contains('square')) tags.add('shape');
    if (iconName.contains('play') || iconName.contains('pause')) tags.add('media-control');
    if (iconName.contains('social') || iconName.contains('facebook')) tags.add('social-media');
    if (iconName.contains('medical') || iconName.contains('health')) tags.add('healthcare');
    if (iconName.contains('business') || iconName.contains('office')) tags.add('business');
    if (iconName.contains('tech') || iconName.contains('code')) tags.add('technology');
    
    return tags;
  }

  /// Statistiques d'enrichissement
  EnrichmentStats getEnrichmentStats(List<EnrichedIcon> icons) {
    final categoriesCount = <String, int>{};
    final stylesCount = <String, int>{};
    var totalKeywords = 0;
    
    for (final icon in icons) {
      // Compter les catégories
      categoriesCount[icon.category] = (categoriesCount[icon.category] ?? 0) + 1;
      
      // Compter les styles
      final style = icon.style ?? 'default';
      stylesCount[style] = (stylesCount[style] ?? 0) + 1;
      
      // Compter les mots-clés
      totalKeywords += icon.keywords.length;
    }
    
    return EnrichmentStats(
      totalIcons: icons.length,
      categoriesCount: categoriesCount,
      stylesCount: stylesCount,
      averageKeywords: totalKeywords / icons.length,
    );
  }
}

/// Statistiques d'enrichissement
class EnrichmentStats {
  final int totalIcons;
  final Map<String, int> categoriesCount;
  final Map<String, int> stylesCount;
  final double averageKeywords;
  
  const EnrichmentStats({
    required this.totalIcons,
    required this.categoriesCount,
    required this.stylesCount,
    required this.averageKeywords,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('📊 Statistiques d\'enrichissement:');
    buffer.writeln('   🎯 Total icônes: $totalIcons');
    buffer.writeln('   🔤 Mots-clés moyenne: ${averageKeywords.toStringAsFixed(1)}');
    buffer.writeln('   📂 Catégories:');
    
    final sortedCategories = categoriesCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedCategories.take(10)) {
      buffer.writeln('      ${entry.key}: ${entry.value} icônes');
    }
    
    return buffer.toString();
  }
}