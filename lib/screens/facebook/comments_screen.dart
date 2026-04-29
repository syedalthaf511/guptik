import 'package:flutter/material.dart';
import 'package:guptik/models/facebook/meta_comment_model.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';
import 'package:guptik/config/app_theme.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final String postCaption;
  final SocialPlatform platform;

  const CommentsScreen({
    super.key,
    required this.postId,
    required this.postCaption,
    required this.platform,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final MetaService _metaService = MetaService();
  final TextEditingController _commentController = TextEditingController();
  List<MetaComment> _comments = [];
  bool _isLoading = true;
  bool _isPosting = false;

  // Track which comments are showing reply input
  final Map<String, bool> _showReplyInput = {};

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);

    try {
      debugPrint(
        "Loading comments for post: ${widget.postId} on platform: ${widget.platform}",
      );

      final comments = await _metaService.getPostComments(
        widget.postId,
        platform: widget.platform,
      );

      debugPrint("Comments loaded: ${comments.length}");

      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading comments: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.isEmpty) return;

    final commentText = _commentController.text;
    _commentController.clear();

    setState(() => _isPosting = true);

    try {
      // Add comment locally for now
      final newComment = MetaComment(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        authorName: 'You',
        authorId: 'me',
        text: commentText,
        createdTime: DateTime.now().toIso8601String(),
        platform: widget.platform,
        isFromPageOwner: true,
        replies: [],
      );

      setState(() {
        _comments.insert(0, newComment);
      });

      // TODO: Call actual API to post comment
      debugPrint("Comment posted: $commentText");
    } catch (e) {
      debugPrint("Error posting comment: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to post comment')));
        setState(() {
          _comments.removeAt(0);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Future<void> _replyToComment(String commentId, String replyText) async {
    try {
      final success = await _metaService.replyToComment(commentId, replyText);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reply posted successfully!")),
        );

        await Future.delayed(const Duration(seconds: 1));
        await _loadComments();
      }
    } catch (e) {
      debugPrint("Error replying to comment: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to post reply")));
      }
    }
  }

  // NEW: Delete comment function
  Future<void> _deleteComment(String commentId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Comment', style: AppTheme.textTheme.titleLarge),
        backgroundColor: AppTheme.surface,
        content: Text(
          'Are you sure you want to delete this comment? This action cannot be undone.',
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

    // Show loading indicator
    setState(() => _isLoading = true);

    try {
      final success = await _metaService.deleteComment(commentId);

      if (success && mounted) {
        // Remove comment from list
        setState(() {
          _comments.removeWhere((c) => c.id == commentId);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Comment deleted successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete comment'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error deleting comment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Widget _buildReplyInput(String commentId, Color platformColor) {
    final replyController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: replyController,
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
              style: AppTheme.textTheme.bodySmall,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) async {
                if (value.isNotEmpty) {
                  setState(() {
                    _showReplyInput[commentId] = false;
                  });
                  await _replyToComment(commentId, value);
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
                if (replyController.text.isNotEmpty) {
                  setState(() {
                    _showReplyInput[commentId] = false;
                  });
                  await _replyToComment(commentId, replyController.text);
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
              // Avatar
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
                  boxShadow: [
                    BoxShadow(
                      color: platformColor.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    comment.authorName.isNotEmpty
                        ? comment.authorName[0].toUpperCase()
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

              // Comment content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            comment.authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              comment.formattedTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.mediumGrey,
                              ),
                            ),
                            if (comment.isFromPageOwner) ...[
                              const SizedBox(width: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: platformColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                                child: Text(
                                  'You',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: platformColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: platformColor.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        comment.text,
                        style: AppTheme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Comment actions
                    Row(
                      children: [
                        _buildCommentAction(
                          icon: '❤️',
                          label: '${comment.likeCount}',
                          platformColor: platformColor,
                        ),
                        const SizedBox(width: AppSpacing.xl),
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
                              fontSize: 12,
                              color: platformColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        // DELETE BUTTON - Always available for page owner
                        GestureDetector(
                          onTap: () => _deleteComment(comment.id),
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Reply input field
                    if (_showReplyInput[comment.id] == true)
                      _buildReplyInput(comment.id, platformColor),
                  ],
                ),
              ),
            ],
          ),

          // Show replies if any
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

          Divider(color: AppTheme.lightGrey, height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildCommentAction({
    required String icon,
    required String label,
    required Color platformColor,
  }) {
    return Text(
      '$icon $label',
      style: TextStyle(
        fontSize: 12,
        color: platformColor,
        fontWeight: FontWeight.w500,
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
              reply.authorName.isNotEmpty
                  ? reply.authorName[0].toUpperCase()
                  : '?',
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
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    reply.formattedTime,
                    style: TextStyle(fontSize: 11, color: AppTheme.mediumGrey),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: platformColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Text(reply.text, style: AppTheme.textTheme.bodySmall),
              ),
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Comments - ${widget.platform == SocialPlatform.facebook ? 'Facebook' : 'Instagram'}',
          style: AppTheme.textTheme.titleMedium,
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.dark,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 20, color: platformColor),
            onPressed: _loadComments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Original Post Preview
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: platformColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              boxShadow: AppShadows.light,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: platformColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        widget.platform == SocialPlatform.facebook
                            ? 'Facebook'
                            : 'Instagram',
                        style: TextStyle(
                          fontSize: 10,
                          color: platformColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  widget.postCaption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // Comments List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(platformColor),
                    ),
                  )
                : _comments.isEmpty
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
                            Icons.comment_outlined,
                            size: 40,
                            color: platformColor.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'No comments yet',
                          style: AppTheme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Comments will appear here',
                          style: AppTheme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: platformColor,
                    onRefresh: _loadComments,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        return _buildCommentTile(
                          _comments[index],
                          platformColor,
                        );
                      },
                    ),
                  ),
          ),

          // Comment Input
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                top: BorderSide(color: AppTheme.lightGrey, width: 1),
              ),
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
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    enabled: !_isPosting,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
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
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  decoration: BoxDecoration(
                    color: platformColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: platformColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: _isPosting
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.send, size: 20, color: Colors.white),
                    onPressed: _isPosting ? null : _postComment,
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