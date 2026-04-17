import 'package:uuid/uuid.dart';

class HistorySnapshot {
  final String id;
  final DateTime timestamp;
  final List<String> proxiesJson;
  
  int get totalCount => proxiesJson.length;
  
  int get onlineCount {
    return proxiesJson.where((json) => json.contains('"lastStatus":"online"')).length;
  }
  
  int get offlineCount {
    return proxiesJson.where((json) => json.contains('"lastStatus":"offline"')).length;
  }
  
  HistorySnapshot({
    String? id,
    required this.timestamp,
    required this.proxiesJson,
  }) : id = id ?? const Uuid().v4();
}