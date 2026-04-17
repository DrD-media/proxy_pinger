import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/proxy_provider.dart';
import '../providers/history_provider.dart';
import '../providers/selection_provider.dart';
import '../data/services/proxy_checker_service.dart';
import '../data/services/link_parser_service.dart';
import '../widgets/proxy_tile.dart';
import '../widgets/add_proxy_bottom_sheet.dart';
import '../domain/entities/proxy.dart';
import '../widgets/proxy_info_bottom_sheet.dart';
import '../services/file_import_export_service.dart';

class MyProxiesScreen extends ConsumerStatefulWidget {
  const MyProxiesScreen({super.key});

  @override
  ConsumerState<MyProxiesScreen> createState() => _MyProxiesScreenState();
}

class _MyProxiesScreenState extends ConsumerState<MyProxiesScreen> {
  String _currentCheckMode = 'parallel'; // 'parallel' или 'sequential'
  bool _isSelectionMode = false;
  final _linkController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final proxiesAsync = ref.watch(proxyListProvider);
    final selectedIds = ref.watch(selectedProxyIdsProvider);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_isSelectionMode ? 'Выбрано ${selectedIds.length}' : 'Мои прокси'),
        centerTitle: false,
        elevation: 0,
        actions: [
          if (!_isSelectionMode)
            // 1. Кнопка выбора режима проверки (только иконка)
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  _currentCheckMode = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Режим проверки: ${value == 'parallel' ? '⚡ Быстрая (параллельная)' : '🔄 Обычная (последовательная)'}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(
                _currentCheckMode == 'parallel' ? Icons.speed : Icons.timer,
                color: _currentCheckMode == 'parallel' ? Colors.green : Colors.orange,
              ),
              tooltip: _currentCheckMode == 'parallel' ? 'Режим: быстрая проверка' : 'Режим: обычная проверка',
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'parallel',
                  child: SizedBox(
                    width: 200,
                    child: Row(
                      children: [
                        Icon(Icons.speed, color: Colors.green),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('⚡ Быстрая проверка'),
                              Text(
                                'Параллельная - все прокси сразу',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'sequential',
                  child: SizedBox(
                    width: 200,
                    child: Row(
                      children: [
                        Icon(Icons.timer, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('🔄 Обычная проверка'),
                              Text(
                                'Последовательная - по одному',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          if (!_isSelectionMode)
            // 2. Кнопка запуска проверки
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: _startCheckWithCurrentMode,
              tooltip: 'Запустить проверку',
              color: Colors.green,
            ),
          if (!_isSelectionMode)
            // 3. Кнопка выбора режима множественного удаления
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () => setState(() => _isSelectionMode = true),
              tooltip: 'Выбрать несколько',
            ),
          if (!_isSelectionMode)
            // 4. Кнопка меню (экспорт/импорт)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'export') {
                  await _exportProxies();
                } else if (value == 'export_json') {
                  await _exportProxiesToJson();
                } else if (value == 'import') {
                  await _importProxies();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.save_alt, size: 20),
                      SizedBox(width: 12),
                      Text('Экспорт в TXT'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_json',
                  child: Row(
                    children: [
                      Icon(Icons.save_alt, size: 20),
                      SizedBox(width: 12),
                      Text('Экспорт в JSON'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.upload_file, size: 20),
                      SizedBox(width: 12),
                      Text('Импорт из файла'),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert),
              tooltip: 'Меню',
            ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
              tooltip: 'Удалить выбранные',
            ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _isSelectionMode = false);
                ref.read(selectedProxyIdsProvider.notifier).clear();
              },
              tooltip: 'Отмена',
            ),
        ],
      ),
      body: Column(
        children: [
          // Секция добавления ссылки
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        hintText: 'Вставить ссылку tg://proxy или socks5://',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addProxyFromLink,
                  ),
                ),
              ],
            ),
          ),
          
          // Список прокси
          Expanded(
            child: proxiesAsync.when(
              data: (proxies) {
                if (proxies.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет прокси',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Добавьте первую ссылку выше',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: proxies.length,
                  itemBuilder: (context, index) {
                    final proxy = proxies[index];
                    final isSelected = selectedIds.contains(proxy.id);
                    
                    if (_isSelectionMode) {
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (_) => _toggleSelection(proxy.id),
                          title: Text(proxy.server),
                          subtitle: Text('Порт: ${proxy.port}'),
                          secondary: Text(proxy.type.name),
                        ),
                      );
                    }
                    
                    return Slidable(
                      key: ValueKey(proxy.id),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) => _deleteProxy(proxy.id),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Удалить',
                          ),
                        ],
                      ),
                      startActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) => _editProxy(proxy),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            icon: Icons.edit,
                            label: 'Изменить',
                          ),
                        ],
                      ),
                      child: ProxyTile(
                        proxy: proxy,
                        onShare: () => _showShareOptions(proxy),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Загрузка прокси...'),
                  ],
                ),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text('Ошибка: $err'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBottomSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Добавить прокси'),
        elevation: 2,
      ),
    );
  }
  
  void _toggleSelection(String id) {
    final notifier = ref.read(selectedProxyIdsProvider.notifier);
    if (ref.read(selectedProxyIdsProvider).contains(id)) {
      notifier.remove(id);
    } else {
      notifier.add(id);
    }
  }
  
  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить выбранные'),
        content: const Text('Вы уверены, что хотите удалить выбранные прокси?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      final selectedIds = ref.read(selectedProxyIdsProvider);
      for (final id in selectedIds) {
        await ref.read(proxyRepositoryProvider).delete(id);
      }
      ref.invalidate(proxyListProvider);
      ref.read(selectedProxyIdsProvider.notifier).clear();
      setState(() => _isSelectionMode = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Удалено ${selectedIds.length} прокси'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  
  Future<void> _startParallelCheck() async {
    final proxies = await ref.read(proxyListProvider.future);
    if (proxies.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет прокси для проверки')),
        );
      }
      return;
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚀 Быстрая проверка прокси...')),
      );
    }
    
    final updated = await ProxyCheckerService.checkAllParallel(proxies);
    
    for (final proxy in updated) {
      await ref.read(proxyRepositoryProvider).update(proxy);
    }
    
    await ref.read(historyRepositoryProvider).addSnapshot(updated);
    ref.invalidate(proxyListProvider);
    
    if (mounted) {
      final onlineCount = updated.where((p) => p.lastStatus == ProxyStatus.online).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Проверено ${updated.length} прокси. Доступно: $onlineCount'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  Future<void> _startSequentialCheck() async {
    final proxies = await ref.read(proxyListProvider.future);
    if (proxies.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет прокси для проверки')),
        );
      }
      return;
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔄 Последовательная проверка прокси...')),
      );
    }
    
    final List<ProxyEntity> updated = [];
    for (final proxy in proxies) {
      final result = await ProxyCheckerService.checkAllParallel([proxy]);
      updated.add(result.first);
      await ref.read(proxyRepositoryProvider).update(result.first);
      
      if (mounted) {
        // Обновляем UI постепенно
        ref.invalidate(proxyListProvider);
      }
    }
    
    await ref.read(historyRepositoryProvider).addSnapshot(updated);
    ref.invalidate(proxyListProvider);
    
    if (mounted) {
      final onlineCount = updated.where((p) => p.lastStatus == ProxyStatus.online).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Проверено ${updated.length} прокси. Доступно: $onlineCount'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _startCheckWithCurrentMode() async {
    if (_currentCheckMode == 'parallel') {
      await _startParallelCheck();
    } else {
      await _startSequentialCheck();
    }
  }

  Future<void> _exportProxies() async {
    final proxies = await ref.read(proxyListProvider.future);
    if (proxies.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет прокси для экспорта')),
        );
      }
      return;
    }
    
    final filePath = await FileImportExportService.exportProxies(proxies);
    if (filePath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Экспортировано в: $filePath'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Ошибка при экспорте'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportProxiesToJson() async {
    final proxies = await ref.read(proxyListProvider.future);
    if (proxies.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет прокси для экспорта')),
        );
      }
      return;
    }
    
    final filePath = await FileImportExportService.exportProxiesToJson(proxies);
    if (filePath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Экспортировано в JSON: $filePath'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Ошибка при экспорте'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importProxies() async {
    final importedProxies = await FileImportExportService.importProxies();
    
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
      await ref.read(proxyRepositoryProvider).add(proxy);
      added++;
    }
    
    ref.invalidate(proxyListProvider);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Импортировано $added прокси'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  void _addProxyFromLink() {
    final link = _linkController.text.trim();
    if (link.isEmpty) return;
    
    try {
      final proxy = LinkParserService.fromLink(link);
      ref.read(proxyRepositoryProvider).add(proxy);
      ref.invalidate(proxyListProvider);
      _linkController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Прокси добавлен'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showAddBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddProxyBottomSheet(),
    );
  }
  
  void _showShareOptions(ProxyEntity proxy) {
    showProxyInfoBottomSheet(context: context, proxy: proxy);
  }
  
  Future<void> _deleteProxy(String id) async {
    await ref.read(proxyRepositoryProvider).delete(id);
    ref.invalidate(proxyListProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Прокси удален'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
  
  void _editProxy(ProxyEntity proxy) {
    final controller = TextEditingController(text: proxy.fullLink);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Редактировать прокси'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Новая ссылка',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final newProxy = LinkParserService.fromLink(controller.text);
                await ref.read(proxyRepositoryProvider).delete(proxy.id);
                await ref.read(proxyRepositoryProvider).add(newProxy);
                ref.invalidate(proxyListProvider);
                if (mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Прокси обновлен')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}