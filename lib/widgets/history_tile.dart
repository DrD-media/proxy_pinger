import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/entities/history_snapshot.dart';

class HistoryTile extends StatelessWidget {
  final HistorySnapshot snapshot;
  final VoidCallback onTap;
  
  const HistoryTile({
    super.key,
    required this.snapshot,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        DateFormat('dd MMM yyyy, HH:mm:ss').format(snapshot.timestamp),
      ),
      subtitle: Text(
        'Всего: ${snapshot.totalCount}, '
        'Доступно: ${snapshot.onlineCount}, '
        'Недоступно: ${snapshot.offlineCount}',
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}