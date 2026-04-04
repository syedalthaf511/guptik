import 'meta_content_model.dart'; // For SocialPlatform enum

class MetaComment {
  final String id;
  final String authorName;
  final String authorId;
  final String text;
  final String createdTime;
  final int likeCount;
  final SocialPlatform platform;
  final String? avatarUrl;
  final bool isFromPageOwner;
  final List<MetaComment> replies; // Nested replies to this comment

  MetaComment({
    required this.id,
    required this.authorName,
    required this.authorId,
    required this.text,
    required this.createdTime,
    this.likeCount = 0,
    required this.platform,
    this.avatarUrl,
    this.isFromPageOwner = false,
    this.replies = const [],
  });

  // Helper to format timestamp
  String get formattedTime {
    try {
      final date = DateTime.parse(createdTime);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 60) {
        return '${difference.inSeconds}s ago';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    } catch (_) {
      return createdTime;
    }
  }
}