import 'dart:convert';
import 'dart:io';
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MobileBridgeService {
  final String gatewayUrl; 

  MobileBridgeService({required this.gatewayUrl});

 String get _cleanGateway {
    String url = gatewayUrl.trim();
    
    // Auto-swap old IP if present
    if (url.contains('192.168.1.15')) {
      url = url.replaceAll('192.168.1.15', '192.168.1.186');
    }

    // Force http:// for local network IPs and localhost
    if (url.contains('192.168.') || url.contains('10.0.') || url.contains('127.0.0.1') || url.contains('localhost')) {
      url = url.replaceAll('https://', '').replaceAll('http://', '');
      url = 'http://$url';
    } else {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
    }

    // Enforce port 55000 for local network nodes if missing
    if ((url.contains('192.168.') || url.contains('10.0.') || url.contains('127.0.0.1')) && !url.contains(':55000')) {
      url = '$url:55000';
    }

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

  
  // 🚀 ADDED: posts a new shoppable sticker to the gateway's
  // POST /player/video/sticker endpoint. Metadata goes in headers, the
  // (optional) product image goes as raw bytes in the body — same pattern
  // mobile_upload_service.dart already uses for video uploads.
  Future<bool> addSticker({
    required String videoId,
    required String productName,
    String description = '',
    double timestampInVideo = 0,
    double durationOnScreen = 8,
    double? mrp,
    double? salePrice,
    String currency = 'USD',
    String? linkUrl,
    Map<String, double>? clickableZone,
    File? imageFile,
  }) async {
    try {
      final request = http.Request('POST', Uri.parse('$_cleanGateway/player/video/sticker'));
      request.headers['Content-Type'] = 'application/octet-stream';
      request.headers['x-video-id'] = videoId;
      request.headers['x-product-name'] = Uri.encodeComponent(productName);
      request.headers['x-description'] = Uri.encodeComponent(description);
      request.headers['x-timestamp'] = timestampInVideo.toString();
      request.headers['x-duration'] = durationOnScreen.toString();
      if (mrp != null) request.headers['x-mrp'] = mrp.toString();
      if (salePrice != null) request.headers['x-price'] = salePrice.toString();
      request.headers['x-currency'] = currency;
      if (linkUrl != null && linkUrl.isNotEmpty) {
        request.headers['x-link-url'] = Uri.encodeComponent(linkUrl);
      }
      if (clickableZone != null) {
        request.headers['x-clickable-zone'] = Uri.encodeComponent(jsonEncode(clickableZone));
      }

      request.bodyBytes = imageFile != null ? await imageFile.readAsBytes() : <int>[];

      final streamedResponse = await request.send();
      return streamedResponse.statusCode == 200;
    } catch (e) {
      debugPrint('Add Sticker Error: $e');
      return false;
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