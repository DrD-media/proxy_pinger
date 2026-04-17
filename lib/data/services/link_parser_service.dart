import '../../domain/entities/mtproto_proxy.dart';
import '../../domain/entities/socks5_proxy.dart';
import '../../domain/entities/proxy.dart';

class LinkParserService {
  static ProxyEntity fromLink(String link) {
    // Случай 1: MTProto tg://proxy
    if (link.startsWith('tg://proxy')) {
      return _parseMtProtoFromTg(link);
    }
    
    // Случай 2: MTProto https://t.me/proxy
    if (link.contains('t.me/proxy') && link.contains('server=')) {
      return _parseMtProtoFromWeb(link);
    }
    
    // Случай 3: SOCKS5 socks5://user:pass@host:port
    if (link.startsWith('socks5://')) {
      return _parseSocks5FromUri(link);
    }
    
    // Случай 4: Кастомный SOCKS5 формат
    if (link.contains('socks') && link.contains('server=')) {
      return _parseSocks5FromCustom(link);
    }
    
    throw FormatException('Unsupported link format: $link');
  }
  
  static ProxyEntity _parseMtProtoFromTg(String link) {
    final uri = Uri.parse(link);
    final server = uri.queryParameters['server'];
    final portStr = uri.queryParameters['port'];
    final secret = uri.queryParameters['secret'];
    
    if (server == null || portStr == null || secret == null) {
      throw FormatException('Missing required fields for MTProto');
    }
    
    final port = int.tryParse(portStr);
    if (port == null) throw FormatException('Invalid port');
    
    return MtprotoProxy(
      server: server,
      port: port,
      secret: secret,
      fullLink: link,
    );
  }
  
  static ProxyEntity _parseMtProtoFromWeb(String link) {
    final uri = Uri.parse(link);
    return _parseMtProtoFromTg(uri.toString());
  }
  
  static ProxyEntity _parseSocks5FromUri(String link) {
    final uri = Uri.parse(link);
    final userInfo = uri.userInfo.split(':');
    final username = userInfo.length > 0 ? userInfo[0] : null;
    final password = userInfo.length > 1 ? userInfo[1] : null;
    
    return Socks5Proxy(
      server: uri.host,
      port: uri.port,
      username: username?.isNotEmpty == true ? username : null,
      password: password?.isNotEmpty == true ? password : null,
      fullLink: link,
    );
  }
  
  static ProxyEntity _parseSocks5FromCustom(String link) {
    final uri = Uri.parse(link);
    final server = uri.queryParameters['server'];
    final portStr = uri.queryParameters['port'];
    final username = uri.queryParameters['user'];
    final password = uri.queryParameters['pass'];
    
    if (server == null || portStr == null) {
      throw FormatException('Missing server or port for SOCKS5');
    }
    
    final port = int.tryParse(portStr);
    if (port == null) throw FormatException('Invalid port');
    
    return Socks5Proxy(
      server: server,
      port: port,
      username: username,
      password: password,
      fullLink: link,
    );
  }
}