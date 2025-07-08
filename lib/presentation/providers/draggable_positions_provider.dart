import 'package:flutter_riverpod/flutter_riverpod.dart';

class DraggablePositions {
  final double minPosition;
  final double intermediatePosition;
  final double maxPosition;
  final bool isCalculated;

  const DraggablePositions({
    this.minPosition = 0.15,
    this.intermediatePosition = 0.70,
    this.maxPosition = 0.85,
    this.isCalculated = false,
  });

  DraggablePositions copyWith({
    double? minPosition,
    double? intermediatePosition,
    double? maxPosition,
    bool? isCalculated,
  }) {
    return DraggablePositions(
      minPosition: minPosition ?? this.minPosition,
      intermediatePosition: intermediatePosition ?? this.intermediatePosition,
      maxPosition: maxPosition ?? this.maxPosition,
      isCalculated: isCalculated ?? this.isCalculated,
    );
  }
}

class DraggablePositionsNotifier extends StateNotifier<DraggablePositions> {
  DraggablePositionsNotifier() : super(const DraggablePositions());

  void updatePositions({
    required double intermediatePosition,
    required double maxPosition,
  }) {
    state = state.copyWith(
      intermediatePosition: intermediatePosition,
      maxPosition: maxPosition,
      isCalculated: true,
    );
  }

  void reset() {
    state = const DraggablePositions();
  }
}

final draggablePositionsProvider =
    StateNotifierProvider<DraggablePositionsNotifier, DraggablePositions>(
      (ref) => DraggablePositionsNotifier(),
    );
