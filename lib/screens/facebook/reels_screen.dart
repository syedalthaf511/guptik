import 'package:flutter/material.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/models/facebook/meta_story_reel_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';
import 'package:guptik/widgets/facebook/reel_player_widget.dart';
import 'package:guptik/config/app_theme.dart';

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
    final platformColor = widget.platform == SocialPlatform.facebook
        ? AppTheme.facebookBlue
        : AppTheme.instagramPink;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          '${widget.platform.name.toUpperCase()} Reels',
          style: AppTheme.textTheme.headlineSmall,
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.dark,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: platformColor),
            onPressed: _loadReels,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(platformColor),
              ),
            )
          : _reels.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: platformColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.videocam_off,
                      size: 40,
                      color: platformColor.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    widget.platform == SocialPlatform.facebook
                        ? 'No Reels Found'
                        : 'No Reels Found',
                    style: AppTheme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Create your first reel to get started',
                    style: AppTheme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  if (widget.platform == SocialPlatform.facebook) ...[
                    const SizedBox(height: AppSpacing.lg),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: platformColor,
                      ),
                      child: const Text('Learn More'),
                    ),
                  ],
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _reels.length,
              itemBuilder: (context, index) {
                final reel = _reels[index];
                final reelId = _extractReelId(reel);
                final bool isPlaying = _currentlyPlayingReelId == reel.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.light,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video Player Section
                      Container(
                        height: 400,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.lg),
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
                                bottom: AppSpacing.lg,
                                right: AppSpacing.lg,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    onPressed: () {},
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Reel Details
                      Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(AppRadius.lg),
                          ),
                          color: AppTheme.surface,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reel.caption.isEmpty
                                  ? '(No caption)'
                                  : reel.caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                _buildStatChip(
                                  icon: Icons.favorite,
                                  label: '${reel.likes}',
                                  color: AppTheme.error,
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                _buildStatChip(
                                  icon: Icons.comment,
                                  label: '${reel.comments}',
                                  color: platformColor,
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                _buildStatChip(
                                  icon: Icons.remove_red_eye,
                                  label: '${reel.plays}',
                                  color: AppTheme.success,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              reel.timeElapsed,
                              style: AppTheme.textTheme.bodySmall,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}