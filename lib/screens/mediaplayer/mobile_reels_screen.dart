import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:guptik/models/mediaplyer/player_comment_model.dart';
import 'package:guptik/services/mediaplayer/mobile_bridge_service.dart';
import 'package:guptik/screens/mediaplayer/mobile_profile_screen.dart';

/// MobileReelsScreen — a YouTube-Shorts / TikTok style, full-screen vertical
/// swipe feed that only ever shows `isReel == true` videos.
///
/// It can be used two ways:
///  1. As the standalone "Shots" bottom-nav tab: pass just [gatewayUrl] and it
///     fetches the full feed itself and filters down to reels only.
///  2. Launched from the home feed's Shorts carousel: pass a pre-filtered
///     [reels] list plus [initialIndex] so it opens straight to the tapped
///     item without re-fetching.
class MobileReelsScreen extends StatefulWidget {
  final String gatewayUrl;
  final List<PlayerVideo>? reels;
  final int initialIndex;

  // 🚀 ADDED: when this screen sits inside an IndexedStack (the bottom-nav
  // "Shots" tab), it stays mounted even while another tab is showing, so
  // without this flag its video would keep auto-playing in the background
  // the moment the app opens. The parent (MobileMainLayout) sets this to
  // true only while the Shots tab is the one actually selected/visible, so
  // playback only starts once the user taps the Shots icon, and stops the
  // instant they switch to any other tab.
  final bool isVisible;

  const MobileReelsScreen({
    Key? key,
    required this.gatewayUrl,
    this.reels,
    this.initialIndex = 0,
    this.isVisible = true,
  }) : super(key: key);

  @override
  State<MobileReelsScreen> createState() => _MobileReelsScreenState();
}

