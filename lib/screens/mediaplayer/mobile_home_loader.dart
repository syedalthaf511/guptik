import 'package:flutter/material.dart';
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:guptik/screens/mediaplayer/mobile_home_feed_screen.dart';
import 'package:guptik/services/mediaplayer/mobile_bridge_service.dart';


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
        // Changed to orange to match your new theme
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.white))),
      );
    }

    // 🚀 Route the user to the new YouTube-style scrolling feed
    return MobileHomeFeedScreen(videoList: _videos);
  }
}