import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../domain/entities/proxy.dart';
import '../domain/entities/mtproto_proxy.dart';
import '../domain/entities/socks5_proxy.dart';
import '../data/services/link_parser_service.dart'; // Исправлен путь
import 'package:flutter/foundation.dart';

class FileImportExportService {
  
  /// Экспорт прокси в файл (TXT)
  static Future<String?> exportProxies(List<ProxyEntity> proxies) async {
    try {
      final content = proxies.map((p) => p.fullLink).join('\n');
      
      final directory = await getDownloadsDirectory();
      if (directory == null) throw Exception('Не удалось найти папку Downloads');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/proxy_backup_$timestamp.txt';
      final file = File(filePath);
      
      await file.writeAsString(content);
      return filePath;
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    }
  }
  
  /// Импорт прокси из файла
  static Future<List<ProxyEntity>> importProxies() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        allowedExtensions: ['txt', 'json'],
        dialogTitle: 'Выберите файл с прокси',
      );
      
      if (result == null) return [];
      
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
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
    } catch (e) {
      debugPrint('Import error: $e');
      return [];
    }
  }
  
  /// Экспорт в JSON формате
  static Future<String?> exportProxiesToJson(List<ProxyEntity> proxies) async {
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
      final directory = await getDownloadsDirectory();
      if (directory == null) throw Exception('Не удалось найти папку Downloads');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/proxy_backup_$timestamp.json';
      final file = File(filePath);
      
      await file.writeAsString(jsonString);
      return filePath;
    } catch (e) {
      debugPrint('Export JSON error: $e');
      return null;
    }
  }
}