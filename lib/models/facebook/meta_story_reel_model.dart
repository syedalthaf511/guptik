import 'meta_content_model.dart'; // For SocialPlatform enum

enum MediaStatus { uploading, published, archived, failed }

/// Model for Instagram/Facebook Stories
class MetaStory {
  final String id;
  final String mediaUrl;
  final String? caption;
  final SocialPlatform platform;
  final String createdTime;
  final int views;
  final int replies;
  final MediaStatus status;
  final String? thumbnail;
  final bool isExpired;

  MetaStory({
    required this.id,
    required this.mediaUrl,
    this.caption,
    required this.platform,
    required this.createdTime,
    this.views = 0,
    this.replies = 0,
    this.status = MediaStatus.published,
    this.thumbnail,
    this.isExpired = false,
  });

  String get timeElapsed {
    try {
      final created = DateTime.parse(createdTime);
      final now = DateTime.now();
      final diff = now.difference(created);

      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Unknown';
    }
  }
}

/// Model for Instagram Reels
class MetaReel {
  final String id;
  final String videoUrl;
  final String? thumbnail;
  final String caption;
  final SocialPlatform platform;
  final String createdTime;
  final int likes;
  final int comments;
  final int shares;
  final int plays;
  final double duration;
  final MediaStatus status;
  final bool isSponsored;

  // Extracted reel ID for embedding
  late final String reelId;

  MetaReel({
    required this.id,
    required this.videoUrl,
    this.thumbnail,
    required this.caption,
    required this.platform,
    required this.createdTime,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.plays = 0,
    this.duration = 0.0,
    this.status = MediaStatus.published,
    this.isSponsored = false,
  }) {
    // Extract reel ID from videoUrl or use the post ID
    if (videoUrl.contains('/reel/')) {
      final uri = Uri.tryParse(videoUrl);
      if (uri != null) {
        final segments = uri.pathSegments;
        final reelIndex = segments.indexOf('reel');
        if (reelIndex != -1 && reelIndex + 1 < segments.length) {
          reelId = segments[reelIndex + 1];
        } else {
          reelId = id;
        }
      } else {
        reelId = id;
      }
    } else {
      reelId = id;
    }
  }

  int get totalEngagement => likes + comments + shares;

  String get timeElapsed {
    try {
      final created = DateTime.parse(createdTime);
      final now = DateTime.now();
      final diff = now.difference(created);

      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Unknown';
    }
  }

  String get formattedDuration {
    final minutes = duration.toInt() ~/ 60;
    final seconds = duration.toInt() % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Model for carousel media
class MetaCarouselItem {
  final String id;
  final String mediaUrl;
  final String mediaType;
  final String? caption;
  final int position;

  MetaCarouselItem({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    required this.position,
  });
}

/// Model for carousel post
class MetaCarousel {
  final String id;
  final List<MetaCarouselItem> items;
  final String caption;
  final SocialPlatform platform;
  final String createdTime;
  final int likes;
  final int comments;
  final int shares;
  final MediaStatus status;

  MetaCarousel({
    required this.id,
    required this.items,
    required this.caption,
    required this.platform,
    required this.createdTime,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.status = MediaStatus.published,
  });

  int get totalEngagement => likes + comments + shares;
}