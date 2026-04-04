import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:guptik/models/facebook/meta_chat_model.dart';
import 'package:guptik/models/facebook/meta_comment_model.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/models/facebook/meta_insights_model.dart';
import 'package:guptik/models/facebook/meta_story_reel_model.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/services/facebook/message_storage_service.dart';

class MetaService {
  static const String _graphApiVersion = "v24.0";
  static const String _uploadServiceUrl =
      "https://uploadservice.myqrmart.com/upload";
  final MessageStorageService _storageService = MessageStorageService();

  Map<String, dynamic>? _cachedCredentials;

  // ---------------------------------------------------------------------------
  // 🔐 HELPER: Convert string to UUID (for Instagram conversation IDs)
  // ---------------------------------------------------------------------------
  String _stringToUuid(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return '${digest.toString().substring(0, 8)}-'
        '${digest.toString().substring(8, 12)}-'
        '${digest.toString().substring(12, 16)}-'
        '${digest.toString().substring(16, 20)}-'
        '${digest.toString().substring(20, 32)}';
  }

  // ---------------------------------------------------------------------------
  // 🔐 HELPER: Fetch Credentials from Supabase
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> _getCredentials() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("User not logged in to App");

    if (_cachedCredentials != null) return _cachedCredentials!;

    try {
      final response = await Supabase.instance.client
          .from('user_api_settings')
          .select()
          .eq('user_id', user.id)
          .single();
      _cachedCredentials = response;
      return response;
    } catch (e) {
      throw Exception("Configure settings first.");
    }
  }

  // Public method to get access token
  Future<String?> getAccessToken() async {
    try {
      final creds = await _getCredentials();
      return creds['facebook_page_access_token'] ??
          creds['facebook_user_access_token'];
    } catch (e) {
      debugPrint("Error getting access token: $e");
      return null;
    }
  }

  // Public method to get account ID for a platform
  Future<String?> getAccountId(SocialPlatform platform) async {
    try {
      final creds = await _getCredentials();
      if (platform == SocialPlatform.facebook) {
        return creds['facebook_account_id'];
      } else {
        return creds['instagram_account_id'];
      }
    } catch (e) {
      debugPrint("Error getting account ID: $e");
      return null;
    }
  }

  // Helper: Make authorized HTTP request with Bearer token
  Future<http.Response> _makeAuthorizedGet(
    String url,
    String accessToken,
  ) async {
    debugPrint("API Call: $url");
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    debugPrint("Response Status: ${response.statusCode}");
    if (response.statusCode != 200) {
      debugPrint("Response Error: ${response.body}");
    }
    return response;
  }

  // Helper: Upload image to your own upload service
  Future<String> _uploadToMyService(File imageFile) async {
    try {
      var uri = Uri.parse(_uploadServiceUrl);
      var request = http.MultipartRequest('POST', uri);
      request.headers['Content-Type'] = 'multipart/form-data';
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      debugPrint("📤 Uploading to your service: $_uploadServiceUrl");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      debugPrint("📨 Upload service response status: ${response.statusCode}");
      debugPrint("📨 Upload service response body: ${response.body}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final fileUrl = data['file']['url'];
          debugPrint("✅ Image uploaded successfully: $fileUrl");
          return fileUrl;
        }
      }
      return '';
    } catch (e) {
      debugPrint("❌ Error uploading to your service: $e");
      return '';
    }
  }

  // ---------------------------------------------------------------------------
  // 1. GET CONTENT (Posts, Reels, Stories)
  // ---------------------------------------------------------------------------
  Future<List<MetaContent>> getContent(
    SocialPlatform platform,
    ContentType filter,
  ) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return [];

    String url = '';

    if (platform == SocialPlatform.instagram) {
      final String? igId = creds['instagram_account_id'];
      if (igId == null) return [];

      if (filter == ContentType.story) {
        url =
            'https://graph.facebook.com/$_graphApiVersion/$igId/stories?fields=id,caption,media_type,media_url,thumbnail_url,like_count,comments_count';
      } else if (filter == ContentType.mention) {
        url =
            'https://graph.facebook.com/$_graphApiVersion/$igId/tags?fields=id,caption,media_type,media_url,thumbnail_url,like_count,comments_count';
      } else {
        url =
            'https://graph.facebook.com/$_graphApiVersion/$igId/media?fields=id,caption,media_type,media_product_type,media_url,thumbnail_url,like_count,comments_count';
      }
    } else {
      final String? pageId = creds['facebook_account_id'];
      if (pageId == null) return [];

      if (filter == ContentType.story) {
        return [];
      } else {
        url =
            'https://graph.facebook.com/$_graphApiVersion/$pageId/feed?fields=id,message,full_picture,likes.summary(true),comments.summary(total_count),created_time';
        debugPrint("Facebook feed URL: $url");
      }
    }

    try {
      final response = await _makeAuthorizedGet(url, accessToken);

      if (response.statusCode != 200) {
        debugPrint("API Error: ${response.body}");
        return [];
      }

      final data = json.decode(response.body);
      if (!data.containsKey('data')) return [];
      final List<dynamic> items = data['data'];

      List<MetaContent> results = [];

      for (var item in items) {
        ContentType itemType = ContentType.post;

        if (platform == SocialPlatform.instagram) {
          if (filter == ContentType.story) {
            itemType = ContentType.story;
          } else if (filter == ContentType.mention) {
            itemType = ContentType.mention;
          } else if (item['media_product_type'] == 'REELS') {
            itemType = ContentType.reel;
          }

          String img = item['media_url'] ?? '';
          if (item['media_type'] == 'VIDEO' && item['thumbnail_url'] != null) {
            img = item['thumbnail_url'];
          }

          if (filter == itemType) {
            results.add(
              MetaContent(
                id: item['id'],
                platform: platform,
                type: itemType,
                imageUrl: img,
                caption: item['caption'] ?? '',
                likes: item['like_count'] ?? 0,
                comments: item['comments_count'] ?? 0,
              ),
            );
          }
        } else {
          debugPrint(
            '✅ Creating Facebook MetaContent with platform: $platform',
          );

          int totalComments = 0;
          if (item['comments'] != null) {
            if (item['comments']['summary'] != null &&
                item['comments']['summary']['total_count'] != null) {
              totalComments = item['comments']['summary']['total_count'];
              debugPrint("Comment total_count: $totalComments");
            } else {
              totalComments = item['comments']['count'] ?? 0;
            }
          }

          results.add(
            MetaContent(
              id: item['id'],
              platform: platform,
              type: ContentType.post,
              imageUrl: item['full_picture'],
              caption: item['message'] ?? '',
              likes: item['likes']?['summary']?['total_count'] ?? 0,
              comments: totalComments,
            ),
          );
        }
      }
      return results;
    } catch (e) {
      debugPrint("Error fetching content: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 2. UPLOAD POST - Using your own upload service for Instagram
  // ---------------------------------------------------------------------------
  Future<bool> uploadPost(
    SocialPlatform platform,
    File? imageFile,
    String caption,
  ) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return false;

    // --- A. FACEBOOK UPLOAD ---
    if (platform == SocialPlatform.facebook) {
      final String? pageId = creds['facebook_account_id'];
      if (pageId == null) return false;

      // If no image, post as text-only using /feed endpoint
      if (imageFile == null) {
        final uri = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$pageId/feed?message=${Uri.encodeComponent(caption)}&access_token=$accessToken',
        );
        try {
          debugPrint("📤 FB Text-only Post URL: $uri");
          final response = await http.post(uri);
          debugPrint("📨 FB Response Status: ${response.statusCode}");
          debugPrint("📨 FB Response Body: ${response.body}");

          if (response.statusCode == 200) {
            debugPrint("✅ FB Text-only Post Success: ${response.body}");
            return true;
          } else {
            debugPrint(
              "❌ FB Feed Error (${response.statusCode}): ${response.body}",
            );
            return false;
          }
        } catch (e) {
          debugPrint("❌ FB Text-only Upload Error: $e");
          return false;
        }
      }

      // If image exists, post with image using /photos endpoint
      var uri = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$pageId/photos',
      );
      var request = http.MultipartRequest('POST', uri);

      request.fields['access_token'] = accessToken;
      request.fields['message'] = caption;
      request.files.add(
        await http.MultipartFile.fromPath('source', imageFile.path),
      );

      try {
        debugPrint("📤 FB Image Post URL: $uri");
        debugPrint("📤 FB Image Post Fields: ${request.fields}");
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        debugPrint("📨 FB Image Response Status: ${response.statusCode}");
        debugPrint("📨 FB Image Response Body: ${response.body}");

        if (response.statusCode == 200) {
          debugPrint("✅ FB Image Post Success: ${response.body}");
          return true;
        } else {
          debugPrint(
            "❌ FB Image Upload Error (${response.statusCode}): ${response.body}",
          );
          return false;
        }
      } catch (e) {
        debugPrint("❌ FB Image Upload Error: $e");
        return false;
      }
    }
    // --- B. INSTAGRAM UPLOAD - USING YOUR OWN UPLOAD SERVICE ---
    else {
      final String? igId = creds['instagram_account_id'];
      if (igId == null) return false;

      if (imageFile == null) {
        debugPrint("❌ IG Error: Instagram posts require an image.");
        return false;
      }

      try {
        final String publicUrl = await _uploadToMyService(imageFile);

        if (publicUrl.isEmpty) {
          debugPrint("❌ Failed to get public URL from upload service");
          return false;
        }

        debugPrint("📤 Image uploaded to your service: $publicUrl");

        final containerUrl = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$igId/media',
        );

        final containerResponse = await http.post(
          containerUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'image_url': publicUrl,
            'caption': caption,
            'access_token': accessToken,
          }),
        );

        if (containerResponse.statusCode != 200) {
          debugPrint("❌ IG Container Error: ${containerResponse.body}");
          return false;
        }

        final containerData = json.decode(containerResponse.body);
        final String creationId = containerData['id'];

        debugPrint("✅ Container created with ID: $creationId");

        await Future.delayed(const Duration(seconds: 5));

        final publishUrl = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$igId/media_publish',
        );

        final publishResponse = await http.post(
          publishUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'creation_id': creationId,
            'access_token': accessToken,
          }),
        );

        if (publishResponse.statusCode == 200) {
          debugPrint("✅ Instagram post published successfully!");
          return true;
        } else {
          debugPrint("❌ Instagram publish error: ${publishResponse.body}");
          return false;
        }
      } catch (e) {
        debugPrint("❌ Instagram upload error: $e");
        return false;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 3. GET UNIFIED INBOX (FB + IG Merged) - WITH STORAGE
  // ---------------------------------------------------------------------------
  Future<List<MetaChat>> getUnifiedInbox() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    List<MetaChat> allChats = [];

    // Load Facebook conversations from Supabase
    final fbConversations = await _storageService.getUserConversations(
      'facebook',
      userId,
    );
    for (var conv in fbConversations) {
      allChats.add(
        MetaChat(
          id: conv['id'],
          supabaseId: conv['id'],
          participantId: conv['sender_id'], // ✅ must be the PSID
          senderName: conv['sender_username'] ?? 'Facebook User',
          lastMessage: conv['last_message'] ?? '',
          time: _formatTime(conv['last_message_time']),
          rawTimestamp: conv['last_message_time'],
          avatarUrl: conv['sender_avatar'] ?? '',
          platform: SocialPlatform.facebook,
          isUnread: (conv['unread_count'] ?? 0) > 0,
        ),
      );
    }

    // Load Instagram conversations from Supabase
    final igConversations = await _storageService.getUserConversations(
      'instagram',
      userId,
    );
    for (var conv in igConversations) {
      // For Instagram, the stored id is the UUID, but we need the original ID for API calls.
      // However, we are not using the API anymore, so we can use the UUID as both.
      // But the original ID is not stored, so we'll just use the UUID.
      allChats.add(
        MetaChat(
          id: conv['id'], // UUID
          supabaseId: conv['id'], // same
          participantId: conv['sender_id'] ?? '',
          senderName:
              'Instagram User', // we don't store sender_username in ig_conversations
          lastMessage: conv['last_message'] ?? '',
          time: _formatTime(conv['last_message_time']),
          rawTimestamp: conv['last_message_time'],
          avatarUrl: '', // not stored
          platform: SocialPlatform.instagram,
          isUnread: conv['is_unread'] ?? false,
        ),
      );
    }

    // Sort by last_message_time descending
    allChats.sort((a, b) {
      DateTime? timeA = _parseIsoTime(a.rawTimestamp);
      DateTime? timeB = _parseIsoTime(b.rawTimestamp);
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeB.compareTo(timeA);
    });
    debugPrint(
      "Inbox loaded conversation IDs: ${allChats.map((c) => '${c.id} (${c.senderName})').toList()}",
    );
    return allChats;
  }

  // ---------------------------------------------------------------------------
  // 4. GET INSTAGRAM MESSAGES - WITH STORAGE
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getInstagramMessages(
    String conversationId,
  ) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];
    final myIgId = creds['instagram_account_id'];

    if (accessToken == null) return [];

    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$conversationId/messages'
        '?fields=id,message,text,from,created_time,timestamp,attachments'
        '&limit=50'
        '&access_token=$accessToken',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> rawMsgs = data['data'] ?? [];

        List<Map<String, dynamic>> messages = [];

        final uuidConversationId = _stringToUuid(conversationId);

        for (var m in rawMsgs) {
          final senderId = m['from']?['id'];
          final isFromMe = senderId == myIgId;

          String messageContent = '';
          if (m['message'] != null && m['message'].isNotEmpty) {
            messageContent = m['message'];
          } else if (m['text'] != null && m['text'].isNotEmpty) {
            messageContent = m['text'];
          } else if (m['attachments'] != null) {
            messageContent = '📎 Attachment';
          }

          final message = {
            'id': m['id'],
            'message': messageContent,
            'is_from_me': isFromMe,
            'created_time':
                m['created_time'] ??
                m['timestamp'] ??
                DateTime.now().toIso8601String(),
            'message_id': m['id'],
            'content': messageContent,
            'message_type': m['attachments'] != null ? 'attachment' : 'text',
            'direction': isFromMe ? 'outgoing' : 'incoming',
            'timestamp': m['created_time'] ?? m['timestamp'],
            'media_info': m['attachments'],
            'raw_data': m,
          };

          messages.add(message);

          await _storageService.saveMessage(
            platform: 'instagram',
            conversationId: uuidConversationId,
            messageId: m['id'],
            content: messageContent,
            messageType: m['attachments'] != null ? 'attachment' : 'text',
            direction: isFromMe ? 'outgoing' : 'incoming',
            timestamp:
                m['created_time'] ??
                m['timestamp'] ??
                DateTime.now().toIso8601String(),
            mediaInfo: m['attachments'],
            rawData: m,
          );
        }

        // Update conversation with latest message
        if (messages.isNotEmpty) {
          final latestMsg = messages.last;
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            await _storageService.saveConversation(
              platform: 'instagram',
              conversationId: uuidConversationId,
              participantId: '',
              participantName: '',
              participantAvatar: '',
              lastMessage: latestMsg['content'] ?? '',
              lastMessageTime:
                  latestMsg['timestamp'] ?? DateTime.now().toIso8601String(),
              unreadCount: 0,
              userId: userId,
            );
          }
        }

        return messages;
      }
    } catch (e) {
      debugPrint("❌ Error loading Instagram messages: $e");
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // 5. GET FACEBOOK MESSAGES - WITH STORAGE
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getChatMessages(
    String conversationId,
  ) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];
    final myPageId = creds['facebook_account_id'];
    final userId = Supabase.instance.client.auth.currentUser?.id;

    debugPrint("🔍 [FB MSG] Starting getChatMessages");
    debugPrint("🔍 [FB MSG] Conversation ID: $conversationId");
    debugPrint("🔍 [FB MSG] My Page ID: $myPageId");
    debugPrint("🔍 [FB MSG] User ID: $userId");

    if (accessToken == null || userId == null) {
      debugPrint("❌ [FB MSG] Missing access token or user ID");
      return [];
    }

    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$conversationId/messages'
        '?fields=message,from,created_time,attachments,sticker'
        '&limit=50'
        '&access_token=$accessToken',
      );

      debugPrint("📥 [FB MSG] Fetching from: $url");
      final response = await http.get(url);
      debugPrint("📥 [FB MSG] Response status: ${response.statusCode}");

      if (response.statusCode != 200) {
        debugPrint("❌ [FB MSG] Error response: ${response.body}");
        return [];
      }

      final data = json.decode(response.body);
      final List<dynamic> rawMsgs = data['data'] ?? [];

      debugPrint("✅ [FB MSG] Found ${rawMsgs.length} messages");

      if (rawMsgs.isEmpty) {
        debugPrint("ℹ️ [FB MSG] No messages found");
        return [];
      }

      // Get conversation details
      String participantName = 'User';
      String participantId = '';

      try {
        final convUrl = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$conversationId?fields=participants,updated_time&access_token=$accessToken',
        );
        debugPrint("🔍 [FB MSG] Fetching conversation details from: $convUrl");

        final convResponse = await http.get(convUrl);
        debugPrint(
          "🔍 [FB MSG] Conversation response status: ${convResponse.statusCode}",
        );

        if (convResponse.statusCode == 200) {
          final convData = json.decode(convResponse.body);
          debugPrint("🔍 [FB MSG] Conversation data: $convData");

          final participants = convData['participants']?['data'] ?? [];
          debugPrint("🔍 [FB MSG] Participants count: ${participants.length}");

          for (var p in participants) {
            debugPrint("🔍 [FB MSG] Participant: ${p['id']} - ${p['name']}");
            if (p['id'] != myPageId) {
              participantName = p['name'] ?? p['username'] ?? 'User';
              participantId = p['id'] ?? '';
              debugPrint(
                "✅ [FB MSG] Selected participant: $participantName ($participantId)",
              );
              break;
            }
          }
        }
      } catch (e) {
        debugPrint("❌ [FB MSG] Error fetching conversation details: $e");
      }

      List<Map<String, dynamic>> messages = [];

      for (var m in rawMsgs) {
        final senderId = m['from']?['id'];
        final isFromMe = senderId == myPageId;

        String messageContent = '';
        String messageType = 'text';

        if (m['message'] != null && m['message'].isNotEmpty) {
          messageContent = m['message'];
        } else if (m['sticker'] != null) {
          messageContent = '😊 Sticker';
          messageType = 'sticker';
        } else if (m['attachments'] != null) {
          messageContent = '📎 Attachment';
          messageType = 'attachment';
        }

        final message = {
          'id': m['id'],
          'message': messageContent,
          'is_from_me': isFromMe,
          'created_time': m['created_time'],
          'message_id': m['id'],
          'content': messageContent,
          'message_type': messageType,
          'direction': isFromMe ? 'outgoing' : 'incoming',
          'timestamp': m['created_time'],
          'media_info': m['attachments'],
          'raw_data': m,
        };

        messages.add(message);

        debugPrint("💾 [FB MSG] Attempting to save message: ${m['id']}");
        try {
          await _storageService.saveMessage(
            platform: 'facebook',
            conversationId: conversationId,
            messageId: m['id'],
            content: messageContent,
            messageType: messageType,
            direction: isFromMe ? 'outgoing' : 'incoming',
            timestamp: m['created_time'],
            mediaInfo: m['attachments'],
            rawData: m,
          );
          debugPrint("✅ [FB MSG] Save completed for message: ${m['id']}");
        } catch (e) {
          debugPrint("❌ [FB MSG] Save failed for message: ${m['id']} - $e");
        }
      }

      // Update conversation with latest message
      if (messages.isNotEmpty) {
        final Map<String, dynamic> latestMsg = messages.last;
        debugPrint("💾 [FB MSG] Updating conversation with latest message");
        debugPrint("💾 [FB MSG] Latest message: ${latestMsg['content']}");

        try {
          await _storageService.saveConversation(
            platform: 'facebook',
            conversationId: conversationId,
            participantId: participantId,
            participantName: participantName,
            participantAvatar: '',
            lastMessage: latestMsg['content'] ?? '',
            lastMessageTime:
                latestMsg['timestamp'] ?? DateTime.now().toIso8601String(),
            unreadCount: 0,
            userId: userId,
          );
          debugPrint("✅ [FB MSG] Conversation updated successfully");
        } catch (e) {
          debugPrint("❌ [FB MSG] Conversation update failed: $e");
        }
      }

      debugPrint("✅ [FB MSG] Returning ${messages.length} messages");
      return messages;
    } catch (e) {
      debugPrint("❌ [FB MSG] Fatal error: $e");
      return [];
    }
  }
  // Helper to determine Facebook message type

  // ---------------------------------------------------------------------------
  // 6. SEND INSTAGRAM MESSAGE - WITH STORAGE
  // ---------------------------------------------------------------------------
  Future<bool> sendInstagramMessage({
    required String recipientId,
    required String message,
  }) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (accessToken == null || userId == null) {
      debugPrint("❌ Missing access token or user ID");
      return false;
    }

    final trimmedRecipientId = recipientId.trim();
    debugPrint(
      "🔍 Looking up Instagram conversation for recipient: '$trimmedRecipientId' (userId: $userId)",
    );

    // Look up correct conversation ID
    var conversationId = await _storageService.getConversationIdBySender(
      'instagram',
      trimmedRecipientId,
      userId,
    );

    if (conversationId == null) {
      debugPrint(
        "⚠️ No conversation found for recipient $trimmedRecipientId. Creating a new one.",
      );
      // Use same UUID generation as webhook
      conversationId = _stringToUuid(trimmedRecipientId);
      await _storageService.saveConversation(
        platform: 'instagram',
        conversationId: conversationId,
        participantId: trimmedRecipientId,
        participantName: '',
        participantAvatar: '',
        lastMessage: null,
        lastMessageTime: null,
        unreadCount: 0,
        userId: userId,
      );
      debugPrint(
        "✅ Created new Instagram conversation with ID: $conversationId",
      );
    }

    debugPrint(
      "🔍 Sending Instagram message to recipient: $trimmedRecipientId (conversation: $conversationId)",
    );

    final sendUrl = Uri.parse(
      'https://graph.facebook.com/$_graphApiVersion/me/messages',
    );
    final payload = {
      'recipient': {'id': trimmedRecipientId},
      'message': {'text': message},
      'access_token': accessToken,
    };

    try {
      final response = await http.post(
        sendUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      debugPrint("📨 Send response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final messageId =
            data['message_id'] ??
            DateTime.now().millisecondsSinceEpoch.toString();
        final timestamp = DateTime.now().toIso8601String();

        debugPrint("✅ Instagram message sent successfully");

        // Save message and conversation asynchronously (fire and forget)
        // Don't wait for this to complete - the API success is what matters
        _storageService
            .saveMessage(
              platform: 'instagram',
              conversationId: conversationId,
              messageId: messageId,
              content: message,
              messageType: 'text',
              direction: 'outgoing',
              timestamp: timestamp,
            )
            .catchError((e) {
              debugPrint("⚠️ Error saving Instagram message to database: $e");
            });

        _storageService
            .saveConversation(
              platform: 'instagram',
              conversationId: conversationId,
              participantId: trimmedRecipientId,
              participantName: '',
              lastMessage: message,
              lastMessageTime: timestamp,
              unreadCount: 0,
              userId: userId,
            )
            .catchError((e) {
              debugPrint(
                "⚠️ Error updating Instagram conversation in database: $e",
              );
            });

        return true;
      } else {
        debugPrint("❌ API error: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 7. SEND FACEBOOK MESSAGE - WITH STORAGE
  // ---------------------------------------------------------------------------
  Future<bool> sendMessage({
    required String conversationId,
    required String recipientId,
    required String message,
  }) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (accessToken == null || userId == null) {
      debugPrint("❌ Missing access token or user ID");
      return false;
    }

    try {
      debugPrint("🔍 Sending message to recipient: $recipientId");

      final sendUrl = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/me/messages',
      );
      final payload = {
        'recipient': {'id': recipientId},
        'message': {'text': message},
        'access_token': accessToken,
      };
      debugPrint("📤 Sending payload: $payload");
      final response = await http.post(
        sendUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      debugPrint("📨 Send response status: ${response.statusCode}");
      debugPrint("📨 Send response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final messageId =
            data['message_id'] ??
            DateTime.now().millisecondsSinceEpoch.toString();
        final timestamp = DateTime.now().toIso8601String();

        debugPrint("✅ Facebook message sent successfully");

        // Save message and conversation asynchronously (fire and forget)
        // Don't wait for this to complete - the API success is what matters
        _storageService
            .saveMessage(
              platform: 'facebook',
              conversationId: conversationId,
              messageId: messageId,
              content: message,
              messageType: 'text',
              direction: 'outgoing',
              timestamp: timestamp,
            )
            .catchError((e) {
              debugPrint("⚠️ Error saving Facebook message to database: $e");
            });

        _storageService
            .saveConversation(
              platform: 'facebook',
              conversationId: conversationId,
              participantId: recipientId, // recipientId is the PSID
              participantName: '', // not needed here
              lastMessage: message,
              lastMessageTime: timestamp,
              unreadCount: 0,
              userId: userId,
            )
            .catchError((e) {
              debugPrint(
                "⚠️ Error updating Facebook conversation in database: $e",
              );
            });

        return true;
      } else {
        debugPrint("❌ Graph API error: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Send Exception: $e");
      return false;
    }
  }
  // ---------------------------------------------------------------------------
  // 8. SEND MEDIA MESSAGE (Image, Video, Document)
  // ---------------------------------------------------------------------------
  Future<bool> sendMediaMessage({
    required SocialPlatform platform,
    required String recipientId,
    required File mediaFile,
    required String conversationId, // ignored; we look up the correct one
    required String mediaType,
    String? caption,
    String? fileName,
    String? mimeType,
  }) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];
    final String? pageId = platform == SocialPlatform.facebook
        ? creds['facebook_account_id']
        : null;
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (accessToken == null || userId == null) {
      debugPrint("❌ Missing access token or user ID");
      return false;
    }

    final trimmedRecipientId = recipientId.trim();
    debugPrint(
      "🔍 [MEDIA] Looking up conversation for recipient: '$trimmedRecipientId' (userId: $userId)",
    );

    // Look up the correct conversation ID
    final correctConversationId = await _storageService
        .getConversationIdBySender(
          platform == SocialPlatform.facebook ? 'facebook' : 'instagram',
          trimmedRecipientId,
          userId,
        );
    if (correctConversationId == null) {
      debugPrint(
        "❌ No conversation found for recipient $trimmedRecipientId. Cannot send media.",
      );
      return false;
    }
    debugPrint("✅ Found conversation ID: $correctConversationId");

    try {
      // Upload file to your service
      final fileUrl = await _uploadToMyService(mediaFile);
      if (fileUrl.isEmpty) {
        debugPrint("❌ Failed to upload media – URL is empty");
        return false;
      }
      debugPrint("📤 Uploaded file URL: $fileUrl");

      // Build attachment payload
      Map<String, dynamic> attachmentPayload;
      if (mediaType == 'image') {
        attachmentPayload = {
          'type': 'image',
          'payload': {'url': fileUrl},
        };
      } else if (mediaType == 'video') {
        attachmentPayload = {
          'type': 'video',
          'payload': {'url': fileUrl},
        };
      } else if (mediaType == 'document') {
        final docName = fileName ?? mediaFile.path.split('/').last;
        attachmentPayload = {
          'type': 'file',
          'payload': {'url': fileUrl, 'filename': docName},
        };
      } else {
        debugPrint("❌ Unsupported media type: $mediaType");
        return false;
      }

      final payload = {
        'recipient': {'id': trimmedRecipientId},
        'message': {'attachment': attachmentPayload},
        'access_token': accessToken,
      };

      Uri url;
      if (platform == SocialPlatform.facebook) {
        if (pageId == null) {
          debugPrint("❌ Facebook page ID missing");
          return false;
        }
        url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$pageId/messages',
        );
        payload['messaging_type'] = 'RESPONSE';
      } else {
        url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/me/messages',
        );
      }

      debugPrint("📤 Sending media to: $url");
      debugPrint("📤 Payload: $payload");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      debugPrint("📨 Send attachment response status: ${response.statusCode}");
      debugPrint("📨 Send attachment response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final messageId =
            data['message_id'] ??
            DateTime.now().millisecondsSinceEpoch.toString();
        final timestamp = DateTime.now().toIso8601String();

        debugPrint("✅ Media message sent successfully");

        // Prepare media info
        final mediaInfo = {
          'url': fileUrl,
          'type': mediaType,
          'caption': caption,
          if (mediaType == 'document')
            'filename': fileName ?? mediaFile.path.split('/').last,
          if (mediaType == 'document')
            'mime_type': mimeType ?? 'application/octet-stream',
        };

        // Save message and conversation asynchronously (fire and forget)
        // Don't wait for this to complete - the API success is what matters
        _storageService
            .saveMessage(
              platform: platform == SocialPlatform.facebook
                  ? 'facebook'
                  : 'instagram',
              conversationId: correctConversationId,
              messageId: messageId,
              content: fileUrl,
              messageType: mediaType,
              direction: 'outgoing',
              timestamp: timestamp,
              mediaInfo: mediaInfo,
            )
            .catchError((e) {
              debugPrint("⚠️ Error saving media message to database: $e");
            });

        // Update conversation last message
        final displayMessage = caption != null && caption.isNotEmpty
            ? '📸 $caption'
            : mediaType == 'image'
            ? '📸 Photo'
            : mediaType == 'video'
            ? '🎥 Video'
            : '📄 Document';
        _storageService
            .saveConversation(
              platform: platform == SocialPlatform.facebook
                  ? 'facebook'
                  : 'instagram',
              conversationId: correctConversationId,
              participantId: trimmedRecipientId,
              participantName: '',
              lastMessage: displayMessage,
              lastMessageTime: timestamp,
              unreadCount: 0,
              userId: userId,
            )
            .catchError((e) {
              debugPrint("⚠️ Error updating conversation after media send: $e");
            });

        return true;
      } else {
        debugPrint("❌ Graph API error: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Exception in sendMediaMessage: $e");
      return false;
    }
  } // ---------------------------------------------------------------------------

  // 9. HELPERS
  // ---------------------------------------------------------------------------
  DateTime? _parseIsoTime(String? isoTime) {
    if (isoTime == null) return null;
    return DateTime.tryParse(isoTime);
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '';
    try {
      final date = DateTime.parse(isoTime);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  // ---------------------------------------------------------------------------
  // 10. DELETE POST
  // ---------------------------------------------------------------------------
  Future<bool> deletePost(String postId, SocialPlatform platform) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return false;

    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$postId?access_token=$accessToken',
      );

      final response = await http.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint("✅ Post deleted successfully: $postId");
        return true;
      } else {
        debugPrint("❌ Delete Error (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Delete Exception: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 11. EDIT POST
  // ---------------------------------------------------------------------------
  Future<bool> editPost(
    String postId,
    String newCaption,
    SocialPlatform platform, {
    File? imageFile,
  }) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return false;

    try {
      if (imageFile != null) {
        final deleteUrl = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$postId?access_token=$accessToken',
        );

        final deleteResponse = await http.delete(deleteUrl);
        if (deleteResponse.statusCode != 200 &&
            deleteResponse.statusCode != 204) {
          debugPrint("❌ Failed to delete old post: ${deleteResponse.body}");
          return false;
        }

        debugPrint("✅ Old post deleted successfully");

        final uploadSuccess = await uploadPost(platform, imageFile, newCaption);

        if (uploadSuccess) {
          debugPrint("✅ Post updated with new image successfully");
          return true;
        } else {
          debugPrint("❌ Failed to upload new post with image");
          return false;
        }
      } else {
        final url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$postId',
        );

        final response = await http.post(
          url,
          body: {'message': newCaption, 'access_token': accessToken},
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          debugPrint("✅ Post caption updated successfully: $postId");
          return true;
        } else {
          debugPrint(
            "❌ Update Error (${response.statusCode}): ${response.body}",
          );
          return false;
        }
      }
    } catch (e) {
      debugPrint("❌ Update Exception: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 12. GET POST COMMENTS
  // ---------------------------------------------------------------------------
  Future<List<MetaComment>> getPostComments(
    String postId, {
    SocialPlatform? platform,
  }) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return [];

    final bool isInstagram =
        platform == SocialPlatform.instagram ||
        postId.contains('instagram') ||
        postId.startsWith('178') ||
        postId.startsWith('179');

    try {
      if (isInstagram) {
        final url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$postId/comments'
          '?fields=id,text,username,timestamp,like_count,replies{id,text,username,timestamp,like_count}'
          '&limit=50&access_token=$accessToken',
        );

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (!data.containsKey('data')) return [];

          final List<dynamic> comments = data['data'];
          return comments.map((comment) {
            List<MetaComment> replies = [];
            if (comment.containsKey('replies') &&
                comment['replies'].containsKey('data')) {
              final repliesData = comment['replies']['data'] as List;
              replies = repliesData.map((replyJson) {
                return MetaComment(
                  id: replyJson['id'] ?? '',
                  authorName: replyJson['username'] ?? 'Instagram User',
                  authorId: replyJson['id'] ?? '',
                  text: replyJson['text'] ?? '',
                  createdTime:
                      replyJson['timestamp'] ??
                      DateTime.now().toIso8601String(),
                  likeCount: replyJson['like_count'] ?? 0,
                  platform: SocialPlatform.instagram,
                  isFromPageOwner: false,
                  replies: [],
                );
              }).toList();
            }

            return MetaComment(
              id: comment['id'] ?? '',
              authorName: comment['username'] ?? 'Instagram User',
              authorId: comment['id'] ?? '',
              text: comment['text'] ?? '',
              createdTime:
                  comment['timestamp'] ?? DateTime.now().toIso8601String(),
              likeCount: comment['like_count'] ?? 0,
              platform: SocialPlatform.instagram,
              isFromPageOwner: false,
              replies: replies,
            );
          }).toList();
        }
      } else {
        final url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$postId/comments'
          '?fields=id,message,from{id,name,picture},created_time,like_count,'
          'comments{id,message,from{id,name,picture},created_time,like_count}'
          '&limit=50&access_token=$accessToken',
        );

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (!data.containsKey('data')) return [];

          final List<dynamic> comments = data['data'];
          return comments.map((comment) {
            List<MetaComment> replies = [];
            if (comment.containsKey('comments') &&
                comment['comments'].containsKey('data')) {
              final repliesData = comment['comments']['data'] as List;
              replies = repliesData.map((replyJson) {
                return MetaComment(
                  id: replyJson['id'] ?? '',
                  authorName: replyJson['from']?['name'] ?? 'Unknown',
                  authorId: replyJson['from']?['id'] ?? '',
                  text: replyJson['message'] ?? '',
                  createdTime: replyJson['created_time'] ?? '',
                  likeCount: replyJson['like_count'] ?? 0,
                  platform: SocialPlatform.facebook,
                  isFromPageOwner: false,
                  replies: [],
                );
              }).toList();
            }

            return MetaComment(
              id: comment['id'] ?? '',
              authorName: comment['from']?['name'] ?? 'Unknown',
              authorId: comment['from']?['id'] ?? '',
              text: comment['message'] ?? '',
              createdTime: comment['created_time'] ?? '',
              likeCount: comment['like_count'] ?? 0,
              platform: SocialPlatform.facebook,
              isFromPageOwner: false,
              replies: replies,
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint("Error loading comments: $e");
    }

    return [];
  }

  // ---------------------------------------------------------------------------
  // 13. REPLY TO COMMENT
  // ---------------------------------------------------------------------------
  Future<bool> replyToComment(String commentId, String replyText) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return false;

    final bool isInstagram =
        commentId.startsWith('178') ||
        commentId.startsWith('179') ||
        commentId.startsWith('180') ||
        commentId.startsWith('181');

    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$commentId/${isInstagram ? 'replies' : 'comments'}',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': replyText, 'access_token': accessToken}),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Reply added successfully");
        return true;
      } else {
        debugPrint("❌ Reply Error (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Reply Exception: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 14. DELETE COMMENT
  // ---------------------------------------------------------------------------
  Future<bool> deleteComment(String commentId) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return false;

    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$commentId?access_token=$accessToken',
      );

      final response = await http.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint("✅ Comment deleted successfully");
        return true;
      } else {
        debugPrint("❌ Delete Error (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Delete Exception: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 15. POST COMMENT
  // ---------------------------------------------------------------------------
  Future<bool> postComment(
    String postId,
    String commentText, {
    SocialPlatform? platform,
  }) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return false;

    final bool isInstagram =
        platform == SocialPlatform.instagram ||
        postId.startsWith('178') ||
        postId.startsWith('179');

    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$postId/${isInstagram ? 'comments' : 'comments'}',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': commentText,
          'access_token': accessToken,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Comment posted successfully");
        return true;
      } else {
        debugPrint("❌ Comment error: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Comment exception: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 16. GET AUDIENCE DEMOGRAPHICS
  // ---------------------------------------------------------------------------
  Future<List<MetaAudienceDemographics>> getAudienceDemographics(
    SocialPlatform platform,
  ) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    String? accountId = platform == SocialPlatform.facebook
        ? creds['facebook_account_id']
        : creds['instagram_account_id'];

    if (accessToken == null || accountId == null) return [];

    try {
      return [
        MetaAudienceDemographics(
          ageGroup: '18-24',
          percentage: 0.25,
          genderPrimary: 'M',
        ),
        MetaAudienceDemographics(
          ageGroup: '25-34',
          percentage: 0.35,
          genderPrimary: 'F',
        ),
        MetaAudienceDemographics(
          ageGroup: '35-44',
          percentage: 0.25,
          genderPrimary: 'M',
        ),
        MetaAudienceDemographics(
          ageGroup: '45+',
          percentage: 0.15,
          genderPrimary: null,
        ),
      ];
    } catch (e) {
      debugPrint("Error fetching audience demographics: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 17. GET PAGE INSIGHTS
  // ---------------------------------------------------------------------------
  Future<MetaPageInsights?> getPageInsights(SocialPlatform platform) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    String? accountId = platform == SocialPlatform.facebook
        ? creds['facebook_account_id']
        : creds['instagram_account_id'];

    if (accessToken == null || accountId == null) return null;

    try {
      final infoUrl = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$accountId?fields=name,followers_count&access_token=$accessToken',
      );

      final infoResponse = await http.get(infoUrl);
      if (infoResponse.statusCode != 200) return null;

      final infoData = json.decode(infoResponse.body);

      final insightsUrl = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$accountId/insights?metric=page_impressions,page_consumptions,page_fan_adds&period=day&access_token=$accessToken',
      );

      final insightsResponse = await http.get(insightsUrl);
      int impressions = 0;
      int reach = 0;

      if (insightsResponse.statusCode == 200) {
        final insightsData = json.decode(insightsResponse.body);
        final data = insightsData['data'] as List<dynamic>;

        for (var metric in data) {
          if (metric['name'] == 'page_impressions') {
            impressions = metric['values']?[0]?['value'] ?? 0;
          } else if (metric['name'] == 'page_consumptions') {
            reach = metric['values']?[0]?['value'] ?? 0;
          }
        }
      }

      return MetaPageInsights(
        accountId: accountId,
        accountName: infoData['name'] ?? 'Unknown',
        platform: platform,
        followers: infoData['followers_count'] ?? 0,
        following: 0,
        postsCount: 0,
        engagementRate: 0.0,
        totalReach: reach,
        totalImpressions: impressions,
        topPosts: [],
      );
    } catch (e) {
      debugPrint("Error fetching page insights: $e");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 18. GET POST INSIGHTS
  // ---------------------------------------------------------------------------
  Future<MetaPostInsights?> getPostInsights(String postId) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return null;

    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$postId?fields=message,likes.summary(true),comments.summary(true),shares,created_time,full_picture&access_token=$accessToken',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);

      final likes = data['likes']?['summary']?['total_count'] ?? 0;
      final comments = data['comments']?['summary']?['total_count'] ?? 0;
      final shares = data['shares'] ?? 0;
      final totalEngagement = likes + comments + shares;

      double engagementRate = 0.0;
      if (totalEngagement > 0) {
        engagementRate = (totalEngagement / 1000);
      }

      return MetaPostInsights(
        postId: postId,
        postCaption: data['message'] ?? '',
        platform: SocialPlatform.facebook,
        likes: likes,
        comments: comments,
        shares: shares,
        reach: 0,
        impressions: 0,
        engagementRate: engagementRate,
        createdTime: data['created_time'] ?? '',
        thumbnailUrl: data['full_picture'],
      );
    } catch (e) {
      debugPrint("Error fetching post insights: $e");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 19. GET STORIES
  // ---------------------------------------------------------------------------
  Future<List<MetaStory>> getStories(SocialPlatform platform) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    String? accountId = platform == SocialPlatform.facebook
        ? creds['facebook_account_id']
        : creds['instagram_account_id'];

    if (accessToken == null || accountId == null) return [];

    try {
      final url =
          'https://graph.facebook.com/$_graphApiVersion/$accountId/stories?fields=id,media_type,media_url,thumbnail_url,caption,created_time';

      final response = await _makeAuthorizedGet(url, accessToken);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      if (!data.containsKey('data')) return [];

      final List<dynamic> stories = data['data'];
      return stories
          .map(
            (story) => MetaStory(
              id: story['id'] ?? '',
              mediaUrl: story['media_url'] ?? '',
              caption: story['caption'],
              platform: platform,
              createdTime: story['created_time'] ?? '',
              thumbnail: story['thumbnail_url'],
            ),
          )
          .toList();
    } catch (e) {
      debugPrint("Error fetching stories: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 20. GET REELS (now fetches from the Instagram account linked to the Facebook page)
  // ---------------------------------------------------------------------------
  Future<List<MetaReel>> getReels(SocialPlatform platform) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return [];

    if (platform == SocialPlatform.instagram) {
      final accountId = creds['instagram_account_id'];
      if (accountId == null) return [];
      return _fetchReels(accountId, accessToken, platform);
    } else {
      // Facebook: need to get the linked Instagram business account ID
      final pageId = creds['facebook_account_id'];
      if (pageId == null) return [];

      final instagramAccountId = await _getInstagramAccountIdForPage(
        pageId,
        accessToken,
      );
      if (instagramAccountId == null) return [];

      return _fetchReels(instagramAccountId, accessToken, platform);
    }
  }

  /// Fetches the Instagram Business account ID linked to a Facebook page.
  Future<String?> _getInstagramAccountIdForPage(
    String pageId,
    String accessToken,
  ) async {
    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$pageId?fields=instagram_business_account&access_token=$accessToken',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final instagramId = data['instagram_business_account']?['id'];
        if (instagramId != null) {
          debugPrint("Found Instagram business account ID: $instagramId");
          return instagramId.toString();
        }
        debugPrint("No Instagram business account linked to page $pageId");
      } else {
        debugPrint(
          "Failed to fetch Instagram account for page: ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("Error fetching Instagram account: $e");
    }
    return null;
  }

  /// Fetches reels from a given account ID (Instagram Business account).
  Future<List<MetaReel>> _fetchReels(
    String accountId,
    String accessToken,
    SocialPlatform platform,
  ) async {
    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$accountId/media'
        '?media_type=REELS'
        '&fields=id,title,media_type,media_url,thumbnail_url,caption,created_time,like_count,comments_count'
        '&access_token=$accessToken',
      );
      final response = await http.get(url);
      if (response.statusCode != 200) {
        debugPrint("Failed to fetch reels: ${response.body}");
        return [];
      }
      final data = json.decode(response.body);
      if (!data.containsKey('data')) return [];

      final List<dynamic> reels = data['data'];
      return reels
          .where(
            (reel) =>
                reel['media_type'] == 'REELS' || reel['media_type'] == 'REEL',
          )
          .map(
            (reel) => MetaReel(
              id: reel['id'] ?? '',
              videoUrl: reel['media_url'] ?? '',
              thumbnail: reel['thumbnail_url'],
              caption: reel['caption'] ?? reel['title'] ?? '',
              platform: platform,
              createdTime: reel['created_time'] ?? '',
              likes: reel['like_count'] ?? 0,
              comments: reel['comments_count'] ?? 0,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint("Error fetching reels: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 21. GET POST LIKES
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getPostLikes(
    String postId, {
    SocialPlatform? platform,
  }) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return [];

    final bool isInstagram =
        platform == SocialPlatform.instagram ||
        postId.contains('instagram') ||
        postId.startsWith('178') ||
        postId.startsWith('179');

    try {
      if (isInstagram) {
        final url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$postId?fields=like_count&access_token=$accessToken',
        );

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final likeCount = data['like_count'] ?? 0;

          return [
            {
              'id': 'placeholder',
              'name': '$likeCount people liked this post',
              'is_placeholder': true,
              'count': likeCount,
            },
          ];
        }
        return [];
      } else {
        final url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$postId/likes?fields=id,name&limit=100&access_token=$accessToken',
        );

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (!data.containsKey('data')) return [];

          final List<dynamic> likes = data['data'];
          return likes.map((like) {
            return {
              'id': like['id'] ?? '',
              'name': like['name'] ?? 'Facebook User',
            };
          }).toList();
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching likes: $e");
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // 22. GET TOP PERFORMING POSTS
  // ---------------------------------------------------------------------------
  Future<List<MetaPostInsights>> getTopPerformingPosts(
    SocialPlatform platform, {
    int limit = 5,
  }) async {
    final creds = await _getCredentials();
    String? accountId = platform == SocialPlatform.facebook
        ? creds['facebook_account_id']
        : creds['instagram_account_id'];

    if (accountId == null) return [];

    try {
      final content = await getContent(platform, ContentType.post);

      final sortedContent =
          content.map((post) => (post, post.likes + post.comments)).toList()
            ..sort((a, b) => b.$2.compareTo(a.$2));

      final topPosts = <MetaPostInsights>[];

      for (
        var i = 0;
        i < sortedContent.length && topPosts.length < limit;
        i++
      ) {
        final post = sortedContent[i].$1;
        final engagement = sortedContent[i].$2;

        topPosts.add(
          MetaPostInsights(
            postId: post.id,
            postCaption: post.caption,
            platform: platform,
            likes: post.likes,
            comments: post.comments,
            shares: 0,
            reach: engagement,
            impressions: 0,
            engagementRate:
                (engagement / (post.likes + post.comments + 1)) * 100,
            createdTime: '',
            thumbnailUrl: post.imageUrl,
          ),
        );
      }

      return topPosts;
    } catch (e) {
      debugPrint("Error fetching top posts: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 23. GET STORIES & REELS SUMMARY
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> getStoriesReelsSummary(
    SocialPlatform platform,
  ) async {
    try {
      final results = await Future.wait([
        getStories(platform),
        getReels(platform),
      ]);

      final stories = results[0] as List<MetaStory>;
      final reels = results[1] as List<MetaReel>;

      final totalStoryViews = stories.fold<int>(0, (sum, s) => sum + s.views);
      final totalStoryReplies = stories.fold<int>(
        0,
        (sum, s) => sum + s.replies,
      );

      final totalReelViews = reels.fold<int>(0, (sum, r) => sum + r.plays);
      final totalReelEngagement = reels.fold<int>(
        0,
        (sum, r) => sum + r.totalEngagement,
      );

      return {
        'stories': stories,
        'reels': reels,
        'totalStories': stories.length,
        'totalReels': reels.length,
        'totalStoryViews': totalStoryViews,
        'totalStoryReplies': totalStoryReplies,
        'totalReelViews': totalReelViews,
        'totalReelEngagement': totalReelEngagement,
        'averageStoryViews': stories.isNotEmpty
            ? totalStoryViews ~/ stories.length
            : 0,
        'averageReelViews': reels.isNotEmpty
            ? totalReelViews ~/ reels.length
            : 0,
      };
    } catch (e) {
      debugPrint("Error fetching stories/reels summary: $e");
      return {
        'stories': [],
        'reels': [],
        'totalStories': 0,
        'totalReels': 0,
        'totalStoryViews': 0,
        'totalStoryReplies': 0,
        'totalReelViews': 0,
        'totalReelEngagement': 0,
        'averageStoryViews': 0,
        'averageReelViews': 0,
      };
    }
  }

  // ---------------------------------------------------------------------------
  // 24. POST STORY
  // ---------------------------------------------------------------------------
  Future<bool> postStory(
    SocialPlatform platform,
    File imageFile,
    String? caption,
  ) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    String? accountId = platform == SocialPlatform.facebook
        ? creds['facebook_account_id']
        : creds['instagram_account_id'];

    if (accessToken == null || accountId == null) return false;

    if (platform == SocialPlatform.instagram) {
      try {
        final publicUrl = await _uploadToMyService(imageFile);
        if (publicUrl.isEmpty) return false;

        final url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$accountId/media',
        );

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'image_url': publicUrl,
            'caption': caption,
            'media_type': 'STORIES',
            'access_token': accessToken,
          }),
        );

        if (response.statusCode == 200) {
          debugPrint("✅ Instagram story container created");
          return true;
        } else {
          debugPrint("❌ Instagram story error: ${response.body}");
          return false;
        }
      } catch (e) {
        debugPrint("❌ Instagram story exception: $e");
        return false;
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // 25. EDIT STORY
  // ---------------------------------------------------------------------------
  Future<bool> editStory(String storyId, String newCaption) async {
    try {
      final creds = await _getCredentials();
      final String? accessToken =
          creds['facebook_page_access_token'] ??
          creds['facebook_user_access_token'];

      if (accessToken == null) return false;

      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$storyId',
      );

      final response = await http.post(
        url,
        body: {'caption': newCaption, 'access_token': accessToken},
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Story updated successfully");
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Error editing story: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 26. ARCHIVE STORY
  // ---------------------------------------------------------------------------
  Future<bool> archiveStory(String storyId) async {
    try {
      final creds = await _getCredentials();
      final String? accessToken =
          creds['facebook_page_access_token'] ??
          creds['facebook_user_access_token'];

      if (accessToken == null) return false;

      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$storyId',
      );

      final response = await http.post(
        url,
        body: {'is_archived': 'true', 'access_token': accessToken},
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Story archived successfully");
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Error archiving story: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 27. DELETE STORY
  // ---------------------------------------------------------------------------
  Future<bool> deleteStory(String storyId) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return false;

    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$storyId?access_token=$accessToken',
      );

      final response = await http.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint("✅ Story deleted successfully");
        return true;
      } else {
        debugPrint("❌ Delete Error: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Delete Exception: $e");
      return false;
    }
  }

  // 28. GET PAGE INFO (Fetch from API if not in credentials)
  // ---------------------------------------------------------------------------
  Future<Map<String, String>> getPageInfo() async {
    try {
      final creds = await _getCredentials();
      final String? accessToken = creds['facebook_page_access_token'];

      String facebookPageName = 'Not connected';
      String facebookPagePicture = '';
      String instagramAccountName = 'Not connected';
      String instagramAccountPicture = '';

      // Get Facebook Page info
      final fbPageId = creds['facebook_account_id'];
      if (fbPageId != null && accessToken != null) {
        try {
          // Method 1: Get picture from fields
          final response = await http.get(
            Uri.parse(
              'https://graph.facebook.com/$_graphApiVersion/$fbPageId?fields=name,picture.width(200).height(200)&access_token=$accessToken',
            ),
          );
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            facebookPageName = data['name'] ?? 'Facebook Page';
            if (data['picture'] != null && data['picture']['data'] != null) {
              facebookPagePicture = data['picture']['data']['url'] ?? '';
            }
            debugPrint("✅ Facebook page: $facebookPageName");
          }

          // Method 2: If still no picture, try direct picture endpoint
          if (facebookPagePicture.isEmpty) {
            final picResponse = await http.get(
              Uri.parse(
                'https://graph.facebook.com/$fbPageId/picture?type=large&redirect=false&access_token=$accessToken',
              ),
            );
            if (picResponse.statusCode == 200) {
              final picData = json.decode(picResponse.body);
              if (picData['data'] != null && picData['data']['url'] != null) {
                facebookPagePicture = picData['data']['url'];
                debugPrint(
                  "✅ Facebook page picture from direct endpoint: $facebookPagePicture",
                );
              }
            }
          }
        } catch (e) {
          debugPrint("Error fetching Facebook page info: $e");
        }
      }

      // Get Instagram Account info
      final igId = creds['instagram_account_id'];
      if (igId != null && accessToken != null) {
        try {
          // Method 1: Try profile_picture_url field
          final response = await http.get(
            Uri.parse(
              'https://graph.facebook.com/$_graphApiVersion/$igId?fields=username,profile_picture_url&access_token=$accessToken',
            ),
          );
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            instagramAccountName = data['username'] ?? 'Instagram Account';
            instagramAccountPicture = data['profile_picture_url'] ?? '';
            debugPrint("✅ Instagram account: $instagramAccountName");
          } else {
            // Method 2: Try profile_pic field
            final altResponse = await http.get(
              Uri.parse(
                'https://graph.facebook.com/$_graphApiVersion/$igId?fields=username,profile_pic&access_token=$accessToken',
              ),
            );
            if (altResponse.statusCode == 200) {
              final altData = json.decode(altResponse.body);
              instagramAccountName = altData['username'] ?? 'Instagram Account';
              instagramAccountPicture = altData['profile_pic'] ?? '';
              debugPrint("✅ Instagram account from alt: $instagramAccountName");
            }
          }
        } catch (e) {
          debugPrint("Error fetching Instagram account info: $e");
        }
      }

      debugPrint(
        "📸 Facebook picture: ${facebookPagePicture.isNotEmpty ? 'Yes' : 'No'}",
      );
      debugPrint(
        "📸 Instagram picture: ${instagramAccountPicture.isNotEmpty ? 'Yes' : 'No'}",
      );

      return {
        'facebook_page_name': facebookPageName,
        'facebook_page_picture': facebookPagePicture,
        'instagram_account_name': instagramAccountName,
        'instagram_account_picture': instagramAccountPicture,
        'facebook_page_id': fbPageId?.toString() ?? '',
        'instagram_account_id': igId?.toString() ?? '',
      };
    } catch (e) {
      debugPrint("❌ Error getting page info: $e");
      return {
        'facebook_page_name': 'Not connected',
        'facebook_page_picture': '',
        'instagram_account_name': 'Not connected',
        'instagram_account_picture': '',
        'facebook_page_id': '',
        'instagram_account_id': '',
      };
    }
  }
}