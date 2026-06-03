import 'dart:convert';
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this import

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
        // 1. Extract the raw URL from the database
        String rawUrl = v['creator_cloudflare_url'] ?? '';
        
        // 2. 🚀 THE FIX: Force the URL to have a scheme so ExoPlayer knows it's a web stream!
        String safeUrl = rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl';
        
        // 3. Pass the safe URL to your Video Model
        return PlayerVideo.fromJson(v, safeUrl);
      }).toList();
      
    } catch (e) {
      debugPrint("Bridge Feed Error: $e");
      return [];
    }
  }
  
  // 2. Fetch a specific creator's profile videos
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

  // 3. Send a Like/Reaction
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
}