import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/link_parser_service.dart';
import '../providers/proxy_provider.dart';

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
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Добавить прокси', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          TextField(
            controller: _linkController,
            decoration: const InputDecoration(
              labelText: 'Вставьте ссылку tg://proxy или socks5://',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _addProxy,
            child: const Text('Добавить'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  void _addProxy() {
    final link = _linkController.text.trim();
    if (link.isEmpty) return;
    
    try {
      final proxy = LinkParserService.fromLink(link);
      ref.read(proxyRepositoryProvider).add(proxy);
      ref.invalidate(proxyListProvider);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Прокси добавлен')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }
}