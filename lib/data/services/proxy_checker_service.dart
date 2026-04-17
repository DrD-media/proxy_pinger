import 'dart:io';
import 'dart:typed_data';
import '../../domain/entities/proxy.dart';
import '../../domain/entities/socks5_proxy.dart';
import '../../domain/entities/mtproto_proxy.dart';

class ProxyCheckerService {
  static const _timeout = Duration(seconds: 3);
  static const _testHost = '1.1.1.1';
  static const _testPort = 443;
  
  static Future<List<ProxyEntity>> checkAllParallel(
    List<ProxyEntity> proxies,
  ) async {
    final futures = proxies.map((proxy) => _checkSingle(proxy));
    final results = await Future.wait(futures);
    return results;
  }
  
  static Future<ProxyEntity> _checkSingle(ProxyEntity proxy) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      bool isOnline = false;
      
      if (proxy is Socks5Proxy) {
        isOnline = await _checkSocks5(proxy);
      } else if (proxy is MtprotoProxy) {
        isOnline = await _checkTcpConnectivity(proxy.server, proxy.port);
      }
      
      stopwatch.stop();
      
      return proxy.copyWith(
        lastStatus: isOnline ? ProxyStatus.online : ProxyStatus.offline,
        lastPing: isOnline ? stopwatch.elapsedMilliseconds : null,
      );
    } catch (e) {
      stopwatch.stop();
      return proxy.copyWith(
        lastStatus: ProxyStatus.offline,
        lastPing: null,
      );
    }
  }
  
  static Future<bool> _checkSocks5(Socks5Proxy proxy) async {
    try {
      final socket = await Socket.connect(
        proxy.server, 
        proxy.port,
        timeout: _timeout,
      );
      
      final hasAuth = proxy.username != null && proxy.password != null;
      
      if (hasAuth) {
        socket.add(Uint8List.fromList([0x05, 0x01, 0x02]));
        await socket.flush();
        
        final response = await socket.timeout(_timeout).first;
        if (response[0] != 0x05 || response[1] != 0x02) {
          throw Exception('SOCKS5 auth method not supported');
        }
        
        final usernameBytes = Uint8List.fromList(proxy.username!.codeUnits);
        final passwordBytes = Uint8List.fromList(proxy.password!.codeUnits);
        
        final authPacket = Uint8List(3 + usernameBytes.length + passwordBytes.length);
        authPacket[0] = 0x01;
        authPacket[1] = usernameBytes.length;
        authPacket.setAll(2, usernameBytes);
        authPacket[2 + usernameBytes.length] = passwordBytes.length;
        authPacket.setAll(3 + usernameBytes.length, passwordBytes);
        
        socket.add(authPacket);
        await socket.flush();
        
        final authResponse = await socket.timeout(_timeout).first;
        if (authResponse[0] != 0x01 || authResponse[1] != 0x00) {
          throw Exception('SOCKS5 auth failed');
        }
      } else {
        socket.add(Uint8List.fromList([0x05, 0x01, 0x00]));
        await socket.flush();
        
        final response = await socket.timeout(_timeout).first;
        if (response[0] != 0x05 || response[1] != 0x00) {
          throw Exception('SOCKS5 handshake failed');
        }
      }
      
      final connectPacket = _buildSocks5ConnectPacket(_testHost, _testPort);
      socket.add(connectPacket);
      await socket.flush();
      
      final connectResponse = await socket.timeout(_timeout).first;
      final success = connectResponse[0] == 0x05 && connectResponse[1] == 0x00;
      
      await socket.close();
      return success;
    } catch (e) {
      return false;
    }
  }
  
  static Uint8List _buildSocks5ConnectPacket(String host, int port) {
    final hostBytes = Uint8List.fromList(host.codeUnits);
    final packet = Uint8List(6 + hostBytes.length);
    
    packet[0] = 0x05;
    packet[1] = 0x01;
    packet[2] = 0x00;
    packet[3] = 0x03;
    packet[4] = hostBytes.length;
    packet.setAll(5, hostBytes);
    packet[5 + hostBytes.length] = (port >> 8) & 0xFF;
    packet[6 + hostBytes.length] = port & 0xFF;
    
    return packet;
  }
  
  static Future<bool> _checkTcpConnectivity(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: _timeout);
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }
}