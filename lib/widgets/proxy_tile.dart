import 'package:flutter/material.dart';
import '../domain/entities/proxy.dart';
import '../domain/entities/mtproto_proxy.dart';
import '../domain/entities/socks5_proxy.dart';

class ProxyTile extends StatelessWidget {
  final ProxyEntity proxy;
  final VoidCallback onShare;

  const ProxyTile({super.key, required this.proxy, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onLongPress: onShare,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Статус индикатор (кружок)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStatusColor(),
                ),
              ),
              const SizedBox(width: 16),
              
              // Информация о прокси
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Сервер
                    Text(
                      proxy.server,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Порт
                    Text(
                      'Порт: ${proxy.port}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    // Secret (только для MTProto)
                    if (proxy is MtprotoProxy)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Ключ: ${_truncateSecret((proxy as MtprotoProxy).secret)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    
                    // Username (только для SOCKS5 с авторизацией)
                    if (proxy is Socks5Proxy && (proxy as Socks5Proxy).username != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Логин: ${(proxy as Socks5Proxy).username}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    
                    // Пароль (только для SOCKS5 с авторизацией)
                    if (proxy is Socks5Proxy && (proxy as Socks5Proxy).password != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Пароль: ${(proxy as Socks5Proxy).password}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 6),
                    
                    // Статус и тип прокси в одной строке
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            proxy.type.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Кнопка меню (три точки)
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: onShare,
                tooltip: 'Действия',
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getStatusColor() {
    switch (proxy.lastStatus) {
      case ProxyStatus.online:
        return Colors.green;
      case ProxyStatus.offline:
        return Colors.red;
      case ProxyStatus.unknown:
        return Colors.grey;
    }
  }
  
  String _getStatusText() {
    switch (proxy.lastStatus) {
      case ProxyStatus.online:
        return '✅ ${proxy.lastPing} ms';
      case ProxyStatus.offline:
        return '❌ Недоступен';
      case ProxyStatus.unknown:
        return '⏳ Не проверен';
    }
  }
  
  String _truncateSecret(String secret, {int maxLength = 20}) {
    if (secret.length <= maxLength) return secret;
    return '${secret.substring(0, maxLength)}...';
  }
}