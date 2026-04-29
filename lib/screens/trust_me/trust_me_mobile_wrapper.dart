import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/trustme/trust_me_service.dart';
import 'mobile_connection_screen.dart';

class TrustMeMobileWrapper extends StatefulWidget {
  const TrustMeMobileWrapper({super.key});

  @override
  State<TrustMeMobileWrapper> createState() => _TrustMeMobileWrapperState();
}

class _TrustMeMobileWrapperState extends State<TrustMeMobileWrapper> {
  bool _isLoading = true;
  bool _hasConnections = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _checkExistingConnections();
  }

  Future<void> _checkExistingConnections() async {
    try {
      const storage = FlutterSecureStorage();
      String? savedUrl = await storage.read(key: 'public_url');
      
      if (savedUrl != null && savedUrl.isNotEmpty) {
        TrustMeService.instance.setGatewayUrl(savedUrl);
        final chats = await TrustMeService.instance.getConversations();
        if (mounted) {
          setState(() { _hasConnections = chats.isNotEmpty; _isLoading = false; });
        }
      } else {
        if (mounted) setState(() { _hasConnections = false; _isLoading = false; });
      }
    } catch (e) {
      debugPrint("Desktop Unreachable: $e");
      if (mounted) setState(() { _errorMessage = e.toString(); _hasConnections = false; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Color(0xFFF0F2F5), body: Center(child: CircularProgressIndicator(color: Color(0xFF128C7E))));
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, color: Colors.redAccent, size: 60),
                const SizedBox(height: 16),
                const Text("Cannot reach Desktop Server", style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_errorMessage, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () { setState(() { _isLoading = true; _errorMessage = ""; }); _checkExistingConnections(); },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF128C7E)),
                  child: const Text("Retry Connection", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ),
      );
    }
    
    // 🚀 THE FIX: Always load the Connection Screen, but tell it if it needs to slide the Chat List on top!
    return MobileConnectionScreen(autoLaunchChats: _hasConnections);
  }
}