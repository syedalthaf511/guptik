import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guptik/models/home/dashboard_models.dart';
import 'package:guptik/models/whatsapp/wa_conversation.dart';
import 'package:guptik/screens/dashboard/flows_screen.dart';
import 'package:guptik/screens/dashboard/message_templates_screen.dart';
import 'package:guptik/screens/facebook/fb_and_insta_screen.dart';
import 'package:guptik/screens/guptik/guptik_screen.dart';
import 'package:guptik/screens/home_control/homecontrol_screen.dart';
import 'package:guptik/screens/media/media_player_screen.dart';
import 'package:guptik/screens/trust_me/trust_me_mobile_wrapper.dart';
import 'package:guptik/screens/vault/vaultscreen.dart';
import 'package:guptik/services/dashboard/whatsapp_business_service.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';
import 'package:guptik/utils/theme/theme_manager.dart';
import 'package:guptik/widgets/home/water_splash_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/screens/dashboard/quick_replies_screen.dart';
import 'package:guptik/screens/dashboard/contacts_screen.dart';
import 'package:guptik/screens/dashboard/contact_lists_screen.dart';
import 'package:guptik/screens/dashboard/contact_tags_screen.dart';
import 'package:guptik/screens/dashboard/smart_segments_screen.dart';
import 'package:guptik/screens/dashboard/import_export_screen.dart';
import 'package:guptik/screens/dashboard/notification_management_screen.dart';
import 'package:guptik/screens/dashboard/analytics_messaging_screen.dart';
import 'package:guptik/screens/dashboard/analytics_message_templates_screen.dart';
import 'package:guptik/screens/dashboard/analytics_flow_responses_screen.dart';
import 'package:guptik/screens/dashboard/analytics_bot_sessions_screen.dart';
import 'package:guptik/screens/dashboard/analytics_drip_sessions_screen.dart';
import 'package:guptik/screens/dashboard/analytics_notifications_screen.dart';
import 'package:guptik/screens/dashboard/basic_automation_screen.dart';
import 'package:guptik/screens/dashboard/auto_replies_screen.dart';
import 'package:guptik/screens/dashboard/bots_screen.dart';
import 'package:guptik/screens/dashboard/drip_sequences_screen.dart';
import 'package:guptik/services/dashboard/conversations_service.dart';
import 'package:guptik/screens/dashboard/business_settings_screen.dart';
import 'package:guptik/screens/whatsapp/main_whatsapp_screen.dart';
// import 'package:guptik/widgets/home/water_key_button.dart';

// IMPORTANT IMPORTS FOR YOUR NEWLY SEPARATED FILES
import 'analytics_and_account_tab.dart'; 
import 'profile_menu_dialog.dart';

// Ancient Gold Color Definition
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);


