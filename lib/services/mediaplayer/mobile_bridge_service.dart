import 'dart:convert';
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class MobileBridgeService {
  final String gatewayUrl; 

  MobileBridgeService({required this.gatewayUrl});

  String get _cleanGateway {
    String url = gatewayUrl.startsWith('http') ? gatewayUrl : 'https://$gatewayUrl';
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Future<List<PlayerVideo>> getRemoteFeed() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('mp_videos')
          .select()
          .order('published_at', ascending: false);
      
      final List<Map<String, dynamic>> allVideos = List<Map<String, dynamic>>.from(response as List);
      
      final List<String> repostIds = allVideos
          .where((v) => v['repost_id'] != null)
          .map((v) => v['repost_id'].toString())
          .toList();

      Map<String, Map<String, dynamic>> originalVideosMap = {};
      if (repostIds.isNotEmpty) {
        final originalsResponse = await supabase
            .from('mp_videos')
            .select('*')
            .filter('id', 'in', repostIds); 
            
        for (final orig in originalsResponse as List) {
          originalVideosMap[orig['id'].toString()] = Map<String, dynamic>.from(orig);
        }
      }

      return allVideos.map((v) {
        if (v['repost_id'] != null) {
          final orig = originalVideosMap[v['repost_id'].toString()];
          if (orig != null) {
            v['video_id'] = orig['video_id'] ?? orig['id']; 
            v['id'] = orig['id']; 
            v['creator_uid'] = orig['creator_uid'];
            v['creator_cloudflare_url'] = orig['creator_cloudflare_url'];
            v['thumbnail_url'] = orig['thumbnail_url'];
            v['original_channel_name'] = orig['channel_name'];
            v['is_repost'] = true;
          }
        }
        final nodeUrl = v['creator_cloudflare_url'] ?? _cleanGateway;
        return PlayerVideo.fromJson(v, nodeUrl);
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
      final response = await http.post(
        Uri.parse('$_cleanGateway/player/video/like'),
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

  Future<void> addVideoView(String videoId, String viewerUid) async {
    try {
      final response = await http.post(
        Uri.parse('$_cleanGateway/player/video/view'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'video_id': videoId, 'viewer_uid': viewerUid}),
      );

      final data = jsonDecode(response.body);
      if (data['status'] == 'view_added') {
        try {
          final supabase = Supabase.instance.client;
          final current = await supabase
              .from('mp_videos')
              .select('view_count')
              .eq('video_id', videoId)
              .maybeSingle();
          final int views = ((current?['view_count'] as int?) ?? 0) + 1;
          await supabase
              .from('mp_videos')
              .update({'view_count': views})
              .eq('video_id', videoId);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('View Tracker Error: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchVideoStats(String videoId) async {
    try {
      final response = await http.get(Uri.parse('$_cleanGateway/player/video/stats/$videoId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Stats Fetch Error: $e');
    }
    return null;
  }

  Future<bool> postComment(
    String videoId, 
    String creatorUid, 
    String commentText, {
    String? parentCommentId,
    String? viewerName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_cleanGateway/player/video/comment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'video_id': videoId, 
          'creator_uid': creatorUid, 
          'comment_text': commentText,
          'parent_comment_id': parentCommentId,
          'viewer_name': viewerName ?? 'Mobile Creator',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Bridge Comment Error: $e');
      return false;
    }
  }

  Future<List<dynamic>> fetchComments(String videoId) async {
    try {
      final response = await http.get(Uri.parse('$_cleanGateway/player/video/comments/$videoId'));
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
      final response = await http.post(
        Uri.parse('$_cleanGateway/player/video/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'video_id': videoId, 'creator_uid': creatorUid}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Bridge Save Error: $e');
      return false;
    }
  }

  Future<bool> repostVideo({
    required String originalVideoId,
    required String originalCreatorUid,
    String? originalCreatorName,
    String? originalChannelName,
    required String reposterUid,
    String? reposterChannelName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_cleanGateway/player/video/repost'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'original_video_id': originalVideoId,
          'original_creator_uid': originalCreatorUid,
          'original_creator_name': originalCreatorName ?? '',
          'original_channel_name': originalChannelName ?? '',
          'reposter_uid': reposterUid,
          'reposter_channel_name': reposterChannelName ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'already_reposted') return false;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Bridge Repost Error: $e');
      return false;
    }
  }

  Future<bool> shareVideo({
    required String videoId,
    required String creatorUid,
    String shareMethod = 'link',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_cleanGateway/player/video/share'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'video_id': videoId,
          'creator_uid': creatorUid,
          'share_method': shareMethod,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Bridge Share Error: $e');
      return false;
    }
  }

  Future<bool> setVideoInterest({
    required String videoId,
    required String creatorUid,
    required String watcherUid,
    required bool? interested,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_cleanGateway/player/video/interest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'video_id': videoId,
          'creator_uid': creatorUid,
          'watcher_uid': watcherUid,
          'interested': interested,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Interest Error: $e');
      return false;
    }
  }

  Future<List<dynamic>> fetchStickers(String videoId) async {
    try {
      final response = await http.get(Uri.parse('$_cleanGateway/player/video/stickers/$videoId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Fetch Stickers Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchChannelProfile(String channelId) async {
    try {
      final response = await http.get(Uri.parse('$_cleanGateway/channel/profile/$channelId'));
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