import 'package:hive/hive.dart';
import '../../domain/entities/proxy.dart';
import '../../domain/entities/mtproto_proxy.dart';
import '../../domain/entities/socks5_proxy.dart';
import '../../domain/repositories/proxy_repository.dart';

class HiveProxyRepository implements ProxyRepository {
  static const String _boxName = 'proxies';
  Box? _box;
  
  Future<Box> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
    }
    return _box!;
  }
  
  @override
  Future<List<ProxyEntity>> getAll() async {
    final box = await _getBox();
    final List<ProxyEntity> proxies = [];
    
    for (var key in box.keys) {
      final data = box.get(key) as Map;
      final type = data['type'];
      
      if (type == 'mtproto') {
        proxies.add(MtprotoProxy(
          id: data['id'],
          server: data['server'],
          port: data['port'],
          secret: data['secret'],
          fullLink: data['fullLink'],
          lastStatus: _stringToStatus(data['lastStatus']),
          lastPing: data['lastPing'],
        ));
      } else if (type == 'socks5') {
        proxies.add(Socks5Proxy(
          id: data['id'],
          server: data['server'],
          port: data['port'],
          username: data['username'],
          password: data['password'],
          fullLink: data['fullLink'],
          lastStatus: _stringToStatus(data['lastStatus']),
          lastPing: data['lastPing'],
        ));
      }
    }
    
    return proxies;
  }
  
  @override
  Future<void> add(ProxyEntity proxy) async {
    final box = await _getBox();
    final Map<String, dynamic> data = {
      'id': proxy.id,
      'type': proxy.type.name,
      'server': proxy.server,
      'port': proxy.port,
      'fullLink': proxy.fullLink,
      'lastStatus': proxy.lastStatus.name,
      'lastPing': proxy.lastPing,
    };
    
    if (proxy is MtprotoProxy) {
      data['secret'] = proxy.secret;
    } else if (proxy is Socks5Proxy) {
      data['username'] = proxy.username;
      data['password'] = proxy.password;
    }
    
    await box.put(proxy.id, data);
  }
  
  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
  
  @override
  Future<void> deleteAll() async {
    final box = await _getBox();
    await box.clear();
  }
  
  @override
  Future<void> update(ProxyEntity proxy) async {
    await add(proxy);
  }
  
  @override
  Future<void> updateAll(List<ProxyEntity> proxies) async {
    for (final proxy in proxies) {
      await update(proxy);
    }
  }
  
  ProxyStatus _stringToStatus(String status) {
    switch (status) {
      case 'online': return ProxyStatus.online;
      case 'offline': return ProxyStatus.offline;
      default: return ProxyStatus.unknown;
    }
  }
}