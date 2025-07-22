import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'proxy_helper.dart';

class HttpService {
  static HttpService? _instance;
  late http.Client _client;
  ProxyConfig? _proxyConfig;
  ProxyDetailedInfo? _detailedProxyInfo;

  HttpService._internal();

  static HttpService get instance {
    _instance ??= HttpService._internal();
    return _instance!;
  }

  /// Initialize HTTP client (including proxy settings)
  Future<void> initialize() async {
    try {
      // Get detailed proxy configuration
      _detailedProxyInfo = await ProxyHelper.getDetailedProxyInfo();
      _proxyConfig = await ProxyHelper.getBestAvailableProxy();
      
      if (_proxyConfig != null) {
        debugPrint('Proxy configuration found: $_proxyConfig');
        _client = _createProxyClient();
      } else {
        debugPrint('No proxy configuration found, using default client');
        _client = _createDefaultClient();
      }
    } catch (e) {
      debugPrint('Failed to initialize HTTP service: $e');
      _client = _createDefaultClient();
    }
  }

  /// Create proxy-aware HTTP client
  http.Client _createProxyClient() {
    final httpClient = HttpClient();
    
    // Apply proxy settings
    httpClient.findProxy = (uri) {
      // Use configured proxy if available
      if (_proxyConfig != null) {
        debugPrint('Using configured proxy: ${_proxyConfig!.host}:${_proxyConfig!.port}');
        return 'PROXY ${_proxyConfig!.host}:${_proxyConfig!.port}';
      }
      
      // Try common proxy configurations for Android emulator
      final proxyConfigs = [
        'PROXY 10.0.2.2:8080',  // Android emulator host machine
        'PROXY 127.0.0.1:8080',
        'PROXY localhost:8080',
        'PROXY 10.0.2.2:3128',
        'PROXY 127.0.0.1:3128',
        'PROXY localhost:3128',
        'PROXY 10.0.2.2:8888',
        'PROXY 127.0.0.1:8888',
        'PROXY localhost:8888',
      ];
      
      // Return first proxy configuration (adjust according to actual environment)
      debugPrint('Using fallback proxy: ${proxyConfigs.first}');
      return proxyConfigs.first;
    };

    // Disable SSL certificate verification (for testing environment)
    httpClient.badCertificateCallback = (cert, host, port) => true;
    
    // Set timeout
    httpClient.connectionTimeout = const Duration(seconds: 15);
    
    return IOClient(httpClient);
  }

  /// Create default HTTP client
  http.Client _createDefaultClient() {
    final httpClient = HttpClient();
    
    // Set timeout
    httpClient.connectionTimeout = const Duration(seconds: 15);
    
    return IOClient(httpClient);
  }

  /// Execute GET request
  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    try {
      debugPrint('Making GET request to: $url');
      if (_proxyConfig != null) {
        debugPrint('Using proxy: $_proxyConfig');
      }
      
      final response = await _client.get(
        Uri.parse(url),
        headers: headers ?? {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      
      debugPrint('Response status: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('HTTP GET error: $e');
      rethrow;
    }
  }

  /// Execute POST request
  Future<http.Response> post(String url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    try {
      debugPrint('Making POST request to: $url');
      if (_proxyConfig != null) {
        debugPrint('Using proxy: $_proxyConfig');
      }
      
      final response = await _client.post(
        Uri.parse(url),
        headers: headers ?? {'Accept': 'application/json'},
        body: body,
        encoding: encoding,
      ).timeout(const Duration(seconds: 30));
      
      debugPrint('Response status: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('HTTP POST error: $e');
      rethrow;
    }
  }

  /// Release resources
  void dispose() {
    _client.close();
  }

  /// Get proxy configuration information
  String getProxyInfo() {
    if (_proxyConfig != null) {
      return 'Proxy in use: ${_proxyConfig!.host}:${_proxyConfig!.port}';
    } else {
      return 'No proxy configured (direct connection)';
    }
  }

  /// Get detailed proxy information
  String getDetailedProxyInfo() {
    if (_detailedProxyInfo != null) {
      return _detailedProxyInfo.toString();
    } else {
      return 'Proxy information not available';
    }
  }

  /// Get Android system proxy information
  ProxyConfig? getAndroidSystemProxy() {
    return _detailedProxyInfo?.androidSystemProxy;
  }

  /// Get iOS system proxy information
  ProxyConfig? getIOSSystemProxy() {
    return _detailedProxyInfo?.iosSystemProxy;
  }

  /// Get standard environment proxy information
  ProxyConfig? getEnvironmentProxy() {
    return _detailedProxyInfo?.environmentProxy;
  }

  /// Get MAGICPOD environment proxy information
  ProxyConfig? getMagicpodProxy() {
    return _detailedProxyInfo?.magicpodProxy;
  }

  /// Get environment variables information
  EnvironmentVariablesInfo getEnvironmentVariablesInfo() {
    return ProxyHelper.getEnvironmentVariablesInfo();
  }

  /// Get all environment variables
  Map<String, String> getAllEnvironmentVariables() {
    return ProxyHelper.getAllEnvironmentVariables();
  }

  /// Get proxy-related environment variables
  Map<String, String> getProxyRelatedEnvironmentVariables() {
    return ProxyHelper.getProxyRelatedEnvironmentVariables();
  }

  /// Force reload proxy settings
  Future<void> refreshProxy() async {
    dispose();
    await initialize();
  }
}
