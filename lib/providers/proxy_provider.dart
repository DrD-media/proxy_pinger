import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/hive_proxy_repository.dart';
import '../domain/entities/proxy.dart';
import '../domain/repositories/proxy_repository.dart';

final proxyRepositoryProvider = Provider<ProxyRepository>((ref) {
  return HiveProxyRepository();
});

final proxyListProvider = FutureProvider<List<ProxyEntity>>((ref) async {
  final repo = ref.watch(proxyRepositoryProvider);
  return await repo.getAll();
});