import 'package:flutter/material.dart';
import 'package:guptik/models/facebook/meta_comment_model.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';
import 'package:guptik/widgets/facebook/likes_list_dialog.dart';

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
                errorBuilder: (ctx, _, __) =>
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
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.platform == SocialPlatform.facebook
                              ? Icons.thumb_up
                              : Icons.favorite,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatNumber(_likesCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.comment,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatNumber(_commentsCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 28,
                    ),
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
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
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
    try {
      final success = await _metaService.deleteComment(commentId);
      if (success && mounted) {
        await _loadComments();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment deleted')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete comment')),
        );
      }
    } catch (e) {
      debugPrint("Error deleting: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildReplyInput(String commentId) {
    if (!_replyControllers.containsKey(commentId)) {
      _replyControllers[commentId] = TextEditingController();
    }
    final controller = _replyControllers[commentId]!;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
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
                if (value.isNotEmpty) {
                  setState(() => _showReplyInput[commentId] = false);
                  await _replyToComment(commentId, value);
                  controller.clear();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, size: 18, color: Colors.blue),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                setState(() => _showReplyInput[commentId] = false);
                await _replyToComment(commentId, controller.text);
                controller.clear();
              }
            },
          ),
        ],
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
                            setState(() {
                              _showReplyInput[comment.id] =
                                  !(_showReplyInput[comment.id] ?? false);
                            });
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
                        if (comment.isFromPageOwner)
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
                      _buildReplyInput(comment.id),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Comments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: _postComment,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? const Center(child: Text('No comments yet'))
                : ListView.separated(
                    itemCount: _comments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _buildCommentTile(_comments[index]),
                  ),
          ),
        ],
      ),
    );
  }
}