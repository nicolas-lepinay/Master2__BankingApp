import 'package:flutter_riverpod/flutter_riverpod.dart';

// State notifier pour gérer l'index de la carte sélectionnée
class SelectedCardNotifier extends StateNotifier<int> {
  SelectedCardNotifier() : super(0);

  void setSelectedCard(int index) {
    state = index;
  }
}

// State notifier pour gérer l'état expanded des cartes
class CardsExpandedNotifier extends StateNotifier<bool> {
  CardsExpandedNotifier() : super(false);

  void setExpanded(bool expanded) {
    state = expanded;
  }

  void toggle() {
    state = !state;
  }
}

// Provider pour l'index de la carte sélectionnée
final selectedCardProvider = StateNotifierProvider<SelectedCardNotifier, int>((
  ref,
) {
  return SelectedCardNotifier();
});

// Provider pour l'état expanded des cartes
final cardsExpandedProvider =
    StateNotifierProvider<CardsExpandedNotifier, bool>((ref) {
      return CardsExpandedNotifier();
    });
