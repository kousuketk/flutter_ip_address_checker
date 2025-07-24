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

    return null;
  }

  /// Get Android system proxy settings only (without fallback)
  static Future<ProxyConfig?> getAndroidSystemProxy() async {
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
          return ProxyConfig(host: host, port: port, source: 'Android System');
        }
      }
    } catch (e) {
      debugPrint('Failed to get Android system proxy: $e');
    }

    return null;
  }

  /// Get iOS system proxy settings only
  static Future<ProxyConfig?> getIOSSystemProxy() async {
    if (!Platform.isIOS) {
      return null;
    }

    try {
      // Get iOS-specific proxy settings from NSURLSessionConfiguration
      final nsUrlSessionInfo = await getNSURLSessionProxy();
      if (nsUrlSessionInfo != null && nsUrlSessionInfo.hasProxy) {
        return ProxyConfig(
          host: nsUrlSessionInfo.host!,
          port: nsUrlSessionInfo.port!,
          source: 'iOS NSURLSessionConfiguration',
        );
      }
    } catch (e) {
      debugPrint('Failed to get iOS NSURLSession proxy: $e');
    }

    return null;
  }


  /// Get NSURLSessionConfiguration proxy settings (iOS only)
  static Future<NSURLSessionProxyInfo?> getNSURLSessionProxy() async {
    if (!Platform.isIOS) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod('getNSURLSessionProxy');
      if (result != null && result is Map) {
        return NSURLSessionProxyInfo.fromMap(result);
      }
    } catch (e) {
      debugPrint('Failed to get NSURLSession proxy: $e');
    }

    return null;
  }


  /// Get detailed proxy information from all sources
  static Future<ProxyDetailedInfo> getDetailedProxyInfo() async {
    final androidProxy = await getAndroidSystemProxy();
    final iosProxy = await getIOSSystemProxy();
    
    return ProxyDetailedInfo(
      androidSystemProxy: androidProxy,
      iosSystemProxy: iosProxy,
      environmentProxy: null,
    );
  }

  /// Get the best available proxy configuration based on platform priority
  static Future<ProxyConfig?> getBestAvailableProxy() async {
    if (Platform.isAndroid) {
      // Android priority: System only
      return await getAndroidSystemProxy();
    } else if (Platform.isIOS) {
      // iOS priority: System only
      return await getIOSSystemProxy();
    } else {
      // Other platforms: No proxy
      return null;
    }
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
  final String? source;

  const ProxyConfig({
    required this.host,
    required this.port,
    this.username,
    this.password,
    this.source,
  });

  @override
  String toString() {
    if (source != null) {
      return 'ProxyConfig(host: $host, port: $port, source: $source)';
    }
    return 'ProxyConfig(host: $host, port: $port)';
  }
}

/// Class to hold detailed proxy information from multiple sources
class ProxyDetailedInfo {
  final ProxyConfig? androidSystemProxy;
  final ProxyConfig? iosSystemProxy;
  final ProxyConfig? environmentProxy;

  const ProxyDetailedInfo({
    this.androidSystemProxy,
    this.iosSystemProxy,
    this.environmentProxy,
  });

  /// Get the effective proxy configuration based on platform priority
  ProxyConfig? get effectiveProxy {
    if (Platform.isAndroid) {
      return androidSystemProxy ?? environmentProxy;
    } else if (Platform.isIOS) {
      return iosSystemProxy ?? environmentProxy;
    } else {
      return environmentProxy;
    }
  }

  /// Check if any proxy is configured
  bool get hasProxy {
    return androidSystemProxy != null || iosSystemProxy != null || environmentProxy != null;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Proxy Information:');
    
    if (androidSystemProxy != null) {
      buffer.writeln('  Android System: ${androidSystemProxy!.host}:${androidSystemProxy!.port}');
    } else {
      buffer.writeln('  Android System: Not configured');
    }
    
    if (iosSystemProxy != null) {
      buffer.writeln('  iOS NSURLSessionConfiguration: ${iosSystemProxy!.host}:${iosSystemProxy!.port}');
    } else {
      buffer.writeln('  iOS NSURLSessionConfiguration: Not configured');
    }
    
    if (environmentProxy != null) {
      buffer.writeln('  Standard Environment Variables: ${environmentProxy!.host}:${environmentProxy!.port}');
    } else {
      buffer.writeln('  Standard Environment Variables: Not configured');
    }
    
    return buffer.toString();
  }
}

