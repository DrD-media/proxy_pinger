import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Добавлено для Clipboard
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/proxy_provider.dart';
import '../providers/history_provider.dart'; // Добавлено для historyRepositoryProvider
import '../providers/selection_provider.dart';
import '../data/services/proxy_checker_service.dart';
import '../data/services/link_parser_service.dart'; // Добавлено для LinkParserService
import '../widgets/proxy_tile.dart';
import '../widgets/add_proxy_bottom_sheet.dart';
import '../domain/entities/proxy.dart';

class MyProxiesScreen extends ConsumerStatefulWidget {
  const MyProxiesScreen({super.key});

  @override
  ConsumerState<MyProxiesScreen> createState() => _MyProxiesScreenState();
}

class _MyProxiesScreenState extends ConsumerState<MyProxiesScreen> {
  bool _isSelectionMode = false;
  final _linkController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final proxiesAsync = ref.watch(proxyListProvider);
    final selectedIds = ref.watch(selectedProxyIdsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? 'Выбрано ${selectedIds.length}' : 'Мои прокси'),
        actions: [
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.speed),
              onPressed: _startParallelCheck,
              tooltip: 'Быстрая проверка',
            ),
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () => setState(() => _isSelectionMode = true),
            ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
            ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _isSelectionMode = false);
                ref.read(selectedProxyIdsProvider.notifier).clear();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Секция добавления ссылки
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _linkController,
                    decoration: const InputDecoration(
                      labelText: 'Вставить ссылку tg://proxy или socks5://',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addProxyFromLink,
                ),
              ],
            ),
          ),
          // Список прокси
          Expanded(
            child: proxiesAsync.when(
              data: (proxies) {
                if (proxies.isEmpty) {
                  return const Center(child: Text('Нет прокси. Добавьте первую ссылку.'));
                }
                
                return ListView.builder(
                  itemCount: proxies.length,
                  itemBuilder: (context, index) {
                    final proxy = proxies[index];
                    final isSelected = selectedIds.contains(proxy.id);
                    
                    if (_isSelectionMode) {
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleSelection(proxy.id),
                        title: Text('${proxy.server}:${proxy.port}'),
                        subtitle: Text(proxy.type.name),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Ошибка: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBottomSheet(),
        child: const Icon(Icons.add),
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
        content: const Text('Вы уверены?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
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
          SnackBar(content: Text('Удалено ${selectedIds.length} прокси')),
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
        const SnackBar(content: Text('Проверка прокси...')),
      );
    }
    
    final updated = await ProxyCheckerService.checkAllParallel(proxies);
    
    for (final proxy in updated) {
      await ref.read(proxyRepositoryProvider).update(proxy);
    }
    
    await ref.read(historyRepositoryProvider).addSnapshot(updated);
    ref.invalidate(proxyListProvider);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Проверено ${updated.length} прокси')),
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
        const SnackBar(content: Text('Прокси добавлен')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }
  
  void _showAddBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddProxyBottomSheet(),
    );
  }
  
  void _showShareOptions(ProxyEntity proxy) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Скопировать ссылку'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: proxy.fullLink));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ссылка скопирована')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Поделиться'),
              onTap: () {
                Navigator.pop(context);
                Share.share(proxy.fullLink);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _deleteProxy(String id) async {
    await ref.read(proxyRepositoryProvider).delete(id);
    ref.invalidate(proxyListProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Прокси удален')),
      );
    }
  }
  
  void _editProxy(ProxyEntity proxy) {
    final controller = TextEditingController(text: proxy.fullLink);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать прокси'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Новая ссылка'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final newProxy = LinkParserService.fromLink(controller.text);
                await ref.read(proxyRepositoryProvider).delete(proxy.id);
                await ref.read(proxyRepositoryProvider).add(newProxy);
                ref.invalidate(proxyListProvider);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Прокси обновлен')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
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