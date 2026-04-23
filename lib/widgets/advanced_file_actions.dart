import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../providers/proxy_provider.dart';
import '../services/file_import_export_with_markers.dart';
import '../domain/entities/mtproto_proxy.dart';
import '../domain/entities/socks5_proxy.dart';
import 'dart:io';

class AdvancedFileActions extends ConsumerStatefulWidget {
  final String fileName;
  final String? customPath;

  const AdvancedFileActions({
    super.key,
    required this.fileName,
    this.customPath,
  });

  @override
  ConsumerState<AdvancedFileActions> createState() => _AdvancedFileActionsState();
}

class _AdvancedFileActionsState extends ConsumerState<AdvancedFileActions> {
  // Кнопка с иконками (для экспорта/импорта)
  Widget _buildMarkerActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool showWifiIcon,
    required bool showMobileIcon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            if (showWifiIcon) ...[
              const SizedBox(width: 12),
              Icon(Icons.wifi, size: 16, color: Colors.white70),
            ],
            if (showMobileIcon) ...[
              const SizedBox(width: 4),
              Icon(Icons.import_export, size: 16, color: Colors.white70),
            ],
          ],
        ),
      ),
    );
  }

  // Маленькая кнопка для копирования
  Widget _buildCopyButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Получение имени маркера
  String _getMarkerName(int value) {
    switch (value) {
      case 1: return 'Красный';
      case 2: return 'Оранжевый';
      case 3: return 'Желтый';
      case 4: return 'Зеленый';
      default: return '';
    }
  }

  // Копирование в буфер с метками
  Future<void> _copyToClipboardWithMarkers(String type) async {
    final proxies = await ref.read(proxyListProvider.future);
    if (proxies.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет прокси для копирования')),
        );
      }
      return;
    }
    
    String content = '';
    
    if (type == 'txt') {
      content = proxies.map((p) {
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
    } else if (type == 'json') {
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
      content = const JsonEncoder.withIndent('  ').convert(jsonList);
    }
    
    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📋 Скопировано в буфер обмена (${type.toUpperCase()} с метками)'),
          backgroundColor: Colors.teal,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Экспорт JSON с маркерами
  Future<void> _exportToJsonWithMarkers() async {
    final proxies = await ref.read(proxyListProvider.future);
    if (proxies.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет прокси для экспорта')),
        );
      }
      return;
    }
    
    final fileName = widget.fileName.trim();
    final customPath = widget.customPath;
    
    try {
      final filePath = await FileImportExportWithMarkersService.exportProxiesWithMarkersToJson(
        proxies,
        fileName: fileName.isEmpty ? null : fileName,
        customPath: customPath,
      );
      
      if (filePath != null && mounted) {
        final file = File(filePath);
        if (await file.exists()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Экспортировано в JSON с метками: $filePath'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Файл не создан. Проверьте права доступа к папке.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Ошибка при создании файла. Проверьте путь.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Экспорт TXT с метками
  Future<void> _exportToTxtWithMarkers() async {
   final proxies = await ref.read(proxyListProvider.future);
    if (proxies.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет прокси для экспорта')),
        );
      }
      return;
    }
    
    final fileName = widget.fileName.trim();
    final customPath = widget.customPath;
    
    try {
      final filePath = await FileImportExportWithMarkersService.exportProxiesWithMarkersToTxt(
        proxies,
        fileName: fileName.isEmpty ? null : fileName,
        customPath: customPath,
      );
      
      if (filePath != null && mounted) {
        // Проверяем, существует ли файл
        final file = File(filePath);
        if (await file.exists()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Экспортировано в TXT с метками: $filePath'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Файл не создан. Проверьте права доступа к папке.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Ошибка при создании файла. Проверьте путь.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Импорт JSON с маркерами
  Future<void> _importFromFileWithMarkers() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Выберите JSON файл с маркерами',
        withData: true,
      );
      
      if (result == null) return;
      
      final filePath = result.files.single.path;
      if (filePath == null) return;
      
      final importedProxies = await FileImportExportWithMarkersService.importProxiesWithMarkersFromPath(filePath);
      
      if (importedProxies.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Не найдено валидных прокси в файле')),
          );
        }
        return;
      }
      
      int added = 0;
      int duplicates = 0;
      
      for (final proxy in importedProxies) {
        final isAdded = await ref.read(proxyRepositoryProvider).addIfNotExists(proxy);
        if (isAdded) {
          added++;
        } else {
          duplicates++;
        }
      }
      
      ref.invalidate(proxyListProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Добавлено: $added (пропущено дубликатов: $duplicates)'),
            backgroundColor: added > 0 ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка при импорте: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Дополнительные способы',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Кнопка: Экспорт JSON с маркерами
        _buildMarkerActionButton(
          icon: Icons.save_alt,
          label: 'JSON (с метками)',
          color: Colors.purple,
          showWifiIcon: true,
          showMobileIcon: true,
          onTap: _exportToJsonWithMarkers,
        ),
        const SizedBox(height: 10),
        
        // Кнопка: Экспорт TXT с метками
        _buildMarkerActionButton(
          icon: Icons.save_alt,
          label: 'TXT (с метками)',
          color: Colors.purple,
          showWifiIcon: true,
          showMobileIcon: true,
          onTap: _exportToTxtWithMarkers,
        ),
        const SizedBox(height: 10),
        
        // Кнопка: Импорт JSON с маркерами
        _buildMarkerActionButton(
          icon: Icons.upload_file,
          label: 'Импорт JSON (с метками)',
          color: Colors.deepOrange,
          showWifiIcon: true,
          showMobileIcon: true,
          onTap: _importFromFileWithMarkers,
        ),
        const SizedBox(height: 16),
        
        // Кнопки копирования (с метками) - в один ряд
        Row(
          children: [
            _buildCopyButton(
              icon: Icons.copy,
              label: 'TXT (с метками)',
              color: Colors.purple,
              onTap: () => _copyToClipboardWithMarkers('txt'),
            ),
            const SizedBox(width: 12),
            _buildCopyButton(
              icon: Icons.copy,
              label: 'JSON (с метками)',
              color: Colors.purple,
              onTap: () => _copyToClipboardWithMarkers('json'),
            ),
          ],
        ),
      ],
    );
  }
}