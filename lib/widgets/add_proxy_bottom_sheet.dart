import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/link_parser_service.dart';
import '../providers/proxy_provider.dart';
import 'add_proxy_manual_bottom_sheet.dart';

class AddProxyBottomSheet extends ConsumerStatefulWidget {
  const AddProxyBottomSheet({super.key});

  @override
  ConsumerState<AddProxyBottomSheet> createState() => _AddProxyBottomSheetState();
}

class _AddProxyBottomSheetState extends ConsumerState<AddProxyBottomSheet> {
  final _linkController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(
            child: Text(
              'Добавить прокси',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          
          // Вкладки (TabBar)
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  indicatorColor: Colors.blue,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(icon: Icon(Icons.link), text: 'По ссылке'),
                    Tab(icon: Icon(Icons.edit_note), text: 'Вручную'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 320,  // ← ТОЛЬКО ЭТО ИЗМЕНЕНО (было 250, стало 320)
                  child: TabBarView(
                    children: [
                      // Вкладка: По ссылке
                      _buildLinkTab(),
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
  }
  
  Widget _buildLinkTab() {
    return Column(
      children: [
        TextField(
          controller: _linkController,
          decoration: const InputDecoration(
            labelText: 'Вставьте ссылку tg://proxy или socks5://',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _addProxyFromLink,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('Добавить'),
        ),
      ],
    );
  }
  
  void _addProxyFromLink() {
    final link = _linkController.text.trim();
    if (link.isEmpty) return;
    
    try {
      final proxy = LinkParserService.fromLink(link);
      ref.read(proxyRepositoryProvider).add(proxy);
      ref.invalidate(proxyListProvider);
      Navigator.pop(context);
      
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
}