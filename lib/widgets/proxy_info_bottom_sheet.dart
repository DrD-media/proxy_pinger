import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/entities/proxy.dart';
import '../domain/entities/mtproto_proxy.dart';
import '../domain/entities/socks5_proxy.dart';

void showProxyInfoBottomSheet({
  required BuildContext context,
  required ProxyEntity proxy,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
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
                // Заголовок
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
                const Divider(height: 24),
                
                // Сервер
                _buildInfoRow(context, 'Сервер', proxy.server),
                const SizedBox(height: 8),
                
                // Порт
                _buildInfoRow(context, 'Порт', proxy.port.toString()),
                const SizedBox(height: 8),
                
                // MTProto специфичные поля
                if (proxy is MtprotoProxy) ...[
                  _buildInfoRow(context, 'Ключ (secret)', proxy.secret, isSecret: true),
                ],
                
                // SOCKS5 специфичные поля
                if (proxy is Socks5Proxy) ...[
                  if (proxy.username != null)
                    _buildInfoRow(context, 'Логин', proxy.username!),
                  if (proxy.password != null)
                    _buildInfoRow(context, 'Пароль', proxy.password!, isSecret: true),
                  if (proxy.username == null && proxy.password == null)
                    _buildInfoRow(context, 'Авторизация', 'Отсутствует'),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Кнопка копирования
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.copy, color: Colors.blue.shade700, size: 20),
            ),
            title: const Text('Скопировать ссылку'),
            onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: proxy.fullLink));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 Ссылка скопирована в буфер обмена'),
                  duration: Duration(seconds: 2),
                ),
              );
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
}

Widget _buildInfoRow(BuildContext context, String label, String value, {bool isSecret = false}) {
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
      if (isSecret)
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📋 Скопировано'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(Icons.copy, size: 16, color: Colors.grey.shade500),
          ),
        ),
    ],
  );
}