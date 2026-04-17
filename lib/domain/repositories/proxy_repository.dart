import '../entities/proxy.dart';

abstract class ProxyRepository {
  Future<List<ProxyEntity>> getAll();
  Future<void> add(ProxyEntity proxy);
  Future<void> delete(String id);
  Future<void> deleteAll();
  Future<void> update(ProxyEntity proxy);
  Future<void> updateAll(List<ProxyEntity> proxies);
}