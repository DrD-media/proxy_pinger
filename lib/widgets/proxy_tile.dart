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
    final markers = proxy.markers;
    
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
                    // Сервер + иконка избранного
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            proxy.server,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (markers.favorite)
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                      ],
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
                    
                    // Статус, тип прокси и маркеры в одной строке
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
                        const SizedBox(width: 4),   // уменьшено с 8
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            proxy.type.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.75,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),  // добавлено вместо Spacer
                        // Маркеры (только если выбран не серый)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (markers.wifi > 0 && markers.wifi != 5)
                                _buildMarkerIcon(Icons.wifi, _getMarkerColor(markers.wifi)),
                              if (markers.mobile > 0 && markers.mobile != 5)
                                _buildMarkerIcon(Icons.import_export, _getMarkerColor(markers.mobile)),
                            ],
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
  
  Widget _buildMarkerIcon(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Icon(icon, size: 14, color: color),
    );
  }
  
  Color _getMarkerColor(int value) {
    switch (value) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.amber;      // желтый
      case 4: return Colors.green;
      default: return Colors.grey;
    }
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