import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

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
  
  Map<String, dynamic> toJson() => {
    'groupByStatus': groupByStatus,
    'sortMode': sortMode.name,
  };
  
  factory SortState.fromJson(Map<String, dynamic> json) => SortState(
    groupByStatus: json['groupByStatus'] ?? false,
    sortMode: SortMode.values.firstWhere(
      (e) => e.name == json['sortMode'],
      orElse: () => SortMode.none,
    ),
  );
}

class SortNotifier extends StateNotifier<SortState> {
  static const String _boxName = 'sort_settings';
  Box? _box;
  
  SortNotifier() : super(const SortState()) {
    _init();
  }
  
  Future<void> _init() async {
    _box = await Hive.openBox(_boxName);
    _loadFromBox();
  }
  
  void _loadFromBox() {
    if (_box == null) return;
    final data = _box!.get('settings');
    if (data != null && data is Map) {
      state = SortState.fromJson(Map<String, dynamic>.from(data));
    }
  }
  
  void _saveToBox() {
    if (_box == null) return;
    _box!.put('settings', state.toJson());
  }
  
  void reset() {
    state = const SortState();
    _saveToBox();
  }
  
  void setGroupByStatus(bool value) {
    state = state.copyWith(groupByStatus: value);
    _saveToBox();
  }
  
  void setSortMode(SortMode mode) {
    state = state.copyWith(sortMode: mode);
    _saveToBox();
  }
}

final sortProvider = StateNotifierProvider<SortNotifier, SortState>((ref) {
  return SortNotifier();
});