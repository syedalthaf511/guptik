import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/config/app_theme.dart';
import 'content_screen.dart';
import 'inbox_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'reels_screen.dart';
import 'stories_screen.dart';
import 'create_post_screen.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';

class FbAndInstaScreen extends StatefulWidget {
  const FbAndInstaScreen({super.key});

  @override
  State<FbAndInstaScreen> createState() => _FbAndInstaScreenState();
}

class _FbAndInstaScreenState extends State<FbAndInstaScreen> {
  final MetaService _metaService = MetaService();
  int _currentIndex = 0;

  // User profile data
  String? _userAvatarUrl;
  String? _userName;
  String? _userEmail;
  bool _isLoadingUser = true;

  // Page/Account names and profile pictures
  String? _facebookPageName;
  String? _facebookPagePicture;
  String? _instagramAccountName;
  String? _instagramAccountPicture;
  bool _isLoadingPageNames = true;

  // Platform selection state
  SocialPlatform _selectedPlatform = SocialPlatform.facebook;

  // Real data variables
  int _fbFollowers = 0;
  int _igFollowers = 0;
  double _engagementRate = 0.0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPageNames();
    _loadStats();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoadingUser = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() {
          _userName =
              user.userMetadata?['full_name'] ??
              user.email?.split('@').first ??
              'User';
          _userEmail = user.email;
          _userAvatarUrl = user.userMetadata?['avatar_url'];
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _loadPageNames() async {
    setState(() => _isLoadingPageNames = true);

    try {
      final pageInfo = await _metaService.getPageInfo();

      if (mounted) {
        setState(() {
          _facebookPageName = pageInfo['facebook_page_name'];
          _facebookPagePicture = pageInfo['facebook_page_picture'];
          _instagramAccountName = pageInfo['instagram_account_name'];
          _instagramAccountPicture = pageInfo['instagram_account_picture'];
          _isLoadingPageNames = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading page names: $e");
      setState(() => _isLoadingPageNames = false);
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);

    try {
      final fbInsights = await _metaService.getPageInsights(
        SocialPlatform.facebook,
      );
      final igInsights = await _metaService.getPageInsights(
        SocialPlatform.instagram,
      );

      double fbEngagement = fbInsights?.engagementRate ?? 0;
      double igEngagement = igInsights?.engagementRate ?? 0;
      double avgEngagement = (fbEngagement + igEngagement) / 2;

      if (mounted) {
        setState(() {
          _fbFollowers = fbInsights?.followers ?? 0;
          _igFollowers = igInsights?.followers ?? 0;
          _engagementRate = avgEngagement;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading stats: $e");
      if (mounted) {
        setState(() => _isLoadingStats = false);
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

  void _showQuickActionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Actions',
              style: AppTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(
                  icon: FontAwesomeIcons.facebook,
                  label: 'FB Analytics',
                  color: AppTheme.facebookBlue,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AnalyticsDashboardScreen(
                          platform: SocialPlatform.facebook,
                        ),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: FontAwesomeIcons.instagram,
                  label: 'IG Analytics',
                  color: AppTheme.instagramPink,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AnalyticsDashboardScreen(
                          platform: SocialPlatform.instagram,
                        ),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.video_library,
                  label: 'Reels',
                  color: const Color(0xFF5851DB),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReelsScreen(
                          platform: SocialPlatform.instagram,
                        ),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.history,
                  label: 'Stories',
                  color: const Color(0xFFFFA500),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StoriesScreen(
                          platform: SocialPlatform.instagram,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTheme.textTheme.labelSmall?.copyWith(
              color: AppTheme.mediumGrey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // FIXED HEADER - Does not scroll
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.surface, AppTheme.background],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  children: [
                    // Top Row: Back + Profile + Create Post
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button + Profile Row
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                color: AppTheme.dark,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.facebookBlue,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundImage: _userAvatarUrl != null
                                    ? NetworkImage(_userAvatarUrl!)
                                    : null,
                                backgroundColor: AppTheme.lightGrey,
                                child: _userAvatarUrl == null
                                    ? _isLoadingUser
                                          ? SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppTheme.facebookBlue),
                                              ),
                                            )
                                          : Text(
                                              _userName?.isNotEmpty == true
                                                  ? _userName![0].toUpperCase()
                                                  : 'U',
                                              style: AppTheme
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.mediumGrey,
                                                  ),
                                            )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: AppTheme.textTheme.labelSmall
                                      ?.copyWith(color: AppTheme.mediumGrey),
                                ),
                                Text(
                                  _userName ?? 'User',
                                  style: AppTheme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                if (_userEmail != null)
                                  Text(
                                    _userEmail!,
                                    style: AppTheme.textTheme.labelSmall
                                        ?.copyWith(color: AppTheme.lightGrey),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        // Create Post Button
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1877F2), Color(0xFFE1306C)],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF1877F2,
                                ).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CreatePostScreen(),
                                ),
                              );
                            },
                            tooltip: 'Create Post',
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Platform Cards - Toggleable
                    if (!_isLoadingPageNames)
                      Row(
                        children: [
                          // Facebook Card
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPlatform = SocialPlatform.facebook;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                  horizontal: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _selectedPlatform ==
                                          SocialPlatform.facebook
                                      ? AppTheme.facebookBlue.withValues(
                                          alpha: 0.12,
                                        )
                                      : AppTheme.facebookBlue.withValues(
                                          alpha: 0.05,
                                        ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.xl,
                                  ),
                                  border: Border.all(
                                    color:
                                        _selectedPlatform ==
                                            SocialPlatform.facebook
                                        ? AppTheme.facebookBlue.withValues(
                                            alpha: 0.5,
                                          )
                                        : AppTheme.facebookBlue.withValues(
                                            alpha: 0.2,
                                          ),
                                    width:
                                        _selectedPlatform ==
                                            SocialPlatform.facebook
                                        ? 2
                                        : 1,
                                  ),
                                  boxShadow:
                                      _selectedPlatform ==
                                          SocialPlatform.facebook
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.facebookBlue
                                                .withValues(alpha: 0.2),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.facebookBlue,
                                            AppTheme.facebookBlue.withValues(
                                              alpha: 0.8,
                                            ),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.facebookBlue
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child:
                                            _facebookPagePicture != null &&
                                                _facebookPagePicture!.isNotEmpty
                                            ? Image.network(
                                                _facebookPagePicture!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    const Center(
                                                      child: FaIcon(
                                                        FontAwesomeIcons
                                                            .facebook,
                                                        size: 24,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                              )
                                            : const Center(
                                                child: FaIcon(
                                                  FontAwesomeIcons.facebook,
                                                  size: 24,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Facebook',
                                            style: AppTheme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: AppTheme.mediumGrey,
                                                ),
                                          ),
                                          Text(
                                            _facebookPageName ??
                                                'Not connected',
                                            style: AppTheme.textTheme.bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      _selectedPlatform ==
                                                          SocialPlatform
                                                              .facebook
                                                      ? AppTheme.facebookBlue
                                                      : AppTheme.mediumGrey,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          // Instagram Card
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPlatform = SocialPlatform.instagram;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                  horizontal: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _selectedPlatform ==
                                          SocialPlatform.instagram
                                      ? AppTheme.instagramPink.withValues(
                                          alpha: 0.12,
                                        )
                                      : AppTheme.instagramPink.withValues(
                                          alpha: 0.05,
                                        ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.xl,
                                  ),
                                  border: Border.all(
                                    color:
                                        _selectedPlatform ==
                                            SocialPlatform.instagram
                                        ? AppTheme.instagramPink.withValues(
                                            alpha: 0.5,
                                          )
                                        : AppTheme.instagramPink.withValues(
                                            alpha: 0.2,
                                          ),
                                    width:
                                        _selectedPlatform ==
                                            SocialPlatform.instagram
                                        ? 2
                                        : 1,
                                  ),
                                  boxShadow:
                                      _selectedPlatform ==
                                          SocialPlatform.instagram
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.instagramPink
                                                .withValues(alpha: 0.2),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.instagramPink,
                                            AppTheme.instagramPink.withValues(
                                              alpha: 0.8,
                                            ),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.instagramPink
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child:
                                            _instagramAccountPicture != null &&
                                                _instagramAccountPicture!
                                                    .isNotEmpty
                                            ? Image.network(
                                                _instagramAccountPicture!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    const Center(
                                                      child: FaIcon(
                                                        FontAwesomeIcons
                                                            .instagram,
                                                        size: 24,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                              )
                                            : const Center(
                                                child: FaIcon(
                                                  FontAwesomeIcons.instagram,
                                                  size: 24,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Instagram',
                                            style: AppTheme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: AppTheme.mediumGrey,
                                                ),
                                          ),
                                          Text(
                                            _instagramAccountName ??
                                                'Not connected',
                                            style: AppTheme.textTheme.bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      _selectedPlatform ==
                                                          SocialPlatform
                                                              .instagram
                                                      ? AppTheme.instagramPink
                                                      : AppTheme.mediumGrey,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.md),
                    // Stats Row
                    if (_isLoadingStats)
                      Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryTeal,
                          ),
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Facebook',
                              _formatNumber(_fbFollowers),
                              AppTheme.facebookBlue,
                              FontAwesomeIcons.facebook,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _buildStatCard(
                              'Instagram',
                              _formatNumber(_igFollowers),
                              AppTheme.instagramPink,
                              FontAwesomeIcons.instagram,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _buildStatCard(
                              'Engagement',
                              '${_engagementRate.toStringAsFixed(1)}%',
                              AppTheme.success,
                              Icons.trending_up,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          // SCROLLABLE CONTENT AREA
          Expanded(
            child: _currentIndex == 0
                ? ContentScreen(platform: _selectedPlatform)
                : InboxScreen(platform: _selectedPlatform),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl),
            topRight: Radius.circular(AppRadius.xl),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.dark.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.facebookBlue,
          unselectedItemColor: AppTheme.mediumGrey,
          selectedLabelStyle: AppTheme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTheme.textTheme.labelSmall,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined, size: 24),
              activeIcon: Icon(Icons.grid_view, size: 24),
              label: 'Content',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline, size: 24),
              activeIcon: Icon(Icons.chat_bubble, size: 24),
              label: 'Inbox',
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActionsMenu,
        backgroundColor: AppTheme.facebookBlue,
        elevation: 8,
        tooltip: 'Quick Actions',
        child: const Icon(Icons.menu, size: 26),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                value,
                style: AppTheme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
    );
  }
}