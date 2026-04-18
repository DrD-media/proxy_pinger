import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/mtproto_proxy.dart';
import '../domain/entities/socks5_proxy.dart';
import '../domain/entities/proxy.dart';
import '../providers/proxy_provider.dart';

class AddProxyManualBottomSheet extends ConsumerStatefulWidget {
  const AddProxyManualBottomSheet({super.key});

  @override
  ConsumerState<AddProxyManualBottomSheet> createState() => _AddProxyManualBottomSheetState();
}

class _AddProxyManualBottomSheetState extends ConsumerState<AddProxyManualBottomSheet> {
  ProxyType _selectedType = ProxyType.mtproto;
  
  final _serverController = TextEditingController();
  final _portController = TextEditingController();
  final _secretController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Переключатель типа
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypeSelector(ProxyType.mtproto, 'MTProto', Icons.security),
                    const SizedBox(width: 8),
                    _buildTypeSelector(ProxyType.socks5, 'SOCKS5', Icons.vpn_key),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Поле Сервер
            TextFormField(
              controller: _serverController,
              decoration: const InputDecoration(
                labelText: 'Сервер (IP или домен)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.dns),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите сервер';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Поле Порт
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Порт',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings_ethernet),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите порт';
                }
                final port = int.tryParse(value);
                if (port == null || port < 1 || port > 65535) {
                  return 'Введите корректный порт (1-65535)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Динамические поля
            if (_selectedType == ProxyType.mtproto) ...[
              _buildSecretField(),
            ] else ...[
              _buildSocks5Fields(),
            ],
            
            const SizedBox(height: 32),
            
            // Кнопки
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addProxy,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Добавить'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTypeSelector(ProxyType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSecretField() {
    return TextFormField(
      controller: _secretController,
      decoration: const InputDecoration(
        labelText: 'Secret ключ (hex)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.key),
        helperText: 'Hex-строка, например: eefd4933b3863b668128a246b6cb22...',
      ),
      maxLines: 2,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Введите secret ключ';
        }
        if (!RegExp(r'^[a-fA-F0-9]+$').hasMatch(value)) {
          return 'Secret должен быть hex-строкой (0-9, A-F)';
        }
        return null;
      },
    );
  }
  
  Widget _buildSocks5Fields() {
    return Column(
      children: [
        TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Логин (опционально)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Пароль (опционально)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
        ),
      ],
    );
  }
  
  void _addProxy() {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final server = _serverController.text.trim();
      final port = int.parse(_portController.text.trim());
      ProxyEntity proxy;
      
      if (_selectedType == ProxyType.mtproto) {
        final secret = _secretController.text.trim();
        final fullLink = 'tg://proxy?server=$server&port=$port&secret=$secret';
        
        proxy = MtprotoProxy(
          server: server,
          port: port,
          secret: secret,
          fullLink: fullLink,
        );
      } else {
        final username = _usernameController.text.trim().isEmpty 
            ? null 
            : _usernameController.text.trim();
        final password = _passwordController.text.trim().isEmpty 
            ? null 
            : _passwordController.text.trim();
        
        String fullLink;
        if (username != null && password != null) {
          fullLink = 'socks5://$username:$password@$server:$port';
        } else {
          fullLink = 'socks5://$server:$port';
        }
        
        proxy = Socks5Proxy(
          server: server,
          port: port,
          username: username,
          password: password,
          fullLink: fullLink,
        );
      }
      
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