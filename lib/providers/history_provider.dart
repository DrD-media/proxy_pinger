import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/hive_history_repository.dart';
import '../domain/entities/history_snapshot.dart';
import '../domain/repositories/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HiveHistoryRepository();
});

final historyListProvider = FutureProvider<List<HistorySnapshot>>((ref) async {
  final repo = ref.watch(historyRepositoryProvider);
  return await repo.getAll();
});