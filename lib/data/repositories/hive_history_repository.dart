import 'dart:convert';
import 'package:hive/hive.dart';
import '../../domain/entities/history_snapshot.dart';
import '../../domain/entities/proxy.dart';
import '../../domain/repositories/history_repository.dart';

class HiveHistoryRepository implements HistoryRepository {
  static const String _boxName = 'history';
  Box? _box;
  
  Future<Box> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
    }
    return _box!;
  }
  
  @override
  Future<List<HistorySnapshot>> getAll() async {
    final box = await _getBox();
    final List<HistorySnapshot> snapshots = [];
    
    for (var key in box.keys) {
      final data = box.get(key) as Map;
      snapshots.add(HistorySnapshot(
        id: data['id'],
        timestamp: DateTime.parse(data['timestamp']),
        proxiesJson: List<String>.from(data['proxiesJson']),
      ));
    }
    
    snapshots.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return snapshots;
  }
  
  @override
  Future<void> addSnapshot(List<ProxyEntity> proxies) async {
    final box = await _getBox();
    final jsonList = proxies.map((p) {
      return jsonEncode({
        'id': p.id,
        'type': p.type.name,
        'server': p.server,
        'port': p.port,
        'lastStatus': p.lastStatus.name,
        'lastPing': p.lastPing,
      });
    }).toList();
    
    final snapshot = HistorySnapshot(
      timestamp: DateTime.now(),
      proxiesJson: jsonList,
    );
    
    final data = {
      'id': snapshot.id,
      'timestamp': snapshot.timestamp.toIso8601String(),
      'proxiesJson': snapshot.proxiesJson,
    };
    
    await box.put(snapshot.id, data);
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
}