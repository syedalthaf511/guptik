import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guptik/screens/facebook/fullscreen_media_screen.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/models/facebook/meta_comment_model.dart';
import 'package:guptik/widgets/facebook/auto_reply_dialog.dart';
import 'package:guptik/widgets/facebook/edit_post_dialog.dart';
import 'package:guptik/widgets/facebook/likes_list_dialog.dart';
import 'package:guptik/services/facebook/meta_service.dart';
import 'package:guptik/screens/facebook/comments_screen.dart';

class MetaGridCard extends StatefulWidget {
  final MetaContent content;
  final VoidCallback? onPostUpdated;

  const MetaGridCard({super.key, required this.content, this.onPostUpdated});

  @override
  State<MetaGridCard> createState() => _MetaGridCardState();
}

class _MetaGridCardState extends State<MetaGridCard> {
  final MetaService _metaService = MetaService();

  // State for expanded sections
  bool _showComments = false;

  // Data
  List<MetaComment> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  // Loading states
  bool _isLoadingComments = false;
  bool _isPostingComment = false;

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

  int _getTotalCommentCount() {
    if (_comments.isEmpty) {
      return widget.content.comments;
    }

    int total = _comments.length;
    for (var comment in _comments) {
      total += comment.replies.length;
    }
    return total;
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text(
          "Are you sure you want to delete this post? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deletePost();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await _metaService.deletePost(
      widget.content.id,
      widget.content.platform,
    );

    if (mounted) {
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post deleted successfully!")),
        );
        widget.onPostUpdated?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to delete post. Please try again."),
          ),
        );
      }
    }
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditPostDialog(
        postId: widget.content.id,
        currentCaption: widget.content.caption,
        currentImageUrl: widget.content.imageUrl,
        platform: widget.content.platform,
        onSuccess: () {
          widget.onPostUpdated?.call();
        },
      ),
    );
  }

  Future<void> _toggleComments() async {
    if (!mounted) return;

    setState(() {
      _showComments = !_showComments;
    });
  }

  Future<void> _loadComments() async {
    if (!mounted) return;

    setState(() => _isLoadingComments = true);

    try {
      final comments = await _metaService.getPostComments(
        widget.content.id,
        platform: widget.content.platform,
      );

      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading comments: $e");
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  Future<void> _replyToComment(String commentId, String replyText) async {
    try {
      final success = await _metaService.replyToComment(commentId, replyText);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Reply posted successfully!"),
              duration: Duration(seconds: 2),
            ),
          );
        }

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          await _loadComments();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Failed to post reply")));
        }
      }
    } catch (e) {
      debugPrint("Error replying to comment: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Error posting reply")));
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text(
          'Are you sure you want to delete this comment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoadingComments = true);

    try {
      final success = await _metaService.deleteComment(commentId);

      if (success && mounted) {
        setState(() {
          _comments.removeWhere((c) => c.id == commentId);
          _isLoadingComments = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isLoadingComments = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete comment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingComments = false);
      debugPrint("Error deleting comment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.isEmpty) return;
    final commentText = _commentController.text;
    _commentController.clear();
    setState(() => _isPostingComment = true);

    try {
      final success = await _metaService.postComment(
        widget.content.id,
        commentText,
        platform: widget.content.platform,
      );

      if (success && mounted) {
        await _loadComments();
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to post comment')));
      }
    } catch (e) {
      debugPrint("Error posting comment: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Show likes dialog
  // ---------------------------------------------------------------------------
  Future<void> _showLikesDialog() async {
    if (widget.content.id.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final likes = await _metaService.getPostLikes(
        widget.content.id,
        platform: widget.content.platform,
      );
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (ctx) =>
              LikesListDialog(likes: likes, platform: widget.content.platform),
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

  Widget _buildPostMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          _showEditDialog();
        } else if (value == 'delete') {
          _showDeleteConfirmation();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(fontSize: 14, color: Colors.red)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.more_vert, color: Colors.blue[600], size: 18),
      ),
    );
  }

  Widget _buildCommentTile(MetaComment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue[100],
                child: Text(
                  comment.authorName.isNotEmpty ? comment.authorName[0] : '?',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment.text, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '❤️ ${comment.likeCount}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            if (mounted) {
                              setState(() {
                                _showReplyInput[comment.id] =
                                    !(_showReplyInput[comment.id] ?? false);
                              });
                            }
                          },
                          child: const Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _deleteComment(comment.id),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showReplyInput[comment.id] == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildReplyInput(comment.id),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.only(left: 32),
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!, width: 2),
                ),
              ),
              child: Column(
                children: comment.replies.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildReplyTile(reply),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyInput(String commentId) {
    final replyController = TextEditingController();

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: replyController,
            decoration: InputDecoration(
              hintText: 'Write a reply...',
              hintStyle: const TextStyle(fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            style: const TextStyle(fontSize: 13),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (value) async {
              if (value.isNotEmpty && mounted) {
                setState(() {
                  _showReplyInput[commentId] = false;
                });
                await _replyToComment(commentId, value);
              }
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send, size: 18, color: Colors.blue),
          onPressed: () async {
            if (replyController.text.isNotEmpty && mounted) {
              setState(() {
                _showReplyInput[commentId] = false;
              });
              await _replyToComment(commentId, replyController.text);
            }
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildReplyTile(MetaComment reply) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.grey[300],
          child: Text(
            reply.authorName.isNotEmpty ? reply.authorName[0] : '?',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
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
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(reply.text, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTextOnly =
        widget.content.imageUrl == null || widget.content.imageUrl!.isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AutoReplyDialog(
                        postId: widget.content.id,
                        platform: widget.content.platform,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.settings,
                      color: Colors.blue[600],
                      size: 18,
                    ),
                  ),
                ),
                Row(
                  children: [
                    _buildPostMenu(),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            widget.content.platform == SocialPlatform.facebook
                            ? const Color(0xFF1877F2).withValues(alpha: 0.1)
                            : const Color(0xFFE1306C).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: FaIcon(
                        widget.content.platform == SocialPlatform.facebook
                            ? FontAwesomeIcons.facebook
                            : FontAwesomeIcons.instagram,
                        size: 16,
                        color:
                            widget.content.platform == SocialPlatform.facebook
                            ? const Color(0xFF1877F2)
                            : const Color(0xFFE1306C),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Image
          if (!isTextOnly)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: GestureDetector(
                onTap: () {
                  if (widget.content.imageUrl != null &&
                      widget.content.imageUrl!.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenMediaScreen(
                          imageUrl: widget.content.imageUrl!,
                          caption: widget.content.caption,
                          postId: widget.content.id,
                          platform: widget.content.platform,
                          initialLikes: widget.content.likes,
                          initialComments: widget.content.comments,
                        ),
                      ),
                    );
                  }
                },
                child: Image.network(
                  widget.content.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 30),
                    ),
                  ),
                ),
              ),
            ),

          // Caption
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              widget.content.caption.isEmpty
                  ? '(No caption)'
                  : widget.content.caption,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Likes - Tappable to show dialog (no toggle)
                GestureDetector(
                  onTap: _showLikesDialog,
                  child: Row(
                    children: [
                      Icon(
                        widget.content.platform == SocialPlatform.facebook
                            ? Icons.thumb_up
                            : Icons.favorite,
                        size: 30,
                        color:
                            widget.content.platform == SocialPlatform.facebook
                            ? Colors.blue[300]
                            : Colors.red[300],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatNumber(widget.content.likes),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Comments - Tappable to expand inline
                GestureDetector(
                  onTap: _toggleComments,
                  child: Row(
                    children: [
                      Icon(
                        Icons.comment,
                        size: 30,
                        color: _showComments ? Colors.blue : Colors.blue[300],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatNumber(_getTotalCommentCount()),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: _showComments
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // View All Comments Button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentsScreen(
                          postId: widget.content.id,
                          postCaption: widget.content.caption,
                          platform: widget.content.platform,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('View All', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Expanded Comments Section
          if (_showComments)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Comments',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          if (mounted) {
                            setState(() => _showComments = false);
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Comments List
                  if (_isLoadingComments)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_comments.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No comments yet',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length > 3 ? 3 : _comments.length,
                      itemBuilder: (context, index) {
                        return _buildCommentTile(_comments[index]);
                      },
                    ),

                  // Comment Input Field
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            enabled: !_isPostingComment,
                            decoration: InputDecoration(
                              hintText: 'Write a comment...',
                              hintStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            style: const TextStyle(fontSize: 13),
                            maxLines: null,
                          ),
                        ),
                        IconButton(
                          icon: _isPostingComment
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.blue),
                          onPressed: _isPostingComment ? null : _postComment,
                        ),
                      ],
                    ),
                  ),

                  if (_comments.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommentsScreen(
                                  postId: widget.content.id,
                                  postCaption: widget.content.caption,
                                  platform: widget.content.platform,
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            'View all ${_comments.length} comments',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}