class _MobileReelsScreenState extends State<MobileReelsScreen> {
  late MobileBridgeService _bridge;
  List<PlayerVideo> _reels = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _bridge = MobileBridgeService(gatewayUrl: widget.gatewayUrl);
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    if (widget.reels != null) {
      _reels = widget.reels!;
      _isLoading = false;
    } else {
      _fetchReels();
    }
  }

  Future<void> _fetchReels() async {
    try {
      final feed = await _bridge.getRemoteFeed();
      if (mounted) {
        setState(() {
          _reels = feed.where((v) => v.isReel).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load Shots. Check your Gateway URL.';
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 🚀 ADDED: when the parent flips `isVisible` (e.g. user switched away
  // from / back to the Shots bottom-nav tab), rebuild so every
  // `_ReelPlayerPage` re-evaluates its `isActive` flag and pauses/resumes
  // accordingly — see didUpdateWidget on _ReelPlayerPageState.
  @override
  void didUpdateWidget(covariant MobileReelsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      setState(() {});
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

    if (_reels.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.slow_motion_video_rounded, color: Colors.white38, size: 56),
              SizedBox(height: 12),
              Text("No Shots yet", style: TextStyle(color: Colors.white54, fontSize: 15)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _reels.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return _ReelPlayerPage(
                key: ValueKey(_reels[index].videoId),
                video: _reels[index],
                isActive: widget.isVisible && index == _currentPage,
              );
            },
          ),
          Positioned(
            top: 8,
            left: 4,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
          ),
          const Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Text(
                  'Shots',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelPlayerPage extends StatefulWidget {
  final PlayerVideo video;
  final bool isActive;

  const _ReelPlayerPage({Key? key, required this.video, required this.isActive}) : super(key: key);

  @override
  State<_ReelPlayerPage> createState() => _ReelPlayerPageState();
}

class _ReelPlayerPageState extends State<_ReelPlayerPage> {
  VideoPlayerController? _controller;
  late MobileBridgeService _bridge;
  bool _hasError = false;
  int _liveLikes = 0;
  int _liveComments = 0;
  bool _isSaved = false;
  bool _hasLiked = false;

  @override
  void initState() {
    super.initState();
    _liveLikes = widget.video.likeCount;
    _liveComments = widget.video.commentCount;
    _bridge = MobileBridgeService(gatewayUrl: widget.video.creatorUrl);
    _initializePlayer();
  }

  String _sanitizeGateway(String raw) {
    String cleanUrl = raw.trim();
    if (cleanUrl.contains('192.168.1.15')) {
      cleanUrl = cleanUrl.replaceAll('192.168.1.15', '192.168.1.186');
    }
    if (cleanUrl.contains('192.168.') || cleanUrl.contains('10.0.') || cleanUrl.contains('127.0.0.1') || cleanUrl.contains('localhost')) {
      cleanUrl = cleanUrl.replaceAll('https://', 'http://');
      if (!cleanUrl.startsWith('http://')) {
        cleanUrl = 'http://$cleanUrl';
      }
    } else {
      if (!cleanUrl.startsWith('http')) {
        cleanUrl = 'https://$cleanUrl';
      }
    }
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if ((cleanUrl.contains('192.168.') || cleanUrl.contains('10.0.') || cleanUrl.contains('127.0.0.1')) && !cleanUrl.contains(':55000')) {
      cleanUrl = '$cleanUrl:55000';
    }
    return cleanUrl;
  }

  Future<void> _initializePlayer() async {
    final cleanGateway = _sanitizeGateway(widget.video.creatorUrl);
    final streamUrl = '$cleanGateway/player/video/stream/${widget.video.videoId}';

    _controller = VideoPlayerController.networkUrl(Uri.parse(streamUrl));
    try {
      await _controller!.initialize();
      await _controller!.setLooping(true);
      if (mounted) {
        setState(() {});
        if (widget.isActive) {
          _controller!.play();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      _bridge.addVideoView(widget.video.videoId, currentUser.id);
    }
    final stats = await _bridge.fetchVideoStats(widget.video.videoId);
    if (stats != null && mounted) {
      setState(() {
        _liveLikes = stats['likes'] ?? _liveLikes;
        _liveComments = stats['comments'] ?? _liveComments;
      });
    }
  }

  @override
  void didUpdateWidget(covariant _ReelPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (widget.isActive && !oldWidget.isActive) {
      _controller!.play();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller!.pause();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
    });
  }

  void _handleLike() async {
    final success = await _bridge.postReaction(widget.video.videoId, widget.video.creatorUid, 'thumbs_up');
    if (!mounted) return;
    if (success) {
      setState(() {
        _hasLiked = true;
        _liveLikes += 1;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Already reacted!")));
    }
  }

  void _handleSave() async {
    if (_isSaved) return;
    final success = await _bridge.saveVideo(widget.video.videoId, widget.video.creatorUid);
    if (!mounted) return;
    if (success) {
      setState(() => _isSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved to your Vault!")));
    }
  }

  void _handleShare() {
    _bridge.shareVideo(videoId: widget.video.videoId, creatorUid: widget.video.creatorUid);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Shared!")));
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  void _showComments() {
    final commentsFuture = _bridge.fetchComments(
      widget.video.videoId,
      viewerUid: Supabase.instance.client.auth.currentUser?.id,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: FutureBuilder<List<PlayerComment>>(
            future: commentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.orange));
              }
              final comments = snapshot.data ?? [];
              if (comments.isEmpty) {
                return const Center(child: Text("No comments yet.", style: TextStyle(color: Colors.white54)));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final c = comments[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.creatorName, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(c.commentText, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_hasError)
              const Center(
                child: Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              )
            else if (_controller != null && _controller!.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              )
            else
              const Center(child: CircularProgressIndicator(color: Colors.orange)),

            if (_controller != null && _controller!.value.isInitialized && !_controller!.value.isPlaying)
              const Center(
                child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 72),
              ),

            // Right-side action rail
            Positioned(
              right: 12,
              bottom: 100,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MobileProfileScreen(
                            channelId: widget.video.channelId,
                            nodeUrl: '',
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.orange,
                      child: Text(
                        widget.video.channelName.isNotEmpty ? widget.video.channelName[0].toUpperCase() : 'G',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildRailButton(
                    icon: _hasLiked ? Icons.favorite : Icons.favorite_border,
                    color: _hasLiked ? Colors.pinkAccent : Colors.white,
                    label: _formatCount(_liveLikes),
                    onTap: _handleLike,
                  ),
                  const SizedBox(height: 18),
                  _buildRailButton(
                    icon: Icons.comment_outlined,
                    color: Colors.white,
                    label: _formatCount(_liveComments),
                    onTap: _showComments,
                  ),
                  const SizedBox(height: 18),
                  _buildRailButton(
                    icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved ? Colors.orange : Colors.white,
                    label: 'Save',
                    onTap: _handleSave,
                  ),
                  const SizedBox(height: 18),
                  _buildRailButton(
                    icon: Icons.share_outlined,
                    color: Colors.white,
                    label: 'Share',
                    onTap: _handleShare,
                  ),
                ],
              ),
            ),

            // Bottom info block
            Positioned(
              left: 16,
              right: 90,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${widget.video.channelName}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.video.title,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRailButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
