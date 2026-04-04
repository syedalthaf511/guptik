import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guptik/models/facebook/meta_chat_model.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';
import 'package:guptik/screens/facebook/chat_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final MetaService _metaService = MetaService();
  List<MetaChat> _chats = [];
  bool _isLoading = true;
  String _searchQuery = '';
  RealtimeChannel? _realtimeChannel;
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _loadInbox();
    _subscribeToConversationUpdates();
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
    if (_searchQuery.isEmpty) return chats;
    return chats.where((chat) {
      return chat.senderName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          chat.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Compact header to avoid overflow in landscape
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF1877F2),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadInbox,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filterChats(_chats).isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No messages yet'
                                : 'No conversations found',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Your messages will appear here'
                                : 'Try a different search term',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filterChats(_chats).length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
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
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: chat.isUnread ? Colors.transparent : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: chat.isUnread
                  ? (chat.platform == SocialPlatform.facebook
                            ? const Color(0xFF1877F2)
                            : const Color(0xFFE1306C))
                        .withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.08),
              blurRadius: chat.isUnread ? 12 : 8,
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          colors: chat.platform == SocialPlatform.facebook
                              ? [
                                  const Color(0xFF1877F2),
                                  const Color(0xFF0A66C2),
                                ]
                              : [
                                  const Color(0xFFE1306C),
                                  const Color(0xFFC13584),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: chat.platform == SocialPlatform.facebook
                                ? const Color(0xFF1877F2)
                                : const Color(0xFFE1306C),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: FaIcon(
                          chat.platform == SocialPlatform.facebook
                              ? FontAwesomeIcons.facebook
                              : FontAwesomeIcons.instagram,
                          size: 14,
                          color: chat.platform == SocialPlatform.facebook
                              ? const Color(0xFF1877F2)
                              : const Color(0xFFE1306C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
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
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            chat.time,
                            style: TextStyle(
                              fontSize: 13,
                              color: chat.isUnread
                                  ? (chat.platform == SocialPlatform.facebook
                                        ? const Color(0xFF1877F2)
                                        : const Color(0xFFE1306C))
                                  : Colors.grey.shade500,
                              fontWeight: chat.isUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        chat.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: chat.isUnread
                              ? Colors.black54
                              : Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: chat.isUnread
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (chat.isUnread) ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: chat.platform == SocialPlatform.facebook
                            ? [const Color(0xFF1877F2), const Color(0xFF0A66C2)]
                            : [
                                const Color(0xFFE1306C),
                                const Color(0xFFC13584),
                              ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (chat.platform == SocialPlatform.facebook
                                      ? const Color(0xFF1877F2)
                                      : const Color(0xFFE1306C))
                                  .withValues(alpha: 0.3),
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