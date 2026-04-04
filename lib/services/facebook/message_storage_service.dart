import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // Test Connection
  // ---------------------------------------------------------------------------
  Future<bool> testConnection() async {
    try {
      debugPrint("🔍 Testing Supabase connection...");
      await _supabase.from('fb_messages').select('count').limit(1);
      debugPrint("✅ fb_messages table exists");
      await _supabase.from('ig_messages').select('count').limit(1);
      debugPrint("✅ ig_messages table exists");
      await _supabase.from('fb_conversations').select('count').limit(1);
      debugPrint("✅ fb_conversations table exists");
      await _supabase.from('ig_conversations').select('count').limit(1);
      debugPrint("✅ ig_conversations table exists");
      return true;
    } catch (e) {
      debugPrint("❌ Supabase connection test failed: $e");
      return false;
    }
  }

  Future<String?> getConversationIdBySender(
    String platform,
    String senderId,
    String userId,
  ) async {
    try {
      final tableName = platform == 'facebook'
          ? 'fb_conversations'
          : 'ig_conversations';
      final trimmedSenderId = senderId.trim();

      // First, try exact match (for future trimmed entries)
      final exact = await _supabase
          .from(tableName)
          .select('id')
          .eq('user_id', userId)
          .eq('sender_id', trimmedSenderId)
          .maybeSingle();
      if (exact != null) return exact['id'] as String?;

      // If not found, fetch all for the user and compare trimmed values
      final all = await _supabase
          .from(tableName)
          .select('id, sender_id')
          .eq('user_id', userId);
      for (var row in all) {
        if (row['sender_id']?.toString().trim() == trimmedSenderId) {
          return row['id'] as String;
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error getting conversation ID by sender: $e");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Conversation Management
  // ---------------------------------------------------------------------------
  Future<void> saveConversation({
    required String platform,
    required String conversationId,
    required String participantId,
    required String participantName,
    String? participantUsername,
    String? participantAvatar,
    String? lastMessage,
    String? lastMessageTime,
    int unreadCount = 0,
    required String userId,
  }) async {
    try {
      if (platform == 'facebook') {
        final data = {
          'id': conversationId,
          'user_id': userId,
          'sender_id': participantId, // store the PSID here
          'sender_username': participantUsername ?? "sender_$participantId",
          'sender_avatar': participantAvatar,
          'last_message': lastMessage,
          'last_message_time': lastMessageTime,
          'unread_count': unreadCount,
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Check if conversation exists
        final existing = await _supabase
            .from('fb_conversations')
            .select()
            .eq('id', conversationId)
            .maybeSingle();

        if (existing == null) {
          await _supabase.from('fb_conversations').insert(data);
          debugPrint("✅ Inserted new Facebook conversation: $conversationId");
        } else {
          await _supabase
              .from('fb_conversations')
              .update(data)
              .eq('id', conversationId);
          debugPrint("✅ Updated Facebook conversation: $conversationId");
        }
      } else if (platform == 'instagram') {
        final data = {
          'id': conversationId, // UUID for Instagram
          'user_id': userId,
          'sender_id': participantId.trim(),
          'last_message': lastMessage,
          'last_message_time': lastMessageTime,
          'is_unread': unreadCount > 0,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };

        final existing = await _supabase
            .from('ig_conversations')
            .select()
            .eq('id', conversationId)
            .maybeSingle();

        if (existing == null) {
          await _supabase.from('ig_conversations').insert(data);
          debugPrint("✅ Inserted new Instagram conversation: $conversationId");
        } else {
          await _supabase
              .from('ig_conversations')
              .update(data)
              .eq('id', conversationId);
          debugPrint("✅ Updated Instagram conversation: $conversationId");
        }
      }
    } catch (e) {
      debugPrint("❌ Error saving $platform conversation: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // Message Management
  // ---------------------------------------------------------------------------
  Future<void> saveMessage({
    required String platform,
    required String conversationId,
    required String messageId,
    required String content,
    required String messageType,
    required String direction,
    String? status,
    required String timestamp,
    Map<String, dynamic>? mediaInfo,
    Map<String, dynamic>? rawData,
  }) async {
    try {
      final tableName = platform == 'facebook' ? 'fb_messages' : 'ig_messages';
      final now = DateTime.now().toIso8601String();

      final data = {
        'conversation_id': conversationId,
        'message_id': messageId,
        'content': content,
        'message_type': messageType,
        'direction': direction,
        'status': status ?? 'delivered',
        'timestamp': timestamp,
        'media_info': mediaInfo,
        'raw_data': rawData,
        'created_at': now,
        'updated_at': now,
      };

      try {
        await _supabase.from(tableName).insert(data);
        debugPrint("✅ Saved message $messageId to $tableName");
      } catch (insertError) {
        if (insertError.toString().contains('duplicate key')) {
          debugPrint("⚠️ Message $messageId already exists");
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint("❌ Error saving $platform message: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // Message Retrieval
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getMessages(
    String platform,
    String conversationId, {
    int limit = 50,
  }) async {
    try {
      final tableName = platform == 'facebook' ? 'fb_messages' : 'ig_messages';
      debugPrint(
        "🔍 Fetching $platform messages for conversation: $conversationId",
      );

      final response = await _supabase
          .from(tableName)
          .select()
          .eq('conversation_id', conversationId)
          .order('timestamp', ascending: true)
          .limit(limit);

      debugPrint("✅ Found ${response.length} messages");
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("❌ Error getting messages: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Update Message Status
  // ---------------------------------------------------------------------------
  Future<void> updateMessageStatus(
    String platform,
    String messageId,
    String status,
  ) async {
    try {
      final tableName = platform == 'facebook' ? 'fb_messages' : 'ig_messages';
      await _supabase
          .from(tableName)
          .update({
            'status': status,
            'status_timestamp': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('message_id', messageId);
      debugPrint("✅ Updated message $messageId status to $status");
    } catch (e) {
      debugPrint("❌ Error updating message status: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // Get All Conversations for a User
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getUserConversations(
    String platform,
    String userId,
  ) async {
    try {
      final tableName = platform == 'facebook'
          ? 'fb_conversations'
          : 'ig_conversations';
      debugPrint("🔍 Fetching $tableName for user: $userId");
      final response = await _supabase
          .from(tableName)
          .select()
          .eq('user_id', userId)
          .order('last_message_time', ascending: false);
      debugPrint("📊 Raw response from $tableName: $response");
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("❌ Error getting user conversations: $e");
      return [];
    }
  }
}