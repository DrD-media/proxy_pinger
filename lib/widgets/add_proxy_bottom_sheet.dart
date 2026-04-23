import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../data/services/link_parser_service.dart';
import '../services/file_import_export_service.dart';
import '../providers/proxy_provider.dart';
import 'add_proxy_manual_bottom_sheet.dart';

import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/entities/mtproto_proxy.dart';
import '../domain/entities/socks5_proxy.dart';
import 'advanced_file_actions.dart';

class AddProxyBottomSheet extends ConsumerStatefulWidget {
  const AddProxyBottomSheet({super.key});

  @override
  ConsumerState<AddProxyBottomSheet> createState() => _AddProxyBottomSheetState();
}

class _AddProxyBottomSheetState extends ConsumerState<AddProxyBottomSheet> with SingleTickerProviderStateMixin {
  final _linkController = TextEditingController();
  bool _isSingleMode = true; // true = одна ссылка, false = несколько ссылок
  late final TabController _tabController;
  
  // Контроллеры для экспорта
  final _fileNameController = TextEditingController();
  final _filePathController = TextEditingController();
  String _selectedPlatform = 'android'; // 'android' или 'windows'
  
  @override
  void initState() {
    super.initState();
    // Устанавливаем дефолтное название
    _fileNameController.text = 'proxy_backup';
    // Устанавливаем дефолтный путь (пусть будет пустым - будем использовать Downloads)
    _filePathController.text = '';
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1); 
  }
  
  @override
  void dispose() {
    _fileNameController.dispose();
    _filePathController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95, // было 0.75, теперь почти на весь экран
      minChildSize: 0.75,     // было 0.55
      maxChildSize: 0.95,     // было 0.92
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Индикатор свайпа
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Добавить прокси',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              // Вкладки (TabBar)
              Expanded(
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.blue,
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(icon: Icon(Icons.folder), text: 'Файлом'),
                        Tab(icon: Icon(Icons.link), text: 'По ссылке'),
                        Tab(icon: Icon(Icons.edit_note), text: 'Вручную'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Вкладка: Файлом
                          SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            child: _buildFileTab(),
                          ),
                          // Вкладка: По ссылке
                          _buildLinkTab(scrollController),
                          // Вкладка: Вручную
                          const AddProxyManualBottomSheet(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Поле "Название файла"
        TextField(
          controller: _fileNameController,
          decoration: const InputDecoration(
            labelText: 'Название файла',
            hintText: 'proxy_backup',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            helperText: 'Без расширения (добавится автоматически)',
          ),
        ),
        const SizedBox(height: 16),
        
        // Переключатель платформы (Android / Windows)
        Row(
          children: [
            const Text(
              'Платформа:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 16),
            _buildPlatformSelector(
              value: 'android',
              label: 'Android',
              icon: Icons.android,
              defaultPath: '/storage/emulated/0/Download',
            ),
            const SizedBox(width: 12),
            _buildPlatformSelector(
              value: 'windows',
              label: 'Windows',
              icon: Icons.computer,
              defaultPath: r'C:\Users\Ефим\Downloads',
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Поле "Путь для сохранения" с кнопкой выбора
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _filePathController,
                decoration: const InputDecoration(
                  labelText: 'Путь для сохранения',
                  hintText: 'Не указан (будет использована папка Downloads)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: _selectDirectory,
              tooltip: 'Выбрать папку',
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Кнопки экспорта/импорта
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.save_alt,
                label: 'TXT',
                color: Colors.green,
                onTap: () => _exportToTxt(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.save_alt,
                label: 'JSON',
                color: Colors.blue,
                onTap: () => _exportToJson(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.upload_file,
                label: 'Импорт',
                color: Colors.orange,
                onTap: _importFromFile,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Кнопки копирования в буфер обмена (без меток)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCopyButton(
              icon: Icons.copy,
              label: 'TXT',
              color: Colors.teal,
              onTap: () => _copyToClipboard('txt'),
            ),
            const SizedBox(width: 24),
            _buildCopyButton(
              icon: Icons.copy,
              label: 'JSON',
              color: Colors.teal,
              onTap: () => _copyToClipboard('json'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Информационная строка
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Импорт поддерживает TXT и JSON форматы',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        // Блок "Дополнительные способы" (с метками)
        AdvancedFileActions(
          fileName: _fileNameController.text,
          customPath: _filePathController.text.trim().isEmpty ? null : _filePathController.text.trim(),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCopyButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  void _copyToClipboard(String type) async {
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
      // TXT: только ссылки
      content = proxies.map((p) => p.fullLink).join('\n');
    } else if (type == 'json') {
      // JSON без маркеров
      final jsonList = proxies.map((p) {
        final Map<String, dynamic> map = {
          'server': p.server,
          'port': p.port,
          'type': p.type.name,
          'fullLink': p.fullLink,
        };
        if (p is MtprotoProxy) {
          map['secret'] = p.secret;
        }
        if (p is Socks5Proxy) {
          if (p.username != null) map['username'] = p.username!;
          if (p.password != null) map['password'] = p.password!;
        }
        return map;
      }).toList();
      content = const JsonEncoder.withIndent('  ').convert(jsonList);
    }
    
    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📋 Скопировано в буфер обмена (${type.toUpperCase()})'),
          backgroundColor: Colors.teal,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  Widget _buildPlatformSelector({
    required String value,
    required String label,
    required IconData icon,
    required String defaultPath,
  }) {
    final isSelected = _selectedPlatform == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlatform = value;
          _setDefaultPath(value, defaultPath);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _setDefaultPath(String platform, String defaultPath) {
    // Если пользователь уже ввел свой путь, не перезаписываем
    if (_filePathController.text.trim().isNotEmpty) {
      // Спрашиваем, хочет ли он заменить путь
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Заменить путь?'),
          content: Text('Вы уже указали путь: ${_filePathController.text}\n\nЗаменить на стандартный путь для $platform?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Нет'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _filePathController.text = defaultPath;
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Да'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _filePathController.text = defaultPath;
      });
    }
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
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
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
  
  Future<void> _selectDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _filePathController.text = selectedDirectory;
      });
    }
  }
  
  Future<void> _exportToTxt() async {
    final proxies = await ref.read(proxyListProvider.future);
    if (proxies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет прокси для экспорта')),
      );
      return;
    }
    
    final fileName = _fileNameController.text.trim();
    final customPath = _filePathController.text.trim().isEmpty ? null : _filePathController.text.trim();
    
    final filePath = await FileImportExportService.exportProxies(
      proxies,
      fileName: fileName.isEmpty ? null : fileName,
      customPath: customPath,
    );
    
    if (filePath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Экспортировано в TXT: $filePath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  Future<void> _exportToJson() async {
    final proxies = await ref.read(proxyListProvider.future);
    if (proxies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет прокси для экспорта')),
      );
      return;
    }
    
    final fileName = _fileNameController.text.trim();
    final customPath = _filePathController.text.trim().isEmpty ? null : _filePathController.text.trim();
    
    final filePath = await FileImportExportService.exportProxiesToJson(
      proxies,
      fileName: fileName.isEmpty ? null : fileName,
      customPath: customPath,
    );
    
    if (filePath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Экспортировано в JSON: $filePath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  Future<void> _importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,  // ← Добавлено: обязательно для allowedExtensions
        allowedExtensions: ['txt', 'json'],
        dialogTitle: 'Выберите файл с прокси',
        withData: true, // Важно для Android
      );
      
      if (result == null) return;
      
      final filePath = result.files.single.path;
      if (filePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Не удалось получить путь к файлу')),
          );
        }
        return;
      }
      
      final importedProxies = await FileImportExportService.importProxiesFromPath(filePath);
      
      if (importedProxies.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Не найдено валидных прокси в файле')),
          );
        }
        return;
      }
      
      int added = 0;
      for (final proxy in importedProxies) {
        final isAdded = await ref.read(proxyRepositoryProvider).addIfNotExists(proxy);
        if (isAdded) added++;
      }
      
      ref.invalidate(proxyListProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Импортировано $added новых прокси (пропущено ${importedProxies.length - added} дубликатов)'),
            backgroundColor: Colors.green,
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
  
  Widget _buildLinkTab(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Переключатели режимов вставки
          Container(
            width: double.infinity,  // ← ДОБАВЛЕНО, чтобы контейнер занял всю ширину
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(  // ← ВМЕСТО Flexible, чтобы кнопки были одинаковой ширины
                  child: _buildInsertModeSelector(
                    label: 'Вставить одну',
                    isSelected: _isSingleMode,
                    onTap: () => setState(() {
                      _isSingleMode = true;
                      _linkController.clear();
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: _buildInsertModeSelector(
                    label: 'Вставить несколько',
                    isSelected: !_isSingleMode,
                    onTap: () => setState(() {
                      _isSingleMode = false;
                      _linkController.clear();
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Динамическое текстовое поле
          TextField(
            controller: _linkController,
            decoration: InputDecoration(
              labelText: _isSingleMode 
                  ? 'Вставьте ссылку tg://proxy или socks5://'
                  : 'Вставьте ссылки (каждая с новой строки)',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: _isSingleMode ? 1 : 11,  // 1 : 9
            minLines: _isSingleMode ? 1 : 10,  // 1 : 3
            autofocus: false,
          ),
          const SizedBox(height: 24),
          
          // Кнопка добавления
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _addProxyFromLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Добавить'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

    Widget _buildInsertModeSelector({
      required String label,
      required bool isSelected,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),  // уменьшены отступы horizontal: 16, vertical: 8
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                fontSize: 13, // чуть меньше шрифт
              ),
            ),
          ),
        ),
      );
    }

    void _addProxyFromLink() async {
      final text = _linkController.text.trim();
      if (text.isEmpty) return;
      
      List<String> links = [];
      
      if (_isSingleMode) {
        // Режим одной ссылки
        links = [text];
      } else {
        // Режим нескольких ссылок - разделяем по строкам
        links = text.split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
      }
      
      if (links.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Не найдено ссылок для добавления'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      int added = 0;
      int invalid = 0;
      int duplicates = 0;
      
      for (final link in links) {
        try {
          final proxy = LinkParserService.fromLink(link);
          final isAdded = await ref.read(proxyRepositoryProvider).addIfNotExists(proxy);
          
          if (isAdded) {
            added++;
          } else {
            duplicates++;
          }
        } catch (e) {
          invalid++;
        }
      }
      
      // Обновляем список и очищаем поле
      if (added > 0) {
        ref.invalidate(proxyListProvider);
        _linkController.clear();
      }
      
      if (mounted) {
        String message = '';
        if (added > 0) message += '✅ Добавлено: $added';
        if (invalid > 0) message += '\n⚠️ Невалидных: $invalid';
        if (duplicates > 0) message += '\n📋 Дубликатов: $duplicates';

        // Определяем цвет в зависимости от результата
        Color backgroundColor;
        if (added > 0 && invalid == 0 && duplicates == 0) {
          backgroundColor = Colors.green;
        } else if (added > 0 && (invalid > 0 || duplicates > 0)) {
          backgroundColor = Colors.orange; // Частичный успех
        } else if (duplicates > 0 && added == 0 && invalid == 0) {
          backgroundColor = Colors.orange; // Только дубликаты
        } else {
          backgroundColor = Colors.red; // Только ошибки
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Если ничего не добавлено, закрываем окно только если была одна ссылка и она невалидна
        if (added == 0 && _isSingleMode) {
          Navigator.pop(context);
        }
      }
    }
}