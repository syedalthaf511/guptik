import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/models/mediaplyer/player_comment_model.dart';
import 'package:guptik/services/mediaplayer/mobile_bridge_service.dart';

/// MobileCommentWidget — mobile counterpart to desktop's PlayerCommentWidget.
/// A single comment tile with nested replies, reactions (like/heart/clap/
/// laugh/disagree), edit/delete (own comments only), and report (others'
/// comments). Designed to be used inside a scrollable comment bottom sheet.
class MobileCommentWidget extends StatefulWidget {
  final PlayerComment comment;
  final MobileBridgeService bridge;
  final String videoId;
  final String videoCreatorUid;
  final VoidCallback? onCommentChanged;

  const MobileCommentWidget({
    Key? key,
    required this.comment,
    required this.bridge,
    required this.videoId,
    required this.videoCreatorUid,
    this.onCommentChanged,
  }) : super(key: key);

  @override
  State<MobileCommentWidget> createState() => _MobileCommentWidgetState();
}

class _MobileCommentWidgetState extends State<MobileCommentWidget> {
  bool _showReplies = false;
  bool _showReplyInput = false;
  bool _showReactionPicker = false;
  bool _isEditing = false;
  late PlayerComment _comment;
  late TextEditingController _replyController;
  late TextEditingController _editController;
  String? _currentViewerReaction;

  @override
  void initState() {
    super.initState();
    _comment = widget.comment;
    _replyController = TextEditingController();
    _editController = TextEditingController(text: _comment.commentText);
    _currentViewerReaction = _comment.viewerReaction;
  }

  @override
  void dispose() {
    _replyController.dispose();
    _editController.dispose();
    super.dispose();
  }

  String _getTimeAgo(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'recently';
    try {
      final date = DateTime.parse(dateString);
      final difference = DateTime.now().difference(date);
      if (difference.inDays > 0) return '${difference.inDays}d ago';
      if (difference.inHours > 0) return '${difference.inHours}h ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
      return 'just now';
    } catch (_) {
      return 'recently';
    }
  }

  Future<void> _handleReaction(String reactionType) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final result = await widget.bridge.toggleCommentReaction(
      commentId: _comment.commentId,
      reactorUid: currentUser.id,
      reactionType: reactionType,
    );

