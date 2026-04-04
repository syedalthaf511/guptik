import 'package:flutter/material.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';
import 'package:guptik/widgets/facebook/meta_grid_card.dart';
import 'fullscreen_media_screen.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  final MetaService _metaService = MetaService();
  late Future<List<MetaContent>> _contentFuture;

  SocialPlatform _selectedPlatform = SocialPlatform.facebook;
  ContentType _selectedFilter = ContentType.post;

  @override
  void initState() {
    super.initState();
    _loadContent();
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
        ? const Color(0xFF1877F2)
        : const Color(0xFFE1306C);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = type;
            _loadContent();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[300]!,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformChip(String label, SocialPlatform platform) {
    final isSelected = _selectedPlatform == platform;
    final color = platform == SocialPlatform.facebook
        ? const Color(0xFF1877F2)
        : const Color(0xFFE1306C);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPlatform = platform;
            _loadContent();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : Colors.grey[300]!),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Platform & Filter Bar – natural height, no extra constraints
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Platform Chips
                Row(
                  children: [
                    _buildPlatformChip('Facebook', SocialPlatform.facebook),
                    const SizedBox(width: 8),
                    _buildPlatformChip('Instagram', SocialPlatform.instagram),
                  ],
                ),
                const SizedBox(height: 8),
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

          // Content Area - List View Only
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadContent();
              },
              child: FutureBuilder<List<MetaContent>>(
                future: _contentFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading content',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadContent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1877F2),
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
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.grid_off,
                              size: 32,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No ${_selectedFilter.name}s found',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first post to get started',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  // LIST VIEW - Single column with inline comments
                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
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