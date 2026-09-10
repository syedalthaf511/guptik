import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:guptik/services/mediaplayer/mobile_bridge_service.dart';
import 'package:guptik/widgets/mediaplayer/mobile_video_player_widget.dart';
import 'package:guptik/screens/mediaplayer/mobile_profile_screen.dart'; // 🚀 Added import for profile routing
import 'package:guptik/screens/mediaplayer/mobile_reels_screen.dart'; // 🚀 ADDED: YouTube-style Shorts carousel opens the full reels feed

class MobileHomeLoader extends StatefulWidget {
  final String gatewayUrl;

  const MobileHomeLoader({Key? key, required this.gatewayUrl}) : super(key: key);

  @override
  _MobileHomeLoaderState createState() => _MobileHomeLoaderState();
}

class _MobileHomeLoaderState extends State<MobileHomeLoader> {
  late MobileBridgeService _bridge;

  // 🚀 ADDED: the unfiltered master lists fetched from the feed, kept intact
  // so search can be cleared and instantly restore the full feed without a
  // re-fetch.
  List<PlayerVideo> _allVideos = [];
  List<PlayerVideo> _allReels = [];

  // The lists actually rendered — either the full feed, or a search-filtered
  // subset of it.
  List<PlayerVideo> _videos = [];
  // 🚀 ADDED: reels are pulled out of the main feed and shown separately in a
  // horizontal "Shots" carousel, YouTube-style, instead of mixed in as
  // regular full-width cards.
  List<PlayerVideo> _reels = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // 🚀 ADDED: search controller — toggles an inline AppBar search field that
  // filters the home feed (both regular videos and Shots) by title, channel
  // name, or category as the user types.
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _bridge = MobileBridgeService(gatewayUrl: widget.gatewayUrl);
    _fetchVideos();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchVideos() async {
    try {
      final feed = await _bridge.getRemoteFeed();
      if (mounted) {
        setState(() {
          _allVideos = feed.where((v) => !v.isReel).toList();
          _allReels = feed.where((v) => v.isReel).toList();
          _videos = _allVideos;
          _reels = _allReels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load videos. Check your Gateway URL.';
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _videos = _allVideos;
        _reels = _allReels;
      } else {
        bool matches(PlayerVideo v) =>
            v.title.toLowerCase().contains(query) ||
            v.channelName.toLowerCase().contains(query) ||
            v.category.toLowerCase().contains(query);
        _videos = _allVideos.where(matches).toList();
        _reels = _allReels.where(matches).toList();
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        // 🚀 ADDED: search controller — tapping the search icon swaps the
        // title for an inline TextField that live-filters the feed by
        // title / channel name / category.
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: Colors.orange,
                decoration: const InputDecoration(
                  hintText: 'Search videos, channels...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              )
            : const Text(
                'Guptik MediaPlayer',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: _buildFeedList(),
    );
  }

  // 🚀 YouTube-style mixed feed: the first 2 regular videos show as normal
  // full-width cards, then (if any reels exist) a horizontal "Shots"
  // carousel is inserted, and the rest of the regular videos continue
  // below it as normal cards — exactly like the YouTube home feed layout.
  Widget _buildFeedList() {
    // 🚀 ADDED: friendly empty-state when a search query matches nothing.
    if (_videos.isEmpty && _reels.isEmpty) {
      return Center(
        child: Text(
          _isSearching || _searchController.text.isNotEmpty
              ? 'No results for "${_searchController.text}"'
              : 'No videos available yet.',
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    const int carouselInsertAfter = 2;
    final bool hasCarousel = _reels.isNotEmpty;
    // Total rows = video cards + (1 carousel row, if any reels)
    final int itemCount = _videos.length + (hasCarousel ? 1 : 0);

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const Divider(
        color: Colors.white12,
        thickness: 1,
        height: 1,
      ),
      itemBuilder: (context, index) {
        // Insert the Shots carousel right after the first `carouselInsertAfter`
        // regular videos (or at the end if fewer videos exist than that).
        final int carouselPosition = hasCarousel
            ? (carouselInsertAfter <= _videos.length ? carouselInsertAfter : _videos.length)
            : -1;

        if (hasCarousel && index == carouselPosition) {
          return _buildShotsCarousel();
        }

        // Shift the video index down by one once we're past the carousel row.
        final videoIndex = (hasCarousel && index > carouselPosition) ? index - 1 : index;
        return LoaderVideoCard(
          video: _videos[videoIndex],
          gatewayUrl: widget.gatewayUrl,
        );
      },
    );
  }

  // 🚀 YouTube-Shorts-style horizontal carousel row. Tapping any thumbnail
  // opens the full-screen vertical MobileReelsScreen, pre-loaded with the
  // whole _reels list starting at the tapped item — mirroring how YouTube's
  // home feed "Shorts" row launches straight into the Shorts player.
  Widget _buildShotsCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: const [
              Icon(Icons.slow_motion_video_rounded, color: Colors.orange, size: 22),
              SizedBox(width: 6),
              Text(
                'Shots',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _reels.length,
            itemBuilder: (context, index) {
              return _ShotsCarouselItem(
                video: _reels[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MobileReelsScreen(
                        gatewayUrl: widget.gatewayUrl,
                        reels: _reels,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// 🚀 ADDED: a single vertical (9:16) thumbnail tile for the Shots carousel.
class _ShotsCarouselItem extends StatelessWidget {
  final PlayerVideo video;
  final VoidCallback onTap;

  const _ShotsCarouselItem({required this.video, required this.onTap});

  String _cleanThumbnailUrl(String raw) {
    String cleanUrl = raw.trim();
    if (cleanUrl.contains('192.168.1.15')) {
      cleanUrl = cleanUrl.replaceAll('192.168.1.15', '192.168.1.186');
    }
    if (cleanUrl.isEmpty) return cleanUrl;
    if (cleanUrl.contains('192.168.') || cleanUrl.contains('10.0.') || cleanUrl.contains('127.0.0.1') || cleanUrl.contains('localhost')) {
      cleanUrl = cleanUrl.replaceAll('https://', 'http://');
      if (!cleanUrl.startsWith('http://')) {
        cleanUrl = 'http://$cleanUrl';
      }
    } else {
      if (!cleanUrl.startsWith('http')) {
        cleanUrl = 'https://$cleanUrl';
      }
    }
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if ((cleanUrl.contains('192.168.') || cleanUrl.contains('10.0.') || cleanUrl.contains('127.0.0.1')) && !cleanUrl.contains(':55000')) {
      cleanUrl = '$cleanUrl:55000';
    }
    return cleanUrl;
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = _cleanThumbnailUrl(video.creatorUrl);
    final thumbnailUrl = '$cleanUrl/player/video/thumbnail/${video.videoId}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.play_circle_fill_rounded, size: 40, color: Colors.orange),
              ),
            ),
            const Positioned(
              top: 8,
              left: 8,
              child: Icon(Icons.slow_motion_video_rounded, color: Colors.white, size: 18),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                video.title,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoaderVideoCard extends StatefulWidget {
  final PlayerVideo video;
  final String gatewayUrl;

  const LoaderVideoCard({Key? key, required this.video, required this.gatewayUrl}) : super(key: key);

  @override
  State<LoaderVideoCard> createState() => _LoaderVideoCardState();
}

class _LoaderVideoCardState extends State<LoaderVideoCard> {
  late int _liveViews;
  late final MobileBridgeService _bridge;

  @override
  void initState() {
    super.initState();
    _liveViews = widget.video.viewCount;
    _bridge = MobileBridgeService(gatewayUrl: widget.video.creatorUrl);
    _fetchLiveNodeViews();
  }

  Future<void> _fetchLiveNodeViews() async {
    final stats = await _bridge.fetchVideoStats(widget.video.videoId);
    if (stats != null && stats['views'] != null && mounted) {
      setState(() {
        _liveViews = stats['views'];
      });
    }
  }

  String _formatViews(int views) {
    if (views >= 1000000) return '${(views / 1000000).toStringAsFixed(1)}M';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}K';
    return views.toString();
  }

  // 🚀 Audience badge — only 18+ shown on home feed cards (monetization/kids
  // tags removed per request; keep this file lean)
  List<Widget> _buildAudienceBadges() {
    final badges = <Widget>[];
    if (widget.video.ageRating == '18+') {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.redAccent.withOpacity(0.55)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 11, color: Colors.redAccent),
              SizedBox(width: 3),
              Text('18+', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
    }
    return badges;
  }

  // 🚀 ADDED: Engagement counts row (reactions / saves / reposts) — mirrors
  // desktop's player_video_card.dart engagement metrics row
  Widget _buildEngagementRow() {
    final items = <Widget>[];
    if (widget.video.totalReactions > 0) {
      items.addAll([
        Icon(Icons.favorite, size: 11, color: Colors.pinkAccent.withOpacity(0.7)),
        const SizedBox(width: 2),
        Text(_formatViews(widget.video.totalReactions), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        const SizedBox(width: 8),
      ]);
    }
    if (widget.video.saveCount > 0) {
      items.addAll([
        Icon(Icons.bookmark, size: 11, color: Colors.grey[500]),
        const SizedBox(width: 2),
        Text(_formatViews(widget.video.saveCount), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        const SizedBox(width: 8),
      ]);
    }
    if (widget.video.repostCount > 0) {
      items.addAll([
        Icon(Icons.repeat, size: 11, color: Colors.grey[500]),
        const SizedBox(width: 2),
        Text(_formatViews(widget.video.repostCount), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ]);
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: items),
    );
  }

  String _getTimeAgo(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'recently';
    try {
      final date = DateTime.parse(dateString);
      final difference = DateTime.now().difference(date);
      if (difference.inDays > 365) return '${(difference.inDays / 365).floor()}y ago';
      if (difference.inDays > 30) return '${(difference.inDays / 30).floor()}mo ago';
      if (difference.inDays > 0) return '${difference.inDays}d ago';
      if (difference.inHours > 0) return '${difference.inHours}h ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
      return 'just now';
    } catch (_) {
      return 'recently';
    }
  }

    @override
  Widget build(BuildContext context) {
    // 🚀 Robust URL normalization for local & cloud nodes
    String cleanUrl = widget.video.creatorUrl.trim();

    // 🚀 THE FIX: only assume "this is my own local gateway" when the video
    // actually belongs to the currently logged-in user. Applying this fallback
    // to OTHER creators' videos was silently redirecting their thumbnail
    // requests to OUR OWN gateway (which doesn't have their file -> 404),
    // even though their video streamed fine because the player widget builds
    // its URL separately and doesn't have this bug.
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnVideo = currentUserId != null && widget.video.creatorUid == currentUserId;

    // Auto-swap old IP to current active PC IP
    if (cleanUrl.contains('192.168.1.15')) {
      cleanUrl = cleanUrl.replaceAll('192.168.1.15', '192.168.1.186');
    }

    // 🚀 THE REAL FIX: 'myqrmart.com' is our OWN app's real cloud tunnel domain
    // (e.g. "xyz.myqrmart.com" is a legitimate, working address for any creator),
    // NOT a placeholder meaning "unset". Treating it as unset was wrongly
    // redirecting other creators' real, working thumbnail URLs to our own PC.
    // We now only substitute our own gateway when the URL is genuinely EMPTY,
    // and only for our own videos. Everyone else's non-empty URL (including
    // myqrmart.com ones) just gets normal scheme normalization, same as the
    // bridge service already does successfully for /stats calls.
    if (cleanUrl.isEmpty) {
      if (isOwnVideo) {
        cleanUrl = 'http://192.168.1.186:55000';
      }
      // else: leave empty; errorBuilder will show the placeholder icon
    } else {
      // Force http for local network addresses
      if (cleanUrl.contains('192.168.') || cleanUrl.contains('10.0.') || cleanUrl.contains('127.0.0.1') || cleanUrl.contains('localhost')) {
        cleanUrl = cleanUrl.replaceAll('https://', 'http://');
        if (!cleanUrl.startsWith('http://')) {
          cleanUrl = 'http://$cleanUrl';
        }
      } else {
        if (!cleanUrl.startsWith('http')) {
          cleanUrl = 'https://$cleanUrl';
        }
      }

      if (cleanUrl.endsWith('/')) {
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
      }

      // Enforce port 55000 for local network IPs if missing
      if ((cleanUrl.contains('192.168.') || cleanUrl.contains('10.0.') || cleanUrl.contains('127.0.0.1')) && !cleanUrl.contains(':55000')) {
        cleanUrl = '$cleanUrl:55000';
      }
    }

    final thumbnailUrl = '$cleanUrl/player/video/thumbnail/${widget.video.videoId}';
    
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
              extendBodyBehindAppBar: true,
              body: MobileVideoPlayerWidget(video: widget.video),
            ),
          ),
        );
        _fetchLiveNodeViews();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: const Color(0xFF1E1E1E),
              child: Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.play_circle_fill_rounded, size: 55, color: Colors.orange),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🚀 Tapping the Avatar opens the creator's profile properly
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MobileProfileScreen(
                          channelId: widget.video.channelId,
                          nodeUrl: '', // 🚀 force fresh tunnel_url lookup instead of trusting a possibly stale stored URL
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Text(
                      widget.video.channelName.isNotEmpty ? widget.video.channelName[0].toUpperCase() : 'G', 
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.title, 
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // 🚀 Tapping the Channel Name opens the profile as well
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MobileProfileScreen(
                                channelId: widget.video.channelId,
                                nodeUrl: '', // 🚀 force fresh tunnel_url lookup instead of trusting a possibly stale stored URL
                              ),
                            ),
                          );
                        },
                        child: Text(
                          '${widget.video.channelName} • ${_formatViews(_liveViews)} views • ${_getTimeAgo(widget.video.createdAt)}', 
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ),
                      // 🚀 ADDED: Engagement counts (reactions/saves/reposts)
                      _buildEngagementRow(),
                      // 🚀 ADDED: Audience badges (Monetized / Made for Kids / 18+)
                      if (widget.video.ageRating == '18+') ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _buildAudienceBadges(),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}