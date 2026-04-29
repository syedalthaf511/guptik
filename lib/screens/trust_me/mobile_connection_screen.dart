import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/trustme/trust_me_service.dart';
import 'mobile_chat_list_screen.dart';

class MobileConnectionScreen extends StatefulWidget {
  final bool autoLaunchChats; // 🚀 Added this variable!
  
  const MobileConnectionScreen({super.key, this.autoLaunchChats = false});

  @override
  State<MobileConnectionScreen> createState() => _MobileConnectionScreenState();
}

class _MobileConnectionScreenState extends State<MobileConnectionScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _peerUrlController = TextEditingController();
  final TextEditingController _myUrlController = TextEditingController();
  String _generatedCode = "";
  bool _isLoading = false;

  @override
  void initState() { 
    super.initState(); 
    _autoFetchMyCloudflareUrl(); 

    // 🚀 THE FIX: If the Wrapper says we have chats, instantly slide the Chat List on top!
    if (widget.autoLaunchChats) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MobileChatListScreen()),
        );
      });
    }
  }


  Future<void> _autoFetchMyCloudflareUrl() async {
    setState(() => _isLoading = true);
    const storage = FlutterSecureStorage();
    String? savedUrl = await storage.read(key: 'public_url');
    
    if (savedUrl != null && savedUrl.isNotEmpty) {
      if (mounted) setState(() { _myUrlController.text = savedUrl; _isLoading = false; });
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final myUserId = supabase.auth.currentUser?.id;
      
      if (myUserId != null) {
        String? fetchedUrl;

        // 1. Try to find if the user CREATED an invite
        final creatorResponse = await supabase.from('trust_me_secure_invites')
            .select('creator_cloudflare_url')
            .eq('creator_id', myUserId)
            .order('created_at', ascending: false)
            .limit(1).maybeSingle();
            
        if (creatorResponse != null && creatorResponse['creator_cloudflare_url'] != null) {
          fetchedUrl = creatorResponse['creator_cloudflare_url'].toString();
        } 
        // 2. If they didn't create one, check if they JOINED an invite!
        else {
          final joinerResponse = await supabase.from('trust_me_secure_invites')
              .select('joiner_cloudflare_url')
              .eq('connected_with', myUserId)
              .order('created_at', ascending: false)
              .limit(1).maybeSingle();
              
          if (joinerResponse != null && joinerResponse['joiner_cloudflare_url'] != null) {
            fetchedUrl = joinerResponse['joiner_cloudflare_url'].toString();
          }
        }

        // 3. THE FIX: Add the "!" to tell Dart it is 100% safe to use!
        if (fetchedUrl != null && fetchedUrl.isNotEmpty) {
          if (mounted) setState(() => _myUrlController.text = fetchedUrl!);
          await storage.write(key: 'public_url', value: fetchedUrl);
        }
      }
    } catch (e) { 
      debugPrint("URL fetch error: $e"); 
    } finally { 
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  
  Future<void> _saveMyUrl(String url) async => await const FlutterSecureStorage().write(key: 'public_url', value: url);

  Future<void> _generateCode() async {
    if (_myUrlController.text.isEmpty) return;
    await _saveMyUrl(_myUrlController.text);
    TrustMeService.instance.setGatewayUrl(_myUrlController.text);
    
    setState(() => _isLoading = true);
    try {
      final data = await TrustMeService.instance.generateHandshakeCode("Mobile_User");
      setState(() => _generatedCode = data['code']);
    } catch (e) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); 
    } finally { 
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  Future<void> _joinWithCode() async {
    if (_codeController.text.isEmpty || _peerUrlController.text.isEmpty || _myUrlController.text.isEmpty) return;
    await _saveMyUrl(_myUrlController.text);
    TrustMeService.instance.setGatewayUrl(_myUrlController.text);
    
    setState(() => _isLoading = true);
    try {
      await TrustMeService.instance.initiatePeerConnection(peerUrl: _peerUrlController.text, code: _codeController.text, myUsername: "Mobile_User", myUrl: _myUrlController.text);
      if (mounted) {
        // 🚀 THE FIX: Push the chat screen on top after a successful link!
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MobileChatListScreen()));
      }
    } catch (e) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e"))); 
    } finally { 
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), 
      appBar: AppBar(
        title: const Text("Secure Connection", style: TextStyle(color: Colors.white)), 
        backgroundColor: Color.fromARGB(255, 115, 11, 134), 
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat, color: Colors.white),
            tooltip: 'Open Secure Chats',
            onPressed: () {
              // 🚀 THE FIX: Uses standard push so back arrow works perfectly
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const MobileChatListScreen())
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading && _myUrlController.text.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 115, 11, 134)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20), 
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), spreadRadius: 1, blurRadius: 5)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Your Desktop's Cloudflare URL", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _myUrlController, style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: "Fetching your secure tunnel...", hintStyle: TextStyle(color: Colors.grey.shade500), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.copy, color: Colors.grey),
                              onPressed: () { Clipboard.setData(ClipboardData(text: _myUrlController.text)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("URL Copied!"))); },
                            ),
                          ),
                          onChanged: _saveMyUrl,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20), 
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), spreadRadius: 1, blurRadius: 5)]),
                    child: Column(
                      children: [
                        const Text("Start a Chat", style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _generatedCode.isEmpty
                            ? ElevatedButton(onPressed: _isLoading ? null : _generateCode, style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 115, 11, 134), minimumSize: const Size(double.infinity, 45)), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Generate 6-Digit Code", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
                            : Column(
                                children: [
                                  Text(_generatedCode, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 115, 11, 134), letterSpacing: 8)),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () { Clipboard.setData(ClipboardData(text: "Join my Guptik chat! URL: ${_myUrlController.text} | Code: $_generatedCode")); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied Invite to Clipboard!"))); },
                                    icon: const Icon(Icons.copy, color: Colors.white), label: const Text("Copy Invite", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 115, 11, 134)),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text("— OR —", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20), 
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), spreadRadius: 1, blurRadius: 5)]),
                    child: Column(
                      children: [
                        const Text("Join a Chat", style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextField(controller: _codeController, style: const TextStyle(color: Colors.black), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Enter Peer's 6-Digit Code", labelStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
                        const SizedBox(height: 12),
                        TextField(controller: _peerUrlController, style: const TextStyle(color: Colors.black), decoration: InputDecoration(labelText: "Peer's Cloudflare URL", labelStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
                        const SizedBox(height: 20),
                        ElevatedButton(onPressed: _isLoading ? null : _joinWithCode, style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 115, 11, 134), minimumSize: const Size(double.infinity, 50)), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Connect securely", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}