import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';
import '../widgets/history_tile.dart';
import '../domain/entities/history_snapshot.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';
  
  @override
  Widget build(BuildContext context) {
    final snapshotsAsync = ref.watch(historyListProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вся история'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearAllHistory,
          ),
        ],
      ),
      body: snapshotsAsync.when(
        data: (snapshots) {
          var filtered = snapshots;
          if (_searchQuery.isNotEmpty) {
            filtered = snapshots.where((s) {
              final formattedDate = DateFormat('yyyy-MM-dd').format(s.timestamp);
              return formattedDate.contains(_searchQuery) ||
                  s.timestamp.toString().contains(_searchQuery);
            }).toList();
          }
          
          if (filtered.isEmpty) {
            return const Center(child: Text('Нет записей истории'));
          }
          
          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final snapshot = filtered[index];
              
              return Slidable(
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) => _deleteSnapshot(snapshot.id),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Удалить',
                    ),
                  ],
                ),
                child: HistoryTile(
                  snapshot: snapshot,
                  onTap: () => _showDetails(snapshot),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка: $err')),
      ),
    );
  }
  
  void _showSearch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск по дате'),
        content: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: const InputDecoration(
            hintText: 'ГГГГ-ММ-ДД',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить историю'),
        content: const Text('Все снимки истории будут удалены без возможности восстановления.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Очистить')),
        ],
      ),
    );
    
    if (confirmed == true) {
      await ref.read(historyRepositoryProvider).deleteAll();
      ref.invalidate(historyListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('История очищена')),
        );
      }
    }
  }
  
  Future<void> _deleteSnapshot(String id) async {
    await ref.read(historyRepositoryProvider).delete(id);
    ref.invalidate(historyListProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Снимок удален')),
      );
    }
  }
  
  void _showDetails(HistorySnapshot snapshot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Прокси от ${DateFormat('dd.MM.yyyy HH:mm').format(snapshot.timestamp)}'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: snapshot.proxiesJson.length,
            itemBuilder: (context, index) {
              final json = snapshot.proxiesJson[index];
              final isOnline = json.contains('"lastStatus":"online"');
              return ListTile(
                leading: Icon(
                  isOnline ? Icons.check_circle : Icons.cancel,
                  color: isOnline ? Colors.green : Colors.red,
                ),
                title: Text(json),
                dense: true,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}