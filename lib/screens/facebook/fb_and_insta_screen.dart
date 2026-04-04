import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final ScrollController _scrollController = ScrollController();

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

  // Real data variables
  int _fbFollowers = 0;
  int _igFollowers = 0;
  double _engagementRate = 0.0;
  bool _isLoadingStats = true;

  final List<Widget> _screens = [const ContentScreen(), const InboxScreen()];

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(
                  icon: FontAwesomeIcons.facebook,
                  label: 'FB Analytics',
                  color: const Color(0xFF1877F2),
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
                  color: const Color(0xFFE1306C),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false, // Removes duplicate back button
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.grey[50]!],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
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
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.black,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF1877F2),
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 28,
                                      backgroundImage: _userAvatarUrl != null
                                          ? NetworkImage(_userAvatarUrl!)
                                          : null,
                                      backgroundColor: Colors.grey[200],
                                      child: _userAvatarUrl == null
                                          ? _isLoadingUser
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : Text(
                                                    _userName?.isNotEmpty ==
                                                            true
                                                        ? _userName![0]
                                                              .toUpperCase()
                                                        : 'U',
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.grey,
                                                    ),
                                                  )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back,',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        _userName ?? 'User',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (_userEmail != null)
                                        Text(
                                          _userEmail!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),

                              // Create Post Button
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1877F2),
                                      Color(0xFFE1306C),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 24,
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
                                  padding: const EdgeInsets.all(10),
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Platform Cards
                          if (!_isLoadingPageNames)
                            Row(
                              children: [
                                // Facebook Card
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF1877F2,
                                      ).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF1877F2,
                                        ).withValues(alpha: 0.25),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF1877F2),
                                                const Color(
                                                  0xFF1877F2,
                                                ).withValues(alpha: 0.8),
                                              ],
                                            ),
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
                                          child: ClipOval(
                                            child:
                                                _facebookPagePicture != null &&
                                                    _facebookPagePicture!
                                                        .isNotEmpty
                                                ? Image.network(
                                                    _facebookPagePicture!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          _,
                                                          __,
                                                          ___,
                                                        ) => const Center(
                                                          child: FaIcon(
                                                            FontAwesomeIcons
                                                                .facebook,
                                                            size: 26,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                  )
                                                : const Center(
                                                    child: FaIcon(
                                                      FontAwesomeIcons.facebook,
                                                      size: 26,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'Facebook',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                _facebookPageName ??
                                                    'Not connected',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1877F2),
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
                                const SizedBox(width: 12),
                                // Instagram Card
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFE1306C,
                                      ).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFE1306C,
                                        ).withValues(alpha: 0.25),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFFE1306C),
                                                const Color(
                                                  0xFFE1306C,
                                                ).withValues(alpha: 0.8),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFE1306C,
                                                ).withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child:
                                                _instagramAccountPicture !=
                                                        null &&
                                                    _instagramAccountPicture!
                                                        .isNotEmpty
                                                ? Image.network(
                                                    _instagramAccountPicture!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          _,
                                                          __,
                                                          ___,
                                                        ) => const Center(
                                                          child: FaIcon(
                                                            FontAwesomeIcons
                                                                .instagram,
                                                            size: 26,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                  )
                                                : const Center(
                                                    child: FaIcon(
                                                      FontAwesomeIcons
                                                          .instagram,
                                                      size: 26,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'Instagram',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                _instagramAccountName ??
                                                    'Not connected',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFFE1306C),
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
                              ],
                            ),
                          const SizedBox(height: 12),
                          // Stats Row
                          if (_isLoadingStats)
                            const Center(child: CircularProgressIndicator())
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Facebook',
                                    _formatNumber(_fbFollowers),
                                    const Color(0xFF1877F2),
                                    FontAwesomeIcons.facebook,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    'Instagram',
                                    _formatNumber(_igFollowers),
                                    const Color(0xFFE1306C),
                                    FontAwesomeIcons.instagram,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    'Engagement',
                                    '${_engagementRate.toStringAsFixed(1)}%',
                                    const Color(0xFF31A24C),
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
              ),
            ),
          ];
        },
        body: _screens[_currentIndex],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
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
          selectedItemColor: const Color(0xFF1877F2),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined, size: 26),
              activeIcon: Icon(Icons.grid_view, size: 26),
              label: 'Content',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline, size: 26),
              activeIcon: Icon(Icons.chat_bubble, size: 26),
              label: 'Inbox',
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActionsMenu,
        backgroundColor: const Color(0xFF1877F2),
        mini: false,
        child: const Icon(Icons.menu, size: 28),
        tooltip: 'Quick Actions',
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
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
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