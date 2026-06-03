import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../providers/home_control/dynamic_theme_provider.dart';
import '../../widgets/home_control/home_control_widgets.dart';

class AddBoardScanScreen extends StatefulWidget {
  final String homeId;
  final String? roomId;

  const AddBoardScanScreen({
    super.key,
    required this.homeId,
    this.roomId,
  });

  @override
  State<AddBoardScanScreen> createState() => _AddBoardScanScreenState();
}

class _AddBoardScanScreenState extends State<AddBoardScanScreen> {
  bool _isScanning = false;
  bool _isConnectingToBoard = false;
  bool _isProvisioning = false;
  
  // ignore: deprecated_member_use
  List<WifiNetwork> _foundESPDevices = [];
  List<String> _nearbyHomeNetworks = []; // Populates the dropdown
  // ignore: deprecated_member_use
  WifiNetwork? _connectedBoard;

  String? _selectedSSID;
  final TextEditingController _passwordController = TextEditingController();
  
  // Security Tools
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndScan();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  // 1. Ask for location permission, then scan for Wi-Fi
  Future<void> _requestPermissionsAndScan() async {
    setState(() {
      _isScanning = true;
      _foundESPDevices = [];
      _nearbyHomeNetworks = [];
    });

    final status = await Permission.locationWhenInUse.request();
    
    if (status.isGranted) {
      _startScan();
    } else {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required to scan for Wi-Fi.')),
        );
      }
    }
  }

  // 2. Scan and filter for "SmartSwitch" and Home Networks
  Future<void> _startScan() async {
    try {
      await WiFiForIoTPlugin.setEnabled(true);
      // ignore: deprecated_member_use
      final networks = await WiFiForIoTPlugin.loadWifiList();
      
      if (mounted) {
        setState(() {
          // Filter ESP boards (Fixed case sensitivity issue here!)
          _foundESPDevices = networks.where((net) {
            final ssid = net.ssid ?? '';
            return ssid.toLowerCase().startsWith('smartswitch');
          }).toList();

          // Filter regular Home Wi-Fi networks for the dropdown
          _nearbyHomeNetworks = networks
              .where((net) {
                final ssid = net.ssid ?? '';
                return !ssid.toLowerCase().startsWith('smartswitch') && ssid.isNotEmpty;
              })
              .map((net) => net.ssid!)
              .toSet() // Remove duplicates
              .toList();

          // Auto-select the first home network if available
          if (_nearbyHomeNetworks.isNotEmpty) {
            _selectedSSID = _nearbyHomeNetworks.first;
            _checkForSavedPassword(_selectedSSID!);
          }

          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to scan: $e')),
        );
      }
    }
  }

  // --- BIOMETRIC & SECURE STORAGE LOGIC ---
  Future<void> _checkForSavedPassword(String ssid) async {
    final savedPassword = await _secureStorage.read(key: 'wifi_$ssid');
    
    if (savedPassword != null && savedPassword.isNotEmpty && mounted) {
      try {
        // Using older local_auth syntax to prevent AuthenticationOptions error
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Unlock saved Wi-Fi password for $ssid',
          biometricOnly: true, 
        );

        if (didAuthenticate && mounted) {
          setState(() {
            _passwordController.text = savedPassword;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password auto-filled securely.'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        // Biometrics failed or unavailable, they must type it manually
      }
    } else {
      // Clear password field if no saved password exists for this network
      setState(() {
        _passwordController.clear();
      });
    }
  }

  // 3. Connect to the tapped ESP AP
  // ignore: deprecated_member_use
  Future<void> _connectToBoard(WifiNetwork network) async {
    setState(() {
      _isConnectingToBoard = true;
    });

    try {
      final connected = await WiFiForIoTPlugin.connect(
        network.ssid ?? '',
        security: NetworkSecurity.NONE,
        withInternet: false, 
      );

      if (connected) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          setState(() {
            _connectedBoard = network;
            _isConnectingToBoard = false;
          });
        }
      } else {
        throw Exception("Could not connect to ${network.ssid}");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnectingToBoard = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
      }
    }
  }

  // 4. Send HTTP request to ESP with Credentials + IDs
  Future<void> _sendCredentialsToBoard() async {
    if (_selectedSSID == null || _selectedSSID!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Home Wi-Fi Name')),
      );
      return;
    }

    setState(() => _isProvisioning = true);

    try {
      // Get the current user's ID
      final ownerId = Supabase.instance.client.auth.currentUser?.id;
      if (ownerId == null) throw Exception("User not logged in");

      await WiFiForIoTPlugin.forceWifiUsage(true);

      final espUrl = Uri.parse('http://192.168.4.1/wifisave'); 
      
      // Sending ALL data to the ESP in the background
      final response = await http.post(
        espUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          's': _selectedSSID, // Selected from dropdown
          'p': _passwordController.text.trim(), // Password
          'o': ownerId, // Owner ID
          'h': widget.homeId, // Home ID
          'r': widget.roomId ?? '', // Room ID (Empty string if null/unassigned)
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Save the Wi-Fi password for next time!
        await _secureStorage.write(key: 'wifi_$_selectedSSID', value: _passwordController.text.trim());

        await WiFiForIoTPlugin.forceWifiUsage(false);
        await WiFiForIoTPlugin.disconnect();

        if (mounted) {
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credentials sent! The board is now connecting and registering itself.')),
          );
        }
      } else {
        throw Exception("ESP rejected data (Status: ${response.statusCode})");
      }
    } catch (e) {
      await WiFiForIoTPlugin.forceWifiUsage(false);
      setState(() => _isProvisioning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to provision: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<DynamicThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Smart Board', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_isScanning || _connectedBoard != null) ? null : _requestPermissionsAndScan,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedSkyBackground(
        isDarkMode: theme.isDarkMode,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildBodyContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isConnectingToBoard) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Connecting to Smart Switch...', style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      );
    }
    if (_connectedBoard != null) return _buildProvisioningForm();
    return _buildScannerList();
  }

  Widget _buildProvisioningForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.router, color: Colors.cyanAccent, size: 60),
        const SizedBox(height: 16),
        Text(
          'Connected to ${_connectedBoard?.ssid}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select your Home Wi-Fi to connect the board to the internet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 24),
        
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _selectedSSID,
          dropdownColor: const Color.fromRGBO(6, 23, 43, 1),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Home Network',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
            prefixIcon: Icon(Icons.wifi, color: Colors.white70),
          ),
          items: _nearbyHomeNetworks.map((String ssid) {
            return DropdownMenuItem<String>(
              value: ssid,
              child: Text(ssid, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedSSID = newValue;
            });
            if (newValue != null) {
              _checkForSavedPassword(newValue);
            }
          },
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _passwordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Wi-Fi Password',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
            prefixIcon: Icon(Icons.lock, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 24),
        _isProvisioning
            ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
            : ElevatedButton(
                onPressed: _sendCredentialsToBoard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Send & Connect', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
      ],
    );
  }

  Widget _buildScannerList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.radar, color: Colors.white, size: 40),
        const SizedBox(height: 16),
        Text(
          _isScanning ? 'Searching for boards...' : 'Select a Board to Setup',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_isScanning)
          const CircularProgressIndicator(color: Colors.cyanAccent)
        else if (_foundESPDevices.isEmpty)
          const Text(
            'No Smart Switches found nearby. Ensure the board is plugged in and blinking.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _foundESPDevices.length,
              itemBuilder: (context, index) {
                final network = _foundESPDevices[index];
                return Card(
                  color: Colors.white.withValues(alpha: 0.1),
                  child: ListTile(
                    leading: const Icon(Icons.memory, color: Colors.cyanAccent),
                    title: Text(network.ssid ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    onTap: () => _connectToBoard(network),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}