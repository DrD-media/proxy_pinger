import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';
import '../widgets/history_tile.dart';
import '../domain/entities/history_snapshot.dart';

class OfflineScreen extends ConsumerWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotsAsync = ref.watch(historyListProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Недоступные прокси')),
      body: snapshotsAsync.when(
        data: (snapshots) {
          final filtered = snapshots.where((s) => s.offlineCount > 0).toList();
          
          if (filtered.isEmpty) {
            return const Center(child: Text('Нет недоступных прокси в истории'));
          }
          
          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return HistoryTile(
                snapshot: filtered[index],
                onTap: () => _showDetails(context, filtered[index]),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка: $err')),
      ),
    );
  }
  
  void _showDetails(BuildContext context, HistorySnapshot snapshot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Недоступные прокси от ${DateFormat('dd.MM.yyyy HH:mm').format(snapshot.timestamp)}'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: snapshot.proxiesJson.length,
            itemBuilder: (context, index) {
              final json = snapshot.proxiesJson[index];
              if (json.contains('"lastStatus":"offline"')) {
                return ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.red),
                  title: Text(json),
                  dense: true,
                );
              }
              return const SizedBox.shrink();
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