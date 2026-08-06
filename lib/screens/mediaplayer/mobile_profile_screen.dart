import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:guptik/services/mediaplayer/mobile_bridge_service.dart';
import 'package:guptik/widgets/mediaplayer/mobile_video_player_widget.dart';

class MobileProfileScreen extends StatefulWidget {
  final String channelId;
  final String nodeUrl;

  const MobileProfileScreen({super.key, required this.channelId, required this.nodeUrl});

  @override
  _MobileProfileScreenState createState() => _MobileProfileScreenState();
}

class _MobileProfileScreenState extends State<MobileProfileScreen> {
  late MobileBridgeService _bridge; 
  Map<String, dynamic>? _profileData;
  List<PlayerVideo> _normalVideos = [];
  List<PlayerVideo> _reels = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0; // 0 = Videos, 1 = Shorts
  late String _resolvedNodeUrl;

  @override
  void initState() {
    super.initState();
    _resolvedNodeUrl = widget.nodeUrl;
    _initAndLoadProfile();
  }

  Future<void> _initAndLoadProfile() async {
    setState(() => _isLoading = true);

    try {
      // 🚀 1. SELF-HEALING TUNNEL RESOLUTION:
      // If the passed nodeUrl is empty or points to a generic domain, 
      // look up this specific channel's active tunnel URL from Supabase (`mp_channels`).
      if (_resolvedNodeUrl.isEmpty || _resolvedNodeUrl.contains('myqrmart.com')) {
        try {
          final channelMeta = await Supabase.instance.client
              .from('mp_channels')
              .select('tunnel_url')
              .eq('channel_id', widget.channelId)
              .maybeSingle();

          if (channelMeta != null && channelMeta['tunnel_url'] != null) {
            String dbTunnel = channelMeta['tunnel_url'].toString();
            if (!dbTunnel.startsWith('http')) {
              dbTunnel = 'https://$dbTunnel';
            }
            _resolvedNodeUrl = dbTunnel;
          }
        } catch (dbErr) {
          debugPrint("⚠️ Tunnel lookup fallback warning: $dbErr");
        }
      }

      // Final fallback if local testing or unmapped node
      if (_resolvedNodeUrl.isEmpty) {
        _resolvedNodeUrl = 'http://10.0.2.2:55000'; // Android Emulator localhost bridge fallback
      }

      _bridge = MobileBridgeService(gatewayUrl: _resolvedNodeUrl);

      // 2. Fetch Profile & Videos in parallel safely
      final profileFuture = _bridge.fetchChannelProfile(widget.channelId);
      final videosFuture = _bridge.fetchChannelVideos(_resolvedNodeUrl, widget.channelId);

      final results = await Future.wait([profileFuture, videosFuture]);

      if (mounted) {
        setState(() {
          _profileData = results[0] as Map<String, dynamic>?;
          final List<PlayerVideo> allVideos = results[1] as List<PlayerVideo>;
          _reels = allVideos.where((v) => v.isReel).toList();
          _normalVideos = allVideos.where((v) => !v.isReel).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ MobileProfileScreen load error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatViews(int views) {
    if (views >= 1000000) return '${(views / 1000000).toStringAsFixed(1)}M';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}K';
    return views.toString();
  }

  void _showVideoOptions(PlayerVideo video) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text('Edit Video', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit coming soon!')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text('Delete Video', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete triggered!')));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    final channelName = _profileData?['channel_name'] ?? 'Creator Channel';
    final bio = _profileData?['bio'] ?? 'Welcome to my decentralized channel!';
    final subscribers = _profileData?['subscribers'] ?? 0;
    final activeList = _selectedTabIndex == 0 ? _normalVideos : _reels;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(channelName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.orange,
                    child: Text(
                      channelName.isNotEmpty ? channelName[0].toUpperCase() : 'C',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    channelName,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${channelName.replaceAll(' ', '').toLowerCase()} • ${_formatViews(subscribers)} subscribers • ${_normalVideos.length + _reels.length} videos',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bio,
                    style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription coming soon!')));
                      },
                      child: const Text('Subscribe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _selectedTabIndex == 0 ? Colors.white : Colors.transparent, width: 2))),
                            child: Center(child: Text("Videos", style: TextStyle(color: _selectedTabIndex == 0 ? Colors.white : Colors.grey.shade500, fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _selectedTabIndex == 1 ? Colors.white : Colors.transparent, width: 2))),
                            child: Center(child: Text("Shorts", style: TextStyle(color: _selectedTabIndex == 1 ? Colors.white : Colors.grey.shade500, fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (activeList.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Center(
                  child: Text(
                    _selectedTabIndex == 0 ? "No videos uploaded yet." : "No Shorts uploaded yet.", 
                    style: TextStyle(color: Colors.grey[600])
                  ),
                ),
              ),
            ),
          if (activeList.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _selectedTabIndex == 0 ? 2 : 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 20,
                  childAspectRatio: _selectedTabIndex == 0 ? 0.75 : 0.55, 
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final video = activeList[index];
                    String baseNodeUrl = _resolvedNodeUrl;
                    if (!baseNodeUrl.startsWith('http')) {
                      baseNodeUrl = 'https://$baseNodeUrl';
                    }
                    if (baseNodeUrl.endsWith('/')) {
                      baseNodeUrl = baseNodeUrl.substring(0, baseNodeUrl.length - 1);
                    }
                    final itemThumbUrl = '$baseNodeUrl/player/video/thumbnail/${video.videoId}';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => Scaffold(
                            backgroundColor: Colors.black, 
                            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
                            extendBodyBehindAppBar: true,
                            body: MobileVideoPlayerWidget(video: video)
                          )
                        ));
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: _selectedTabIndex == 0 ? 16 / 9 : 9 / 16,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  itemThumbUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.play_arrow, color: Colors.white70)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, height: 1.2),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatViews(video.viewCount)} views',
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: activeList.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}