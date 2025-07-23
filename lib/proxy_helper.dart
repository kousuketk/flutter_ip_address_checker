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
      // Get iOS-specific proxy settings
      final result = await _channel.invokeMethod('getSystemProxy');
      if (result != null && result is Map) {
        final host = result['host'] as String?;
        final port = result['port'] as int?;
        
        if (host != null && port != null) {
          return ProxyConfig(host: host, port: port, source: 'iOS System');
        }
      }
    } catch (e) {
      debugPrint('Failed to get iOS system proxy: $e');
    }

    return null;
  }

  /// Get detailed CFNetwork proxy settings (iOS only)
  static Future<Map<String, String>?> getCFNetworkProxyDetails() async {
    if (!Platform.isIOS) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod('getSystemProxyDetails');
      if (result != null && result is Map) {
        return Map<String, String>.from(result);
      }
    } catch (e) {
      debugPrint('Failed to get CFNetwork proxy details: $e');
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


  /// Get proxy settings from standard environment variables
  static ProxyConfig? getProxyFromEnvironment() {
    final httpProxy = Platform.environment['HTTP_PROXY'] ?? 
                     Platform.environment['http_proxy'];
    
    if (httpProxy != null && httpProxy.isNotEmpty) {
      final uri = Uri.tryParse(httpProxy);
      if (uri != null && uri.host.isNotEmpty && uri.port > 0) {
        return ProxyConfig(host: uri.host, port: uri.port, source: 'Standard Environment Variables');
      }
    }
    
    return null;
  }

  /// Get proxy settings from MAGICPOD environment variables (iOS specific)
  static ProxyConfig? getMagicpodProxyFromEnvironment() {
    final host = Platform.environment['MAGICPOD_DYLIB_PROXY_HOST'];
    final portStr = Platform.environment['MAGICPOD_DYLIB_PROXY_PORT'];
    
    if (host != null && host.isNotEmpty && portStr != null && portStr.isNotEmpty) {
      final port = int.tryParse(portStr);
      if (port != null && port > 0) {
        return ProxyConfig(host: host, port: port, source: 'MAGICPOD Environment Variables');
      }
    }
    
    return null;
  }

  /// Get all environment variables
  static Map<String, String> getAllEnvironmentVariables() {
    return Platform.environment;
  }

  /// Get proxy-related environment variables
  static Map<String, String> getProxyRelatedEnvironmentVariables() {
    final allEnv = Platform.environment;
    final proxyEnv = <String, String>{};
    
    for (final entry in allEnv.entries) {
      final key = entry.key.toUpperCase();
      if (key.contains('PROXY') || 
          key.contains('HTTP') || 
          key.contains('HTTPS') ||
          key.contains('MAGICPOD')) {
        proxyEnv[entry.key] = entry.value;
      }
    }
    return proxyEnv;
  }

  /// Get environment variables summary for display
  static EnvironmentVariablesInfo getEnvironmentVariablesInfo() {
    final allEnv = getAllEnvironmentVariables();
    final proxyEnv = getProxyRelatedEnvironmentVariables();
    
    return EnvironmentVariablesInfo(
      allVariables: allEnv,
      proxyRelatedVariables: proxyEnv,
    );
  }

  /// Get proxy settings from environment variables (private method for backward compatibility)
  static ProxyConfig? _getProxyFromEnvironment() {
    return getProxyFromEnvironment();
  }

  /// Get detailed proxy information from all sources
  static Future<ProxyDetailedInfo> getDetailedProxyInfo() async {
    final androidProxy = await getAndroidSystemProxy();
    final iosProxy = await getIOSSystemProxy();
    final envProxy = getProxyFromEnvironment();
    final magicpodProxy = getMagicpodProxyFromEnvironment();
    
    return ProxyDetailedInfo(
      androidSystemProxy: androidProxy,
      iosSystemProxy: iosProxy,
      environmentProxy: envProxy,
      magicpodProxy: magicpodProxy,
    );
  }

  /// Get the best available proxy configuration based on platform priority
  static Future<ProxyConfig?> getBestAvailableProxy() async {
    if (Platform.isAndroid) {
      // Android priority: System → Standard Env → MAGICPOD Env
      final androidProxy = await getAndroidSystemProxy();
      if (androidProxy != null) return androidProxy;
      
      final envProxy = getProxyFromEnvironment();
      if (envProxy != null) return envProxy;
      
      return getMagicpodProxyFromEnvironment();
    } else if (Platform.isIOS) {
      // iOS priority: System → MAGICPOD Env → Standard Env
      final iosProxy = await getIOSSystemProxy();
      if (iosProxy != null) return iosProxy;
      
      final magicpodProxy = getMagicpodProxyFromEnvironment();
      if (magicpodProxy != null) return magicpodProxy;
      
      return getProxyFromEnvironment();
    } else {
      // Other platforms: Standard Env only
      return getProxyFromEnvironment();
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
  final ProxyConfig? magicpodProxy;

  const ProxyDetailedInfo({
    this.androidSystemProxy,
    this.iosSystemProxy,
    this.environmentProxy,
    this.magicpodProxy,
  });

  /// Get the effective proxy configuration based on platform priority
  ProxyConfig? get effectiveProxy {
    if (Platform.isAndroid) {
      return androidSystemProxy ?? environmentProxy ?? magicpodProxy;
    } else if (Platform.isIOS) {
      return iosSystemProxy ?? magicpodProxy ?? environmentProxy;
    } else {
      return environmentProxy;
    }
  }

  /// Check if any proxy is configured
  bool get hasProxy {
    return androidSystemProxy != null || iosSystemProxy != null || environmentProxy != null || magicpodProxy != null;
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
      buffer.writeln('  iOS System: ${iosSystemProxy!.host}:${iosSystemProxy!.port}');
    } else {
      buffer.writeln('  iOS System: Not configured');
    }
    
    if (environmentProxy != null) {
      buffer.writeln('  Standard Environment Variables: ${environmentProxy!.host}:${environmentProxy!.port}');
    } else {
      buffer.writeln('  Standard Environment Variables: Not configured');
    }
    
    if (magicpodProxy != null) {
      buffer.writeln('  MAGICPOD Environment Variables: ${magicpodProxy!.host}:${magicpodProxy!.port}');
    } else {
      buffer.writeln('  MAGICPOD Environment Variables: Not configured');
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
  final Map<String, String>? allProxySettings;
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

/// Class to hold environment variables information
class EnvironmentVariablesInfo {
  final Map<String, String> allVariables;
  final Map<String, String> proxyRelatedVariables;

  const EnvironmentVariablesInfo({
    required this.allVariables,
    required this.proxyRelatedVariables,
  });

  /// Get total count of environment variables
  int get totalCount => allVariables.length;

  /// Get count of proxy-related environment variables
  int get proxyRelatedCount => proxyRelatedVariables.length;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Environment Variables Summary:');
    buffer.writeln('  Total variables: $totalCount');
    buffer.writeln('  Proxy-related variables: $proxyRelatedCount');
    
    if (proxyRelatedVariables.isNotEmpty) {
      buffer.writeln('\nProxy-related variables:');
      for (final entry in proxyRelatedVariables.entries) {
        buffer.writeln('  ${entry.key} = ${entry.value}');
      }
    }
    
    return buffer.toString();
  }
}