    if (mounted) {
      setState(() {
        if (_currentViewerReaction != null) {
          _decrementReaction(_currentViewerReaction!);
        }
        if (result != null) {
          _incrementReaction(result);
        }
        _currentViewerReaction = result;
        _showReactionPicker = false;
      });
      widget.onCommentChanged?.call();
    }
  }

  void _incrementReaction(String type) {
    switch (type) {
      case 'like':
        _comment = _comment.copyWith(likesCount: _comment.likesCount + 1);
        break;
      case 'heart':
        _comment = _comment.copyWith(heartCount: _comment.heartCount + 1);
        break;
      case 'clap':
        _comment = _comment.copyWith(clapCount: _comment.clapCount + 1);
        break;
      case 'laugh':
        _comment = _comment.copyWith(laughCount: _comment.laughCount + 1);
        break;
      case 'disagree':
        _comment = _comment.copyWith(disagreeCount: _comment.disagreeCount + 1);
        break;
    }
  }

  void _decrementReaction(String type) {
    switch (type) {
      case 'like':
        _comment = _comment.copyWith(likesCount: (_comment.likesCount - 1).clamp(0, 999999));
        break;
      case 'heart':
        _comment = _comment.copyWith(heartCount: (_comment.heartCount - 1).clamp(0, 999999));
        break;
      case 'clap':
        _comment = _comment.copyWith(clapCount: (_comment.clapCount - 1).clamp(0, 999999));
        break;
      case 'laugh':
        _comment = _comment.copyWith(laughCount: (_comment.laughCount - 1).clamp(0, 999999));
        break;
      case 'disagree':
        _comment = _comment.copyWith(disagreeCount: (_comment.disagreeCount - 1).clamp(0, 999999));
        break;
    }
  }

  Future<void> _postReply() async {
    if (_replyController.text.trim().isEmpty) return;
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    // Same fallback chain as the top-level comment box, so replies show the
    // real username consistently too (matches the earlier top-level fix).
    final viewerName = currentUser.userMetadata?['channel_name'] ??
        currentUser.userMetadata?['username'] ??
        currentUser.email?.split('@')[0] ??
        'Creator';

    final success = await widget.bridge.postComment(
      widget.videoId,
      widget.videoCreatorUid,
      _replyController.text.trim(),
      parentCommentId: _comment.commentId,
      viewerName: viewerName,
    );

    if (success && mounted) {
      _replyController.clear();
      setState(() => _showReplyInput = false);
      _loadReplies();
      widget.onCommentChanged?.call();
    }
  }

  Future<void> _loadReplies() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final replies = await widget.bridge.fetchReplies(
      widget.videoId,
      _comment.commentId,
      viewerUid: currentUser?.id,
    );

    if (mounted) {
      setState(() {
        _comment = _comment.copyWith(replies: replies);
        _showReplies = true;
      });
    }
  }

  Future<void> _handleEdit() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    if (_editController.text.trim().isEmpty) return;

    final success = await widget.bridge.editComment(
      _comment.commentId,
      _editController.text.trim(),
      currentUser.id,
    );

    if (success && mounted) {
      setState(() {
        _comment = _comment.copyWith(commentText: _editController.text.trim(), isEdited: true);
        _isEditing = false;
      });
      widget.onCommentChanged?.call();
    }
  }

  Future<void> _handleDelete() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final success = await widget.bridge.deleteComment(_comment.commentId, currentUser.id);

    if (success && mounted) {
      setState(() {
        _comment = _comment.copyWith(isDeleted: true, commentText: '[Comment deleted]');
      });
      widget.onCommentChanged?.call();
    }
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Comment?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('This comment will be removed. Are you sure?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              _handleDelete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReport() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final reasons = [
      'Spam or misleading',
      'Harassment or bullying',
      'Hate speech',
      'Violence or dangerous content',
      'Other',
    ];

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Report Comment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: reasons
              .map((r) => RadioListTile<String>(
                    title: Text(r, style: const TextStyle(color: Colors.white70)),
                    value: r,
                    groupValue: null,
                    activeColor: Colors.orange,
                    onChanged: (val) => Navigator.pop(ctx, val),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );

    if (reason == null || !mounted) return;

    final success = await widget.bridge.reportComment(
      commentId: _comment.commentId,
      reporterUid: currentUser.id,
      reason: reason,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Comment reported. Thank you.' : 'Failed to report comment.'),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildReactionChip(IconData icon, int count, String type, Color color) {
    final isActive = _currentViewerReaction == type;
    return GestureDetector(
      onTap: () => _handleReaction(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.orange.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? Colors.orange : Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? Colors.orange : color),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                color: isActive ? Colors.orange : Colors.white70,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionPicker() {
    final reactions = [
      ('like', Icons.thumb_up, Colors.cyanAccent),
      ('heart', Icons.favorite, Colors.pinkAccent),
      ('clap', Icons.celebration, Colors.yellow),
      ('laugh', Icons.sentiment_very_satisfied, Colors.amber),
      ('disagree', Icons.thumb_down, Colors.blueGrey),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions
            .map((r) => IconButton(
                  icon: Icon(r.$2, color: r.$3, size: 20),
                  onPressed: () => _handleReaction(r.$1),
                  splashRadius: 16,
                  tooltip: r.$1,
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isOwnComment = currentUser?.id == _comment.creatorUid;
    final hasReplies = _comment.replies.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF1E1E1E),
                child: Text(
                  _comment.creatorName.isNotEmpty ? _comment.creatorName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _comment.isIncognito ? 'Anonymous' : (_comment.creatorName.isEmpty ? 'Creator' : _comment.creatorName),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(_getTimeAgo(_comment.createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        if (_comment.isEdited) ...[
                          const SizedBox(width: 4),
                          Text('(edited)', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        ],
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 16),
                          color: const Color(0xFF1E1E1E),
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                setState(() {
                                  _isEditing = true;
                                  _editController.text = _comment.commentText;
                                });
                                break;
                              case 'delete':
                                _showDeleteConfirm();
                                break;
                              case 'report':
                                _handleReport();
                                break;
                              case 'reply':
                                setState(() => _showReplyInput = true);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'reply',
                              child: Row(children: [
                                Icon(Icons.reply, color: Colors.white, size: 16),
                                SizedBox(width: 8),
                                Text('Reply', style: TextStyle(color: Colors.white)),
                              ]),
                            ),
                            if (isOwnComment && !_comment.isDeleted)
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  Icon(Icons.edit, color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text('Edit', style: TextStyle(color: Colors.white)),
                                ]),
                              ),
                            if (isOwnComment && !_comment.isDeleted)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(Icons.delete, color: Colors.redAccent, size: 16),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                ]),
                              ),
                            if (!isOwnComment && !_comment.isDeleted)
                              const PopupMenuItem(
                                value: 'report',
                                child: Row(children: [
                                  Icon(Icons.flag, color: Colors.orange, size: 16),
                                  SizedBox(width: 8),
                                  Text('Report', style: TextStyle(color: Colors.orange)),
                                ]),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_isEditing)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _editController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF0F0F0F),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.orange),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(icon: const Icon(Icons.check, color: Colors.orange), onPressed: _handleEdit),
                          IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => setState(() => _isEditing = false)),
                        ],
                      )
                    else
                      Text(
                        _comment.commentText,
                        style: TextStyle(
                          color: _comment.isDeleted ? Colors.grey : Colors.white,
                          fontSize: 14,
                          fontStyle: _comment.isDeleted ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    const SizedBox(height: 6),
                    if (!_comment.isDeleted) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (_comment.likesCount > 0) _buildReactionChip(Icons.thumb_up, _comment.likesCount, 'like', Colors.cyanAccent),
                          if (_comment.heartCount > 0) _buildReactionChip(Icons.favorite, _comment.heartCount, 'heart', Colors.pinkAccent),
                          if (_comment.clapCount > 0) _buildReactionChip(Icons.celebration, _comment.clapCount, 'clap', Colors.yellow),
                          if (_comment.laughCount > 0)
                            _buildReactionChip(Icons.sentiment_very_satisfied, _comment.laughCount, 'laugh', Colors.amber),
                          if (_comment.disagreeCount > 0)
                            _buildReactionChip(Icons.thumb_down, _comment.disagreeCount, 'disagree', Colors.blueGrey),
                          GestureDetector(
                            onTap: () => setState(() => _showReactionPicker = !_showReactionPicker),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_reaction_outlined, color: Colors.grey[400], size: 14),
                                  const SizedBox(width: 4),
                                  Text('React', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_showReactionPicker) _buildReactionPicker(),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _showReplyInput = !_showReplyInput),
                            child: Text('Reply', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          if (hasReplies) ...[
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () => setState(() => _showReplies = !_showReplies),
                              child: Text(
                                _showReplies ? 'Hide ${_comment.replies.length} replies' : 'View ${_comment.replies.length} replies',
                                style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_showReplyInput)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _replyController,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Add a reply...',
                                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                    filled: true,
                                    fillColor: const Color(0xFF0F0F0F),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Colors.orange),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(icon: const Icon(Icons.send, color: Colors.orange, size: 18), onPressed: _postReply),
                            ],
                          ),
                        ),
                      if (_showReplies && hasReplies)
                        Container(
                          margin: const EdgeInsets.only(top: 8, left: 8),
                          padding: const EdgeInsets.only(left: 12),
                          decoration: const BoxDecoration(
                            border: Border(left: BorderSide(color: Colors.white12, width: 2)),
                          ),
                          child: Column(
                            children: _comment.replies
                                .map((reply) => MobileCommentWidget(
                                      comment: reply,
                                      bridge: widget.bridge,
                                      videoId: widget.videoId,
                                      videoCreatorUid: widget.videoCreatorUid,
                                      onCommentChanged: widget.onCommentChanged,
                                    ))
                                .toList(),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}