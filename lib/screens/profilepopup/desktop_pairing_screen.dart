import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guptik/screens/profilepopup/qr_scanner_screen.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
 // Adjust path if necessary
// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class DesktopPairingScreen extends StatefulWidget {
  const DesktopPairingScreen({super.key});

  @override
  State<DesktopPairingScreen> createState() => _DesktopPairingScreenState();
}

class _DesktopPairingScreenState extends State<DesktopPairingScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _checkExistingConnection();
  }

  Future<void> _checkExistingConnection() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('desktop_devices')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      setState(() {
        _connectedDevice = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error checking connection: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleQRScan() async {
    final String? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(result);
        await _saveDeviceToSupabase(data);
      } catch (e) {
        _showSnackBar("Invalid QR Code format", Colors.redAccent);
      }
    }
  }

  Future<void> _saveDeviceToSupabase(Map<String, dynamic> deviceData) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('desktop_devices').upsert({
        'user_id': userId,
        'device_id': deviceData['device_id'],
        'device_model': deviceData['model'],
        'is_verified': true,
        'installation_status': 'completed',
        'last_active_at': DateTime.now().toIso8601String(),
      });

      _showSnackBar("Device paired successfully!", Colors.greenAccent);
      _checkExistingConnection();
    } catch (e) {
      _showSnackBar("Failed to pair device: $e", Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message, 
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ), 
        backgroundColor: color,
      ),
    );
  }

  String _generateUserUrl() {
    final uid = _supabase.auth.currentUser?.id ?? "";
    final reversedUid = uid.split('').reversed.join('');
    final deviceId = _connectedDevice?['device_id'] ?? "unknown";
    return "MyQRMart.com/guptik/users/$reversedUid/$deviceId";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text(
          'Desktop Connection', 
          style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        iconTheme: const IconThemeData(color: _ancientGold),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _ancientGold.withValues(alpha: 0.2), height: 1.0),
        ),
      ),
      // THE FIX: Full screen container ensures the background stretches to cover all scrollable area
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // The Shared Cinematic Nebula Background
            const Positioned.fill(child: DynamicAppBackground()),

            // The Actual UI Content
            SafeArea(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: _ancientGold))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: _connectedDevice == null 
                        ? _buildScannerPrompt() 
                        : _buildConnectedView(),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerPrompt() {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.4),
              border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: _ancientGold.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: const Icon(Icons.desktop_windows, size: 80, color: _ancientGold),
          ),
          const SizedBox(height: 32),
          const Text(
            "No Desktop Device Paired",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _ancientGold),
          ),
          const SizedBox(height: 16),
          Text(
            "Open the GupTik Desktop App and scan the QR code to sync your server settings.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _handleQRScan,
            icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
            label: const Text(
              "Scan Desktop QR", 
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _ancientGold,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.5),
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedView() {
    final url = _generateUserUrl();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
            ),
            title: Text(
              "Connected to ${_connectedDevice?['device_model']}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "ID: ${_connectedDevice?['device_id']}",
                style: TextStyle(color: Colors.grey[500], fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          "Your Unique Server URL:",
          style: TextStyle(fontWeight: FontWeight.bold, color: _ancientGold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  url,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: _ancientGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.copy, size: 20, color: Colors.black),
                  tooltip: 'Copy URL',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    _showSnackBar("URL copied to clipboard", _ancientGold);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}