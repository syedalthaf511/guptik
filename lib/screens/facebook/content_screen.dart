import 'package:flutter/material.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';
import 'package:guptik/widgets/facebook/meta_grid_card.dart';
import 'package:guptik/config/app_theme.dart';
import 'fullscreen_media_screen.dart';

class ContentScreen extends StatefulWidget {
  final SocialPlatform platform;

  const ContentScreen({super.key, this.platform = SocialPlatform.facebook});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  final MetaService _metaService = MetaService();
  late Future<List<MetaContent>> _contentFuture;

  late SocialPlatform _selectedPlatform;
  ContentType _selectedFilter = ContentType.post;

  @override
  void initState() {
    super.initState();
    _selectedPlatform = widget.platform;
    _loadContent();
  }

  @override
  void didUpdateWidget(ContentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.platform != widget.platform) {
      _selectedPlatform = widget.platform;
      _loadContent();
    }
  }

  void _loadContent() {
    setState(() {
      _contentFuture = _metaService.getContent(
        _selectedPlatform,
        _selectedFilter,
      );
    });
  }

  Widget _buildFilterChip(String label, ContentType type) {
    final isSelected = _selectedFilter == type;
    final primaryColor = _selectedPlatform == SocialPlatform.facebook
        ? AppTheme.facebookBlue
        : AppTheme.instagramPink;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = type;
            _loadContent();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : AppTheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : AppTheme.lightGrey.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? AppShadows.light : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.dark,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final platformColor = _selectedPlatform == SocialPlatform.facebook
        ? AppTheme.facebookBlue
        : AppTheme.instagramPink;

    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            color: AppTheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filter Chips – scrollable horizontally
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('📱 Posts', ContentType.post),
                      _buildFilterChip('🎬 Reels', ContentType.reel),
                      _buildFilterChip('📖 Stories', ContentType.story),
                      _buildFilterChip('🏷️ Mentions', ContentType.mention),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadContent();
              },
              color: platformColor,
              child: FutureBuilder<List<MetaContent>>(
                future: _contentFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          platformColor,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppTheme.lightGrey,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Error loading content',
                            style: AppTheme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ElevatedButton(
                            onPressed: _loadContent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: platformColor,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final posts = snapshot.data ?? [];

                  if (posts.isEmpty) {
                    return Center(
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
                              Icons.grid_off,
                              size: 32,
                              color: platformColor.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'No ${_selectedFilter.name}s found',
                            style: AppTheme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Create your first post to get started',
                            style: AppTheme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  // LIST VIEW
                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: GestureDetector(
                          onTap: () {
                            if (posts[index].imageUrl != null &&
                                posts[index].imageUrl!.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenMediaScreen(
                                    imageUrl: posts[index].imageUrl!,
                                    caption: posts[index].caption,
                                  ),
                                ),
                              );
                            }
                          },
                          child: MetaGridCard(
                            content: posts[index],
                            onPostUpdated: _loadContent,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}