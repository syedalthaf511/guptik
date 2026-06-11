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
  late int _currentComments;
  late MobileBridgeService _bridge;

  @override
  void initState() {
    super.initState();
    _currentLikes = widget.video.likeCount;
    _currentComments = widget.video.commentCount;
    _bridge = MobileBridgeService(gatewayUrl: widget.video.creatorUrl);
    _fetchLiveStats();
  }

  Future<void> _fetchLiveStats() async {
    final stats = await _bridge.fetchVideoStats(widget.video.videoId);
    if (stats != null && mounted) {
      setState(() {
        _currentLikes = stats['likes'] ?? _currentLikes;
        _currentComments = stats['comments'] ?? _currentComments;
      });
    }
  }

  void _handleLike() async {
    bool success = await _bridge.postReaction(widget.video.videoId, widget.video.creatorUid, 'heart');
    if (!mounted) return;
    if (success) {
      setState(() => _currentLikes += 1);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Liked!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Already liked!")));
    }
  }

  void _handleShare() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link copied to clipboard!")));
  }

  void _handleSave() async {
    bool success = await _bridge.saveVideo(widget.video.videoId, widget.video.creatorUid);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved to your Vault!")));
    }
  }

  // 🚀 THE NEW COMMENT UI: A sleek Bottom Sheet
  void _showCommentsBottomSheet() {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows it to move up when keyboard appears
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              // Pushes the sheet up when the keyboard opens
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6, // Takes up 60% of the screen
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Comments ($_currentComments)", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                    ),
                    
                    // The Comment List
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
                                  comment['creator_uid']?.toString().substring(0, 8) ?? 'User', 
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

                    // The Input Area
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
                                if (commentController.text.trim().isEmpty) return;
                                
                                bool success = await _bridge.postComment(
                                  widget.video.videoId, 
                                  widget.video.creatorUid, 
                                  commentController.text.trim()
                                );

                                if (success) {
                                  commentController.clear();
                                  setModalState(() {}); // Refresh the bottom sheet
                                  setState(() => _currentComments += 1); // Refresh the button number
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

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          // 1. Channel Profile Row
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
                  radius: 18,
                  backgroundColor: Colors.orange,
                  child: Text(
                    widget.video.channelName.isNotEmpty ? widget.video.channelName[0].toUpperCase() : 'G', 
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.video.channelName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  onPressed: () {},
                  child: const Text("Subscribe", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 2. YouTube-Style Action Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionBtn(Icons.thumb_up_alt_outlined, "$_currentLikes", _handleLike),
                const SizedBox(width: 12),
                // 🚀 NOW THIS BUTTON OPENS THE BOTTOM SHEET
                _buildActionBtn(Icons.comment_outlined, "$_currentComments", _showCommentsBottomSheet),
                const SizedBox(width: 12),
                _buildActionBtn(Icons.share_outlined, "Share", _handleShare),
                const SizedBox(width: 12),
                _buildActionBtn(Icons.bookmark_border, "Save", _handleSave),
              ],
            ),
          )
        ],
      ),
    );
  }
}