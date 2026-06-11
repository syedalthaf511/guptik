import 'dart:convert';
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MobileBridgeService {
  final String gatewayUrl; 

  MobileBridgeService({required this.gatewayUrl});

  Future<List<PlayerVideo>> getRemoteFeed() async {
    try {
      final supabase = Supabase.instance.client;
      
      final response = await supabase
          .from('mp_videos')
          .select()
          .order('published_at', ascending: false);
      
      return (response as List).map((v) {
        String rawUrl = v['creator_cloudflare_url'] ?? '';
        String safeUrl = rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl';
        return PlayerVideo.fromJson(v, safeUrl);
      }).toList();
      
    } catch (e) {
      debugPrint("Bridge Feed Error: $e");
      return [];
    }
  }
  
  Future<List<PlayerVideo>> fetchChannelVideos(String nodeUrl, String channelId) async {
    try {
      final safeUrl = nodeUrl.startsWith('http') ? nodeUrl : 'https://$nodeUrl';
      final response = await http.get(Uri.parse('$safeUrl/channel/videos/$channelId'));
      
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((v) => PlayerVideo.fromJson(v, safeUrl)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Bridge Channel Videos Error: $e');
      return [];
    }
  }

  Future<bool> postReaction(String videoId, String creatorUid, String reactionType) async {
    try {
      final safeUrl = gatewayUrl.startsWith('http') ? gatewayUrl : 'https://$gatewayUrl';
      
      final response = await http.post(
        Uri.parse('$safeUrl/player/video/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'video_id': videoId, 
          'creator_uid': creatorUid, 
          'reaction_type': reactionType
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'already_liked') return false;
        return true; 
      }
      return false;
    } catch (e) { 
      debugPrint('Bridge Reaction Error: $e');
      return false; 
    }
  }

  // 🚀 PROXY TRACKER: Increments the view inside the gatekeeper unique tracker table
  Future<void> addVideoView(String videoId, String viewerUid) async {
    try {
      final safeUrl = gatewayUrl.startsWith('http') ? gatewayUrl : 'https://$gatewayUrl';
      final response = await http.post(
        Uri.parse('$safeUrl/player/video/view'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'video_id': videoId, 'viewer_uid': viewerUid}),
      );

      final data = jsonDecode(response.body);
      if (data['status'] == 'view_added') {
        await Supabase.instance.client.rpc('increment_video_view', params: {'vid': videoId});
      }
    } catch (e) {
      debugPrint('View Tracker Error: $e');
    }
  }

  // 🚀 STATS TRACKER: Synchronizes real-time views, likes, and count structures
  Future<Map<String, dynamic>?> fetchVideoStats(String videoId) async {
    try {
      final safeUrl = gatewayUrl.startsWith('http') ? gatewayUrl : 'https://$gatewayUrl';
      final response = await http.get(Uri.parse('$safeUrl/player/video/stats/$videoId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Stats Fetch Error: $e');
    }
    return null;
  }


  // 🚀 ADD THESE TO mobile_bridge_service.dart

  Future<bool> postComment(String videoId, String creatorUid, String commentText) async {
    try {
      final safeUrl = gatewayUrl.startsWith('http') ? gatewayUrl : 'https://$gatewayUrl';
      final response = await http.post(
        Uri.parse('$safeUrl/player/video/comment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'video_id': videoId, 'creator_uid': creatorUid, 'comment_text': commentText}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Bridge Comment Error: $e');
      return false;
    }
  }


  // 🚀 ADD THIS METHOD to mobile_bridge_service.dart
  Future<List<dynamic>> fetchComments(String videoId) async {
    try {
      final safeUrl = gatewayUrl.startsWith('http') ? gatewayUrl : 'https://$gatewayUrl';
      final response = await http.get(Uri.parse('$safeUrl/player/video/comments/$videoId'));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Fetch Comments Error: $e');
      return [];
    }
  }

  Future<bool> saveVideo(String videoId, String creatorUid) async {
    try {
      final safeUrl = gatewayUrl.startsWith('http') ? gatewayUrl : 'https://$gatewayUrl';
      final response = await http.post(
        Uri.parse('$safeUrl/player/video/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'video_id': videoId, 'creator_uid': creatorUid}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Bridge Save Error: $e');
      return false;
    }
  }

  // 🚀 ADD THIS METHOD to mobile_bridge_service.dart
  Future<Map<String, dynamic>?> fetchChannelProfile(String channelId) async {
    try {
      final safeUrl = gatewayUrl.startsWith('http') ? gatewayUrl : 'https://$gatewayUrl';
      final response = await http.get(Uri.parse('$safeUrl/channel/profile/$channelId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Profile Fetch Error: $e');
      return null;
    }
  }
}