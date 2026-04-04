import 'package:flutter/material.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/models/facebook/meta_insights_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final SocialPlatform platform;

  const AnalyticsDashboardScreen({super.key, required this.platform});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final MetaService _metaService = MetaService();

  // Data variables
  MetaPageInsights? _pageInsights;
  List<MetaPostInsights> _topPosts = [];
  List<MetaAudienceDemographics> _demographics = [];
  Map<String, dynamic> _storiesReelsSummary = {};

  // UI state
  bool _isLoading = true;
  String _selectedTimeRange = '7d';
  bool _isRefreshing = false;

  final List<Map<String, String>> _timeRanges = [
    {'value': '7d', 'label': 'Last 7 Days'},
    {'value': '30d', 'label': 'Last 30 Days'},
    {'value': '90d', 'label': 'Last 90 Days'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });

    try {
      final results = await Future.wait([
        _metaService.getPageInsights(widget.platform),
        _metaService.getTopPerformingPosts(widget.platform, limit: 5),
        _metaService.getAudienceDemographics(widget.platform),
        _metaService.getStoriesReelsSummary(widget.platform),
      ]);

      if (mounted) {
        setState(() {
          _pageInsights = results[0] as MetaPageInsights?;
          _topPosts = results[1] as List<MetaPostInsights>;
          _demographics = results[2] as List<MetaAudienceDemographics>;
          _storiesReelsSummary = results[3] as Map<String, dynamic>;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading analytics: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _getPlatformName() {
    return widget.platform == SocialPlatform.facebook
        ? 'Facebook'
        : 'Instagram';
  }

  Color _getPlatformColor() {
    return widget.platform == SocialPlatform.facebook
        ? const Color(0xFF1877F2)
        : const Color(0xFFE1306C);
  }

  @override
  Widget build(BuildContext context) {
    final platformColor = _getPlatformColor();
    final platformName = _getPlatformName();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '$platformName Analytics',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: platformColor,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 18,
            ),
            onSelected: (value) {
              setState(() {
                _selectedTimeRange = value;
              });
              _loadAnalytics();
            },
            itemBuilder: (context) {
              return _timeRanges.map((range) {
                return PopupMenuItem(
                  value: range['value'],
                  child: Text(range['label']!),
                );
              }).toList();
            },
          ),
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white, size: 18),
            onPressed: _isRefreshing ? null : _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: platformColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Key Metrics - FIXED OVERFLOW
                  _buildMetricsSection(),
                  const SizedBox(height: 8),

                  // Stories & Reels - FIXED OVERFLOW
                  if (_storiesReelsSummary.isNotEmpty) ...[
                    _buildStoriesReelsSection(),
                    const SizedBox(height: 8),
                  ],

                  // Top Posts
                  _buildTopPostsSection(),
                  const SizedBox(height: 8),

                  // Audience Demographics
                  if (_demographics.isNotEmpty) ...[
                    _buildDemographicsSection(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildMetricsSection() {
    if (_pageInsights == null) {
      return _buildCard('No analytics data available');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Key Metrics',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPlatformColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _timeRanges.firstWhere(
                    (e) => e['value'] == _selectedTimeRange,
                    orElse: () => _timeRanges[0],
                  )['label']!,
                  style: TextStyle(
                    fontSize: 9,
                    color: _getPlatformColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Using Wrap instead of Row to prevent overflow
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricItem(
                label: 'Followers',
                value: _formatNumber(_pageInsights!.followers),
                icon: Icons.people,
                color: const Color(0xFF1877F2),
              ),
              _buildMetricItem(
                label: 'Reach',
                value: _formatNumber(_pageInsights!.totalReach),
                icon: Icons.trending_up,
                color: const Color(0xFF31A24C),
              ),
              _buildMetricItem(
                label: 'Impressions',
                value: _formatNumber(_pageInsights!.totalImpressions),
                icon: Icons.visibility,
                color: const Color(0xFFFF6B35),
              ),
              _buildMetricItem(
                label: 'Engagement',
                value: '${_pageInsights!.engagementRate.toStringAsFixed(1)}%',
                icon: Icons.favorite,
                color: const Color(0xFFE1306C),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    // Calculate width to fit 2 per row with proper spacing
    return Container(
      width:
          (MediaQuery.of(context).size.width - 32) /
          2, // 8px padding + 8px spacing
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesReelsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Stories & Reels',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          // Using Wrap instead of Row to prevent overflow
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMediaItem(
                title: 'Stories',
                count: '${_storiesReelsSummary['totalStories'] ?? 0}',
                subtitle:
                    '${_storiesReelsSummary['totalStoryViews'] ?? 0} views',
                icon: Icons.history,
                color: const Color(0xFFFFA500),
              ),
              _buildMediaItem(
                title: 'Reels',
                count: '${_storiesReelsSummary['totalReels'] ?? 0}',
                subtitle:
                    '${_storiesReelsSummary['totalReelViews'] ?? 0} plays',
                icon: Icons.video_library,
                color: const Color(0xFF5851DB),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaItem({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: (MediaQuery.of(context).size.width - 32) / 2,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPostsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Top Posts',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_topPosts.isEmpty)
            _buildEmptyState('No posts available')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topPosts.length > 3 ? 3 : _topPosts.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final post = _topPosts[index];
                return _buildPostItem(post);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPostItem(MetaPostInsights post) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 36,
              height: 36,
              color: Colors.grey[200],
              child: post.thumbnailUrl != null && post.thumbnailUrl!.isNotEmpty
                  ? Image.network(
                      post.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    )
                  : Icon(Icons.image, size: 16, color: Colors.grey[400]),
            ),
          ),
          const SizedBox(width: 6),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  post.postCaption.isEmpty ? '(No caption)' : post.postCaption,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.favorite,
                      count: post.likes,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    _buildStatChip(
                      icon: Icons.comment,
                      count: post.comments,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: color),
          const SizedBox(width: 1),
          Text(
            _formatNumber(count),
            style: TextStyle(
              fontSize: 8,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Audience',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Column(
            children: _demographics.map((demo) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildDemographicBar(demo),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicBar(MetaAudienceDemographics demo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              demo.ageGroup,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
            Text(
              '${(demo.percentage * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Stack(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: demo.percentage,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getPlatformColor(),
                      _getPlatformColor().withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
}