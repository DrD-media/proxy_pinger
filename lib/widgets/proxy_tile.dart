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
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: proxy.lastStatus == ProxyStatus.online 
            ? Colors.green 
            : (proxy.lastStatus == ProxyStatus.offline ? Colors.red : Colors.grey),
        radius: 8,
      ),
      title: Text(
        '${proxy.server}:${proxy.port}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MTProto secret
          if (proxy is MtprotoProxy)
            Text(
              _truncateSecret((proxy as MtprotoProxy).secret),
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          // SOCKS5 username
          if (proxy is Socks5Proxy && (proxy as Socks5Proxy).username != null)
            Text(
              'user: ${(proxy as Socks5Proxy).username}',
              style: const TextStyle(fontSize: 12),
            ),
          // Пинг
          Text(
            proxy.lastPing != null ? 'Пинг: ${proxy.lastPing} ms' : 'Не проверен',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: onShare,
      ),
    );
  }

  String _truncateSecret(String secret, {int maxLength = 30}) {
    if (secret.length <= maxLength) return secret;
    return '${secret.substring(0, maxLength)}...';
  }
}