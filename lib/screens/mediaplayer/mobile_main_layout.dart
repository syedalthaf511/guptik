import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mobile_home_loader.dart';
import 'mobile_upload_screen.dart';
import 'mobile_profile_screen.dart';

class MobileMainLayout extends StatefulWidget {
  final String gatewayUrl;
  final String currentUserUid; 

  const MobileMainLayout({
    Key? key, 
    required this.gatewayUrl,
    required this.currentUserUid,
  }) : super(key: key);

  @override
  _MobileMainLayoutState createState() => _MobileMainLayoutState();
}

class _MobileMainLayoutState extends State<MobileMainLayout> {
  int _currentIndex = 0;
  late String _resolvedUserId;
  String? _userChannelId;
  bool _isResolvingChannel = true;

  @override
  void initState() {
    super.initState();
    _resolvedUserId = widget.currentUserUid;
    _resolveActiveUserAndChannel();
  }

  String _getSanitizedGatewayUrl() {
    String url = widget.gatewayUrl.trim();
    
    // Auto-correct old IP references from database records
    if (url.contains('192.168.1.15')) {
      url = url.replaceAll('192.168.1.15', '192.168.1.186');
    }

    if (url.isEmpty || url.contains('myqrmart.com')) {
      return 'http://192.168.1.186:55000';
    }
    
    if (url.contains('192.168.') || url.contains('10.0.') || url.contains('127.0.0.1') || url.contains('localhost')) {
      url = url.replaceAll('https://', 'http://');
      if (!url.startsWith('http://')) {
        url = 'http://$url';
      }
    } else {
      if (!url.startsWith('http')) {
        url = 'https://$url';
      }
    }
    
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    
    // Automatically enforce port 55000 for local network IPs if missing
    if ((url.contains('192.168.') || url.contains('10.0.') || url.contains('127.0.0.1')) && !url.contains(':55000')) {
      url = '$url:55000';
    }
    
    return url;
  }

  Future<void> _resolveActiveUserAndChannel() async {
    try {
      final supabase = Supabase.instance.client;
      var user = supabase.auth.currentUser;
      
      if (_resolvedUserId.isEmpty && user != null) {
        _resolvedUserId = user.id;
      }

      if (_resolvedUserId.isNotEmpty) {
        // 1. Try to find the channel using the user's explicit auth ID / owner_uid
        try {
          final channelData = await supabase
              .from('mp_channels')
              .select('channel_id')
              .or('channel_id.eq.$_resolvedUserId,owner_uid.eq.$_resolvedUserId')
              .maybeSingle();

          if (channelData != null && channelData['channel_id'] != null) {
            if (mounted) {
              setState(() {
                _userChannelId = channelData['channel_id'].toString();
                _isResolvingChannel = false;
              });
            }
            return;
          }
        } catch (_) {}

        // 2. Fallback: Query mp_videos to find the channel_id associated with this user's uploads
        try {
          final videoChannel = await supabase
              .from('mp_videos')
              .select('channel_id')
              .eq('creator_uid', _resolvedUserId)
              .limit(1)
              .maybeSingle();

          if (videoChannel != null && videoChannel['channel_id'] != null) {
            if (mounted) {
              setState(() {
                _userChannelId = videoChannel['channel_id'].toString();
                _isResolvingChannel = false;
              });
            }
            return;
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("⚠️ Channel resolution warning: $e");
    }

    // 3. Ultimate Fallback: Default to the active local testing channel ID that holds your videos
    if (mounted) {
      setState(() {
        _userChannelId = '93f468b5-6653-4103-8f5e-71b7b323b46e';
        _isResolvingChannel = false;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isResolvingChannel) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    final effectiveChannelId = _userChannelId ?? '93f468b5-6653-4103-8f5e-71b7b323b46e';
    final sanitizedNodeUrl = _getSanitizedGatewayUrl();

    // 🚀 Updated screens layout: Home (0), Upload (1), Profile (2), Settings (3) positioned at the very bottom/end
    final List<Widget> screens = [
      MobileHomeLoader(gatewayUrl: sanitizedNodeUrl),
      MobileUploadScreen(gatewayUrl: sanitizedNodeUrl),
      MobileProfileScreen(
        key: ValueKey(effectiveChannelId), 
        channelId: effectiveChannelId, 
        nodeUrl: sanitizedNodeUrl,
      ), 
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      extendBody: true, 
      bottomNavigationBar: _buildGlassmorphicNavBar(),
    );
  }

  Widget _buildGlassmorphicNavBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          height: 85,
          padding: const EdgeInsets.only(bottom: 15), 
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.6), 
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(icon: Icons.home_filled, index: 0, label: "Home"),
              _buildCenterUploadButton(),
              _buildNavItem(icon: Icons.person_rounded, index: 2, label: "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index, required String label}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: isSelected ? Colors.orange : Colors.grey[500],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.orange : Colors.grey[500],
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCenterUploadButton() {
    return GestureDetector(
      onTap: () => _onTabTapped(1),
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.orange, Colors.deepOrangeAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            if (_currentIndex == 1)
              BoxShadow(
                color: Colors.orange.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              )
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

