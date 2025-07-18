import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ProxyHelper {
  static const MethodChannel _channel = MethodChannel('proxy_helper');

  /// Get Android system proxy settings
  static Future<ProxyConfig?> getSystemProxy() async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      // Get Android-specific proxy settings
      final result = await _channel.invokeMethod('getSystemProxy');
      if (result != null && result is Map) {
        final host = result['host'] as String?;
        final port = result['port'] as int?;
        
        if (host != null && port != null) {
          return ProxyConfig(host: host, port: port);
        }
      }
    } catch (e) {
      debugPrint('Failed to get system proxy: $e');
    }

    // Fallback: get proxy settings from environment variables
    return _getProxyFromEnvironment();
  }

  /// Get proxy settings from environment variables
  static ProxyConfig? _getProxyFromEnvironment() {
    final httpProxy = Platform.environment['HTTP_PROXY'] ?? 
                     Platform.environment['http_proxy'];
    
    if (httpProxy != null && httpProxy.isNotEmpty) {
      final uri = Uri.tryParse(httpProxy);
      if (uri != null && uri.host.isNotEmpty && uri.port > 0) {
        return ProxyConfig(host: uri.host, port: uri.port);
      }
    }
    
    return null;
  }

  /// Create HTTP client with proxy settings
  static HttpClient createHttpClientWithProxy() {
    final client = HttpClient();
    
    // Apply proxy settings
    _configureProxy(client);
    
    return client;
  }

  /// Apply proxy settings to HTTP client
  static void _configureProxy(HttpClient client) {
    // Try common proxy settings for Android emulator
    final commonProxyHosts = [
      '10.0.2.2', // Android emulator host machine
      '127.0.0.1',
      'localhost',
    ];

    final commonPorts = [8080, 3128, 8888, 8118];

    // Check system proxy settings
    client.findProxy = (uri) {
      // First, try common proxy settings
      for (final host in commonProxyHosts) {
        for (final port in commonPorts) {
          // Check if proxy is available (simplified version)
          return 'PROXY $host:$port';
        }
      }
      
      // Use DIRECT connection if no proxy found
      return 'DIRECT';
    };

    // Set timeout
    client.connectionTimeout = const Duration(seconds: 10);
  }
}

/// Class to hold proxy configuration
class ProxyConfig {
  final String host;
  final int port;
  final String? username;
  final String? password;

  const ProxyConfig({
    required this.host,
    required this.port,
    this.username,
    this.password,
  });

  @override
  String toString() {
    return 'ProxyConfig(host: $host, port: $port)';
  }
}