class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassContainer({super.key, required this.child, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _ancientGold.withValues(alpha: 0.25), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SafeRow extends StatelessWidget {
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final List<Widget> children;
  final MainAxisSize mainAxisSize;

  const SafeRow({
    super.key,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  DashboardData? _dashboardData;
  bool _isLoading = true;
  String? _error;
  final int _maxRetries = 3;

  final WhatsAppBusinessService _whatsappService = WhatsAppBusinessService();
  final ConversationsService _conversationsService = ConversationsService();

  User? get _currentUser => Supabase.instance.client.auth.currentUser;

  final List<DashboardSection> _sections = [
    DashboardSection(icon: Icons.dashboard, title: 'Dashboard', isSelected: true),
    DashboardSection(
      icon: Icons.library_books,
      title: 'Content Library',
      subSections: [
        SubSection(title: 'Message Templates', icon: Icons.message),
        SubSection(title: 'Flows', icon: Icons.account_tree),
        SubSection(title: 'Quick Replies', icon: Icons.reply),
      ],
    ),
    DashboardSection(
      icon: Icons.contacts,
      title: 'Contacts',
      subSections: [
        SubSection(title: 'Contacts', icon: Icons.person),
        SubSection(title: 'Lists', icon: Icons.list),
        SubSection(title: 'Tags', icon: Icons.local_offer),
        SubSection(title: 'Smart Segments', icon: Icons.group),
        SubSection(title: 'Import / Export', icon: Icons.import_export),
      ],
    ),
    DashboardSection(
      icon: Icons.notifications,
      title: 'Notifications',
      subSections: [
        SubSection(title: 'Notifications', icon: Icons.notifications),
        SubSection(title: 'Add New', icon: Icons.add),
      ],
    ),
    DashboardSection(
      icon: Icons.autorenew,
      title: 'Automations',
      subSections: [
        SubSection(title: 'Basic', icon: Icons.play_arrow),
        SubSection(title: 'Auto-replies', icon: Icons.reply_all),
        SubSection(title: 'Bots', icon: Icons.smart_toy),
        SubSection(title: 'Drip Sequences', icon: Icons.water_drop),
      ],
    ),
    DashboardSection(
      icon: Icons.analytics,
      title: 'Analytics & Reports',
      subSections: [
        SubSection(title: 'Messaging', icon: Icons.message),
        SubSection(title: 'Notifications', icon: Icons.notifications),
        SubSection(title: 'Message Templates', icon: Icons.description),
        SubSection(title: 'Flow Responses', icon: Icons.account_tree),
        SubSection(title: 'Bot Sessions', icon: Icons.smart_toy),
        SubSection(title: 'Drip Sessions', icon: Icons.water_drop),
      ],
    ),
    DashboardSection(icon: Icons.inbox, title: 'Inbox'),
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadLiveData();
    _startPeriodicRefresh();
  }

  void _loadLiveData() async {
    await _loadLiveDataWithRetry();
  }

  Future<void> _loadLiveDataWithRetry([int attemptCount = 0]) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _whatsappService.getLiveDashboardData();

      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final isNetworkError = e.toString().contains('network') || e.toString().contains('timeout') || e.toString().contains('connection');
        if (isNetworkError && attemptCount < _maxRetries) {
          final delaySeconds = (2 << attemptCount) * 2;
          setState(() {
            _error = 'Connection issue. Retrying in $delaySeconds seconds... (${attemptCount + 1}/$_maxRetries)';
            _isLoading = false;
          });
          Future.delayed(Duration(seconds: delaySeconds), () {
            if (mounted) _loadLiveDataWithRetry(attemptCount + 1);
          });
        } else {
          setState(() {
            _error = attemptCount >= _maxRetries ? 'Failed to load data after $_maxRetries attempts.' : 'Failed to load live data: $e';
            _isLoading = false;
          });
        }
      }
    }
  }

  void _startPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadLiveData();
        _startPeriodicRefresh();
      }
    });
  }

  void _showUpgradePlanDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Row(
            children: [
              Icon(Icons.star, color: _ancientGold),
              SizedBox(width: 8),
              Text('Upgrade Your Plan', style: TextStyle(color: _ancientGold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unlock premium features to grow your business faster:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70)),
              const SizedBox(height: 16),
              _buildFeatureItem('❖', 'Unlimited message templates'),
              _buildFeatureItem('❖', 'Advanced analytics & reports'),
              _buildFeatureItem('❖', 'Unlimited contacts & segments'),
              _buildFeatureItem('❖', 'AI-powered automation'),
              _buildFeatureItem('❖', 'Multi-device access'),
              _buildFeatureItem('❖', 'Priority customer support'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _ancientGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.local_offer, color: _ancientGold),
                    SizedBox(width: 8),
                    Expanded(child: Text('Special offer: Get 30% off your first 3 months!', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Maybe Later', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleUpgrade();
              },
              style: ElevatedButton.styleFrom(backgroundColor: _ancientGold, foregroundColor: Colors.black),
              child: const Text('Upgrade Now'),
            ),
          ],
        );
      },
    );
  }

  void _showThemePicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black87,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
    ),
    builder: (context) {
      return ListenableBuilder(
        listenable: ThemeManager.instance,
        builder: (context, _) {
          final current = ThemeManager.instance.currentMode;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Select Theme", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome, color: Colors.purpleAccent),
                    title: const Text("Animated Nebula", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: current == AppThemeMode.nebula ? const Icon(Icons.check_circle, color: Color(0xFFD4AF37)) : null,
                    onTap: () => ThemeManager.instance.changeTheme(AppThemeMode.nebula),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dark_mode, color: Colors.blueGrey),
                    title: const Text("Solid Dark", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: current == AppThemeMode.dark ? const Icon(Icons.check_circle, color: Color(0xFFD4AF37)) : null,
                    onTap: () => ThemeManager.instance.changeTheme(AppThemeMode.dark),
                  ),
                  ListTile(
                    leading: const Icon(Icons.light_mode, color: Colors.orangeAccent),
                    title: const Text("Classic Light", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: current == AppThemeMode.classic ? const Icon(Icons.check_circle, color: Color(0xFFD4AF37)) : null,
                    onTap: () => ThemeManager.instance.changeTheme(AppThemeMode.classic),
                  ),
                ],
              ),
            ),
          );
        }
      );
    },
  );
}

  Widget _buildFeatureItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16, color: _ancientGold)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.white70), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  void _handleUpgrade() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('Choose Your Plan', style: TextStyle(color: _ancientGold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPlanOption('Starter', '\$19/month', 'Perfect for small businesses', ['5,000 messages/month', 'Basic analytics', 'Email support'], false),
              const SizedBox(height: 16),
              _buildPlanOption('Professional', '\$49/month', 'Best for growing businesses', ['25,000 messages/month', 'Advanced analytics', 'Priority support', 'AI automation'], true),
              const SizedBox(height: 16),
              _buildPlanOption('Enterprise', '\$99/month', 'For large organizations', ['Unlimited messages', 'Custom integrations', 'Dedicated manager', 'White-label options'], false),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ],
        );
      },
    );
  }

  Widget _buildPlanOption(String name, String price, String description, List<String> features, bool isRecommended) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: isRecommended ? _ancientGold : Colors.grey[800]!, width: isRecommended ? 2 : 1),
        borderRadius: BorderRadius.circular(12),
        color: isRecommended ? _ancientGold.withValues(alpha: 0.1) : Colors.black,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isRecommended ? _ancientGold : Colors.white), overflow: TextOverflow.ellipsis)),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: _ancientGold, borderRadius: BorderRadius.circular(12)),
                            child: const Text('RECOMMENDED', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[500]), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text(price, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isRecommended ? _ancientGold : Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: isRecommended ? _ancientGold : Colors.grey[400]),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature, style: const TextStyle(fontSize: 12, color: Colors.white70), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _selectPlan(name, price);
              },
              style: ElevatedButton.styleFrom(backgroundColor: isRecommended ? _ancientGold : Colors.grey[800], foregroundColor: isRecommended ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
              child: Text('Select $name', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _selectPlan(String planName, String price) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected $planName plan ($price). Redirecting to payment...', style: const TextStyle(color: Colors.black)),
        backgroundColor: _ancientGold,
        action: SnackBarAction(label: 'PROCEED', textColor: Colors.black, onPressed: () {}),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length == 1) return nameParts[0][0].toUpperCase();
    return '${nameParts[0][0].toUpperCase()}${nameParts[1][0].toUpperCase()}';
  }

  String _getUserDisplayName() {
    return _dashboardData?.businessProfile?.displayName ?? _currentUser?.userMetadata?['full_name'] ?? _currentUser?.email?.split('@')[0] ?? 'Business User';
  }

  String _getUserEmail() {
    return _currentUser?.email ?? 'user@example.com';
  }

  int _getTotalMenuItemCount() {
    int count = 0;
    for (var section in _sections) {
      count++;
      if (section.isExpanded && section.subSections != null) {
        count += section.subSections!.length;
      }
    }
    return count;
  }

  Widget _buildMenuItem(int flatIndex) {
    int currentIndex = 0;
    for (int sectionIndex = 0; sectionIndex < _sections.length; sectionIndex++) {
      final section = _sections[sectionIndex];
      if (currentIndex == flatIndex) return _buildMainMenuItem(section, sectionIndex);
      currentIndex++;

      if (section.isExpanded && section.subSections != null) {
        for (int subIndex = 0; subIndex < section.subSections!.length; subIndex++) {
          if (currentIndex == flatIndex) {
            return _buildSubMenuItem(section.subSections![subIndex], sectionIndex, subIndex);
          }
          currentIndex++;
        }
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildMainMenuItem(DashboardSection section, int sectionIndex) {
    final isSelected = sectionIndex == _selectedIndex;
    final hasSubSections = section.subSections != null && section.subSections!.isNotEmpty;

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: ListTile(
        dense: true,
        leading: Icon(section.icon, color: isSelected ? _ancientGold : Colors.grey[500], size: 20),
        title: Text(
          section.title,
          style: TextStyle(color: isSelected ? _ancientGold : Colors.grey[400], fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: hasSubSections ? Icon(section.isExpanded ? Icons.expand_less : Icons.expand_more, color: isSelected ? _ancientGold : Colors.grey[500], size: 20) : null,
        selected: isSelected,
        selectedTileColor: _ancientGold.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          setState(() {
            if (hasSubSections) {
              section.isExpanded = !section.isExpanded;
              _selectedIndex = sectionIndex;
            } else {
              _selectedIndex = sectionIndex;
            }
            for (int i = 0; i < _sections.length; i++) {
              _sections[i].isSelected = i == sectionIndex;
              if (_sections[i].subSections != null) {
                for (var subSection in _sections[i].subSections!) subSection.isSelected = false;
              }
            }
          });
          if (MediaQuery.of(context).size.width < 768) Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildSubMenuItem(SubSection subSection, int sectionIndex, int subIndex) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: ListTile(
        dense: true,
        leading: const SizedBox(width: 20),
        title: Row(
          children: [
            if (subSection.icon != null) ...[
              Icon(subSection.icon!, color: subSection.isSelected ? _ancientGold : Colors.grey[500], size: 16),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                subSection.title,
                style: TextStyle(color: subSection.isSelected ? _ancientGold : Colors.grey[400], fontWeight: subSection.isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        selected: subSection.isSelected,
        selectedTileColor: _ancientGold.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.only(left: 32, right: 16),
        onTap: () {
          setState(() {
            _selectedIndex = -1;
            for (var section in _sections) {
              section.isSelected = false;
              if (section.subSections != null) {
                for (var sub in section.subSections!) sub.isSelected = false;
              }
            }
            subSection.isSelected = true;
          });
          if (MediaQuery.of(context).size.width < 768) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 768) {
          // Mobile Layout
          return SafeArea(
            child: Scaffold(
              backgroundColor: _darkBg,
              key: _scaffoldKey,
              drawer: _buildMobileDrawer(context),
              body: Stack(
                children: [
                  const Positioned.fill(child: DynamicAppBackground()),
                  Column(
                    children: [
                      // Top Bar for Mobile
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border(bottom: BorderSide(color: _ancientGold.withValues(alpha: 0.2))),
                          boxShadow: [
                            BoxShadow(color: _ancientGold.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.menu, color: _ancientGold, size: 24),
                              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getCurrentTitle(),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _ancientGold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(maxWidth: 100),
                              child: InkWell(
                                onTap: _showUpgradePlanDialog,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    border: Border.all(color: _ancientGold),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Upgrade',
                                    style: TextStyle(color: _ancientGold, fontWeight: FontWeight.w600, fontSize: 11),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined, color: _ancientGold, size: 20),
                              onPressed: () {},
                            ),
                            // const SizedBox(width: 0),
                            IconButton(
                            icon: const Icon(Icons.palette, color: _ancientGold, size: 20),
                            tooltip: 'Change Theme',
                            onPressed: () => _showThemePicker(context),
                                  ),
                            InkWell(
                              onTap: () {
                                showProfileMenu(
                                  context: context,
                                  displayName: _getUserDisplayName(),
                                  email: _getUserEmail(),
                                  initials: _getInitials(_getUserDisplayName()),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: _ancientGold,
                                child: Text(
                                  _getInitials(_getUserDisplayName()),
                                  style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: _buildCurrentContent()),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // Desktop Layout
        return Scaffold(
          backgroundColor: _darkBg,
          body: SafeArea(
            child: Row(
              children: [
                // Sidebar
                Container(
                  width: 260,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    border: Border(right: BorderSide(color: _ancientGold.withValues(alpha: 0.2))),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: const Row(
                            children: [
                              Icon(Icons.chat_bubble_outline, color: _ancientGold, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Meta Fly',
                                  style: TextStyle(color: _ancientGold, fontSize: 20, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Business Info
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _ancientGold.withValues(alpha: 0.05),
                            border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: _ancientGold,
                                    child: Icon(Icons.store, color: Colors.black, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _dashboardData?.businessProfile?.displayName ?? 'Business Name',
                                      style: const TextStyle(color: _ancientGold, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _dashboardData?.businessProfile?.phoneNumber ?? 'Phone Number',
                                style: TextStyle(color: _ancientGold.withValues(alpha: 0.7), fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Menu
                        Expanded(
                          child: ListView.builder(
                            itemCount: _getTotalMenuItemCount(),
                            itemBuilder: (context, index) => _buildMenuItem(index),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Content
                Expanded(
                  child: Stack(
                    children: [
                      const Positioned.fill(child: DynamicAppBackground()),
                      Column(
                        children: [
                          // Top Bar
                          Container(
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border(bottom: BorderSide(color: _ancientGold.withValues(alpha: 0.2))),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _getCurrentTitle(),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _ancientGold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  constraints: const BoxConstraints(maxWidth: 100),
                                  child: InkWell(
                                    onTap: _showUpgradePlanDialog,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        border: Border.all(color: _ancientGold),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Upgrade',
                                        style: TextStyle(color: _ancientGold, fontWeight: FontWeight.w600, fontSize: 11),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined, color: _ancientGold, size: 20),
                                  onPressed: () {},
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    showProfileMenu(
                                      context: context,
                                      displayName: _getUserDisplayName(),
                                      email: _getUserEmail(),
                                      initials: _getInitials(_getUserDisplayName()),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: _ancientGold,
                                    child: Text(
                                      _getInitials(_getUserDisplayName()),
                                      style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Content Area
                          Expanded(child: _buildCurrentContent()),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      width: 280,
      child: Container(
        color: Colors.black,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _ancientGold.withValues(alpha: 0.2)))),
              child: const Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: _ancientGold, size: 28),
                  SizedBox(width: 12),
                  Text('Meta Fly', style: TextStyle(color: _ancientGold, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _getTotalMenuItemCount(),
                itemBuilder: (context, index) => _buildMenuItem(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentTitle() {
    for (var section in _sections) {
      if (section.subSections != null) {
        for (var subSection in section.subSections!) {
          if (subSection.isSelected) return subSection.title;
        }
      }
    }
    if (_selectedIndex >= 0 && _selectedIndex < _sections.length) {
      if (_sections[_selectedIndex].title == 'Inbox') return 'Conversations';
      return _sections[_selectedIndex].title;
    }
    return 'Dashboard';
  }

  Widget _buildCurrentContent() {
    for (var section in _sections) {
      if (section.subSections != null) {
        for (var subSection in section.subSections!) {
          if (subSection.isSelected) {
            return _buildSubSectionContent(subSection.title, section.title);
          }
        }
      }
    }
    if (_selectedIndex == 0) return _buildDashboardContent();
    if (_selectedIndex > 0 && _selectedIndex < _sections.length) return _buildOtherContent();
    return _buildDashboardContent();
  }

  Widget _buildSubSectionContent(String subSectionTitle, [String? parentSection]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getSubSectionIcon(subSectionTitle), size: 64, color: _ancientGold),
          const SizedBox(height: 16),
          Text(subSectionTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _ancientGold)),
          const SizedBox(height: 8),
          Text(_getSubSectionDescription(subSectionTitle), style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (subSectionTitle == 'Message Templates') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MessageTemplatesScreen()));
              } else if (subSectionTitle == 'Flows') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FlowsScreen()));
              } else if (subSectionTitle == 'Quick Replies') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const QuickRepliesScreen()));
              } else if (subSectionTitle == 'Contacts') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactsScreen()));
              } else if (subSectionTitle == 'Lists') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactListsScreen()));
              } else if (subSectionTitle == 'Tags') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactTagsScreen()));
              } else if (subSectionTitle == 'Smart Segments') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SmartSegmentsScreen()));
              } else if (subSectionTitle == 'Import / Export') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ImportExportScreen()));
              } else if (subSectionTitle == 'Notifications') {
                if (parentSection == 'Analytics & Reports') {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsNotificationsScreen()));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationManagementScreen()));
                }
              } else if (subSectionTitle == 'Add New') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationManagementScreen()));
              } else if (subSectionTitle == 'Messaging') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsMessagingScreen()));
              } else if (subSectionTitle == 'Message Templates') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsMessageTemplatesScreen()));
              } else if (subSectionTitle == 'Flow Responses') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsFlowResponsesScreen()));
              } else if (subSectionTitle == 'Bot Sessions') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsBotSessionsScreen()));
              } else if (subSectionTitle == 'Drip Sessions') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsDripSessionsScreen()));
              } else if (subSectionTitle == 'Basic') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BasicAutomationScreen()));
              } else if (subSectionTitle == 'Auto-replies') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AutoRepliesScreen()));
              } else if (subSectionTitle == 'Bots') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BotsScreen()));
              } else if (subSectionTitle == 'Drip Sequences') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DripSequencesScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening...', style: TextStyle(color: Colors.black)), backgroundColor: _ancientGold),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _ancientGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Manage $subSectionTitle'),
          ),
        ],
      ),
    );
  }

  IconData _getSubSectionIcon(String subSectionTitle) {
    switch (subSectionTitle) {
      case 'Message Templates': return Icons.message;
      case 'Flows': return Icons.account_tree;
      case 'Quick Replies': return Icons.reply;
      case 'Contacts': return Icons.person;
      case 'Lists': return Icons.list;
      case 'Tags': return Icons.local_offer;
      case 'Smart Segments': return Icons.group;
      case 'Import / Export': return Icons.import_export;
      case 'Notifications': return Icons.notifications;
      case 'Add New': return Icons.add;
      case 'Basic': return Icons.play_arrow;
      case 'Auto-replies': return Icons.reply_all;
      case 'Bots': return Icons.smart_toy;
      case 'Drip Sequences': return Icons.water_drop;
      case 'Messaging': return Icons.message;
      case 'Flow Responses': return Icons.account_tree;
      case 'Bot Sessions': return Icons.smart_toy;
      case 'Drip Sessions': return Icons.water_drop;
      default: return Icons.description;
    }
  }

  String _getSubSectionDescription(String subSectionTitle) {
    switch (subSectionTitle) {
      case 'Message Templates': return 'Create and manage reusable message templates\nfor your WhatsApp Business communications.';
      case 'Flows': return 'Design automated conversation flows\nto engage with your customers effectively.';
      case 'Quick Replies': return 'Set up quick reply options to respond\nto common customer inquiries instantly.';
      case 'Contacts': return 'Manage your customer contact database and profiles.';
      case 'Lists': return 'Organize contacts into targeted lists for better communication.';
      case 'Tags': return 'Create and assign tags to categorize your contacts efficiently.';
      case 'Smart Segments': return 'Build dynamic customer segments based on behavior and attributes.';
      case 'Import / Export': return 'Import contacts from external sources or export your contact data.';
      case 'Notifications': return 'View and manage all your notification campaigns and alerts.';
      case 'Add New': return 'Create new notification campaigns to engage with your customers.';
      case 'Basic': return 'Set up basic automation rules for common business workflows.';
      case 'Auto-replies': return 'Configure automatic responses for incoming messages and inquiries.';
      case 'Bots': return 'Create intelligent chatbots to handle customer interactions automatically.';
      case 'Drip Sequences': return 'Design automated message sequences to nurture customer relationships.';
      case 'Messaging': return 'Analyze your messaging performance, delivery rates, and engagement metrics.';
      case 'Flow Responses': return 'Track and analyze how customers interact with your automated flows.';
      case 'Bot Sessions': return 'Monitor chatbot conversations and performance analytics.';
      case 'Drip Sessions': return 'Review drip campaign performance and customer engagement data.';
      default: return 'Content management feature';
    }
  }

  Widget _buildDashboardContent() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Custom TabBar
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              border: Border(bottom: BorderSide(color: _ancientGold.withValues(alpha: 0.2))),
            ),
            child: const TabBar(
              indicatorColor: _ancientGold,
              labelColor: _ancientGold,
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 3,
              tabs: [
                Tab(icon: Icon(Icons.apps), text: 'Apps & Socials'),
                Tab(icon: Icon(Icons.analytics), text: 'Analytics & Account'),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              children: [
                // ==========================================
                // PAGE 1: APPS & SOCIALS
                // ==========================================
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _ancientGold)),
                            const SizedBox(height: 8),
                            Text('Manage your ecosystem', style: TextStyle(fontSize: 14, color: _ancientGold.withValues(alpha: 0.8))),
                            const SizedBox(height: 24),

                            // FIRST ROW
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  fit: FlexFit.tight,
                                  child: WaterSplashButton(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HomecontrolScreen())),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 5),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _ancientGold.withValues(alpha: 0.5)),
                                      ),
                                      child: const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FaIcon(FontAwesomeIcons.house, color: _ancientGold, size: 28),
                                          SizedBox(height: 6),
                                          Text('Homecontrol', style: TextStyle(fontSize: 10, color: _ancientGold, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  fit: FlexFit.tight,
                                  child: WaterSplashButton(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VaultScreen())),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 5),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _ancientGold.withValues(alpha: 0.5)),
                                      ),
                                      child: const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FaIcon(FontAwesomeIcons.vault, color: _ancientGold, size: 28),
                                          SizedBox(height: 6),
                                          Text('Vault', style: TextStyle(fontSize: 12, color: _ancientGold, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),  
                              ],
                            ),
                            const SizedBox(height: 20),

                            // SECOND ROW
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  fit: FlexFit.tight,
                                  child: WaterSplashButton(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TrustMeMobileWrapper())),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 5),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _ancientGold.withValues(alpha: 0.5)),
                                      ),
                                      child: const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FaIcon(FontAwesomeIcons.solidHandshake, color: _ancientGold, size: 28),
                                          SizedBox(height: 6),
                                          Text('Trust Me', style: TextStyle(fontSize: 11, color: _ancientGold, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  fit: FlexFit.tight,
                                  child: WaterSplashButton(
                                    onTap: () async {
                                      showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator(color: _ancientGold)));
                                      try {
                                        final userId = Supabase.instance.client.auth.currentUser!.id;
                                        final data = await Supabase.instance.client.from('desktop_devices').select('public_url, status').eq('user_id', userId).single();
                                        if (!mounted) return;
                                        Navigator.pop(context);

                                        if (data['status'] != 'online') {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your desktop is offline.', style: TextStyle(color: Colors.black)), backgroundColor: _ancientGold));
                                          return;
                                        }
                                        String rawUrl = data['public_url'] ?? '';
                                        if (!rawUrl.startsWith('http')) rawUrl = 'https://$rawUrl';
                                        if (rawUrl.isNotEmpty) {
                                          if (!mounted) return;
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => GuptikScreen(tunnelUrl: rawUrl)));
                                        }
                                      } catch (e) {
                                        if (!mounted) return;
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not find desktop device.', style: TextStyle(color: Colors.black)), backgroundColor: _ancientGold));
                                      }
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 5),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _ancientGold.withValues(alpha: 0.5)),
                                      ),
                                      child: const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FaIcon(FontAwesomeIcons.personSnowboarding, color: _ancientGold, size: 28),
                                          SizedBox(height: 6),
                                          Text('GupTik', style: TextStyle(fontSize: 12, color: _ancientGold, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  fit: FlexFit.tight,
                                  child: WaterSplashButton(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MediaPlayerScreen())),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 5),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _ancientGold.withValues(alpha: 0.5)),
                                      ),
                                      child: const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FaIcon(FontAwesomeIcons.youtube, color: _ancientGold, size: 28),
                                          SizedBox(height: 6),
                                          Text('Media Player', style: TextStyle(fontSize: 10, color: _ancientGold, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 40),
                            const Text('Connect with us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _ancientGold)),
                            const SizedBox(height: 8),
                            const Text('social media platforms', style: TextStyle(fontSize: 14, color: _ancientGold), textAlign: TextAlign.center),
                            const SizedBox(height: 24),

                            // fourth ROW
                            Row(
                              children: [
                                Expanded(
                                  child: WaterSplashButton(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Whatsapp())),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _ancientGold.withValues(alpha: 0.5)),
                                      ),
                                      child: const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FaIcon(FontAwesomeIcons.whatsapp, color: _ancientGold, size: 28),
                                          SizedBox(height: 8),
                                          Text('WhatsApp', style: TextStyle(fontSize: 12, color: _ancientGold, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: WaterSplashButton(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FbAndInstaScreen())),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _ancientGold.withValues(alpha: 0.5)),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              FaIcon(FontAwesomeIcons.facebook, color: _ancientGold, size: 28),
                                              SizedBox(height: 8),
                                              Text('Facebook', style: TextStyle(fontSize: 12, color: _ancientGold, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                          SizedBox(height: 30, child: VerticalDivider(color: _ancientGold, thickness: 0.5)),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              FaIcon(FontAwesomeIcons.instagram, color: _ancientGold, size: 28),
                                              SizedBox(height: 8),
                                              Text('Instagram', style: TextStyle(fontSize: 12, color: _ancientGold, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ),
                    ],
                  
                  ),
                ),

                // ==========================================
                // PAGE 2: ANALYTICS & ACCOUNT
                // ==========================================
                AnalyticsAndAccountTab(
                  dashboardData: _dashboardData,
                  isLoading: _isLoading,
                  error: _error,
                  onRefresh: _loadLiveData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherContent() {
    if (_selectedIndex >= 0 && _selectedIndex < _sections.length && _sections[_selectedIndex].title == 'Inbox') {
      return _buildInboxContent();
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_sections[_selectedIndex].icon, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            _sections[_selectedIndex].title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _ancientGold),
          ),
          const SizedBox(height: 8),
          Text('Content coming soon...', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildInboxContent() {
    return InboxContentWidget(conversationsService: _conversationsService);
  }
}

// Inbox Content Widget 
class InboxContentWidget extends StatefulWidget {
  final ConversationsService conversationsService;

  const InboxContentWidget({super.key, required this.conversationsService});

  @override
  State<InboxContentWidget> createState() => _InboxContentWidgetState();
}

class _InboxContentWidgetState extends State<InboxContentWidget> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  List<Conversation> conversations = [];
  List<Message> selectedConversationMessages = [];
  Conversation? selectedConversation;
  bool isLoading = true;
  String selectedFilter = 'All';
  String searchQuery = '';

  final List<String> filters = ['All', 'Active', 'Closed'];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => isLoading = true);

    try {
      String? filterParam = selectedFilter == 'All' ? null : selectedFilter.toLowerCase();
      final loadedConversations = searchQuery.isEmpty
          ? await widget.conversationsService.getConversations(filter: filterParam)
          : await widget.conversationsService.searchConversations(searchQuery);

      setState(() {
        conversations = loadedConversations;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error loading conversations', style: TextStyle(color: Colors.black)), backgroundColor: _ancientGold));
      }
    }
  }

  Future<void> _loadConversationMessages(Conversation conversation) async {
    setState(() {
      selectedConversation = conversation;
      selectedConversationMessages = [];
    });

    try {
      final messages = await widget.conversationsService.getConversationMessages(conversation.id);
      setState(() {
        selectedConversationMessages = messages;
      });

      if (conversation.isUnread) {
        await widget.conversationsService.markAsRead(conversation.id);
        _loadConversations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error loading messages', style: TextStyle(color: Colors.black)), backgroundColor: _ancientGold));
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || selectedConversation == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: selectedConversation!.id,
      content: messageText,
      timestamp: DateTime.now(),
      isFromBusiness: true,
      messageType: MessageType.text,
      status: MessageStatus.sent,
    );

    setState(() {
      selectedConversationMessages.add(newMessage);
    });

    final success = await widget.conversationsService.sendMessage(
      phoneNumber: selectedConversation!.phoneNumber,
      message: messageText,
    );

    if (success) {
      setState(() {
        final index = selectedConversationMessages.indexWhere((m) => m.id == newMessage.id);
        if (index != -1) {
          selectedConversationMessages[index] = Message(
            id: newMessage.id,
            conversationId: newMessage.conversationId,
            content: newMessage.content,
            timestamp: newMessage.timestamp,
            isFromBusiness: newMessage.isFromBusiness,
            messageType: newMessage.messageType,
            status: MessageStatus.delivered,
          );
        }
      });
    } else {
      setState(() {
        final index = selectedConversationMessages.indexWhere((m) => m.id == newMessage.id);
        if (index != -1) {
          selectedConversationMessages[index] = Message(
            id: newMessage.id,
            conversationId: newMessage.conversationId,
            content: newMessage.content,
            timestamp: newMessage.timestamp,
            isFromBusiness: newMessage.isFromBusiness,
            messageType: newMessage.messageType,
            status: MessageStatus.failed,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1024) {
          return Stack(
            children: [
              if (selectedConversation == null || constraints.maxWidth > 600)
                Positioned.fill(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: _ancientGold.withValues(alpha: 0.3))),
                    child: _buildConversationList(),
                  ),
                ),
              if (selectedConversation != null)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: _ancientGold.withValues(alpha: 0.3))),
                    child: _buildConversationView(),
                  ),
                ),
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: _ancientGold.withValues(alpha: 0.3))),
                  child: _buildConversationList(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: _ancientGold.withValues(alpha: 0.3))),
                  child: selectedConversation == null ? _buildSelectConversationState() : _buildConversationView(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConversationList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            border: Border(bottom: BorderSide(color: _ancientGold.withValues(alpha: 0.2))),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text('Conversations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ancientGold), overflow: TextOverflow.ellipsis),
              ),
              IconButton(icon: const Icon(Icons.comment_outlined, color: _ancientGold, size: 18), onPressed: () {}, tooltip: 'New Conversation', padding: const EdgeInsets.all(4), constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
              IconButton(icon: const Icon(Icons.settings, color: _ancientGold, size: 18), onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const BusinessSettingsScreen())); }, tooltip: 'Settings', padding: const EdgeInsets.all(4), constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
              IconButton(icon: const Icon(Icons.refresh, color: _ancientGold, size: 18), onPressed: _loadConversations, tooltip: 'Refresh', padding: const EdgeInsets.all(4), constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: Colors.black),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: _ancientGold),
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: _ancientGold),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (value) {
                    setState(() => searchQuery = value);
                    _loadConversations();
                  },
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: filters.map((filter) => GestureDetector(
                  onTap: () {
                    setState(() => selectedFilter = filter);
                    _loadConversations();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selectedFilter == filter ? _ancientGold : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: selectedFilter == filter ? _ancientGold : Colors.grey[800]!),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: selectedFilter == filter ? Colors.black : Colors.grey[400],
                        fontWeight: selectedFilter == filter ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),

        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: _ancientGold))
              : conversations.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return _buildConversationTile(conversation);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final isSelected = selectedConversation?.id == conversation.id;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? _ancientGold.withValues(alpha: 0.1) : Colors.black,
        border: Border(bottom: BorderSide(color: _ancientGold.withValues(alpha: 0.1))),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _ancientGold,
          child: Text(
            _getInitials(conversation.contactName ?? ''),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation.contactName ?? '',
                style: TextStyle(
                  color: _ancientGold,
                  fontWeight: conversation.isUnread ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatTimestamp(conversation.timestamp),
              style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: conversation.isUnread ? FontWeight.w600 : FontWeight.normal),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                conversation.lastMessage ?? '',
                style: TextStyle(
                  fontSize: 11,
                  color: conversation.isUnread ? _ancientGold : Colors.grey[500],
                  fontWeight: conversation.isUnread ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conversation.isUnread)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: _ancientGold, shape: BoxShape.circle),
                child: const Text('?', style: TextStyle(color: Colors.black, fontSize: 6)),
              ),
          ],
        ),
        onTap: () => _loadConversationMessages(conversation),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[700]),
          const SizedBox(height: 12),
          Text('All conversations loaded.', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildSelectConversationState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_outlined, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 12),
          Text('Select a contact to view conversation.', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildConversationView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            border: Border(bottom: BorderSide(color: _ancientGold.withValues(alpha: 0.2))),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _ancientGold,
                child: Text(
                  _getInitials(selectedConversation!.contactName ?? ''),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedConversation!.contactName ?? '',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ancientGold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      selectedConversation!.phoneNumber,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.more_vert, size: 20, color: _ancientGold), onPressed: () {}),
            ],
          ),
        ),

        Expanded(
          child: selectedConversationMessages.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _ancientGold))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: selectedConversationMessages.length,
                  itemBuilder: (context, index) {
                    final message = selectedConversationMessages[index];
                    return _buildMessageBubble(message);
                  },
                ),
        ),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
            border: Border(top: BorderSide(color: _ancientGold.withValues(alpha: 0.2))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: _ancientGold),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: _ancientGold, shape: BoxShape.circle),
                  child: const Icon(Icons.send, color: Colors.black, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isFromBusiness = message.isFromBusiness;

    return Align(
      alignment: isFromBusiness ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isFromBusiness ? _ancientGold : Colors.grey[900],
          border: Border.all(color: isFromBusiness ? Colors.transparent : _ancientGold.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isFromBusiness ? 12 : 4),
            bottomRight: Radius.circular(isFromBusiness ? 4 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isFromBusiness ? Colors.black : _ancientGold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(
                    color: isFromBusiness ? Colors.black54 : Colors.grey[500],
                    fontSize: 10,
                  ),
                ),
                if (isFromBusiness) ...[
                  const SizedBox(width: 4),
                  Icon(_getStatusIcon(message.status), size: 10, color: Colors.black54),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent: return Icons.check;
      case MessageStatus.delivered: return Icons.done_all;
      case MessageStatus.read: return Icons.done_all;
      case MessageStatus.failed: return Icons.error_outline;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}