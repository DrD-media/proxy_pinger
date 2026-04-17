import 'package:uuid/uuid.dart';
import 'proxy.dart';

class MtprotoProxy extends ProxyEntity {
  @override
  final String id;
  
  @override
  final ProxyType type = ProxyType.mtproto;
  
  @override
  final String server;
  
  @override
  final int port;
  
  final String secret;
  
  @override
  final String fullLink;
  
  @override
  ProxyStatus lastStatus;
  
  @override
  int? lastPing;

  MtprotoProxy({
    String? id,
    required this.server,
    required this.port,
    required this.secret,
    required this.fullLink,
    this.lastStatus = ProxyStatus.unknown,
    this.lastPing,
  }) : id = id ?? const Uuid().v4();

  @override
  MtprotoProxy copyWith({
    ProxyStatus? lastStatus,
    int? lastPing,
  }) {
    return MtprotoProxy(
      id: id,
      server: server,
      port: port,
      secret: secret,
      fullLink: fullLink,
      lastStatus: lastStatus ?? this.lastStatus,
      lastPing: lastPing ?? this.lastPing,
    );
  }
}