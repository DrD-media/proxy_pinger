enum ProxyType { mtproto, socks5 }
enum ProxyStatus { unknown, online, offline }

abstract class ProxyEntity {
  String get id;
  ProxyType get type;
  String get server;
  int get port;
  String get fullLink;
  ProxyStatus get lastStatus;
  int? get lastPing;
  
  ProxyEntity copyWith({
    ProxyStatus? lastStatus,
    int? lastPing,
  });
}