import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';  // Добавлено для debugPrint
import 'package:path_provider/path_provider.dart';
import '../domain/entities/proxy.dart';
import '../domain/entities/mtproto_proxy.dart';
import '../domain/entities/socks5_proxy.dart';
import '../data/services/link_parser_service.dart';

class FileImportExportService {
  
  /// Экспорт прокси в TXT файл
  static Future<String?> exportProxies(
    List<ProxyEntity> proxies, {
    String? fileName,
    String? customPath,
  }) async {
    try {
      final content = proxies.map((p) => p.fullLink).join('\n');
      
      String finalFileName = fileName ?? 'proxy_backup';
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
      debugPrint('Export TXT error: $e');
      return null;
    }
  }
  
  /// Экспорт прокси в JSON файл
  static Future<String?> exportProxiesToJson(
    List<ProxyEntity> proxies, {
    String? fileName,
    String? customPath,
  }) async {
    try {
      final List<Map<String, dynamic>> jsonList = [];
      
      for (final p in proxies) {
        final map = <String, dynamic>{
          'server': p.server,
          'port': p.port,
          'type': p.type.name,
          'fullLink': p.fullLink,
        };
        
        if (p is MtprotoProxy) {
          map['secret'] = p.secret;
        }
        if (p is Socks5Proxy) {
          if (p.username != null) map['username'] = p.username;
          if (p.password != null) map['password'] = p.password;
        }
        
        jsonList.add(map);
      }
      
      final jsonString = jsonEncode(jsonList);
      
      String finalFileName = fileName ?? 'proxy_backup';
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
      debugPrint('Export JSON error: $e');
      return null;
    }
  }
  
  /// Импорт прокси из файла по пути
  static Future<List<ProxyEntity>> importProxiesFromPath(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      
      if (filePath.endsWith('.json')) {
        return _importFromJson(content);
      } else {
        return _importFromTxt(content);
      }
    } catch (e) {
      debugPrint('Import error: $e');
      return [];
    }
  }
  
  /// Импорт из JSON строки
  static Future<List<ProxyEntity>> _importFromJson(String content) async {
    try {
      final List<dynamic> jsonList = jsonDecode(content);
      final List<ProxyEntity> proxies = [];
      final Set<String> uniqueKeys = {};
      
      for (var item in jsonList) {
        try {
          final fullLink = item['fullLink'];
          if (fullLink == null) continue;
          
          final proxy = LinkParserService.fromLink(fullLink);
          final key = '${proxy.server}:${proxy.port}';
          
          if (!uniqueKeys.contains(key)) {
            uniqueKeys.add(key);
            proxies.add(proxy);
          }
        } catch (e) {
          // Пропускаем невалидные записи
        }
      }
      
      return proxies;
    } catch (e) {
      debugPrint('JSON parse error: $e');
      return [];
    }
  }
  
  /// Импорт из TXT строки
  static Future<List<ProxyEntity>> _importFromTxt(String content) async {
    final lines = content.split('\n');
    final List<ProxyEntity> proxies = [];
    final Set<String> uniqueKeys = {};
    
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      
      try {
        final proxy = LinkParserService.fromLink(line);
        final key = '${proxy.server}:${proxy.port}';
        
        if (!uniqueKeys.contains(key)) {
          uniqueKeys.add(key);
          proxies.add(proxy);
        }
      } catch (e) {
        // Пропускаем невалидные строки
      }
    }
    
    return proxies;
  }
}