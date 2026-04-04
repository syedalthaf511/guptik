enum SocialPlatform { facebook, instagram }

enum ContentType { post, reel, story, mention } // NEW ENUM

class MetaContent {
  final String id;
  final SocialPlatform platform;
  final ContentType type; // NEW FIELD
  final String? imageUrl;
  final String caption;
  final int likes;
  final int comments;

  MetaContent({
    required this.id,
    required this.platform,
    required this.type, // NEW FIELD
    this.imageUrl,
    required this.caption,
    required this.likes,
    required this.comments,
  });
}