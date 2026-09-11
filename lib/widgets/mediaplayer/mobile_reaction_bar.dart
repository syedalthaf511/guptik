import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../services/mediaplayer/mobile_bridge_service.dart';
import '../../services/vault/vault_sync_service.dart';
import '../../screens/mediaplayer/mobile_profile_screen.dart';

class MobileReactionBar extends StatefulWidget {
  final PlayerVideo video;
  final VoidCallback onOpenComments;

  const MobileReactionBar({
    Key? key, 
    required this.video, 
    required this.onOpenComments
  }) : super(key: key);

  @override
  _MobileReactionBarState createState() => _MobileReactionBarState();
}

class _MobileReactionBarState extends State<MobileReactionBar> {
  late int _currentLikes;
  late int _currentComments;
  late int _repostCount;
  bool _isSaved = false;
  bool _isReposted = false;
  late MobileBridgeService _bridge;

  @override
  void initState() {
    super.initState();
    _currentLikes = widget.video.likeCount;
    _currentComments = widget.video.commentCount;
    _repostCount = widget.video.repostCount;
    _bridge = MobileBridgeService(gatewayUrl: widget.video.creatorUrl);
    _fetchLiveStats();
  }

  Future<void> _fetchLiveStats() async {
    final stats = await _bridge.fetchVideoStats(widget.video.videoId);
    if (stats != null && mounted) {
      setState(() {
        _currentLikes = stats['likes'] ?? _currentLikes;
        _currentComments = stats['comments'] ?? _currentComments;
        _repostCount = stats['reposts'] ?? _repostCount;
      });
    }
  }

  void _handleReaction(String type) async {
    bool success = await _bridge.postReaction(widget.video.videoId, widget.video.creatorUid, type);
    if (!mounted) return;
    if (success) {
      setState(() => _currentLikes += 1);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Reacted ($type)!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Already reacted!")));
    }
  }

