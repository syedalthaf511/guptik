import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrustMeService {
  static TrustMeService? _instance;
  static TrustMeService get instance => _instance ??= TrustMeService._();
  TrustMeService._();

  WebSocketChannel? _wsChannel;
  final _listeners = <String, List<Function(Map<String, dynamic>)>>{};

  // 🚀 Starts empty, dynamically set by the user's input!
  String _gatewayUrl = '';
  
  String get gatewayUrl => _gatewayUrl;
  String get _wsUrl => '${_gatewayUrl.replaceFirst('http', 'ws')}/ws';

  void setGatewayUrl(String url) {
    var cleanUrl = url.trim();
    if (!cleanUrl.startsWith('http')) cleanUrl = 'https://$cleanUrl';
    cleanUrl = cleanUrl.replaceAll(RegExp(r'/$'), '');
    _gatewayUrl = cleanUrl;
    debugPrint("🌐 Gateway URL dynamically set to: $_gatewayUrl");
  }

  Future<void> connect() async {
    if (_gatewayUrl.isEmpty) return;
    try {
      _wsChannel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _wsChannel!.stream.listen(
        (message) {
          final event = jsonDecode(message as String) as Map<String, dynamic>;
          final type = event['type'] as String?;
          if (type != null) {
            _listeners[type]?.forEach((cb) => cb(event));
            _listeners['*']?.forEach((cb) => cb(event));
          }
        },
        onDone: () => Future.delayed(const Duration(seconds: 5), connect),
      );
    } catch (e) {
      debugPrint("WebSocket Connection Error: $e");
    }
  }

  void forceUIConversationsRefresh() {
    if (_listeners['*'] != null) _listeners['*']?.forEach((cb) => cb({'type': 'connection_established'}));
  }

  Future<Map<String, dynamic>> generateHandshakeCode(String targetUsername) async {
    if (_gatewayUrl.isEmpty) throw Exception("Gateway URL not set!");
    final response = await http.post(
      Uri.parse('$_gatewayUrl/internal/handshake/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'target_username': targetUsername}),
    );
    if (response.statusCode != 200) throw Exception("Generation failed");
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final code = data['code'];

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        const storage = FlutterSecureStorage();
        final myUsername = await storage.read(key: 'current_username') ?? 'Mobile_User';
        var myUrl = await storage.read(key: 'public_url') ?? '';
        if (myUrl.isNotEmpty && !myUrl.startsWith('http')) myUrl = 'https://$myUrl';
        final myIdentityKey = await storage.read(key: 'my_identity_pubkey') ?? '';
        final mySignedPreKey = await storage.read(key: 'my_signed_prekey') ?? '';
        final mySignedPreKeyId = await storage.read(key: 'my_signed_prekey_id') ?? '0';

        await supabase.from('trust_me_secure_invites').insert({
          'creator_id': userId, 'invite_code': code, 'creator_username': myUsername,
          'creator_cloudflare_url': myUrl, 'creator_identity_pubkey': myIdentityKey,
          'creator_signed_prekey': mySignedPreKey, 'creator_signed_prekey_id': int.tryParse(mySignedPreKeyId) ?? 0,
        });
        _startActiveRadar(code);
      }
    } catch (e) { debugPrint("⚠️ Supabase Invite Insert Error: $e"); }
    return data;
  }

  Future<void> _startActiveRadar(String code) async {
    final supabase = Supabase.instance.client;
    bool nodeBJoined = false;
    int attempts = 0;
    while (!nodeBJoined && attempts < 100) {
      await Future.delayed(const Duration(seconds: 3));
      attempts++;
      try {
        final checkResult = await supabase.from('trust_me_secure_invites').select().eq('invite_code', code).maybeSingle();
        if (checkResult != null && checkResult['connected_with'] != null) {
          nodeBJoined = true;
          await finaliseHandshakeLocallyForNodeA(
            joinerGId: checkResult['connected_with'], joinerUsername: checkResult['joiner_username'] ?? 'Peer_B',
            joinerUrl: checkResult['joiner_cloudflare_url'], identityKey: checkResult['joiner_identity_pubkey'] ?? 'pending',
            signedPreKey: checkResult['joiner_signed_prekey'] ?? 'pending', signedPreKeyId: checkResult['joiner_signed_prekey_id'] ?? 0,
          );
        }
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>> initiatePeerConnection({required String peerUrl, required String code, required String myUsername, required String myUrl}) async {
    if (_gatewayUrl.isEmpty) throw Exception("Gateway URL not set!");
    var target = peerUrl.trim();
    if (!target.startsWith('http')) target = 'https://$target';
    target = target.replaceAll(RegExp(r'/$'), '');

    try {
      final supabase = Supabase.instance.client;
      final myUserId = supabase.auth.currentUser?.id;
      if (myUserId != null) {
        final inviteResult = await supabase.from('trust_me_secure_invites').select().eq('invite_code', code).maybeSingle();
        if (inviteResult == null) throw Exception("Invalid or expired invite code.");
        
        final creatorId = inviteResult['creator_id'];
        final creatorUsername = inviteResult['creator_username'] ?? 'Peer_A';
        var creatorUrl = inviteResult['creator_cloudflare_url'] ?? target;
        if (creatorUrl.isNotEmpty && !creatorUrl.startsWith('http')) creatorUrl = 'https://$creatorUrl';

        const storage = FlutterSecureStorage();
        final myIdentityKey = await storage.read(key: 'my_identity_pubkey') ?? '';
        final mySignedPreKey = await storage.read(key: 'my_signed_prekey') ?? '';
        final mySignedPreKeyId = await storage.read(key: 'my_signed_prekey_id') ?? '0';

        await supabase.from('trust_me_secure_invites').update({
          'connected_with': myUserId, 'joiner_username': myUsername, 'joiner_cloudflare_url': myUrl,
          'joiner_identity_pubkey': myIdentityKey, 'joiner_signed_prekey': mySignedPreKey, 'joiner_signed_prekey_id': int.tryParse(mySignedPreKeyId) ?? 0,
        }).eq('id', inviteResult['id']);

        await _finaliseConnectionLocally(
          counterpartGId: creatorId, counterpartUsername: creatorUsername, counterpartUrl: creatorUrl,
          identityKey: inviteResult['creator_identity_pubkey'] ?? 'pending', signedPreKey: inviteResult['creator_signed_prekey'] ?? 'pending',
          signedPreKeyId: int.tryParse(inviteResult['creator_signed_prekey_id']?.toString() ?? '0') ?? 0,
        );
        return {'status': 'linked_and_finalised_locally'};
      }
    } catch (e) { throw Exception("Supabase linking failed: $e"); }
    throw Exception("Authentication error.");
  }

  Future<void> _finaliseConnectionLocally({required String counterpartGId, required String counterpartUsername, required String counterpartUrl, required String identityKey, required String signedPreKey, required int signedPreKeyId}) async {
    final response = await http.post(
      Uri.parse('$_gatewayUrl/internal/finalise_connection'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({ 'counterpart_guptik_id': counterpartGId, 'counterpart_username': counterpartUsername, 'counterpart_url': counterpartUrl, 'contact_identity_pubkey': identityKey, 'contact_signed_prekey': signedPreKey, 'contact_signed_prekey_id': signedPreKeyId }),
    );
    if (response.statusCode != 200) throw Exception("Local DB failure");
    forceUIConversationsRefresh();
  }

  Future<void> finaliseHandshakeLocallyForNodeA({required String joinerGId, required String joinerUsername, required String joinerUrl, String identityKey = 'pending', String signedPreKey = 'pending', int signedPreKeyId = 0}) async {
    await _finaliseConnectionLocally(counterpartGId: joinerGId, counterpartUsername: joinerUsername, counterpartUrl: joinerUrl, identityKey: identityKey, signedPreKey: signedPreKey, signedPreKeyId: signedPreKeyId);
  }

Future<List<ConversationSummary>> getConversations() async {
    if (_gatewayUrl.isEmpty) return [];
    
    final response = await http.get(Uri.parse('$_gatewayUrl/internal/conversations'));
    
    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) throw Exception("Server returned status ${response.statusCode}");

    final data = jsonDecode(response.body);
    
    if (data is Map<String, dynamic> && data['conversations'] != null) {
      return (data['conversations'] as List)
          .map((c) => ConversationSummary.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    
    return []; 
  }
  
  Future<Map<String, dynamic>> sendMessage({required String conversationId, required String content, String contentType = 'text'}) async {
    final myUserId = Supabase.instance.client.auth.currentUser?.id ?? 'unknown_user';
    final myUsername = await const FlutterSecureStorage().read(key: 'current_username') ?? 'Me';
    final response = await http.post(
      Uri.parse('$_gatewayUrl/internal/message/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'conversation_id': conversationId, 'content': content, 'content_type': contentType, 'sender_id': myUserId, 'sender_username': myUsername}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    if (_gatewayUrl.isEmpty) return [];
    try {
      final response = await http.get(Uri.parse('$_gatewayUrl/internal/messages/$conversationId'));
      if (response.statusCode != 200 || response.body.isEmpty) return [];
      final data = jsonDecode(response.body);
      if (data == null || data['messages'] == null) return [];
      return (data['messages'] as List).cast<Map<String, dynamic>>();
    } catch (e) { return []; }
  }

  Future<void> markConversationAsRead(String conversationId) async {
    if (_gatewayUrl.isEmpty) return;
    try {
      final myUserId = Supabase.instance.client.auth.currentUser?.id ?? 'unknown_user';
      
      await http.post(
        Uri.parse('$_gatewayUrl/internal/conversation/$conversationId/read'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': myUserId}),
      );
    } catch (e) {
      debugPrint("Could not mark as read: $e");
    }
  }

  Future<Map<String, dynamic>> streamMediaFile({required String conversationId, required String filePath, required String contentType}) async {
    if (_gatewayUrl.isEmpty) throw Exception("Gateway URL not set!");
    
    final myUserId = Supabase.instance.client.auth.currentUser?.id ?? 'unknown_user';
    final myUsername = await const FlutterSecureStorage().read(key: 'current_username') ?? 'Me';
    final file = File(filePath);
    final ext = filePath.split('.').last.toLowerCase();
    
    final request = http.StreamedRequest('POST', Uri.parse('$_gatewayUrl/internal/message/stream_send/$conversationId/$ext'));
    request.headers['x-sender-id'] = myUserId; 
    request.headers['x-sender-username'] = myUsername; 
    request.headers['x-content-type'] = contentType;
    request.contentLength = await file.length();
    
    file.openRead().listen(request.sink.add, onDone: request.sink.close, onError: request.sink.addError);
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode != 200) throw Exception("Stream Upload Failed: $responseBody");
    return jsonDecode(responseBody) as Map<String, dynamic>;
  }
  
  Future<Map<String, dynamic>?> getContactForConversation(String conversationId) async {
    if (_gatewayUrl.isEmpty) return null;
    try {
      final res = await http.get(Uri.parse('$_gatewayUrl/internal/conversation/$conversationId/contact'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  Future<bool> renameContact({required String conversationId, required String customName}) async {
    if (_gatewayUrl.isEmpty) return false;
    try {
      final response = await http.post(
        Uri.parse('$_gatewayUrl/internal/contact/rename'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conversation_id': conversationId,
          'custom_name': customName,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Rename error: $e");
      return false;
    }
  }

  Future<bool> editMessage({required String conversationId, required String messageId, required String newContent}) async {
    if (_gatewayUrl.isEmpty) return false;
    try {
      final response = await http.post(
        Uri.parse('$_gatewayUrl/internal/message/edit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'conversation_id': conversationId, 'message_id': messageId, 'new_content': newContent}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Edit error: $e");
      return false;
    }
  }

  Future<bool> deleteMessage({required String conversationId, required String messageId, required bool forEveryone}) async {
    if (_gatewayUrl.isEmpty) return false;
    try {
      final response = await http.post(
        Uri.parse('$_gatewayUrl/internal/message/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'conversation_id': conversationId, 'message_id': messageId, 'for_everyone': forEveryone}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Delete error: $e");
      return false;
    }
  }

}

class ConversationSummary {
  final String id; 
  final String type; 
  final String? contactUsername; 
  final String? customUsername;
  final String? lastMessagePreview; 
  final DateTime? lastMessageAt; 
  final int unreadCount;
  bool isOnline; 
  final bool isPinned; 
  final bool isMuted;

  String get displayName => (customUsername != null && customUsername!.trim().isNotEmpty) ? customUsername! : contactUsername ?? "Unknown";

  ConversationSummary({
    required this.id, 
    required this.type, 
    this.contactUsername, 
    this.customUsername, 
    this.lastMessagePreview, 
    this.lastMessageAt, 
    required this.unreadCount, 
    required this.isOnline, 
    required this.isPinned, 
    required this.isMuted
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    // 🚀 THE FIX: Safely parse UTC from Database and convert to Local Time (IST)
    String? rawTime = json['last_message_at'] as String?;
    DateTime? parsedTime;
    
    if (rawTime != null) {
      // Force Flutter to recognize this as UTC time before parsing
      if (!rawTime.endsWith('Z') && !rawTime.contains('+')) {
        rawTime += 'Z'; 
      }
      parsedTime = DateTime.tryParse(rawTime)?.toLocal();
    }

    return ConversationSummary(
      id: json['id'] as String, 
      type: json['type'] as String, 
      contactUsername: json['contact_username'] as String?, 
      customUsername: json['custom_username'] as String?,
      lastMessagePreview: json['last_message_preview'] as String?, 
      lastMessageAt: parsedTime, // 🚀 Fixed Time is mapped here!
      unreadCount: (json['unread_count'] as int?) ?? 0, 
      isOnline: (json['is_online'] as bool?) ?? false, 
      isPinned: (json['is_pinned'] as bool?) ?? false, 
      isMuted: (json['is_muted'] as bool?) ?? false,
    );
  }
}