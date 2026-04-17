import '../entities/history_snapshot.dart';
import '../entities/proxy.dart';

abstract class HistoryRepository {
  Future<List<HistorySnapshot>> getAll();
  Future<void> addSnapshot(List<ProxyEntity> proxies);
  Future<void> delete(String id);
  Future<void> deleteAll();
}