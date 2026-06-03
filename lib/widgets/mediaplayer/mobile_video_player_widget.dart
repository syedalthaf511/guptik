import 'package:flutter/material.dart';
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:video_player/video_player.dart';
import 'mobile_reaction_bar.dart';

class MobileVideoPlayerWidget extends StatefulWidget {
  final PlayerVideo video;
  
  const MobileVideoPlayerWidget({Key? key, required this.video}) : super(key: key);

  @override
  State<MobileVideoPlayerWidget> createState() => _MobileVideoPlayerWidgetState();
}

class _MobileVideoPlayerWidgetState extends State<MobileVideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    final String fullStreamUrl = '${widget.video.creatorUrl}/player/video/stream/${widget.video.videoId}';
    
    _controller = VideoPlayerController.networkUrl(Uri.parse(fullStreamUrl))
      ..initialize().then((_) {
        setState(() {});
      });
      
    _controller.play();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 THE FIX: SafeArea prevents the video from hiding under the top notch.
    // 🚀 THE FIX: SingleChildScrollView allows you to scroll down to see the likes!
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: The Video Player
            GestureDetector(
              onTap: _togglePlay, 
              child: Container(
                width: double.infinity,
                // Prevents vertical videos from taking up too much screen space
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65
                ),
                color: Colors.black,
                child: _controller.value.isInitialized
                  ? Center(
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    )
                  : const SizedBox(
                      height: 250, 
                      child: Center(child: CircularProgressIndicator(color: Colors.orange))
                    ),
              ),
            ),
            
            // Middle: Video Title & Views
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${widget.video.viewCount} views • ${widget.video.createdAt}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const Divider(color: Colors.white24, height: 1),

            // Bottom: The Horizontal Reaction Bar
            MobileReactionBar(video: widget.video),
          ],
        ),
      ),
    );
  }
}