  void _handleRepost() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    if (currentUser.id == widget.video.creatorUid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("This is your own video.")));
      return;
    }

    final reposterName = currentUser.userMetadata?['channel_name'] ?? 
                         currentUser.userMetadata?['username'] ?? 
                         currentUser.email?.split('@')[0] ?? 
                         'Creator';

    bool success = await _bridge.repostVideo(
      originalVideoId: widget.video.videoId,
      originalCreatorUid: widget.video.creatorUid,
      originalCreatorName: widget.video.channelName,
      originalChannelName: widget.video.channelName,
      reposterUid: currentUser.id,
      reposterChannelName: reposterName,
    );

    if (success) {
      // 🚀 FIX: Mirrors desktop's PlayerOrganizationService.saveLocalRepost —
      // on desktop, the reposter's OWN local Postgres (127.0.0.1:55432) gets
      // a mirror row in `mp_repost_videos` so "My Reposts" shows on THEIR
      // node's user-side table too (visible in Adminer under their own DB).
      // Mobile has no local Postgres of its own, so instead we call the same
      // gateway `/player/video/repost` endpoint — but against the REPOSTER's
      // own linked desktop node (fetched via VaultSyncService), not the
      // original video's creator's node. This is a best-effort mirror: if
      // the reposter has no desktop paired yet, we simply skip it.
      try {
        final myDesktopUrl = await VaultSyncService().getDesktopUrl();
        if (myDesktopUrl != null && myDesktopUrl.isNotEmpty) {
          final myBridge = MobileBridgeService(gatewayUrl: myDesktopUrl);
          await myBridge.repostVideo(
            originalVideoId: widget.video.videoId,
            originalCreatorUid: widget.video.creatorUid,
            originalCreatorName: widget.video.channelName,
            originalChannelName: widget.video.channelName,
            reposterUid: currentUser.id,
            reposterChannelName: reposterName,
          );
        }
      } catch (e) {
        debugPrint('Mobile local-node repost mirror error (non-fatal): $e');
      }

      try {
        final supabase = Supabase.instance.client;

        final orig = await supabase
            .from('mp_videos')
            .select('id')
            .eq('video_id', widget.video.videoId)
            .maybeSingle();

        final origRowId = orig?['id']?.toString();

        if (origRowId != null) {
          final repostVideoId = const Uuid().v4();

          await supabase.from('mp_videos').insert({
            'video_id': repostVideoId,
            'creator_uid': currentUser.id,
            'channel_name': reposterName,
            'title': widget.video.title,
            'description': widget.video.description,
            'creator_cloudflare_url': widget.video.originalCreatorUrl ?? widget.video.creatorUrl,
            'thumbnail_url': widget.video.thumbnailUrl ?? '',
            'category': widget.video.category,
            'visibility': 'public',
            'is_reel': widget.video.isReel,
            'is_monetized': false,
            'made_for_kids': widget.video.madeForKids,
            'age_rating': widget.video.ageRating,
            'repost_id': origRowId,
          });
        }
      } catch (e) {
        debugPrint('Mobile repost global feed insert error (non-fatal): $e');
      }
    }

    if (mounted) {
      if (success) {
        setState(() {
          _isReposted = true;
          _repostCount += 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Video reposted to your channel!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Already reposted.")));
      }
    }
  }

  void _handleShare() {
    final link = '${widget.video.creatorUrl}/watch/${widget.video.videoId}';
    Clipboard.setData(ClipboardData(text: link));
    _bridge.shareVideo(videoId: widget.video.videoId, creatorUid: widget.video.creatorUid);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link copied to clipboard!")));
  }

  void _handleSave() async {
    if (_isSaved) return;
    bool success = await _bridge.saveVideo(widget.video.videoId, widget.video.creatorUid);
    if (!mounted) return;
    if (success) {
      setState(() => _isSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved to your Vault!")));
    }
  }

  Widget _buildEmojiButton(IconData icon, Color color, String type) {
    return GestureDetector(
      onTap: () => _handleReaction(type),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap, {bool highlight = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: highlight ? Colors.orange.withOpacity(0.2) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: highlight ? Colors.orange : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: highlight ? Colors.orange : Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: highlight ? Colors.orange : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
          
          const SizedBox(height: 14),

          // 2. 7-Emoji Reaction Selector Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildEmojiButton(Icons.favorite, Colors.pinkAccent, 'heart'),
                  _buildEmojiButton(Icons.local_fire_department, Colors.orange, 'fire'),
                  _buildEmojiButton(Icons.thumb_up, Colors.cyanAccent, 'thumbs_up'),
                  _buildEmojiButton(Icons.celebration, Colors.yellow, 'clap'),
                  _buildEmojiButton(Icons.sentiment_very_satisfied, Colors.amber, 'laugh'),
                  _buildEmojiButton(Icons.auto_awesome, Colors.purpleAccent, 'surprised'),
                  _buildEmojiButton(Icons.sentiment_very_dissatisfied, Colors.blueGrey, 'sad'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          
          // 3. YouTube-Style Action Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActionBtn(Icons.thumb_up_alt_outlined, "$_currentLikes", () => _handleReaction('thumbs_up')),
                const SizedBox(width: 10),
                _buildActionBtn(Icons.comment_outlined, "$_currentComments", widget.onOpenComments),
                const SizedBox(width: 10),
                _buildActionBtn(
                  _isReposted ? Icons.repeat : Icons.repeat_outlined, 
                  "$_repostCount", 
                  _handleRepost,
                  highlight: _isReposted,
                ),
                const SizedBox(width: 10),
                _buildActionBtn(_isSaved ? Icons.bookmark : Icons.bookmark_border, _isSaved ? "Saved" : "Save", _handleSave, highlight: _isSaved),
                const SizedBox(width: 10),
                _buildActionBtn(Icons.share_outlined, "Share", _handleShare),
              ],
            ),
          )
        ],
      ),
    );
  }
}