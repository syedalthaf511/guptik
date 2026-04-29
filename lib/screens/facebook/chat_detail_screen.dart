import 'dart:io';
import 'package:flutter/material.dart';
import 'package:guptik/models/facebook/meta_chat_model.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';
import 'package:guptik/services/facebook/message_storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/config/app_theme.dart';

class ChatDetailScreen extends StatefulWidget {
  final MetaChat conversation;

  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final MetaService _metaService = MetaService();
  final MessageStorageService _storageService = MessageStorageService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToNewMessages();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToNewMessages() {
    final table = widget.conversation.platform == SocialPlatform.facebook
        ? 'fb_messages'
        : 'ig_messages';

    _realtimeChannel = Supabase.instance.client
        .channel('messages-${widget.conversation.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversation.supabaseId,
          ),
          callback: (payload) {
            final newMessage = payload.newRecord;
            final message = {
              'id': newMessage['message_id'],
              'message': newMessage['content'],
              'is_from_me':
                  newMessage['direction'] == 'outgoing' ||
                  newMessage['direction'] == 'ai_outgoing',
              'created_time': newMessage['timestamp'],
              'message_id': newMessage['message_id'],
              'content': newMessage['content'],
              'message_type': newMessage['message_type'],
              'direction': newMessage['direction'],
              'timestamp': newMessage['timestamp'],
              'media_info': newMessage['media_info'],
              'raw_data': newMessage['raw_data'],
            };

            if (!_messages.any(
              (m) => m['message_id'] == message['message_id'],
            )) {
              if (mounted) {
                setState(() {
                  _messages.add(message);
                  _messages.sort((a, b) {
                    final timeA = DateTime.parse(a['created_time']);
                    final timeB = DateTime.parse(b['created_time']);
                    return timeA.compareTo(timeB);
                  });
                });
                _scrollToBottom();
              }
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final storedMessages = await _storageService.getMessages(
        widget.conversation.platform == SocialPlatform.facebook
            ? 'facebook'
            : 'instagram',
        widget.conversation.supabaseId,
      );

      if (storedMessages.isNotEmpty) {
        _messages = storedMessages.map((msg) {
          return {
            'id': msg['message_id'],
            'message': msg['content'],
            'is_from_me':
                msg['direction'] == 'outgoing' ||
                msg['direction'] == 'ai_outgoing',
            'created_time': msg['timestamp'],
            'message_id': msg['message_id'],
            'content': msg['content'],
            'message_type': msg['message_type'],
            'direction': msg['direction'],
            'timestamp': msg['timestamp'],
            'media_info': msg['media_info'],
            'raw_data': msg['raw_data'],
          };
        }).toList();

        _messages.sort((a, b) {
          final timeA = DateTime.parse(a['created_time']);
          final timeB = DateTime.parse(b['created_time']);
          return timeA.compareTo(timeB);
        });

        setState(() => _isLoading = false);
        _scrollToBottom();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading messages: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final messageText = _textController.text.trim();
    _textController.clear();

    final tempMessage = {
      'message': messageText,
      'is_from_me': true,
      'created_time': DateTime.now().toIso8601String(),
      'is_sending': true,
      'message_type': 'text',
    };

    setState(() {
      _isSending = true;
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      bool success;
      if (widget.conversation.platform == SocialPlatform.instagram) {
        success = await _metaService.sendInstagramMessage(
          recipientId: widget.conversation.participantId,
          message: messageText,
        );
      } else {
        success = await _metaService.sendMessage(
          conversationId: widget.conversation.id,
          recipientId: widget.conversation.participantId,
          message: messageText,
        );
      }

      if (success && mounted) {
        setState(() {
          _messages.removeWhere((msg) => msg['is_sending'] == true);
        });
        await _loadMessages();
      } else if (mounted) {
        setState(() {
          _messages.removeWhere((msg) => msg['is_sending'] == true);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                _textController.text = messageText;
                _sendMessage();
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _messages.removeWhere((msg) => msg['is_sending'] == true);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Attachment Handling
  // ---------------------------------------------------------------------------
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose Image from Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (picked != null && mounted) {
                  _showCaptionDialog(File(picked.path), 'image');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (picked != null && mounted) {
                  _showCaptionDialog(File(picked.path), 'image');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Choose Video'),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final picked = await picker.pickVideo(
                  source: ImageSource.gallery,
                );
                if (picked != null && mounted) {
                  _showCaptionDialog(File(picked.path), 'video');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Choose Document'),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.any,
                );
                if (result != null && mounted) {
                  final file = File(result.files.single.path!);
                  _showCaptionDialog(
                    file,
                    'document',
                    fileName: result.files.single.name,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCaptionDialog(
    File file,
    String mediaType, {
    String? fileName,
  }) async {
    final captionController = TextEditingController();
    final platformColor =
        widget.conversation.platform == SocialPlatform.facebook
        ? AppTheme.facebookBlue
        : AppTheme.instagramPink;

    final caption = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Add Caption (Optional)',
          style: AppTheme.textTheme.titleLarge,
        ),
        backgroundColor: AppTheme.surface,
        content: TextField(
          controller: captionController,
          maxLines: 3,
          style: AppTheme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Write a caption...',
            hintStyle: AppTheme.textTheme.bodySmall,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppTheme.lightGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppTheme.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: platformColor, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.background,
            contentPadding: const EdgeInsets.all(AppSpacing.md),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Skip', style: TextStyle(color: AppTheme.mediumGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, captionController.text),
            style: ElevatedButton.styleFrom(backgroundColor: platformColor),
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (mounted && caption != null) {
      _sendMediaMessage(
        file,
        mediaType,
        caption.isNotEmpty ? caption : null,
        fileName: fileName,
      );
    }
  }

  Future<void> _sendMediaMessage(
    File mediaFile,
    String mediaType,
    String? caption, {
    String? fileName,
  }) async {
    // Optimistic UI
    final tempMessage = {
      'message': mediaType == 'image'
          ? '📸 Sending image...'
          : (mediaType == 'video'
                ? '🎥 Sending video...'
                : '📄 Sending document...'),
      'is_from_me': true,
      'created_time': DateTime.now().toIso8601String(),
      'is_sending': true,
      'message_type': mediaType,
      'caption': caption,
    };
    setState(() {
      _messages.add(tempMessage);
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final success = await _metaService.sendMediaMessage(
        platform: widget.conversation.platform,
        recipientId: widget.conversation.participantId,
        mediaFile: mediaFile,
        conversationId: widget.conversation.supabaseId,
        mediaType: mediaType,
        caption: caption,
        fileName: fileName,
        // mimeType can be auto-detected by upload service; not required here
      );

      if (success && mounted) {
        setState(() {
          _messages.removeWhere((msg) => msg['is_sending'] == true);
        });
        await _loadMessages();
      } else if (mounted) {
        setState(() {
          _messages.removeWhere((msg) => msg['is_sending'] == true);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send $mediaType')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((msg) => msg['is_sending'] == true);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = widget.conversation.platform;
    final platformColor = platform == SocialPlatform.facebook
        ? AppTheme.facebookBlue
        : AppTheme.instagramPink;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [platformColor, platformColor.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  widget.conversation.senderName.isNotEmpty
                      ? widget.conversation.senderName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.senderName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      platform == SocialPlatform.facebook
                          ? 'Facebook'
                          : 'Instagram',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: platformColor,
        foregroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(platformColor),
                    ),
                  )
                : RefreshIndicator(
                    color: platformColor,
                    onRefresh: _loadMessages,
                    child: _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: platformColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline,
                                    size: 40,
                                    color: platformColor.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  'No messages yet',
                                  style: AppTheme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'Send a message to start the conversation',
                                  style: AppTheme.textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isSending = msg['is_sending'] == true;
                              return _buildMessageBubble(
                                msg,
                                isSending,
                                platformColor,
                              );
                            },
                          ),
                  ),
          ),
          _buildMessageInput(platformColor),
        ],
      ),
    );
  }

  Widget _buildMessageInput(Color platformColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: platformColor),
            onPressed: _isSending ? null : _showAttachmentOptions,
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: !_isSending,
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: AppTheme.textTheme.bodySmall,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              style: AppTheme.textTheme.bodyMedium,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [platformColor, platformColor.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: platformColor.withValues(alpha: 0.3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> msg,
    bool isSending,
    Color platformColor,
  ) {
    final isMe = msg['is_from_me'] ?? false;
    final messageType = msg['message_type'] ?? 'text';
    final content = msg['message'] ?? '';
    final caption = msg['caption'];
    final mediaInfo = msg['media_info'] ?? {};

    Widget contentWidget;
    if (messageType == 'image') {
      contentWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Image.network(
              content,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 200,
                height: 200,
                color: AppTheme.lightGrey,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
          if (caption != null && caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                caption,
                style: TextStyle(
                  fontSize: 12,
                  color: isMe ? Colors.white70 : AppTheme.dark,
                ),
              ),
            ),
        ],
      );
    } else if (messageType == 'video') {
      contentWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.dark,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_filled,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          if (caption != null && caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                caption,
                style: TextStyle(
                  fontSize: 12,
                  color: isMe ? Colors.white70 : AppTheme.dark,
                ),
              ),
            ),
        ],
      );
    } else if (messageType == 'document') {
      final fileName = mediaInfo['filename'] ?? 'Document';
      contentWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 200,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: platformColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: platformColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.insert_drive_file, color: platformColor),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppTheme.dark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (caption != null && caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                caption,
                style: TextStyle(
                  fontSize: 12,
                  color: isMe ? Colors.white70 : AppTheme.dark,
                ),
              ),
            ),
        ],
      );
    } else {
      contentWidget = Text(
        content,
        style: TextStyle(
          color: isMe ? Colors.white : AppTheme.dark,
          fontSize: 14,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [platformColor, platformColor.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  (msg['sender_name'] as String?)?.isNotEmpty == true
                      ? (msg['sender_name'] as String)[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (!isMe) const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isMe ? platformColor : AppTheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl).copyWith(
                  bottomRight: isMe
                      ? const Radius.circular(AppRadius.sm)
                      : const Radius.circular(AppRadius.xl),
                  bottomLeft: isMe
                      ? const Radius.circular(AppRadius.xl)
                      : const Radius.circular(AppRadius.sm),
                ),
                boxShadow: [
                  BoxShadow(
                    color: platformColor.withValues(alpha: isMe ? 0.2 : 0.05),
                    blurRadius: isMe ? 4 : 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  contentWidget,
                  if (isSending)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sending',
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe
                                  ? Colors.white70
                                  : AppTheme.mediumGrey,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isMe ? Colors.white70 : AppTheme.mediumGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: AppSpacing.md),
          if (isMe)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.mediumGrey.withValues(alpha: 0.3),
              ),
              child: const Icon(Icons.person, size: 14, color: Colors.white),
            ),
        ],
      ),
    );
  }
}