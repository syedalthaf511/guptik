import 'package:flutter/material.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/models/facebook/meta_insights_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';
import 'package:guptik/config/app_theme.dart';

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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          '$platformName Analytics',
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: platformColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.calendar_today, color: Colors.white, size: 20),
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
                  child: Text(
                    range['label']!,
                    style: AppTheme.textTheme.bodyMedium,
                  ),
                );
              }).toList();
            },
          ),
          IconButton(
            icon: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(platformColor),
                    ),
                  )
                : Icon(Icons.refresh, color: Colors.white, size: 20),
            onPressed: _isRefreshing ? null : _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(platformColor),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              color: platformColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Key Metrics Section
                    _buildMetricsSection(),
                    const SizedBox(height: AppSpacing.xl),

                    // Stories & Reels Section
                    if (_storiesReelsSummary.isNotEmpty) ...[
                      _buildStoriesReelsSection(),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // Top Posts Section
                    _buildTopPostsSection(),
                    const SizedBox(height: AppSpacing.xl),

                    // Audience Demographics
                    if (_demographics.isNotEmpty) ...[
                      _buildDemographicsSection(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricsSection() {
    if (_pageInsights == null) {
      return _buildEmptyCard('No analytics data available');
    }

    final platformColor = _getPlatformColor();

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Key Metrics',
                  style: AppTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.dark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: platformColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Text(
                    _timeRanges.firstWhere(
                      (e) => e['value'] == _selectedTimeRange,
                      orElse: () => _timeRanges[0],
                    )['label']!,
                    style: AppTheme.textTheme.labelSmall?.copyWith(
                      color: platformColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppTheme.lightGrey),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.lg,
              children: [
                _buildMetricCard(
                  label: 'Followers',
                  value: _formatNumber(_pageInsights!.followers),
                  icon: Icons.people,
                  color: AppTheme.facebookBlue,
                ),
                _buildMetricCard(
                  label: 'Reach',
                  value: _formatNumber(_pageInsights!.totalReach),
                  icon: Icons.trending_up,
                  color: const Color(0xFF31A24C),
                ),
                _buildMetricCard(
                  label: 'Impressions',
                  value: _formatNumber(_pageInsights!.totalImpressions),
                  icon: Icons.visibility,
                  color: const Color(0xFFFF6B35),
                ),
                _buildMetricCard(
                  label: 'Engagement',
                  value: '${_pageInsights!.engagementRate.toStringAsFixed(1)}%',
                  icon: Icons.favorite,
                  color: AppTheme.instagramPink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    // Each card takes approximately half the width minus spacing
    final double cardWidth = (MediaQuery.of(context).size.width - 64) / 2;
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.light,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  style: AppTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.mediumGrey,
                    fontWeight: FontWeight.w500,
                  ),
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
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Stories & Reels',
              style: AppTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.dark,
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppTheme.lightGrey),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.lg,
              children: [
                _buildMediaCard(
                  title: 'Stories',
                  count: '${_storiesReelsSummary['totalStories'] ?? 0}',
                  subtitle:
                      '${_storiesReelsSummary['totalStoryViews'] ?? 0} views',
                  icon: Icons.history,
                  color: const Color(0xFFFFA500),
                ),
                _buildMediaCard(
                  title: 'Reels',
                  count: '${_storiesReelsSummary['totalReels'] ?? 0}',
                  subtitle:
                      '${_storiesReelsSummary['totalReelViews'] ?? 0} plays',
                  icon: Icons.video_library,
                  color: const Color(0xFF5851DB),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final double cardWidth = (MediaQuery.of(context).size.width - 64) / 2;
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.light,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      count,
                      style: AppTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.mediumGrey,
                  ),
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
    final platformColor = _getPlatformColor();

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Top Performing Posts',
              style: AppTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.dark,
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppTheme.lightGrey),
          if (_topPosts.isEmpty)
            _buildEmptyMessage('No posts available')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _topPosts.length > 3 ? 3 : _topPosts.length,
              separatorBuilder: (ctx, i) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final post = _topPosts[index];
                return _buildPostCard(post);
              },
            ),
          if (_topPosts.length > 3)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Center(
                child: Text(
                  '+ ${_topPosts.length - 3} more posts',
                  style: AppTheme.textTheme.labelSmall?.copyWith(
                    color: platformColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostCard(MetaPostInsights post) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppTheme.lightGrey),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              width: 60,
              height: 60,
              color: AppTheme.lightGrey,
              child: post.thumbnailUrl != null && post.thumbnailUrl!.isNotEmpty
                  ? Image.network(
                      post.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.broken_image,
                        size: 24,
                        color: AppTheme.mediumGrey,
                      ),
                    )
                  : Icon(Icons.image, size: 24, color: AppTheme.mediumGrey),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.postCaption.isEmpty ? '(No caption)' : post.postCaption,
                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.favorite,
                      count: post.likes,
                      color: AppTheme.error,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _buildStatChip(
                      icon: Icons.comment,
                      count: post.comments,
                      color: AppTheme.primaryTeal,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    if (post.shares > 0)
                      _buildStatChip(
                        icon: Icons.share,
                        count: post.shares,
                        color: AppTheme.success,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _formatNumber(count),
            style: AppTheme.textTheme.labelSmall?.copyWith(
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
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Audience Demographics',
              style: AppTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.dark,
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppTheme.lightGrey),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: _demographics.map((demo) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: _buildDemographicBar(demo),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicBar(MetaAudienceDemographics demo) {
    final platformColor = _getPlatformColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              demo.ageGroup,
              style: AppTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(demo.percentage * 100).toStringAsFixed(1)}%',
              style: AppTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            FractionallySizedBox(
              widthFactor: demo.percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      platformColor,
                      platformColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      decoration: _cardDecoration(),
      child: Center(
        child: Text(
          message,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.mediumGrey,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Center(
        child: Text(
          message,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      boxShadow: AppShadows.medium,
    );
  }
}