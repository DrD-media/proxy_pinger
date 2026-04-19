import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SortMode {
  none,   // Без сортировки
  smart,  // Умная сортировка (статус + пинг)
}

class SortState {
  final bool groupByStatus;  // Группировка по статусу
  final SortMode sortMode;   // Режим сортировки
  
  const SortState({
    this.groupByStatus = false,
    this.sortMode = SortMode.none,
  });
  
  SortState copyWith({
    bool? groupByStatus,
    SortMode? sortMode,
  }) {
    return SortState(
      groupByStatus: groupByStatus ?? this.groupByStatus,
      sortMode: sortMode ?? this.sortMode,
    );
  }
}

class SortNotifier extends StateNotifier<SortState> {
  SortNotifier() : super(const SortState());
  
  void reset() {
    state = const SortState();
  }
  
  void setGroupByStatus(bool value) {
    state = state.copyWith(groupByStatus: value);
  }
  
  void setSortMode(SortMode mode) {
    state = state.copyWith(sortMode: mode);
  }
}

final sortProvider = StateNotifierProvider<SortNotifier, SortState>((ref) {
  return SortNotifier();
});