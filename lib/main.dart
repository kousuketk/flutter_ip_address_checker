import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String _ipAddress = '';
  String _country = '';
  String _countryCode = '';
  String _city = '';
  String _region = '';
  String _isp = '';
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getIPAddress();
  }

  Future<void> _getIPAddress() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Try multiple APIs
      await _tryGetIPFromAPI();
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _tryGetIPFromAPI() async {
    // First, get IP address from ipify API
    try {
      final ipResponse = await http.get(
        Uri.parse('https://api.ipify.org?format=json'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (ipResponse.statusCode == 200) {
        final ipData = json.decode(ipResponse.body);
        final ip = ipData['ip'];
        
        setState(() {
          _ipAddress = ip;
        });

        // Get detailed IP information
        await _getIPDetails(ip);
      } else {
        throw Exception('Failed to get IP address');
      }
    } catch (e) {
      // Fallback: use ip-api.com
      await _tryAlternativeAPI();
    }
  }

  Future<void> _tryAlternativeAPI() async {
    try {
      final response = await http.get(
        Uri.parse('http://ip-api.com/json/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          _ipAddress = data['query'] ?? '';
          _country = data['country'] ?? '';
          _countryCode = data['countryCode'] ?? '';
          _city = data['city'] ?? '';
          _region = data['regionName'] ?? '';
          _isp = data['isp'] ?? '';
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to get data from alternative API');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get data from all APIs: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getIPDetails(String ip) async {
    try {
      // Get additional detailed information from ip-api.com
      final detailResponse = await http.get(
        Uri.parse('http://ip-api.com/json/$ip'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (detailResponse.statusCode == 200) {
        final detailData = json.decode(detailResponse.body);
        
        setState(() {
          _country = detailData['country'] ?? '';
          _countryCode = detailData['countryCode'] ?? '';
          _city = detailData['city'] ?? '';
          _region = detailData['regionName'] ?? '';
          _isp = detailData['isp'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current IP Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Getting IP information...'),
                          ],
                        ),
                      )
                    else if (_errorMessage.isNotEmpty)
                      Column(
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
                      )
                    else
                      Column(
                        children: [
                          _buildInfoRow('IP Address', _ipAddress, Icons.public),
                          _buildInfoRow('Country', _country, Icons.flag),
                          _buildInfoRow('Country Code', _countryCode, Icons.language),
                          _buildInfoRow('City', _city, Icons.location_city),
                          _buildInfoRow('Region', _region, Icons.map),
                          _buildInfoRow('ISP', _isp, Icons.business),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _getIPAddress,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'For Proxy Testing',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This app was created to test the behavior of Flutter apps in a proxy environment. '
                      'When a proxy is configured, you can verify that the displayed IP address changes.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Loading...' : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
