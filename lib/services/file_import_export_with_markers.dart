import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../domain/entities/proxy.dart';
import '../domain/entities/mtproto_proxy.dart';
import '../domain/entities/socks5_proxy.dart';
import '../data/services/link_parser_service.dart';

class FileImportExportWithMarkersService {
  
  /// Экспорт в JSON с маркерами
  static Future<String?> exportProxiesWithMarkersToJson(
    List<ProxyEntity> proxies, {
    String? fileName,
    String? customPath,
  }) async {
    try {
      final jsonList = proxies.map((p) {
        final markers = p.markers;
        final Map<String, dynamic> map = {
          'server': p.server,
          'port': p.port,
          'type': p.type.name,
          'fullLink': p.fullLink,
          'markers': {
            'wifi': markers.wifi,
            'mobile': markers.mobile,
            'favorite': markers.favorite,
          },
        };
        
        if (p is MtprotoProxy) {
          map['secret'] = p.secret;
        }
        if (p is Socks5Proxy) {
          if (p.username != null) map['username'] = p.username;
          if (p.password != null) map['password'] = p.password;
        }
        return map;
      }).toList();
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);
      
      String finalFileName = fileName ?? 'proxy_backup_with_markers';
      if (!finalFileName.endsWith('.json')) {
        finalFileName = '$finalFileName.json';
      }
      
      String directoryPath;
      if (customPath != null && customPath.isNotEmpty) {
        directoryPath = customPath;
        final dir = Directory(directoryPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } else {
        final directory = await getDownloadsDirectory();
        if (directory == null) throw Exception('Не удалось найти папку Downloads');
        directoryPath = directory.path;
      }
      
      final filePath = '$directoryPath/$finalFileName';
      final file = File(filePath);
      await file.writeAsString(jsonString);
      return filePath;
    } catch (e) {
      debugPrint('Export JSON with markers error: $e');
      return null;
    }
  }
  
  /// Экспорт в TXT с маркерами (в виде текста после ссылки)
  static Future<String?> exportProxiesWithMarkersToTxt(
    List<ProxyEntity> proxies, {
    String? fileName,
    String? customPath,
  }) async {
    try {
      final content = proxies.map((p) {
        final markers = p.markers;
        String markerStr = '';
        
        if (markers.wifi > 0 && markers.wifi != 5) {
          markerStr += '[WiFi:${_getMarkerName(markers.wifi)}]';
        }
        if (markers.mobile > 0 && markers.mobile != 5) {
          markerStr += '[Mobile:${_getMarkerName(markers.mobile)}]';
        }
        if (markers.favorite) {
          markerStr += '[★]';
        }
        
        return markerStr.isEmpty ? p.fullLink : '${p.fullLink} $markerStr';
      }).join('\n');
      
      String finalFileName = fileName ?? 'proxy_backup_with_markers';
      if (!finalFileName.endsWith('.txt')) {
        finalFileName = '$finalFileName.txt';
      }
      
      String directoryPath;
      if (customPath != null && customPath.isNotEmpty) {
        directoryPath = customPath;
        final dir = Directory(directoryPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } else {
        final directory = await getDownloadsDirectory();
        if (directory == null) throw Exception('Не удалось найти папку Downloads');
        directoryPath = directory.path;
      }
      
      final filePath = '$directoryPath/$finalFileName';
      final file = File(filePath);
      await file.writeAsString(content);
      return filePath;
    } catch (e) {
      debugPrint('Export TXT with markers error: $e');
      return null;
    }
  }
  
  /// Импорт из JSON с восстановлением маркеров
  static Future<List<ProxyEntity>> importProxiesWithMarkersFromPath(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      final List<ProxyEntity> proxies = [];
      final Set<String> uniqueKeys = {};
      
      for (var item in jsonList) {
        try {
          final fullLink = item['fullLink'];
          if (fullLink == null) continue;
          
          final proxy = LinkParserService.fromLink(fullLink);
          
          // Восстанавливаем маркеры из JSON
          if (item['markers'] != null) {
            final markersData = item['markers'];
            final updatedProxy = proxy.copyWith(
              markers: ProxyMarkers(
                wifi: markersData['wifi'] ?? 5,
                mobile: markersData['mobile'] ?? 5,
                favorite: markersData['favorite'] ?? false,
              ),
            );
            
            final key = '${updatedProxy.server}:${updatedProxy.port}';
            if (!uniqueKeys.contains(key)) {
              uniqueKeys.add(key);
              proxies.add(updatedProxy);
            }
          } else {
            final key = '${proxy.server}:${proxy.port}';
            if (!uniqueKeys.contains(key)) {
              uniqueKeys.add(key);
              proxies.add(proxy);
            }
          }
        } catch (e) {
          debugPrint('Import item error: $e');
        }
      }
      
      return proxies;
    } catch (e) {
      debugPrint('Import JSON with markers error: $e');
      return [];
    }
  }
  
  /// Импорт из TXT с маркерами
  static Future<List<ProxyEntity>> importProxiesWithMarkersFromTxt(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final lines = content.split('\n');
      final List<ProxyEntity> proxies = [];
      final Set<String> uniqueKeys = {};
      
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;
        
        try {
          // Извлекаем ссылку (до пробела или до маркера)
          String fullLink = line;
          final markerIndex = line.indexOf(' [WiFi:');
          if (markerIndex != -1) {
            fullLink = line.substring(0, markerIndex);
          }
          
          final proxy = LinkParserService.fromLink(fullLink);
          final key = '${proxy.server}:${proxy.port}';
          
          if (!uniqueKeys.contains(key)) {
            uniqueKeys.add(key);
            proxies.add(proxy);
          }
        } catch (e) {
          debugPrint('Import TXT line error: $e');
        }
      }
      
      return proxies;
    } catch (e) {
      debugPrint('Import TXT with markers error: $e');
      return [];
    }
  }
  
  static String _getMarkerName(int value) {
    switch (value) {
      case 1: return 'Красный';
      case 2: return 'Оранжевый';
      case 3: return 'Желтый';
      case 4: return 'Зеленый';
      default: return '';
    }
  }
}