import 'package:uuid/uuid.dart';
import 'proxy.dart';

class Socks5Proxy extends ProxyEntity {
  @override
  final String id;
  
  @override
  final ProxyType type = ProxyType.socks5;
  
  @override
  final String server;
  
  @override
  final int port;
  
  final String? username;
  final String? password;
  
  @override
  final String fullLink;
  
  @override
  ProxyStatus lastStatus;
  
  @override
  int? lastPing;
  
  @override
  final ProxyMarkers markers;

  Socks5Proxy({
    String? id,
    required this.server,
    required this.port,
    this.username,
    this.password,
    required this.fullLink,
    this.lastStatus = ProxyStatus.unknown,
    this.lastPing,
    ProxyMarkers? markers,
  }) : id = id ?? const Uuid().v4(),
       markers = markers ?? const ProxyMarkers();

  @override
  Socks5Proxy copyWith({
    ProxyStatus? lastStatus,
    int? lastPing,
    ProxyMarkers? markers,
  }) {
    return Socks5Proxy(
      id: id,
      server: server,
      port: port,
      username: username,
      password: password,
      fullLink: fullLink,
      lastStatus: lastStatus ?? this.lastStatus,
      lastPing: lastPing ?? this.lastPing,
      markers: markers ?? this.markers,
    );
  }
}