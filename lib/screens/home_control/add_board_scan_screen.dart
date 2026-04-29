import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

import '../../providers/home_control/dynamic_theme_provider.dart';
import '../../widgets/home_control/home_control_widgets.dart';
import '../../services/home_control/home_control_services.dart';

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
  
  List<WifiNetwork> _foundDevices = [];
  WifiNetwork? _connectedBoard;

  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndScan();
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 1. Ask for location permission, then scan for Wi-Fi
  Future<void> _requestPermissionsAndScan() async {
    setState(() {
      _isScanning = true;
      _foundDevices = [];
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

  // 2. Scan and filter for "SmartSwitch"
  Future<void> _startScan() async {
    try {
      // Force Wi-Fi on (Android only)
      await WiFiForIoTPlugin.setEnabled(true);
      
      final networks = await WiFiForIoTPlugin.loadWifiList();
      
      if (mounted) {
        setState(() {
          // Filter networks that start with "SmartSwitch"
          _foundDevices = networks.where((net) {
            final ssid = net.ssid ?? '';
            return ssid.toLowerCase().startsWith('smartswitch');
          }).toList();
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

  // 3. Connect to the tapped ESP12-E AP
  Future<void> _connectToBoard(WifiNetwork network) async {
    setState(() {
      _isConnectingToBoard = true;
    });

    try {
      // Connect to the open ESP AP
      final connected = await WiFiForIoTPlugin.connect(
        network.ssid ?? '',
        security: NetworkSecurity.NONE, // Assuming the ESP AP has no password
        withInternet: false, // We know this AP has no internet
      );

      if (connected) {
        // Wait a moment for the IP assignment to settle
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

  // 4. Send HTTP request to ESP12-E and save to database
  Future<void> _sendCredentialsToBoard() async {
    if (_ssidController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Home Wi-Fi Name')),
      );
      return;
    }

    setState(() => _isProvisioning = true);

    try {
      // ---> CRITICAL FIX FOR ANDROID <---
      // Force the phone to route HTTP traffic over the ESP32's Wi-Fi network, 
      // otherwise Android will try to use Cellular Data because the ESP has no internet.
      await WiFiForIoTPlugin.forceWifiUsage(true);

      final espUrl = Uri.parse('http://192.168.4.1/wifisave'); 
      
      final response = await http.post(
        espUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          's': _ssidController.text.trim(), // SSID parameter
          'p': _passwordController.text.trim(), // Password parameter
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Formulate a Board ID (e.g., from "SmartSwitch_4node" -> "BOARD_4node")
        final deviceName = _connectedBoard?.ssid ?? 'Unknown_Board';
        final extractedBoardId = deviceName.replaceAll(RegExp(r'(?i)smartswitch_'), 'BOARD_');

        // Claim it in Supabase
        await HomeControlService().validateAndClaimBoard(
          boardId: extractedBoardId,
          homeId: widget.homeId,
          roomId: widget.roomId,
          customName: deviceName,
        );

        // Turn off forced Wi-Fi usage and disconnect so the phone returns to normal internet
        await WiFiForIoTPlugin.forceWifiUsage(false);
        await WiFiForIoTPlugin.disconnect();

        if (mounted) {
          Navigator.pop(context); // Go back to Board List
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Board connected and claimed successfully!')),
          );
        }
      } else {
        throw Exception("ESP rejected credentials (Status: ${response.statusCode})");
      }
    } catch (e) {
      // ALWAYS ensure we release the forced Wi-Fi usage if something goes wrong
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
          Text(
            'Connecting to Smart Switch...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      );
    }

    if (_connectedBoard != null) {
      return _buildProvisioningForm();
    }

    return _buildScannerList();
  }

  // UI: Step 3 - Enter Home Credentials
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
          'Enter your Home Wi-Fi details to connect the board to the internet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _ssidController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Home Wi-Fi Name (SSID)',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
            prefixIcon: Icon(Icons.wifi, color: Colors.white70),
          ),
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

  // UI: Step 1 & 2 - Scanning and Listing Devices
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
        else if (_foundDevices.isEmpty)
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
              itemCount: _foundDevices.length,
              itemBuilder: (context, index) {
                final network = _foundDevices[index];
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