import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/link_parser_service.dart';
import '../providers/proxy_provider.dart';
import 'add_proxy_manual_bottom_sheet.dart';
import '../services/file_import_export_service.dart';

class AddProxyBottomSheet extends ConsumerStatefulWidget {
  const AddProxyBottomSheet({super.key});

  @override
  ConsumerState<AddProxyBottomSheet> createState() => _AddProxyBottomSheetState();
}

class _AddProxyBottomSheetState extends ConsumerState<AddProxyBottomSheet> {
  final _linkController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.92,
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
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const TabBar(
                        indicatorColor: Colors.blue,
                        labelColor: Colors.blue,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(icon: Icon(Icons.folder), text: 'Файлом'),
                          Tab(icon: Icon(Icons.link), text: 'По ссылке'),
                          Tab(icon: Icon(Icons.edit_note), text: 'Вручную'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Вкладка: Файлом (экспорт/импорт)
                            _buildFileTab(),
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
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildFileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          // Экспорт в TXT
          _buildFileButton(
            icon: Icons.save_alt,
            color: Colors.green,
            title: 'Экспорт в TXT',
            subtitle: 'Сохранить список прокси в текстовый файл',
            onTap: () => _exportToTxt(),
          ),
          
          const SizedBox(height: 16),
          
          // Экспорт в JSON
          _buildFileButton(
            icon: Icons.save_alt,
            color: Colors.blue,
            title: 'Экспорт в JSON',
            subtitle: 'Сохранить список прокси в JSON формате',
            onTap: () => _exportToJson(),
          ),
          
          const SizedBox(height: 16),
          
          // Импорт из файла
          _buildFileButton(
            icon: Icons.upload_file,
            color: Colors.orange,
            title: 'Импорт из файла',
            subtitle: 'Загрузить прокси из TXT или JSON файла',
            onTap: () => _importFromFile(),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildFileButton({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _exportToTxt() async {
    final proxies = await ref.read(proxyListProvider.future);
    if (proxies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет прокси для экспорта')),
      );
      return;
    }
    
    final filePath = await FileImportExportService.exportProxies(proxies);
    if (filePath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Экспортировано в TXT: $filePath'),
          backgroundColor: Colors.green,
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
    
    final filePath = await FileImportExportService.exportProxiesToJson(proxies);
    if (filePath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Экспортировано в JSON: $filePath'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  Future<void> _importFromFile() async {
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
  
  Widget _buildLinkTab(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _linkController,
            decoration: const InputDecoration(
              labelText: 'Вставьте ссылку tg://proxy или socks5://',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            autofocus: false,
          ),
          const SizedBox(height: 24),
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