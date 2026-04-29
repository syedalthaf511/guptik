import 'package:flutter/material.dart';
import 'package:guptik/models/facebook/meta_comment_model.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';
import 'package:guptik/widgets/facebook/likes_list_dialog.dart';
import 'package:guptik/config/app_theme.dart';

class FullScreenMediaScreen extends StatefulWidget {
  final String imageUrl;
  final String caption;
  final String? postId;
  final SocialPlatform? platform;
  final int initialLikes;
  final int initialComments;

  const FullScreenMediaScreen({
    super.key,
    required this.imageUrl,
    this.caption = '',
    this.postId,
    this.platform,
    this.initialLikes = 0,
    this.initialComments = 0,
  });

  @override
  State<FullScreenMediaScreen> createState() => _FullScreenMediaScreenState();
}

class _FullScreenMediaScreenState extends State<FullScreenMediaScreen> {
  final MetaService _metaService = MetaService();
  int _likesCount = 0;
  int _commentsCount = 0;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.initialLikes;
    _commentsCount = widget.initialComments;
    if (widget.postId != null && widget.platform != null) {
      _fetchPostDetails();
      _fetchCommentCount();
    }
  }

  Future<void> _fetchPostDetails() async {
    try {
      final insights = await _metaService.getPostInsights(widget.postId!);
      if (insights != null && mounted) {
        setState(() {
          _likesCount = insights.likes;
        });
      }
    } catch (e) {
      debugPrint("Error fetching post details: $e");
    }
  }

  Future<void> _fetchCommentCount() async {
    if (widget.postId == null || widget.platform == null) return;
    try {
      final comments = await _metaService.getPostComments(
        widget.postId!,
        platform: widget.platform,
      );
      if (mounted) {
        int total = 0;
        for (var comment in comments) {
          total += 1;
          total += comment.replies.length;
        }
        setState(() {
          _commentsCount = total;
        });
      }
    } catch (e) {
      debugPrint("Error fetching comment count: $e");
    }
  }

  Future<void> _showLikesDialog() async {
    if (widget.postId == null || widget.platform == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final likes = await _metaService.getPostLikes(
        widget.postId!,
        platform: widget.platform,
      );
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (ctx) =>
              LikesListDialog(likes: likes, platform: widget.platform!),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load likes: $e')));
      }
    }
  }

  void _showCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => CommentsBottomSheet(
        postId: widget.postId,
        platform: widget.platform,
        initialCommentCount: _commentsCount,
        onCommentCountUpdated: (newCount) {
          setState(() {
            _commentsCount = newCount;
          });
        },
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final platformColor = widget.platform == SocialPlatform.facebook
        ? AppTheme.facebookBlue
        : AppTheme.instagramPink;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text(
          widget.platform == SocialPlatform.facebook
              ? 'Facebook Post'
              : 'Instagram Post',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (ctx, _, _) =>
                    const Icon(Icons.broken_image, color: Colors.white),
              ),
            ),
          ),
          if (widget.caption.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: platformColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.caption,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _showLikesDialog,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: platformColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: platformColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.platform == SocialPlatform.facebook
                              ? Icons.thumb_up
                              : Icons.favorite,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _formatNumber(_likesCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _showCommentsSheet,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: platformColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: platformColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.comment,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _formatNumber(_commentsCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share feature coming soon'),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: platformColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: platformColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.share,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Share',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommentsBottomSheet extends StatefulWidget {
  final String? postId;
  final SocialPlatform? platform;
  final int initialCommentCount;
  final ValueChanged<int> onCommentCountUpdated;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    required this.platform,
    required this.initialCommentCount,
    required this.onCommentCountUpdated,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final MetaService _metaService = MetaService();
  List<MetaComment> _comments = [];
  bool _isLoading = true;
  final TextEditingController _commentController = TextEditingController();
  final Map<String, bool> _showReplyInput = {};
  final Map<String, TextEditingController> _replyControllers = {};
  int _currentCommentCount = 0;

  @override
  void initState() {
    super.initState();
    _currentCommentCount = widget.initialCommentCount;
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    for (var controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _calculateTotalComments(List<MetaComment> comments) {
    int total = 0;
    for (var comment in comments) {
      total += 1;
      total += comment.replies.length;
    }
    return total;
  }

  Future<void> _loadComments() async {
    if (widget.postId == null || widget.platform == null) return;
    setState(() => _isLoading = true);
    try {
      final comments = await _metaService.getPostComments(
        widget.postId!,
        platform: widget.platform,
      );
      final total = _calculateTotalComments(comments);
      setState(() {
        _comments = comments;
        _currentCommentCount = total;
        widget.onCommentCountUpdated(total);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading comments: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.isEmpty) return;
    final text = _commentController.text;
    _commentController.clear();

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final newComment = MetaComment(
      id: tempId,
      authorName: 'You',
      authorId: 'me',
      text: text,
      createdTime: DateTime.now().toIso8601String(),
      platform: widget.platform!,
      isFromPageOwner: true,
      replies: [],
    );
    setState(() {
      _comments.insert(0, newComment);
      _currentCommentCount++;
      widget.onCommentCountUpdated(_currentCommentCount);
    });

    try {
      final success = await _metaService.postComment(
        widget.postId!,
        text,
        platform: widget.platform,
      );
      if (success && mounted) {
        await _loadComments();
      } else {
        setState(() {
          _comments.removeWhere((c) => c.id == tempId);
          _currentCommentCount--;
          widget.onCommentCountUpdated(_currentCommentCount);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to post comment')));
      }
    } catch (e) {
      setState(() {
        _comments.removeWhere((c) => c.id == tempId);
        _currentCommentCount--;
        widget.onCommentCountUpdated(_currentCommentCount);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _replyToComment(String commentId, String replyText) async {
    if (replyText.isEmpty) return;
    try {
      final success = await _metaService.replyToComment(commentId, replyText);
      if (success && mounted) {
        _loadComments();
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to post reply')));
      }
    } catch (e) {
      debugPrint("Error replying: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error posting reply: $e')));
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Comment', style: AppTheme.textTheme.titleLarge),
        backgroundColor: AppTheme.surface,
        content: Text(
          'Are you sure you want to delete this comment?',
          style: AppTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.mediumGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final success = await _metaService.deleteComment(commentId);
      if (success && mounted) {
        await _loadComments();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Comment deleted'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete comment'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Widget _buildReplyInput(String commentId, Color platformColor) {
    if (!_replyControllers.containsKey(commentId)) {
      _replyControllers[commentId] = TextEditingController();
    }
    final controller = _replyControllers[commentId]!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTheme.textTheme.bodySmall,
              decoration: InputDecoration(
                hintText: 'Write a reply...',
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
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) async {
                if (value.isNotEmpty) {
                  setState(() => _showReplyInput[commentId] = false);
                  await _replyToComment(commentId, value);
                  controller.clear();
                }
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: AppSpacing.md),
            decoration: BoxDecoration(
              color: platformColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, size: 16, color: platformColor),
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  setState(() => _showReplyInput[commentId] = false);
                  await _replyToComment(commentId, controller.text);
                  controller.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(MetaComment comment, Color platformColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      platformColor,
                      platformColor.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    comment.authorName.isNotEmpty ? comment.authorName[0] : '?',
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          comment.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          comment.formattedTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.mediumGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(comment.text, style: AppTheme.textTheme.bodySmall),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Text(
                          '❤️ ${comment.likeCount}',
                          style: TextStyle(
                            fontSize: 11,
                            color: platformColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showReplyInput[comment.id] =
                                  !(_showReplyInput[comment.id] ?? false);
                            });
                          },
                          child: Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 11,
                              color: platformColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (comment.isFromPageOwner)
                          GestureDetector(
                            onTap: () => _deleteComment(comment.id),
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_showReplyInput[comment.id] == true)
                      _buildReplyInput(comment.id, platformColor),
                  ],
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              margin: const EdgeInsets.only(left: 32),
              padding: const EdgeInsets.only(left: AppSpacing.lg),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: platformColor.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: comment.replies.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _buildReplyTile(reply, platformColor),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyTile(MetaComment reply, Color platformColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                platformColor.withValues(alpha: 0.8),
                platformColor.withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              reply.authorName.isNotEmpty ? reply.authorName[0] : '?',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    reply.authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    reply.formattedTime,
                    style: TextStyle(fontSize: 10, color: AppTheme.mediumGrey),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(reply.text, style: AppTheme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final platformColor = widget.platform == SocialPlatform.facebook
        ? AppTheme.facebookBlue
        : AppTheme.instagramPink;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Comments', style: AppTheme.textTheme.headlineSmall),
              IconButton(
                icon: Icon(Icons.close, color: AppTheme.dark),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Divider(color: AppTheme.lightGrey, height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: AppTheme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
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
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: AppSpacing.md),
                decoration: BoxDecoration(
                  color: platformColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: _postComment,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(platformColor),
                    ),
                  )
                : _comments.isEmpty
                ? Center(
                    child: Text(
                      'No comments yet',
                      style: AppTheme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    itemCount: _comments.length,
                    separatorBuilder: (_, _) =>
                        Divider(color: AppTheme.lightGrey, height: 1),
                    itemBuilder: (context, index) =>
                        _buildCommentTile(_comments[index], platformColor),
                  ),
          ),
        ],
      ),
    );
  }
}