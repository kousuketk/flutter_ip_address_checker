import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'http_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IP Address Checker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const IPAddressChecker(),
    );
  }
}

class IPAddressChecker extends StatefulWidget {
  const IPAddressChecker({super.key});

  @override
  State<IPAddressChecker> createState() => _IPAddressCheckerState();
}

class _IPAddressCheckerState extends State<IPAddressChecker> {
  // Proxy connection information
  String _proxyIpAddress = '';
  String _proxyCountry = '';
  String _proxyCountryCode = '';
  String _proxyCity = '';
  String _proxyRegion = '';
  String _proxyIsp = '';
  
  // Direct connection information
  String _directIpAddress = '';
  String _directCountry = '';
  String _directCountryCode = '';
  String _directCity = '';
  String _directRegion = '';
  String _directIsp = '';
  
  bool _isLoading = false;
  String _errorMessage = '';
  String _proxyInfo = '';
  String _androidProxyInfo = '';
  String _iosProxyInfo = '';
  String _environmentProxyInfo = '';
  String _magicpodProxyInfo = '';

  @override
  void initState() {
    super.initState();
    _initializeAndGetIPs();
  }

  Future<void> _initializeAndGetIPs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Initialize HTTP service (including proxy settings)
      await HttpService.instance.initialize();
      _updateProxyInfo();
      
      // Get both IP address information in parallel
      await Future.wait([
        _getProxyIP(),
        _getDirectIP(),
      ]);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Service initialization error: $e';
        _isLoading = false;
      });
    }
  }

  /// Update proxy information from HttpService
  void _updateProxyInfo() {
    _proxyInfo = HttpService.instance.getProxyInfo();
    
    final androidProxy = HttpService.instance.getAndroidSystemProxy();
    final iosProxy = HttpService.instance.getIOSSystemProxy();
    final environmentProxy = HttpService.instance.getEnvironmentProxy();
    final magicpodProxy = HttpService.instance.getMagicpodProxy();
    
    if (androidProxy != null) {
      _androidProxyInfo = 'Android System Proxy: ${androidProxy.host}:${androidProxy.port}';
    } else {
      _androidProxyInfo = 'Android System Proxy: Not configured';
    }
    
    if (iosProxy != null) {
      _iosProxyInfo = 'iOS System Proxy: ${iosProxy.host}:${iosProxy.port}';
    } else {
      _iosProxyInfo = 'iOS System Proxy: Not configured';
    }
    
    if (environmentProxy != null) {
      _environmentProxyInfo = 'Standard Environment Variables: ${environmentProxy.host}:${environmentProxy.port}';
    } else {
      _environmentProxyInfo = 'Standard Environment Variables: Not configured';
    }
    
    if (magicpodProxy != null) {
      _magicpodProxyInfo = 'MAGICPOD Environment Variables: ${magicpodProxy.host}:${magicpodProxy.port}';
    } else {
      _magicpodProxyInfo = 'MAGICPOD Environment Variables: Not configured';
    }
  }

  Future<void> _refreshIPs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Reload proxy settings
      await HttpService.instance.refreshProxy();
      _updateProxyInfo();
      
      // Get both IP address information in parallel
      await Future.wait([
        _getProxyIP(),
        _getDirectIP(),
      ]);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Refresh error: $e';
        _isLoading = false;
      });
    }
  }

  /// Get IP address via proxy connection
  Future<void> _getProxyIP() async {
    try {
      // Get IP address via proxy
      final response = await HttpService.instance.get('http://ip-api.com/json/');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _proxyIpAddress = data['query'] ?? '';
          _proxyCountry = data['country'] ?? '';
          _proxyCountryCode = data['countryCode'] ?? '';
          _proxyCity = data['city'] ?? '';
          _proxyRegion = data['regionName'] ?? '';
          _proxyIsp = data['isp'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Proxy IP fetch error: $e');
      setState(() {
        _proxyIpAddress = 'Error';
        _proxyCountry = 'Error';
        _proxyCountryCode = 'Error';
        _proxyCity = 'Error';
        _proxyRegion = 'Error';
        _proxyIsp = 'Error';
      });
    }
  }

  /// Get IP address via direct connection
  Future<void> _getDirectIP() async {
    try {
      // Create HTTP client for direct connection
      final httpClient = HttpClient();
      httpClient.findProxy = (uri) => 'DIRECT'; // Do not use proxy
      httpClient.connectionTimeout = const Duration(seconds: 15);
      final directClient = IOClient(httpClient);
      
      final response = await directClient.get(
        Uri.parse('http://ip-api.com/json/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _directIpAddress = data['query'] ?? '';
          _directCountry = data['country'] ?? '';
          _directCountryCode = data['countryCode'] ?? '';
          _directCity = data['city'] ?? '';
          _directRegion = data['regionName'] ?? '';
          _directIsp = data['isp'] ?? '';
        });
      }
      
      directClient.close();
    } catch (e) {
      debugPrint('Direct IP fetch error: $e');
      setState(() {
        _directIpAddress = 'Error';
        _directCountry = 'Error';
        _directCountryCode = 'Error';
        _directCity = 'Error';
        _directRegion = 'Error';
        _directIsp = 'Error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IP Address Checker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Proxy information card
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.network_check, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Proxy Configuration Status',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Currently in use: $_proxyInfo',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Detailed Information:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _androidProxyInfo,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _iosProxyInfo,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _environmentProxyInfo,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _magicpodProxyInfo,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Proxy connection IP information
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'IP Information via Proxy',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Column(
                          children: [
                            _buildInfoRow('IP Address', _proxyIpAddress, Icons.public),
                            _buildInfoRow('Country', _proxyCountry, Icons.flag),
                            _buildInfoRow('Country Code', _proxyCountryCode, Icons.language),
                            _buildInfoRow('City', _proxyCity, Icons.location_city),
                            _buildInfoRow('Region', _proxyRegion, Icons.map),
                            _buildInfoRow('ISP', _proxyIsp, Icons.business),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Direct connection IP information
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.public, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'IP Information via Direct Connection',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Column(
                          children: [
                            _buildInfoRow('IP Address', _directIpAddress, Icons.public),
                            _buildInfoRow('Country', _directCountry, Icons.flag),
                            _buildInfoRow('Country Code', _directCountryCode, Icons.language),
                            _buildInfoRow('City', _directCity, Icons.location_city),
                            _buildInfoRow('Region', _directRegion, Icons.map),
                            _buildInfoRow('ISP', _directIsp, Icons.business),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Refresh button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _refreshIPs,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Both IPs'),
              ),
              const SizedBox(height: 16),
              
              // Error message
              if (_errorMessage.isNotEmpty)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Usage instructions
              Card(
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Proxy Testing App',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This app is a tool for verifying proxy configuration behavior.\n\n'
                        '• The blue card shows IP information via proxy\n'
                        '• The green card shows IP information via direct connection\n'
                        '• If proxy is configured correctly, the two IP addresses should be different\n\n'
                        'Example proxy configuration command:\n'
                        'adb shell settings put global http_proxy 10.0.2.2:8080',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Loading...' : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.grey : 
                       value == 'Error' ? Colors.red : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