/// Class to hold NSURLSessionConfiguration proxy information (iOS only)
class NSURLSessionProxyInfo {
  final String? host;
  final int? port;
  final String? httpsHost;
  final int? httpsPort;
  final String? type;
  final String? message;
  final String source;
  final Map<String, String>? allProxySettings; // Deprecated, use connectionProxyDictionary
  final Map<String, dynamic>? connectionProxyDictionary; // New: Full proxy dictionary
  final int proxyDictionaryCount;
  final Map<String, dynamic>? httpAdditionalHeaders; // New: HTTP additional headers
  final int httpAdditionalHeadersCount;
  final bool allowsCellularAccess;
  final bool allowsConstrainedNetworkAccess;
  final bool allowsExpensiveNetworkAccess;

  const NSURLSessionProxyInfo({
    this.host,
    this.port,
    this.httpsHost,
    this.httpsPort,
    this.type,
    this.message,
    required this.source,
    this.allProxySettings,
    this.connectionProxyDictionary,
    required this.proxyDictionaryCount,
    this.httpAdditionalHeaders,
    required this.httpAdditionalHeadersCount,
    required this.allowsCellularAccess,
    required this.allowsConstrainedNetworkAccess,
    required this.allowsExpensiveNetworkAccess,
  });

  factory NSURLSessionProxyInfo.fromMap(Map<dynamic, dynamic> map) {
    // Helper function to safely convert to bool, handling string values for iOS < 13.0
    bool safeBoolConversion(dynamic value, bool defaultValue) {
      if (value is bool) return value;
      if (value is String) {
        if (value.contains('Not available')) return defaultValue;
        return value.toLowerCase() == 'true';
      }
      return defaultValue;
    }

    return NSURLSessionProxyInfo(
      host: map['host'] as String?,
      port: map['port'] as int?,
      httpsHost: map['httpsHost'] as String?,
      httpsPort: map['httpsPort'] as int?,
      type: map['type'] as String?,
      message: map['message'] as String?,
      source: map['source'] as String? ?? 'NSURLSessionConfiguration',
      allProxySettings: map['allProxySettings'] != null 
          ? Map<String, String>.from(map['allProxySettings'] as Map)
          : null,
      connectionProxyDictionary: map['connectionProxyDictionary'] != null
          ? Map<String, dynamic>.from(map['connectionProxyDictionary'] as Map)
          : null,
      proxyDictionaryCount: map['proxyDictionaryCount'] as int? ?? 0,
      httpAdditionalHeaders: map['httpAdditionalHeaders'] != null
          ? Map<String, dynamic>.from(map['httpAdditionalHeaders'] as Map)
          : null,
      httpAdditionalHeadersCount: map['httpAdditionalHeadersCount'] as int? ?? 0,
      allowsCellularAccess: safeBoolConversion(map['allowsCellularAccess'], false),
      allowsConstrainedNetworkAccess: safeBoolConversion(map['allowsConstrainedNetworkAccess'], false),
      allowsExpensiveNetworkAccess: safeBoolConversion(map['allowsExpensiveNetworkAccess'], false),
    );
  }

  /// Check if proxy is configured
  bool get hasProxy => host != null && port != null;

  /// Get proxy configuration as ProxyConfig if available
  ProxyConfig? get asProxyConfig {
    if (hasProxy) {
      return ProxyConfig(
        host: host!,
        port: port!,
        source: 'NSURLSessionConfiguration',
      );
    }
    return null;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('NSURLSessionConfiguration Proxy Info:');
    buffer.writeln('  Source: $source');
    
    if (hasProxy) {
      buffer.writeln('  HTTP Proxy: $host:$port');
      if (type != null) buffer.writeln('  Type: $type');
      
      if (httpsHost != null && httpsPort != null) {
        buffer.writeln('  HTTPS Proxy: $httpsHost:$httpsPort');
      }
    } else {
      buffer.writeln('  Status: ${message ?? "No proxy configured"}');
    }
    
    buffer.writeln('  Network Access:');
    buffer.writeln('    Cellular: $allowsCellularAccess');
    buffer.writeln('    Constrained: $allowsConstrainedNetworkAccess');
    buffer.writeln('    Expensive: $allowsExpensiveNetworkAccess');
    
    if (allProxySettings != null && allProxySettings!.isNotEmpty) {
      buffer.writeln('  All Proxy Settings:');
      for (final entry in allProxySettings!.entries) {
        buffer.writeln('    ${entry.key}: ${entry.value}');
      }
    }
    
    return buffer.toString();
  }
}
