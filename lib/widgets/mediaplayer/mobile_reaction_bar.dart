import 'package:flutter/material.dart';
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:guptik/services/mediaplayer/mobile_bridge_service.dart';
import 'package:guptik/screens/mediaplayer/mobile_profile_screen.dart';

class MobileReactionBar extends StatefulWidget {
  final PlayerVideo video;

  const MobileReactionBar({Key? key, required this.video}) : super(key: key);

  @override
  _MobileReactionBarState createState() => _MobileReactionBarState();
}

class _MobileReactionBarState extends State<MobileReactionBar> {
  late int _currentLikes;

  @override
  void initState() {
    super.initState();
    _currentLikes = widget.video.likeCount;
  }

  void _handleLike() async {
    final bridge = MobileBridgeService(gatewayUrl: widget.video.creatorUrl);
    bool success = await bridge.postReaction(widget.video.videoId, widget.video.creatorUid, 'heart');
    
    if (success) {
      setState(() {
        _currentLikes += 1; 
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Liked!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Already liked!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 THE FIX: Changed Column to Row for the YouTube look
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile Avatar on the left
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MobileProfileScreen(
                    channelId: widget.video.creatorUid, 
                    nodeUrl: widget.video.creatorUrl,
                  ),
                ),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.orange,
                  child: Text(
                    widget.video.channelName.isNotEmpty ? widget.video.channelName[0].toUpperCase() : 'G', 
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(width: 10),
                Text(widget.video.channelName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          // Action Buttons on the right
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: _handleLike,
              ),
              Text("$_currentLikes", style: const TextStyle(color: Colors.white)),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.comment, color: Colors.white),
                onPressed: () {},
              ),
              Text("${widget.video.commentCount}", style: const TextStyle(color: Colors.white)),
            ],
          )
        ],
      ),
    );
  }
}