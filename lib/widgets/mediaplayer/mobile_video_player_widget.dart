import 'package:flutter/material.dart';
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:guptik/services/mediaplayer/mobile_bridge_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'mobile_reaction_bar.dart';

class MobileVideoPlayerWidget extends StatefulWidget {
  final PlayerVideo video;
  
  const MobileVideoPlayerWidget({Key? key, required this.video}) : super(key: key);

  @override
  State<MobileVideoPlayerWidget> createState() => _MobileVideoPlayerWidgetState();
}

class _MobileVideoPlayerWidgetState extends State<MobileVideoPlayerWidget> {
  VideoPlayerController? _controller;
  late MobileBridgeService _bridge;
  
  int _liveViews = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _liveViews = widget.video.viewCount;
    _bridge = MobileBridgeService(gatewayUrl: widget.video.creatorUrl);
    _initializeSyncAndPlayer();
  }

  Future<void> _initializeSyncAndPlayer() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    
    // 1. Logs view count to the gatekeeper unique viewed_videos table
    if (currentUser != null) {
      await _bridge.addVideoView(widget.video.videoId, currentUser.id);
    }

    // 2. Extracts stats parameters over the active tunnel proxy channel
    final liveStats = await _bridge.fetchVideoStats(widget.video.videoId);
    if (liveStats != null && mounted) {
      setState(() {
        _liveViews = liveStats['views'] ?? _liveViews;
      });
    }

    // 3. Establishes the video streaming link
    String cleanGateway = widget.video.creatorUrl;
    if (cleanGateway.endsWith('/')) cleanGateway = cleanGateway.substring(0, cleanGateway.length - 1);
    final String fullStreamUrl = '$cleanGateway/player/video/stream/${widget.video.videoId}';
    
    debugPrint("📱 Mobile attempting to stream channel: $fullStreamUrl");

    _controller = VideoPlayerController.networkUrl(Uri.parse(fullStreamUrl));
    
    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
        _controller!.play();
      }
    } catch (playerException) {
      debugPrint("❌ VideoPlayer initialization crashed: $playerException");
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: The Widescreen Streaming Player Section
            GestureDetector(
              onTap: _togglePlay, 
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.40,
                ),
                color: Colors.black,
                child: _hasError
                  ? const SizedBox(
                      height: 230,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
                            SizedBox(height: 8),
                            Text("Playback error. Connection dropped.", style: TextStyle(color: Colors.white60, fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  : (_controller != null && _controller!.value.isInitialized)
                      ? Center(
                          child: AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio,
                            child: VideoPlayer(_controller!),
                          ),
                        )
                      : const SizedBox(
                          height: 230, 
                          child: Center(child: CircularProgressIndicator(color: Colors.orange))
                        ),
              ),
            ),
            
            // Middle Information Block
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_liveViews views • Synced Broadcast Network',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
            
            const Divider(color: Colors.white24, height: 1),

            // Bottom Reaction Action Layout Bar
            MobileReactionBar(video: widget.video),
          ],
        ),
      ),
    );
  }
}