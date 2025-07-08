import 'package:flutter_riverpod/flutter_riverpod.dart';

// Classe pour stocker les positions calculées
class CardPositions {
  final double? accountHeaderPosition; // Position du header avec nom du compte
  final double? actualBalanceLabelPosition; // Position du label "Solde Réel"
  final double screenHeight;

  CardPositions({
    this.accountHeaderPosition,
    this.actualBalanceLabelPosition,
    required this.screenHeight,
  });

  // Calculer les extents pour le DraggableScrollableSheet
  DraggableSheetExtents get sheetExtents {
    if (accountHeaderPosition == null || actualBalanceLabelPosition == null) {
      // Valeurs de fallback si les positions ne sont pas encore mesurées
      return const DraggableSheetExtents(
        minExtent: 0.15,
        initialExtent: 0.70,
        maxExtent: 0.85,
      );
    }

    // Calculer les extents basés sur les positions réelles
    final minExtent = 0.15; // Position minimale fixe

    // Position initiale : juste au-dessus du label "Solde Réel"
    final initialExtent = 1.0 - (actualBalanceLabelPosition! / screenHeight);

    // Position maximale : juste au-dessus du header du compte
    final maxExtent = 1.0 - (accountHeaderPosition! / screenHeight);

    return DraggableSheetExtents(
      minExtent: minExtent,
      initialExtent: initialExtent.clamp(0.15, 0.85),
      maxExtent: maxExtent.clamp(0.15, 0.90),
    );
  }

  CardPositions copyWith({
    double? accountHeaderPosition,
    double? actualBalanceLabelPosition,
    double? screenHeight,
  }) {
    return CardPositions(
      accountHeaderPosition:
          accountHeaderPosition ?? this.accountHeaderPosition,
      actualBalanceLabelPosition:
          actualBalanceLabelPosition ?? this.actualBalanceLabelPosition,
      screenHeight: screenHeight ?? this.screenHeight,
    );
  }
}

class DraggableSheetExtents {
  final double minExtent;
  final double initialExtent;
  final double maxExtent;

  const DraggableSheetExtents({
    required this.minExtent,
    required this.initialExtent,
    required this.maxExtent,
  });

  List<double> get snapSizes => [minExtent, initialExtent, maxExtent];
}

// State notifier pour gérer les positions
class CardPositionsNotifier extends StateNotifier<CardPositions> {
  CardPositionsNotifier(double screenHeight)
    : super(CardPositions(screenHeight: screenHeight));

  void updateScreenHeight(double screenHeight) {
    state = state.copyWith(screenHeight: screenHeight);
  }

  void updateAccountHeaderPosition(double position) {
    state = state.copyWith(accountHeaderPosition: position);
  }

  void updateActualBalanceLabelPosition(double position) {
    state = state.copyWith(actualBalanceLabelPosition: position);
  }

  void updatePositions({
    double? accountHeaderPosition,
    double? actualBalanceLabelPosition,
  }) {
    state = state.copyWith(
      accountHeaderPosition: accountHeaderPosition,
      actualBalanceLabelPosition: actualBalanceLabelPosition,
    );
  }

  void resetPositions() {
    state = CardPositions(screenHeight: state.screenHeight);
  }
}

// Provider pour les positions des cartes
final cardPositionsProvider =
    StateNotifierProvider<CardPositionsNotifier, CardPositions>((ref) {
      return CardPositionsNotifier(
        800.0,
      ); // Valeur par défaut, sera mise à jour
    });
