import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guptik/widgets/home/animated_nebula_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;


// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const String kMetaAppId = '1647936262889799';
const String kGraphVersion = 'v19.0';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL: MetaStory
// ─────────────────────────────────────────────────────────────────────────────
class MetaStory {
  final String id;
  final String mediaType;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String timestamp;
  final int views;
  final int replies;
  final int exits;
  final int impressions;

  MetaStory({
    required this.id,
    required this.mediaType,
    this.mediaUrl,
    this.thumbnailUrl,
    required this.timestamp,
    required this.views,
    required this.replies,
    required this.exits,
    required this.impressions,
  });

  factory MetaStory.fromJson(Map<String, dynamic> json) {
    return MetaStory(
      id: json['id'] ?? '',
      mediaType: json['media_type'] ?? 'IMAGE',
      mediaUrl: json['media_url'],
      thumbnailUrl: json['thumbnail_url'],
      timestamp: json['timestamp'] ?? '',
      views:
          (json['video_views'] as num?)?.toInt() ??
          (json['impressions'] as num?)?.toInt() ??
          0,
      replies: (json['replies'] as num?)?.toInt() ?? 0,
      exits: (json['exits'] as num?)?.toInt() ?? 0,
      impressions: (json['impressions'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL: MetaReel
// ─────────────────────────────────────────────────────────────────────────────
class MetaReel {
  final String id;
  final String? caption;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String timestamp;
  final int plays;
  final int likes;
  final int comments;
  final int shares;
  final int saved;
  final int reach;

  MetaReel({
    required this.id,
    this.caption,
    this.mediaUrl,
    this.thumbnailUrl,
    required this.timestamp,
    required this.plays,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.saved,
    required this.reach,
  });

  int get totalEngagement => likes + comments + shares + saved;

  factory MetaReel.fromJson(Map<String, dynamic> json) {
    return MetaReel(
      id: json['id'] ?? '',
      caption: json['caption'],
      mediaUrl: json['media_url'],
      thumbnailUrl: json['thumbnail_url'],
      timestamp: json['timestamp'] ?? '',
      plays:
          (json['plays'] as num?)?.toInt() ??
          (json['video_views'] as num?)?.toInt() ??
          0,
      likes: (json['like_count'] as num?)?.toInt() ?? 0,
      comments: (json['comments_count'] as num?)?.toInt() ?? 0,
      shares: (json['shares'] as num?)?.toInt() ?? 0,
      saved: (json['saved'] as num?)?.toInt() ?? 0,
      reach: (json['reach'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENUM: SocialPlatform
// ─────────────────────────────────────────────────────────────────────────────
enum SocialPlatform { facebook, instagram }

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class FacebookAndInstagramScreen extends StatefulWidget {
  const FacebookAndInstagramScreen({super.key});

  @override
  State<FacebookAndInstagramScreen> createState() =>
      _FacebookAndInstagramScreenState();
}

class _FacebookAndInstagramScreenState
    extends State<FacebookAndInstagramScreen> {
  // ── Saved accounts list (shown in the card) ────────────────────────────────
  final List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = false;

  // ── Data fetched during the login flow ────────────────────────────────────
  String? _userToken;
  String? _fbAccountId;
  String? _fbName;

  // Selected Page & Instagram
  String? _selectedPageToken;
  String? _selectedPageId;
  String? _selectedPageName;
  String? _selectedIgAccountId;

  // Selected Business
  String? _selectedBusinessId;
  String? _selectedBusinessName;

  // WhatsApp
  String? _whatsappPhoneNumberId;
  String? _whatsappPhoneNumber;
  String? _selectedWabaId;

  // Raw lists for picker dropdowns
  List<Map<String, dynamic>> _pages = [];
  List<Map<String, dynamic>> _businesses = [];
  List<Map<String, dynamic>> _wabaPhoneNumbers = [];

  @override
  void initState() {
    super.initState();
    _loadSavedKeys();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. LOAD SAVED SETTINGS FROM SUPABASE
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _loadSavedKeys() async {
    try {
      setState(() => _isLoading = true);
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('user_api_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (mounted && response != null) {
        final hasData =
            response['facebook_user_access_token'] != null ||
            response['facebook_account_id'] != null;

        if (hasData) {
          setState(() {
            _accounts.clear();
            _accounts.add({
              'id': response['id'],
              'facebook_token': response['facebook_user_access_token'],
              'facebook_account_id': response['facebook_account_id'],
              'page_token': response['facebook_page_access_token'],
              'instagram_account_id': response['instagram_account_id'],
              'business_id': response['meta_business_account_id'],
              'business_name': response['meta_business_name'],
              'wa_phone_number_id': response['meta_wa_phone_number_id'],
              'mobile_number': response['mobile_number'],
            });
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved keys: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. SAVE ALL SETTINGS TO SUPABASE
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _saveSettingsToSupabase() async {
    if (_userToken == null) {
      _showSnack('Please connect your Facebook account first.', isError: true);
      return;
    }

    try {
      Navigator.pop(context);
      setState(() => _isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // NOTE: instagram_access_token uses the Page Access Token — this is
      // correct per Meta docs. Instagram Business Graph API authenticates
      // via the linked Page token, not a separate Instagram token.
      final data = {
        'user_id': user.id,
        'meta_app_id': kMetaAppId,

        // Facebook User
        'facebook_user_access_token': _userToken,
        'facebook_account_id': _fbAccountId,

        // Facebook Page
        'facebook_page_access_token': _selectedPageToken,

        // Instagram (uses Page token — correct per Meta docs)
        'instagram_access_token': _selectedPageToken,
        'instagram_account_id': _selectedIgAccountId,

        // Meta Business
        'meta_business_account_id': _selectedBusinessId,
        'meta_business_name': _selectedBusinessName,

        // WhatsApp
        'whatsapp_access_token': _userToken,
        'meta_wa_phone_number_id': _whatsappPhoneNumberId,
        'mobile_number': _whatsappPhoneNumber,
      };

      final response = await Supabase.instance.client
          .from('user_api_settings')
          .upsert(data, onConflict: 'user_id')
          .select()
          .single();

      setState(() {
        _accounts.clear();
        _accounts.add({
          'id': response['id'],
          'facebook_token': response['facebook_user_access_token'],
          'facebook_account_id': response['facebook_account_id'],
          'page_token': response['facebook_page_access_token'],
          'instagram_account_id': response['instagram_account_id'],
          'business_id': response['meta_business_account_id'],
          'business_name': response['meta_business_name'],
          'wa_phone_number_id': response['meta_wa_phone_number_id'],
          'mobile_number': response['mobile_number'],
        });
      });

      if (mounted) {
        _showSnack('✅ All accounts saved successfully!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error saving: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. CLEAR SETTINGS FROM SUPABASE
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _clearSocialSettings(int index) async {
    try {
      final accountId = _accounts[index]['id'];
      if (accountId == null) return;

      setState(() => _isLoading = true);

      await Supabase.instance.client
          .from('user_api_settings')
          .update({
            'facebook_user_access_token': null,
            'facebook_account_id': null,
            'facebook_page_access_token': null,
            'instagram_access_token': null,
            'instagram_account_id': null,
            'meta_business_account_id': null,
            'meta_business_name': null,
            'whatsapp_access_token': null,
            'meta_wa_phone_number_id': null,
            'mobile_number': null,
            'meta_app_id': null,
          })
          .eq('id', accountId);

      if (!mounted) return;
      setState(() {
        _accounts.clear();
        _userToken = null;
        _fbAccountId = null;
        _fbName = null;
        _selectedPageToken = null;
        _selectedPageId = null;
        _selectedPageName = null;
        _selectedIgAccountId = null;
        _selectedBusinessId = null;
        _selectedBusinessName = null;
        _whatsappPhoneNumberId = null;
        _whatsappPhoneNumber = null;
        _selectedWabaId = null;
        _pages = [];
        _businesses = [];
        _wabaPhoneNumbers = [];
      });

      _showSnack('Account disconnected.', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error removing: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. FACEBOOK LOGIN (nativeWithFallback = works on mobile)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _handleFacebookLogin() async {
    try {
      setState(() => _isLoading = true);

      // ✅ nativeWithFallback: tries native FB app, falls back to Chrome tab.
      final LoginResult result = await FacebookAuth.instance.login(
        loginBehavior: LoginBehavior.nativeWithFallback,
        permissions: [
          'email',
          'public_profile',
          'pages_show_list',
          'instagram_basic',
          'pages_read_engagement',
          'business_management',
          'instagram_branded_content_brand',
          'instagram_branded_content_creator',
          'instagram_content_publish',
          'instagram_manage_comments',
          'instagram_manage_insights',
          'instagram_manage_messages',
          'manage_fundraisers',
          'pages_manage_engagement',
          'pages_manage_metadata',
          'pages_manage_posts',
          'pages_messaging',
          'pages_read_user_content',
          'pages_utility_messaging',
          'paid_marketing_messages',
          'publish_video',
          'read_insights',
          'whatsapp_business_manage_events',
          'whatsapp_business_management',
          'whatsapp_business_messaging',
          'catalog_management',
          'instagram_manage_upcoming_events',
          'manage_app_solution',
          'instagram_manage_contents',
          'instagram_creator_marketplace_discovery',
          'instagram_branded_content_ads_brand',
        ],
      );

      if (result.status == LoginStatus.cancelled) {
        debugPrint('User cancelled login.');
        return;
      }

      if (result.status != LoginStatus.success) {
        _showSnack('Login failed: ${result.message}', isError: true);
        return;
      }

      final userToken = result.accessToken!.tokenString;
      final userData = await FacebookAuth.instance.getUserData();

      setState(() {
        _userToken = userToken;
        _fbAccountId = userData['id'];
        _fbName = userData['name'];
      });

      // Fetch all Graph API data sequentially
      await _fetchPagesAndInstagram(userToken);
      await _fetchBusinesses(userToken);

      if (_businesses.isNotEmpty) {
        await _fetchWhatsAppNumbers(userToken, _businesses.first['id']);
      }

      if (mounted) {
        _showSnack(
          '✅ Connected as $_fbName! Review selections and tap Save.',
          isError: false,
        );
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GRAPH API 1: /me/accounts → Pages + linked Instagram accounts
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _fetchPagesAndInstagram(String userToken) async {
    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$kGraphVersion/me/accounts'
        '?fields=id,name,access_token,instagram_business_account'
        '&access_token=$userToken',
      );
      final res = await http.get(url);
      if (res.statusCode != 200) {
        debugPrint('Pages API error: ${res.body}');
        return;
      }

      final data = jsonDecode(res.body);
      final List pages = data['data'] ?? [];

      setState(() {
        _pages = pages
            .map<Map<String, dynamic>>(
              (p) => {
                'id': p['id'],
                'name': p['name'],
                'access_token': p['access_token'],
                'instagram_business_account':
                    p['instagram_business_account']?['id'],
              },
            )
            .toList();

        // Auto-select first page that has Instagram; fallback to first page
        final pageWithIg = _pages.firstWhere(
          (p) => p['instagram_business_account'] != null,
          orElse: () => _pages.isNotEmpty ? _pages.first : {},
        );

        if (pageWithIg.isNotEmpty) {
          _selectedPageToken = pageWithIg['access_token'];
          _selectedPageId = pageWithIg['id'];
          _selectedPageName = pageWithIg['name'];
          _selectedIgAccountId = pageWithIg['instagram_business_account'];
        }
      });

      debugPrint('✅ Pages fetched: ${_pages.length}');
    } catch (e) {
      debugPrint('Error fetching pages: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GRAPH API 2: /me/businesses → Meta Business accounts
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _fetchBusinesses(String userToken) async {
    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$kGraphVersion/me/businesses'
        '?fields=id,name'
        '&access_token=$userToken',
      );
      final res = await http.get(url);
      if (res.statusCode != 200) {
        debugPrint('Businesses API error: ${res.body}');
        return;
      }

      final data = jsonDecode(res.body);
      final List biz = data['data'] ?? [];

      setState(() {
        _businesses = biz
            .map<Map<String, dynamic>>(
              (b) => {'id': b['id'], 'name': b['name']},
            )
            .toList();

        if (_businesses.isNotEmpty) {
          _selectedBusinessId = _businesses.first['id'];
          _selectedBusinessName = _businesses.first['name'];
        }
      });

      debugPrint('✅ Businesses fetched: ${_businesses.length}');
    } catch (e) {
      debugPrint('Error fetching businesses: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GRAPH API 3+4: WABA → Phone Numbers
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _fetchWhatsAppNumbers(
    String userToken,
    String businessId,
  ) async {
    try {
      // Step A: Get WhatsApp Business Accounts under this Business
      final wabaUrl = Uri.parse(
        'https://graph.facebook.com/$kGraphVersion/$businessId'
        '/owned_whatsapp_business_accounts'
        '?fields=id,name'
        '&access_token=$userToken',
      );
      final wabaRes = await http.get(wabaUrl);
      if (wabaRes.statusCode != 200) {
        debugPrint('WABA API error: ${wabaRes.body}');
        return;
      }

      final wabaData = jsonDecode(wabaRes.body);
      final List wabas = wabaData['data'] ?? [];
      if (wabas.isEmpty) {
        debugPrint('No WABA found for business $businessId');
        return;
      }

      final wabaId = wabas.first['id'];
      setState(() => _selectedWabaId = wabaId);

      // Step B: Get Phone Numbers under this WABA
      final phoneUrl = Uri.parse(
        'https://graph.facebook.com/$kGraphVersion/$wabaId/phone_numbers'
        '?fields=id,display_phone_number,verified_name'
        '&access_token=$userToken',
      );
      final phoneRes = await http.get(phoneUrl);
      if (phoneRes.statusCode != 200) {
        debugPrint('Phone Numbers API error: ${phoneRes.body}');
        return;
      }

      final phoneData = jsonDecode(phoneRes.body);
      final List phones = phoneData['data'] ?? [];

      setState(() {
        _wabaPhoneNumbers = phones
            .map<Map<String, dynamic>>(
              (p) => {
                'id': p['id'],
                'display_phone_number': p['display_phone_number'],
                'verified_name': p['verified_name'],
              },
            )
            .toList();

        if (_wabaPhoneNumbers.isNotEmpty) {
          _whatsappPhoneNumberId = _wabaPhoneNumbers.first['id'];
          _whatsappPhoneNumber =
              _wabaPhoneNumbers.first['display_phone_number'];
        }
      });

      debugPrint(
        '✅ WhatsApp phone numbers fetched: ${_wabaPhoneNumbers.length}',
      );
    } catch (e) {
      debugPrint('Error fetching WhatsApp numbers: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STORIES & REELS: Fetch from Instagram Graph API
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<MetaStory>> getStories(SocialPlatform platform) async {
    try {
      final pageToken = _selectedPageToken;
      final igAccountId = _selectedIgAccountId;

      if (pageToken == null || igAccountId == null) return [];

      final url = Uri.parse(
        'https://graph.facebook.com/$kGraphVersion/$igAccountId/stories'
        '?fields=id,media_type,media_url,thumbnail_url,timestamp'
        '&access_token=$pageToken',
      );
      final res = await http.get(url);
      if (res.statusCode != 200) {
        debugPrint('Stories API error: ${res.body}');
        return [];
      }

      final data = jsonDecode(res.body);
      final List items = data['data'] ?? [];
      return items.map((s) => MetaStory.fromJson(s)).toList();
    } catch (e) {
      debugPrint('Error fetching stories: $e');
      return [];
    }
  }

  Future<List<MetaReel>> getReels(SocialPlatform platform) async {
    try {
      final pageToken = _selectedPageToken;
      final igAccountId = _selectedIgAccountId;

      if (pageToken == null || igAccountId == null) return [];

      final url = Uri.parse(
        'https://graph.facebook.com/$kGraphVersion/$igAccountId/media'
        '?fields=id,caption,media_type,media_url,thumbnail_url,timestamp,'
        'like_count,comments_count'
        '&access_token=$pageToken',
      );
      final res = await http.get(url);
      if (res.statusCode != 200) {
        debugPrint('Reels API error: ${res.body}');
        return [];
      }

      final data = jsonDecode(res.body);
      final List items = data['data'] ?? [];
      // Filter only VIDEO type (Reels)
      return items
          .where((m) => m['media_type'] == 'VIDEO')
          .map((r) => MetaReel.fromJson(r))
          .toList();
    } catch (e) {
      debugPrint('Error fetching reels: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STORIES & REELS SUMMARY
  // ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getStoriesReelsSummary(
    SocialPlatform platform,
  ) async {
    try {
      final List<MetaStory> stories = await getStories(platform);
      final List<MetaReel> reels = await getReels(platform);

      final totalStoryViews = stories.fold<int>(0, (sum, s) => sum + s.views);
      final totalStoryReplies = stories.fold<int>(
        0,
        (sum, s) => sum + s.replies,
      );
      final totalReelViews = reels.fold<int>(0, (sum, r) => sum + r.plays);
      final totalReelEngagement = reels.fold<int>(
        0,
        (sum, r) => sum + r.totalEngagement,
      );

      return {
        'stories': stories,
        'reels': reels,
        'totalStories': stories.length,
        'totalReels': reels.length,
        'totalStoryViews': totalStoryViews,
        'totalStoryReplies': totalStoryReplies,
        'totalReelViews': totalReelViews,
        'totalReelEngagement': totalReelEngagement,
        'averageStoryViews': stories.isNotEmpty
            ? totalStoryViews ~/ stories.length
            : 0,
        'averageReelViews': reels.isNotEmpty
            ? totalReelViews ~/ reels.length
            : 0,
      };
    } catch (e) {
      debugPrint('Error fetching stories/reels summary: $e');
      return {
        'stories': <MetaStory>[],
        'reels': <MetaReel>[],
        'totalStories': 0,
        'totalReels': 0,
        'totalStoryViews': 0,
        'totalStoryReplies': 0,
        'totalReelViews': 0,
        'totalReelEngagement': 0,
        'averageStoryViews': 0,
        'averageReelViews': 0,
      };
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  void _showSnack(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: isError ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? Colors.redAccent : _ancientGold,
      ),
    );
  }

  String _maskToken(String? token) {
    if (token == null || token.isEmpty) return 'Not Set';
    if (token.length <= 8) return '****';
    return '••••••••${token.substring(token.length - 6)}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DIALOG — Login + selection dropdowns
  // ─────────────────────────────────────────────────────────────────────────
  void _showConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: _ancientGold, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Connect Meta Suite', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Login Button ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _handleFacebookLogin();
                      setDialogState(() {});
                    },
                    icon: const Icon(Icons.facebook, color: Colors.white),
                    label: Text(
                      _userToken == null
                          ? 'Login with Facebook'
                          : 'Re-Login  (${_fbName ?? ''})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),

                if (_isLoading) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(color: _ancientGold),
                  const SizedBox(height: 8),
                  const Text('Fetching your Meta data…', style: TextStyle(color: Colors.white70)),
                ],

                // ── Page Selector ─────────────────────────────────────────
                if (_pages.length > 1) ...[
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Facebook Page:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _ancientGold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: Colors.black,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: _ancientGold),
                      style: const TextStyle(color: Colors.white),
                      value: _selectedPageId,
                      items: _pages.map((p) {
                        final hasIg = p['instagram_business_account'] != null;
                        return DropdownMenuItem<String>(
                          value: p['id'],
                          child: Text(
                            '${p['name']}  ${hasIg ? '✅ IG' : '❌ IG'}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          final page = _pages.firstWhere((p) => p['id'] == val);
                          _selectedPageId = page['id'];
                          _selectedPageName = page['name'];
                          _selectedPageToken = page['access_token'];
                          _selectedIgAccountId =
                              page['instagram_business_account'];
                        });
                      },
                    ),
                  ),
                ],

                // ── Business Selector ──────────────────────────────────────
                if (_businesses.length > 1) ...[
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Business Account:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _ancientGold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: Colors.black,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: _ancientGold),
                      style: const TextStyle(color: Colors.white),
                      value: _selectedBusinessId,
                      items: _businesses.map((b) {
                        return DropdownMenuItem<String>(
                          value: b['id'],
                          child: Text(b['name'], overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        setDialogState(() => _selectedBusinessId = val);
                        if (_userToken != null && val != null) {
                          await _fetchWhatsAppNumbers(_userToken!, val);
                          setDialogState(() {});
                        }
                      },
                    ),
                  ),
                ],

                // ── WhatsApp Phone Selector ────────────────────────────────
                if (_wabaPhoneNumbers.length > 1) ...[
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select WhatsApp Number:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _ancientGold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: Colors.black,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: _ancientGold),
                      style: const TextStyle(color: Colors.white),
                      value: _whatsappPhoneNumberId,
                      items: _wabaPhoneNumbers.map((p) {
                        return DropdownMenuItem<String>(
                          value: p['id'],
                          child: Text(p['display_phone_number']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          final phone = _wabaPhoneNumbers.firstWhere(
                            (p) => p['id'] == val,
                          );
                          _whatsappPhoneNumberId = phone['id'];
                          _whatsappPhoneNumber = phone['display_phone_number'];
                        });
                      },
                    ),
                  ),
                ],

                // ── Summary ────────────────────────────────────────────────
                if (_userToken != null) ...[
                  const SizedBox(height: 16),
                  Divider(color: _ancientGold.withValues(alpha: 0.2)),
                  _summaryRow('FB User', _fbName ?? '—'),
                  _summaryRow('Page', _selectedPageName ?? '—'),
                  _summaryRow('IG Account ID', _selectedIgAccountId ?? 'None'),
                  _summaryRow('Business', _selectedBusinessName ?? '—'),
                  _summaryRow('WA Number', _whatsappPhoneNumber ?? 'None'),
                ],

                const SizedBox(height: 16),
                const Text(
                  '⚠️ App Secret is NEVER stored here — keep it in your '
                  'n8n/backend env only.',
                  style: TextStyle(fontSize: 11, color: Colors.orangeAccent),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: _userToken != null ? _saveSettingsToSupabase : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ancientGold,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey[800],
                disabledForegroundColor: Colors.grey[500],
              ),
              child: const Text('Save All to Database', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Social Media Settings',
          style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        iconTheme: const IconThemeData(color: _ancientGold),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _ancientGold.withValues(alpha: 0.2), height: 1.0),
        ),
        actions: [
          if (_accounts.isEmpty)
            IconButton(
              icon: const Icon(Icons.add, color: _ancientGold),
              onPressed: _showConfigDialog,
            ),
        ],
      ),
      // THE FIX: Full screen container to prevent background cutting off
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // The Shared Cinematic Nebula Background
            const Positioned.fill(child: AnimatedNebulaBackground()),
            
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: _ancientGold))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Facebook & Instagram',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _ancientGold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage your Meta Business, Pages, WhatsApp & Instagram accounts from a single source.',
                          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 30),
                        if (_accounts.isEmpty)
                          _buildEmptyState()
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _accounts.length,
                            itemBuilder: (context, index) =>
                                _buildAccountCard(_accounts[index], index),
                          ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.4),
                border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 2),
              ),
              child: Icon(Icons.link_off, size: 64, color: _ancientGold.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 24),
            Text(
              'No social accounts connected.',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showConfigDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ancientGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Connect Accounts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACCOUNT CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAccountCard(Map<String, dynamic> account, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Active Configuration',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _ancientGold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: _showConfigDialog,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: _ancientGold, width: 1.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text('Disconnect Accounts?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            content: const Text('Are you sure you want to disconnect your Meta accounts?', style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.black),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _clearSocialSettings(index);
                                },
                                child: const Text('Disconnect', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            Divider(color: _ancientGold.withValues(alpha: 0.2), height: 20),

            if (account['facebook_token'] != null) ...[
              _sectionHeader('Facebook User', Colors.blueAccent),
              _buildInfoRow(
                'Account ID',
                account['facebook_account_id'] ?? '—',
              ),
              _buildInfoRow('Token', _maskToken(account['facebook_token'])),
              const SizedBox(height: 16),
            ],

            if (account['page_token'] != null) ...[
              _sectionHeader('Facebook Page', Colors.orangeAccent),
              _buildInfoRow('Page Token', _maskToken(account['page_token'])),
              const SizedBox(height: 16),
            ],

            if (account['instagram_account_id'] != null) ...[
              _sectionHeader('Instagram', Colors.pinkAccent),
              _buildInfoRow('IG Account ID', account['instagram_account_id']),
              const SizedBox(height: 16),
            ],

            if (account['business_id'] != null) ...[
              _sectionHeader('Meta Business', Colors.lightBlueAccent),
              _buildInfoRow('Business ID', account['business_id']),
              _buildInfoRow('Business Name', account['business_name'] ?? '—'),
              const SizedBox(height: 16),
            ],

            if (account['wa_phone_number_id'] != null) ...[
              _sectionHeader('WhatsApp', Colors.greenAccent),
              _buildInfoRow('Phone Number ID', account['wa_phone_number_id']),
              _buildInfoRow('Number', account['mobile_number'] ?? '—'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.stop_circle, size: 12, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
            ),
          ),
          if (value != '—' && value != 'Not Set')
            SizedBox(
              width: 32,
              height: 24,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.copy, size: 16, color: _ancientGold),
                tooltip: 'Copy to clipboard',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      backgroundColor: _ancientGold,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}