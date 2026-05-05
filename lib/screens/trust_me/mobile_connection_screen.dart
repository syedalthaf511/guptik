import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/trustme/trust_me_service.dart';
import 'mobile_chat_list_screen.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

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
    setState(() {
      _isLoading = true;
    });
    const storage = FlutterSecureStorage();
    String? savedUrl = await storage.read(key: 'public_url');
    
    if (savedUrl != null && savedUrl.isNotEmpty) {
      if (mounted) {
        setState(() { 
          _myUrlController.text = savedUrl; 
          _isLoading = false; 
        });
      }
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

        if (fetchedUrl != null && fetchedUrl.isNotEmpty) {
          if (mounted) {
            setState(() {
              _myUrlController.text = fetchedUrl!;
            });
          }
          await storage.write(key: 'public_url', value: fetchedUrl);
        }
      }
    } catch (e) { 
      debugPrint("URL fetch error: $e"); 
    } finally { 
      if (mounted) {
        setState(() {
          _isLoading = false;
        }); 
      }
    }
  }

  Future<void> _saveMyUrl(String url) async => await const FlutterSecureStorage().write(key: 'public_url', value: url);

  Future<void> _generateCode() async {
    if (_myUrlController.text.isEmpty) return;
    await _saveMyUrl(_myUrlController.text);
    TrustMeService.instance.setGatewayUrl(_myUrlController.text);
    
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await TrustMeService.instance.generateHandshakeCode("Mobile_User");
      setState(() {
        _generatedCode = data['code'];
      });
    } catch (e) { 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: $e", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: _ancientGold,
        )); 
      }
    } finally { 
      if (mounted) {
        setState(() {
          _isLoading = false;
        }); 
      }
    }
  }

  Future<void> _joinWithCode() async {
    if (_codeController.text.isEmpty || _peerUrlController.text.isEmpty || _myUrlController.text.isEmpty) return;
    await _saveMyUrl(_myUrlController.text);
    TrustMeService.instance.setGatewayUrl(_myUrlController.text);
    
    setState(() {
      _isLoading = true;
    });
    try {
      await TrustMeService.instance.initiatePeerConnection(peerUrl: _peerUrlController.text, code: _codeController.text, myUsername: "Mobile_User", myUrl: _myUrlController.text);
      if (mounted) {
        // 🚀 THE FIX: Push the chat screen on top after a successful link!
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MobileChatListScreen()));
      }
    } catch (e) { 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed: $e", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
        )); 
      }
    } finally { 
      if (mounted) {
        setState(() {
          _isLoading = false;
        }); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg, 
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Secure Connection", style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.black.withValues(alpha: 0.7), 
        elevation: 0,
        iconTheme: const IconThemeData(color: _ancientGold),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _ancientGold.withValues(alpha: 0.2), height: 1.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat, color: _ancientGold),
            tooltip: 'Open Secure Chats',
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const MobileChatListScreen())
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // The Shared Cinematic Nebula Background
            const Positioned.fill(child: DynamicAppBackground()),
            
            _isLoading && _myUrlController.text.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _ancientGold))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 110, 24, 40), 
                  child: Column(
                    children: [
                      // My Cloudflare URL Container
                      Container(
                        padding: const EdgeInsets.all(20), 
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6), 
                          borderRadius: BorderRadius.circular(16), 
                          border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4), 
                              spreadRadius: 1, 
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.link, color: _ancientGold, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Your Desktop's Cloudflare URL", 
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _myUrlController, 
                              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                              decoration: InputDecoration(
                                hintText: "Fetching your secure tunnel...", 
                                hintStyle: TextStyle(color: Colors.grey.shade500), 
                                filled: true, 
                                fillColor: Colors.black.withValues(alpha: 0.5), 
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12), 
                                  borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3))
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12), 
                                  borderSide: const BorderSide(color: _ancientGold, width: 2)
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.copy, color: _ancientGold),
                                  onPressed: () { 
                                    Clipboard.setData(ClipboardData(text: _myUrlController.text)); 
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                      content: Text("URL Copied!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                      backgroundColor: _ancientGold,
                                    )); 
                                  },
                                ),
                              ),
                              onChanged: _saveMyUrl,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Start a Chat Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24), 
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6), 
                          borderRadius: BorderRadius.circular(16), 
                          border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4), 
                              spreadRadius: 1, 
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.vpn_key, color: _ancientGold, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  "Start a Chat", 
                                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _generatedCode.isEmpty
                                ? ElevatedButton(
                                    onPressed: _isLoading ? null : _generateCode, 
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _ancientGold, 
                                      foregroundColor: Colors.black,
                                      minimumSize: const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 8,
                                    ), 
                                    child: _isLoading 
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                                        : const Text("Generate 6-Digit Code", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                                  )
                                : Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _ancientGold.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _ancientGold.withValues(alpha: 0.5), width: 2),
                                        ),
                                        child: Text(
                                          _generatedCode, 
                                          style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: _ancientGold, letterSpacing: 12)
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () { 
                                          Clipboard.setData(ClipboardData(text: "Join my Guptik chat! URL: ${_myUrlController.text} | Code: $_generatedCode")); 
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                            content: Text("Copied Invite to Clipboard!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                            backgroundColor: _ancientGold,
                                          )); 
                                        },
                                        icon: const Icon(Icons.copy, color: Colors.black), 
                                        label: const Text("Copy Invite", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), 
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _ancientGold,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: _ancientGold.withValues(alpha: 0.3))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text("OR", style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          ),
                          Expanded(child: Container(height: 1, color: _ancientGold.withValues(alpha: 0.3))),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Join a Chat Container
                      Container(
                        padding: const EdgeInsets.all(24), 
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6), 
                          borderRadius: BorderRadius.circular(16), 
                          border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4), 
                              spreadRadius: 1, 
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login, color: _ancientGold, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  "Join a Chat", 
                                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _codeController, 
                              // THE FIX 1: Removed textAlign from TextStyle
                              style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 4, fontWeight: FontWeight.bold), 
                              keyboardType: TextInputType.number, 
                              // THE FIX 2: textAlign belongs directly to the TextField
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: "Enter Peer's 6-Digit Code", 
                                labelStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 0, fontSize: 14), 
                                floatingLabelAlignment: FloatingLabelAlignment.center,
                                alignLabelWithHint: true,
                                filled: true, 
                                fillColor: Colors.black.withValues(alpha: 0.5), 
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12), 
                                  borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3))
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12), 
                                  borderSide: const BorderSide(color: _ancientGold, width: 2)
                                )
                              )
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _peerUrlController, 
                              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'), 
                              decoration: InputDecoration(
                                labelText: "Peer's Cloudflare URL", 
                                labelStyle: TextStyle(color: Colors.grey.shade400), 
                                filled: true, 
                                fillColor: Colors.black.withValues(alpha: 0.5), 
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12), 
                                  borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3))
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12), 
                                  borderSide: const BorderSide(color: _ancientGold, width: 2)
                                )
                              )
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _joinWithCode, 
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _ancientGold, 
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 8,
                              ), 
                              child: _isLoading 
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                                  : const Text("Connect Securely", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}