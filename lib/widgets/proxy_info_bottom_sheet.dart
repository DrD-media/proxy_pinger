import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/entities/proxy.dart';
import '../domain/entities/mtproto_proxy.dart';
import '../domain/entities/socks5_proxy.dart';
import 'markers_panel.dart';

void showProxyInfoBottomSheet({
  required BuildContext context,
  required ProxyEntity proxy,
  required Function(ProxyEntity) onUpdate,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                // Индикатор свайпа
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Информация о прокси
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок с общей кнопкой копирования
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                proxy.type == ProxyType.mtproto 
                                    ? Icons.security 
                                    : Icons.vpn_key,
                                size: 20,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                proxy.type == ProxyType.mtproto ? 'MTProto Proxy' : 'SOCKS5 Proxy',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // Общая кнопка копирования всех данных
                          GestureDetector(
                            onTap: () => _copyAllProxyData(context, proxy),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.copy_all, size: 14, color: Colors.blue.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Копировать всё',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      
                      // Сервер с кнопкой копирования
                      _buildInfoRowWithCopy(
                        context,
                        'Сервер',
                        proxy.server,
                        onCopy: () => _copyToClipboard(context, proxy.server, 'Сервер скопирован'),
                      ),
                      const SizedBox(height: 8),
                      
                      // Порт с кнопкой копирования
                      _buildInfoRowWithCopy(
                        context,
                        'Порт',
                        proxy.port.toString(),
                        onCopy: () => _copyToClipboard(context, proxy.port.toString(), 'Порт скопирован'),
                      ),
                      const SizedBox(height: 8),
                      
                      // MTProto специфичные поля
                      if (proxy is MtprotoProxy) ...[
                        _buildInfoRowWithCopy(
                          context,
                          'Ключ (secret)',
                          proxy.secret,
                          isSecret: true,
                          onCopy: () => _copyToClipboard(context, proxy.secret, 'Ключ скопирован'),
                        ),
                      ],
                      
                      // SOCKS5 специфичные поля
                      if (proxy is Socks5Proxy) ...[
                        if (proxy.username != null)
                          _buildInfoRowWithCopy(
                            context,
                            'Логин',
                            proxy.username!,
                            onCopy: () => _copyToClipboard(context, proxy.username!, 'Логин скопирован'),
                          ),
                        if (proxy.password != null)
                          _buildInfoRowWithCopy(
                            context,
                            'Пароль',
                            proxy.password!,
                            isSecret: true,
                            onCopy: () => _copyToClipboard(context, proxy.password!, 'Пароль скопирован'),
                          ),
                        if (proxy.username == null && proxy.password == null)
                          _buildInfoRowWithCopy(
                            context,
                            'Авторизация',
                            'Отсутствует',
                            onCopy: null,
                          ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Панель маркеров
                MarkersPanel(
                  markers: proxy.markers,
                  onChanged: (newMarkers) {
                    final updatedProxy = proxy.copyWith(markers: newMarkers);
                    onUpdate(updatedProxy);
                    setState(() {});
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Кнопка "Открыть в Telegram"
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.send, color: Colors.blue.shade700, size: 20),
                  ),
                  title: const Text('Открыть в Telegram'),
                  onTap: () => _openInTelegram(context, proxy.fullLink),
                ),
                
                // Кнопка копирования ссылки
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.link, color: Colors.blue.shade700, size: 20),
                  ),
                  title: const Text('Скопировать ссылку'),
                  onTap: () {
                    Navigator.pop(context);
                    _copyToClipboard(context, proxy.fullLink, 'Ссылка скопирована');
                  },
                ),
                
                // Кнопка поделиться
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.share, color: Colors.green.shade700, size: 20),
                  ),
                  title: const Text('Поделиться'),
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(proxy.fullLink);
                  },
                ),
                
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Копирование всех данных прокси
void _copyAllProxyData(BuildContext context, ProxyEntity proxy) {
  String allData = '';
  
  allData += 'Тип: ${proxy.type == ProxyType.mtproto ? 'MTProto' : 'SOCKS5'}\n';
  allData += 'Сервер: ${proxy.server}\n';
  allData += 'Порт: ${proxy.port}\n';
  
  if (proxy is MtprotoProxy) {
    allData += 'Ключ (secret): ${proxy.secret}\n';
  }
  
  if (proxy is Socks5Proxy) {
    if (proxy.username != null) {
      allData += 'Логин: ${proxy.username}\n';
    }
    if (proxy.password != null) {
      allData += 'Пароль: ${proxy.password}\n';
    }
    if (proxy.username == null && proxy.password == null) {
      allData += 'Авторизация: Отсутствует\n';
    }
  }
  
  allData += '\nСсылка: ${proxy.fullLink}';
  
  Clipboard.setData(ClipboardData(text: allData));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('📋 Все данные прокси скопированы'),
      duration: Duration(seconds: 2),
    ),
  );
}

/// Копирование в буфер обмена
void _copyToClipboard(BuildContext context, String text, String message) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('📋 $message'),
      duration: const Duration(seconds: 1),
    ),
  );
}

/// Строка с информацией и кнопкой копирования
Widget _buildInfoRowWithCopy(
  BuildContext context,
  String label,
  String value, {
  bool isSecret = false,
  VoidCallback? onCopy,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 90,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontFamily: isSecret ? 'monospace' : null,
            color: isSecret ? Colors.blue.shade800 : Colors.black87,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (onCopy != null)
        GestureDetector(
          onTap: onCopy,
          child: Container(
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.copy, size: 14, color: Colors.grey.shade600),
          ),
        ),
    ],
  );
}

void _openInTelegram(BuildContext context, String link) async {
  // Преобразуем https ссылку в tg://
  String tgLink = link;
  if (link.startsWith('https://t.me/proxy')) {
    tgLink = link.replaceFirst('https://t.me/proxy', 'tg://proxy');
  }
  
  final Uri url = Uri.parse(tgLink);
  
  // Проверяем, можно ли открыть ссылку
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    // Если не открывается, пробуем открыть через браузер
    final httpsUrl = Uri.parse(link);
    if (await canLaunchUrl(httpsUrl)) {
      await launchUrl(httpsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Не удалось открыть Telegram. Убедитесь, что Telegram установлен.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}