import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sort_provider.dart';

Future<void> showSortDialog(BuildContext context, WidgetRef ref) {
  return showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.filter_list, size: 24),
          SizedBox(width: 8),
          Text('Сортировка'),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(sortProvider);
          return SizedBox(
            width: 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Вариант 1: Без сортировки
                _buildSortOption(
                  ref: ref,
                  isSelected: state.sortMode == SortMode.none,
                  onTap: () {
                    ref.read(sortProvider.notifier).setSortMode(SortMode.none);
                    ref.read(sortProvider.notifier).setGroupByStatus(false);
                    Navigator.pop(dialogContext);
                  },
                  title: 'Без сортировки',
                  subtitle: 'Порядок добавления',
                ),
                
                const SizedBox(height: 8),
                
                // Вариант 2: Умная сортировка
                _buildSortOption(
                  ref: ref,
                  isSelected: state.sortMode == SortMode.smart,
                  onTap: () {
                    ref.read(sortProvider.notifier).setSortMode(SortMode.smart);
                    ref.read(sortProvider.notifier).setGroupByStatus(true);
                    Navigator.pop(dialogContext);
                  },
                  title: 'Умная сортировка',
                  subtitle: 'Unknown → Online (по пингу ↑) → Offline',
                ),
                
                const SizedBox(height: 24),
                
                // Кнопка сброса
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(sortProvider.notifier).reset();
                      Navigator.pop(dialogContext);
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Сбросить сортировку'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Закрыть'),
        ),
      ],
    ),
  );
}

Widget _buildSortOption({
  required WidgetRef ref,
  required bool isSelected,
  required VoidCallback onTap,
  required String title,
  required String subtitle,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Кастомная радиокнопка
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.blue : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}