import 'package:flutter/material.dart';
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:guptik/widgets/mediaplayer/mobile_video_player_widget.dart';

class MobileHomeFeedScreen extends StatelessWidget {
  final List<PlayerVideo> videoList;

  const MobileHomeFeedScreen({Key? key, required this.videoList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Guptik Network', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
        ],
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: videoList.length,
        itemBuilder: (context, index) {
          return _buildVideoCard(context, videoList[index]);
        },
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, PlayerVideo video) {
    return GestureDetector(
      onTap: () {
        // Tap to open the full video player in a clean new screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.transparent, 
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              extendBodyBehindAppBar: true,
              body: MobileVideoPlayerWidget(video: video),
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Thumbnail Placeholder Area
          Container(
            width: double.infinity,
            height: 220,
            color: const Color(0xFF1E1E1E), 
            child: const Center(
              child: Icon(Icons.play_circle_fill_rounded, size: 60, color: Colors.orange), 
            ),
          ),
          
          // 2. Video Information Row (Title, Avatar, Views)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Text(
                    video.channelName.isNotEmpty ? video.channelName[0].toUpperCase() : 'G', 
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title, 
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${video.channelName} • ${video.viewCount} views', 
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}