import 'package:flutter/material.dart';
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:guptik/services/mediaplayer/mobile_bridge_service.dart';
import 'package:guptik/widgets/mediaplayer/mobile_video_player_widget.dart';


class MobileProfileScreen extends StatefulWidget {
  final String channelId;
  final String nodeUrl;

  MobileProfileScreen({required this.channelId, required this.nodeUrl});

  @override
  _MobileProfileScreenState createState() => _MobileProfileScreenState();
}

class _MobileProfileScreenState extends State<MobileProfileScreen> {
  late MobileBridgeService _bridge; // Changed to Bridge
  List<PlayerVideo> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize bridge with the creator's specific node URL
    _bridge = MobileBridgeService(gatewayUrl: widget.nodeUrl);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final videos = await _bridge.fetchChannelVideos(widget.nodeUrl, widget.channelId); // Changed call
    setState(() {
      _videos = videos;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Creator Profile")),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemCount: _videos.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(
                     builder: (_) => Scaffold(body: MobileVideoPlayerWidget(video: _videos[index]))
                   ));
                },
                child: Container(
                  color: Colors.grey[900],
                  margin: EdgeInsets.all(2),
                  child: Center(child: Icon(Icons.play_arrow, color: Colors.white)),
                ),
              );
            },
          ),
    );
  }
}