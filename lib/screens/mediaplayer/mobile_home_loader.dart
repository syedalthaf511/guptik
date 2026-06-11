import 'package:flutter/material.dart';
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:guptik/services/mediaplayer/mobile_bridge_service.dart';
import 'package:guptik/widgets/mediaplayer/mobile_video_player_widget.dart';

class MobileHomeLoader extends StatefulWidget {
  // 🚀 Accept the dynamic Gateway URL from the Main Layout
  final String gatewayUrl;

  const MobileHomeLoader({Key? key, required this.gatewayUrl}) : super(key: key);

  @override
  _MobileHomeLoaderState createState() => _MobileHomeLoaderState();
}

class _MobileHomeLoaderState extends State<MobileHomeLoader> {
  late MobileBridgeService _bridge;
  List<PlayerVideo> _videos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // 🚀 Initialize the bridge using the dynamic URL
    _bridge = MobileBridgeService(gatewayUrl: widget.gatewayUrl);
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    try {
      final videos = await _bridge.getRemoteFeed();
      
      // 🚀 Safety check to prevent memory leak crashes
      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load videos. Check your Gateway URL.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.white))),
      );
    }

    // 🚀 Clean Video List Directly inside the Loader
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Guptik Network', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)
        ),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          // 🚀 We use a Stateful card here so the views can update live!
          return LoaderVideoCard(
            video: _videos[index], 
            gatewayUrl: widget.gatewayUrl,
          );
        },
      ),
    );
  }
}

// ============================================================================
// 🚀 STATEFUL VIDEO CARD (Fixes the Live View Bug & Removes Action Buttons)
// ============================================================================
class LoaderVideoCard extends StatefulWidget {
  final PlayerVideo video;
  final String gatewayUrl;

  const LoaderVideoCard({Key? key, required this.video, required this.gatewayUrl}) : super(key: key);

  @override
  State<LoaderVideoCard> createState() => _LoaderVideoCardState();
}

class _LoaderVideoCardState extends State<LoaderVideoCard> {
  late int _liveViews;
  late final MobileBridgeService _bridge;

  @override
  void initState() {
    super.initState();
    _liveViews = widget.video.viewCount; // Start with the DB default
    _bridge = MobileBridgeService(gatewayUrl: widget.video.creatorUrl);
    _fetchLiveNodeViews(); // Ping the node for the real number immediately
  }

  Future<void> _fetchLiveNodeViews() async {
    final stats = await _bridge.fetchVideoStats(widget.video.videoId);
    if (stats != null && stats['views'] != null && mounted) {
      setState(() {
        _liveViews = stats['views'];
      });
    }
  }

  String _formatViews(int views) {
    if (views >= 1000000) return '${(views / 1000000).toStringAsFixed(1)}M';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}K';
    return views.toString();
  }

  String _getTimeAgo(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'recently';
    try {
      final date = DateTime.parse(dateString);
      final difference = DateTime.now().difference(date);
      if (difference.inDays > 365) return '${(difference.inDays / 365).floor()}y ago';
      if (difference.inDays > 30) return '${(difference.inDays / 30).floor()}mo ago';
      if (difference.inDays > 0) return '${difference.inDays}d ago';
      if (difference.inHours > 0) return '${difference.inHours}h ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
      return 'just now';
    } catch (e) {
      return 'recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    String cleanUrl = widget.video.creatorUrl;
    if (cleanUrl.endsWith('/')) cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    final thumbnailUrl = '$cleanUrl/player/video/thumbnail/${widget.video.videoId}';

    return GestureDetector(
      onTap: () async {
        // Navigate to the player (where the Like/Comment buttons actually live)
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
              extendBodyBehindAppBar: true,
              body: MobileVideoPlayerWidget(video: widget.video),
            ),
          ),
        );
        // Refresh view count when user returns from the player
        _fetchLiveNodeViews();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. The Large Thumbnail
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: const Color(0xFF1E1E1E),
              child: Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.play_circle_fill_rounded, size: 55, color: Colors.orange),
                ),
              ),
            ),
          ),
          
          // 2. The Clean Details Row (NO action buttons here)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Text(
                    widget.video.channelName.isNotEmpty ? widget.video.channelName[0].toUpperCase() : 'G', 
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.title, 
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.video.channelName} • ${_formatViews(_liveViews)} views • ${_getTimeAgo(widget.video.createdAt)}', 
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}