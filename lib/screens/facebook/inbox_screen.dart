import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guptik/models/facebook/meta_chat_model.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';
import 'package:guptik/screens/facebook/chat_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/config/app_theme.dart';

class InboxScreen extends StatefulWidget {
  final SocialPlatform platform;

  const InboxScreen({super.key, this.platform = SocialPlatform.facebook});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final MetaService _metaService = MetaService();
  late SocialPlatform _selectedPlatform;
  List<MetaChat> _chats = [];
  bool _isLoading = true;
  String _searchQuery = '';
  RealtimeChannel? _realtimeChannel;
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _selectedPlatform = widget.platform;
    _loadInbox();
    _subscribeToConversationUpdates();
  }

  @override
  void didUpdateWidget(InboxScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.platform != widget.platform) {
      _selectedPlatform = widget.platform;
      _loadInbox();
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _debouncedLoadInbox() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _loadInbox);
  }

  void _subscribeToConversationUpdates() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _realtimeChannel = Supabase.instance.client
        .channel('inbox-updates-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'fb_conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) {
            debugPrint("📝 [FB] New Facebook conversation detected");
            _debouncedLoadInbox();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'fb_conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) {
            debugPrint("🔄 [FB] Facebook conversation updated");
            _debouncedLoadInbox();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'ig_conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) {
            debugPrint("📝 [IG] New Instagram conversation detected");
            _debouncedLoadInbox();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'ig_conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) {
            debugPrint("🔄 [IG] Instagram conversation updated");
            _debouncedLoadInbox();
          },
        )
        .subscribe();
  }

  Future<void> _loadInbox() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final chats = await _metaService.getUnifiedInbox();
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading inbox: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<MetaChat> _filterChats(List<MetaChat> chats) {
    // Filter by selected platform
    List<MetaChat> platformFiltered = chats
        .where((chat) => chat.platform == _selectedPlatform)
        .toList();

    // Then filter by search query
    if (_searchQuery.isEmpty) return platformFiltered;
    return platformFiltered.where((chat) {
      return chat.senderName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          chat.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Compact header to avoid overflow in landscape
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: AppShadows.light,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Messages', style: AppTheme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: AppTheme.textTheme.bodySmall,
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppTheme.facebookBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide(color: AppTheme.lightGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide(color: AppTheme.lightGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide(
                        color: AppTheme.facebookBlue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppTheme.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  style: AppTheme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.facebookBlue,
              onRefresh: _loadInbox,
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.facebookBlue,
                        ),
                      ),
                    )
                  : _filterChats(_chats).isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppTheme.facebookBlue.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline,
                              size: 40,
                              color: AppTheme.facebookBlue.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No messages yet'
                                : 'No conversations found',
                            style: AppTheme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Your messages will appear here'
                                : 'Try a different search term',
                            style: AppTheme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: _filterChats(_chats).length,
                      separatorBuilder: (ctx, i) =>
                          const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (context, index) {
                        final chat = _filterChats(_chats)[index];
                        return _buildChatCard(chat);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(MetaChat chat) {
    final platformColor = chat.platform == SocialPlatform.facebook
        ? AppTheme.facebookBlue
        : AppTheme.instagramPink;
    final platformColors = chat.platform == SocialPlatform.facebook
        ? [AppTheme.facebookBlue, const Color(0xFF0A66C2)]
        : [AppTheme.instagramPink, const Color(0xFFC13584)];

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: chat.isUnread
                ? platformColor.withValues(alpha: 0.3)
                : AppTheme.lightGrey.withValues(alpha: 0.5),
            width: chat.isUnread ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: chat.isUnread
                  ? platformColor.withValues(alpha: 0.15)
                  : AppTheme.mediumGrey.withValues(alpha: 0.08),
              blurRadius: chat.isUnread ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(conversation: chat),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: platformColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: platformColor.withValues(alpha: 0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          chat.senderName.isNotEmpty
                              ? chat.senderName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: platformColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: FaIcon(
                          chat.platform == SocialPlatform.facebook
                              ? FontAwesomeIcons.facebook
                              : FontAwesomeIcons.instagram,
                          size: 14,
                          color: platformColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chat.senderName,
                              style: TextStyle(
                                fontWeight: chat.isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 15,
                                color: AppTheme.dark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Text(
                            chat.time,
                            style: TextStyle(
                              fontSize: 12,
                              color: chat.isUnread
                                  ? platformColor
                                  : AppTheme.mediumGrey,
                              fontWeight: chat.isUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        chat.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: chat.isUnread
                              ? AppTheme.dark.withValues(alpha: 0.7)
                              : AppTheme.mediumGrey,
                          fontSize: 13,
                          fontWeight: chat.isUnread
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (chat.isUnread) ...[
                  const SizedBox(width: AppSpacing.lg),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: platformColors),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: platformColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}