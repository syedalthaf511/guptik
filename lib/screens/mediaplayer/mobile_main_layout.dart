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

  @override
  void initState() {
    super.initState();
    _resolvedUserId = widget.currentUserUid;
    _resolveActiveUser();
  }

  Future<void> _resolveActiveUser() async {
    if (_resolvedUserId.isEmpty) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && mounted) {
        setState(() {
          _resolvedUserId = user.id;
        });
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 Fallback to active session ID if layout was initialized with empty string
    final effectiveUserId = _resolvedUserId.isNotEmpty 
        ? _resolvedUserId 
        : (Supabase.instance.client.auth.currentUser?.id ?? 'guest_channel');

    final List<Widget> screens = [
      MobileHomeLoader(gatewayUrl: widget.gatewayUrl),
      MobileUploadScreen(gatewayUrl: widget.gatewayUrl),
      MobileProfileScreen(
        key: ValueKey(effectiveUserId), // 🚀 Forces rebuild if user context changes
        channelId: effectiveUserId, 
        nodeUrl: widget.gatewayUrl,
      ),
      const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text("Settings Coming Soon", style: TextStyle(color: Colors.white, fontSize: 20))),
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