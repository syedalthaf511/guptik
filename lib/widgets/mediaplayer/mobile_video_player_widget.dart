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
  int _liveComments = 0;
  bool _hasError = false;
  bool _ageConfirmed = false;
  bool _isBlockedByAge = false;
  String? _watcherInterest;
  List<PlayerVideo> _recommendedVideos = [];

  @override
  void initState() {
    super.initState();
    _liveViews = widget.video.viewCount;
    _liveComments = widget.video.commentCount;
    _bridge = MobileBridgeService(gatewayUrl: widget.video.creatorUrl);

    // 🚀 AGE GATE CHECK
    if (widget.video.ageRating == '18+' && !widget.video.madeForKids) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showAgeGate());
    } else {
      _initializeSyncAndPlayer();
    }
  }

  void _showAgeGate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Age Restriction', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text(
          'This video is rated 18+. Confirm you are 18 or older to watch.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isBlockedByAge = true);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _ageConfirmed = true);
              _initializeSyncAndPlayer();
            },
            child: const Text('I am 18+', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
        _liveComments = liveStats['comments'] ?? _liveComments;
      });
    }

    _fetchRecommendations();

    // 3. Establishes the video streaming link
    String cleanGateway = widget.video.creatorUrl;
    
    // 🚀 THE EXOPLAYER FIX: Force the HTTP/HTTPS scheme so Android knows it's a network stream, not a local file!
    if (!cleanGateway.startsWith('http')) {
      if (cleanGateway.contains('localhost') || cleanGateway.contains('127.0.0.1')) {
        cleanGateway = 'http://$cleanGateway';
      } else {
        cleanGateway = 'https://$cleanGateway';
      }
    }

    if (cleanGateway.endsWith('/')) {
      cleanGateway = cleanGateway.substring(0, cleanGateway.length - 1);
    }
    
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
        setState(() => _hasError = true);
      }
    }
  }

  Future<void> _fetchRecommendations() async {
    final feed = await _bridge.getRemoteFeed();
    if (mounted) {
      setState(() {
        _recommendedVideos = feed.where((v) => v.videoId != widget.video.videoId).toList();
      });
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

  void _setInterest(bool? interest) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    await _bridge.setVideoInterest(
      videoId: widget.video.videoId,
      creatorUid: widget.video.creatorUid,
      watcherUid: currentUser.id,
      interested: interest,
    );

    setState(() {
      _watcherInterest = interest == true ? 'interested' : (interest == false ? 'not_interested' : null);
    });
  }

  void _showCommentsBottomSheet() {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Comments ($_liveComments)", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<List<dynamic>>(
                        future: _bridge.fetchComments(widget.video.videoId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.orange));
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text("No comments yet. Be the first!", style: TextStyle(color: Colors.white54)));
                          }

                          final comments = snapshot.data!;
                          return ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.orange, 
                                  child: Icon(Icons.person, color: Colors.black, size: 20)
                                ),
                                title: Text(
                                  comment['creator_name'] ?? 'Viewer', 
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)
                                ),
                                subtitle: Text(
                                  comment['comment_text'] ?? '', 
                                  style: const TextStyle(color: Colors.white, fontSize: 14)
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        border: Border(top: BorderSide(color: Colors.white12)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Add a comment...",
                                hintStyle: const TextStyle(color: Colors.white54),
                                filled: true,
                                fillColor: const Color(0xFF1E1E1E),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.black, size: 20),
                              onPressed: () async {
                                final text = commentController.text.trim();
                                if (text.isEmpty) return;
                                
                                final currentUser = Supabase.instance.client.auth.currentUser;
                                final username = currentUser?.userMetadata?['channel_name'] ?? 'Mobile Viewer';

                                bool success = await _bridge.postComment(
                                  widget.video.videoId, 
                                  widget.video.creatorUid, 
                                  text,
                                  viewerName: username,
                                );

                                if (success) {
                                  commentController.clear();
                                  setModalState(() {});
                                  setState(() => _liveComments += 1);
                                }
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Player Section
            GestureDetector(
              onTap: _togglePlay, 
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.40,
                ),
                color: Colors.black,
                child: _isBlockedByAge
                  ? const Center(child: Text("Age Restricted Content", style: TextStyle(color: Colors.redAccent)))
                  : _hasError
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
                        : const Center(child: CircularProgressIndicator(color: Colors.orange)),
              ),
            ),
            
            // 2. Title & Audience Badges
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
                  Row(
                    children: [
                      Text('$_liveViews views', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      if (widget.video.madeForKids) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text("Made for Kids", style: TextStyle(color: Colors.cyanAccent, fontSize: 10)),
                        ),
                      ],
                      if (widget.video.ageRating == '18+') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text("18+", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            const Divider(color: Colors.white24, height: 1),

            // 3. Reactions & Actions Bar
            MobileReactionBar(
              video: widget.video,
              onOpenComments: _showCommentsBottomSheet,
            ),

            // 4. Watcher Interest Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text("Interested", style: TextStyle(fontSize: 11)),
                    selected: _watcherInterest == 'interested',
                    selectedColor: Colors.orange,
                    backgroundColor: const Color(0xFF1E1E1E),
                    onSelected: (_) => _setInterest(true),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("Not Interested", style: TextStyle(fontSize: 11)),
                    selected: _watcherInterest == 'not_interested',
                    selectedColor: Colors.redAccent,
                    backgroundColor: const Color(0xFF1E1E1E),
                    onSelected: (_) => _setInterest(false),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white24, height: 1),

            // 5. Description Block
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  widget.video.description.isNotEmpty ? widget.video.description : "No description provided.",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),

            // 6. Recommended Feed List
            if (_recommendedVideos.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text("Up Next", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recommendedVideos.length,
                itemBuilder: (ctx, idx) {
                  final rec = _recommendedVideos[idx];
                  
                  // Clean URL for thumbnails
                  String cleanUrl = rec.creatorUrl;
                  if (!cleanUrl.startsWith('http')) {
                    if (cleanUrl.contains('localhost') || cleanUrl.contains('127.0.0.1')) {
                      cleanUrl = 'http://$cleanUrl';
                    } else {
                      cleanUrl = 'https://$cleanUrl';
                    }
                  }
                  if (cleanUrl.endsWith('/')) {
                    cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
                  }
                  
                  return ListTile(
                    leading: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: Colors.grey[800],
                        child: Image.network(
                          '$cleanUrl/player/video/thumbnail/${rec.videoId}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.play_circle_fill, color: Colors.orange),
                        ),
                      ),
                    ),
                    title: Text(rec.title, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(rec.channelName, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            backgroundColor: Colors.black,
                            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
                            extendBodyBehindAppBar: true,
                            body: MobileVideoPlayerWidget(video: rec),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}