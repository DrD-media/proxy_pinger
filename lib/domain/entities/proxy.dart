enum ProxyType { mtproto, socks5 }
enum ProxyStatus { unknown, online, offline }

// Маркеры прокси
class ProxyMarkers {
  final int wifi;      // 0=не выбран, 1=красный, 2=оранжевый, 3=зеленый
  final int mobile;    // 0=не выбран, 1=красный, 2=оранжевый, 3=зеленый
  final bool favorite; // true=желтая звезда, false=серая звезда

  const ProxyMarkers({
    this.wifi = 0,
    this.mobile = 0,
    this.favorite = false,
  });

  ProxyMarkers copyWith({
    int? wifi,
    int? mobile,
    bool? favorite,
  }) {
    return ProxyMarkers(
      wifi: wifi ?? this.wifi,
      mobile: mobile ?? this.mobile,
      favorite: favorite ?? this.favorite,
    );
  }

  Map<String, dynamic> toJson() => {
    'wifi': wifi,
    'mobile': mobile,
    'favorite': favorite,
  };

  factory ProxyMarkers.fromJson(Map<String, dynamic> json) => ProxyMarkers(
    wifi: json['wifi'] is int ? json['wifi'] : 0,
    mobile: json['mobile'] is int ? json['mobile'] : 0,
    favorite: json['favorite'] is bool ? json['favorite'] : false,
  );
}

abstract class ProxyEntity {
  String get id;
  ProxyType get type;
  String get server;
  int get port;
  String get fullLink;
  ProxyStatus get lastStatus;
  int? get lastPing;
  ProxyMarkers get markers;
  
  ProxyEntity copyWith({
    ProxyStatus? lastStatus,
    int? lastPing,
    ProxyMarkers? markers,
  });
}