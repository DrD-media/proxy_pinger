import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedProxyIdsProvider = StateNotifierProvider<SelectedIdsNotifier, Set<String>>((ref) {
  return SelectedIdsNotifier();
});

class SelectedIdsNotifier extends StateNotifier<Set<String>> {
  SelectedIdsNotifier() : super({});
  
  void add(String id) {
    state = {...state, id};
  }
  
  void remove(String id) {
    state = state.where((element) => element != id).toSet();
  }
  
  void clear() {
    state = {};
  }
}