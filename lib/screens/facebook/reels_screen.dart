import 'package:flutter/material.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/models/facebook/meta_story_reel_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';
import 'package:guptik/widgets/facebook/reel_player_widget.dart';

class ReelsScreen extends StatefulWidget {
  final SocialPlatform platform;

  const ReelsScreen({super.key, required this.platform});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final MetaService _metaService = MetaService();
  List<MetaReel> _reels = [];
  bool _isLoading = true;
  String? _currentlyPlayingReelId;

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  Future<void> _loadReels() async {
    setState(() => _isLoading = true);
    try {
      final reels = await _metaService.getReels(widget.platform);
      if (mounted) {
        setState(() {
          _reels = reels;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading reels: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _extractReelId(MetaReel reel) {
    if (reel.id.startsWith('178') ||
        reel.id.startsWith('179') ||
        reel.id.startsWith('180') ||
        reel.id.startsWith('181')) {
      return reel.id;
    }
    if (reel.videoUrl.contains('/reel/')) {
      final uri = Uri.tryParse(reel.videoUrl);
      if (uri != null) {
        final segments = uri.pathSegments;
        final reelIndex = segments.indexOf('reel');
        if (reelIndex != -1 && reelIndex + 1 < segments.length) {
          return segments[reelIndex + 1].replaceAll('/', '');
        }
      }
    }
    return reel.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.platform.name.toUpperCase()} Reels'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReels),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reels.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    widget.platform == SocialPlatform.facebook
                        ? 'No reels found for this Facebook page.\n'
                              'Make sure your page is connected to an Instagram business account.'
                        : 'No reels found',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  if (widget.platform == SocialPlatform.facebook) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Connect Instagram'),
                            content: const Text(
                              'To see reels for your Facebook page, you need to connect an Instagram business account in your app settings.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Learn More'),
                    ),
                  ],
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _reels.length,
              itemBuilder: (context, index) {
                final reel = _reels[index];
                final reelId = _extractReelId(reel);
                final bool isPlaying = _currentlyPlayingReelId == reel.id;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video Player Section
                      Container(
                        height: 400,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          color: Colors.black,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            ReelPlayerWidget(
                              reelId: reelId,
                              thumbnailUrl: reel.thumbnail,
                              videoUrl: reel.videoUrl,
                            ),
                            if (!isPlaying)
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      // The WebView handles play/pause automatically
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Reel Details
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reel.caption.isEmpty
                                  ? '(No caption)'
                                  : reel.caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildStatChip(
                                  icon: Icons.favorite,
                                  label: '${reel.likes}',
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                _buildStatChip(
                                  icon: Icons.comment,
                                  label: '${reel.comments}',
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                _buildStatChip(
                                  icon: Icons.remove_red_eye,
                                  label: '${reel.plays}',
                                  color: Colors.green,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              reel.timeElapsed,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}