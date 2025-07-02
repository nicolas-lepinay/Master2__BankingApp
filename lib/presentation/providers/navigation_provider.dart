import 'package:flutter_riverpod/flutter_riverpod.dart';

// State notifier pour gérer l'index de navigation
class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0);

  void setIndex(int index) {
    state = index;
  }
}

// State notifier pour gérer l'index de la page courante dans le PageView
class PageViewNotifier extends StateNotifier<int> {
  PageViewNotifier() : super(0);

  void setPageIndex(int index) {
    state = index;
  }
}

// Provider pour l'index de navigation de la bottom nav bar
final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((
  ref,
) {
  return NavigationNotifier();
});

// Provider pour l'index de la page courante dans le PageView des comptes
final pageViewProvider = StateNotifierProvider<PageViewNotifier, int>((ref) {
  return PageViewNotifier();
});
