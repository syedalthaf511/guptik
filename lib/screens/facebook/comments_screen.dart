import 'package:flutter/material.dart';
import 'package:guptik/models/facebook/meta_comment_model.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';

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
          const SnackBar(
            content: Text('Comment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete comment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error deleting comment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildReplyInput(String commentId) {
    final replyController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
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
                if (value.isNotEmpty) {
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
              if (replyController.text.isNotEmpty) {
                setState(() {
                  _showReplyInput[commentId] = false;
                });
                await _replyToComment(commentId, replyController.text);
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
              // Avatar
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
              const SizedBox(width: 12),

              // Comment content
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
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              comment.formattedTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (comment.isFromPageOwner) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'You',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        comment.text,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Comment actions
                    Row(
                      children: [
                        Text(
                          '❤️ ${comment.likeCount}',
                          style: const TextStyle(fontSize: 12),
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
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // DELETE BUTTON - Always available for page owner
                        GestureDetector(
                          onTap: () => _deleteComment(comment.id),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Reply input field
                    if (_showReplyInput[comment.id] == true)
                      _buildReplyInput(comment.id),
                  ],
                ),
              ),
            ],
          ),

          // Show replies if any
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.only(left: 32),
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!, width: 2),
                ),
              ),
              child: Column(
                children: comment.replies.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildReplyTile(reply),
                  );
                }).toList(),
              ),
            ),
          ],

          const Divider(height: 24),
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
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    reply.formattedTime,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(reply.text, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Comments - ${widget.platform == SocialPlatform.facebook ? 'Facebook' : 'Instagram'}',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadComments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Original Post Preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: widget.platform == SocialPlatform.facebook
                            ? Colors.blue[50]
                            : Colors.pink[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.platform == SocialPlatform.facebook
                            ? 'Facebook'
                            : 'Instagram',
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.platform == SocialPlatform.facebook
                              ? Colors.blue
                              : Colors.pink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.postCaption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),

          // Comments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadComments,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        return _buildCommentTile(_comments[index]);
                      },
                    ),
                  ),
          ),

          // Comment Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    enabled: !_isPosting,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isPosting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.send,
                          size: 20,
                          color: Color(0xFF1877F2),
                        ),
                  onPressed: _isPosting ? null : _postComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}