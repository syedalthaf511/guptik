import 'meta_content_model.dart'; // For SocialPlatform enum

/// Analytics data for a specific page/account
class MetaPageInsights {
  final String accountId;
  final String accountName;
  final SocialPlatform platform;
  final int followers;
  final int following;
  final int postsCount;
  final double engagementRate;
  final int totalReach;
  final int totalImpressions;
  final List<MetaPostInsights> topPosts;

  MetaPageInsights({
    required this.accountId,
    required this.accountName,
    required this.platform,
    required this.followers,
    required this.following,
    required this.postsCount,
    required this.engagementRate,
    required this.totalReach,
    required this.totalImpressions,
    this.topPosts = const [],
  });
}

/// Analytics data for a specific post
class MetaPostInsights {
  final String postId;
  final String postCaption;
  final SocialPlatform platform;
  final int likes;
  final int comments;
  final int shares;
  final int saves; // Instagram specific
  final int reach;
  final int impressions;
  final double engagementRate;
  final String createdTime;
  final String? thumbnailUrl;

  MetaPostInsights({
    required this.postId,
    required this.postCaption,
    required this.platform,
    required this.likes,
    required this.comments,
    required this.shares,
    this.saves = 0,
    required this.reach,
    required this.impressions,
    required this.engagementRate,
    required this.createdTime,
    this.thumbnailUrl,
  });

  // Helper to calculate total engagement
  int get totalEngagement => likes + comments + shares + saves;

  // Helper to format engagement rate as percentage
  String get formattedEngagementRate {
    return '${(engagementRate * 100).toStringAsFixed(2)}%';
  }
}

/// Analytics data for a story
class MetaStoryInsights {
  final String storyId;
  final SocialPlatform platform;
  final int views;
  final int replies;
  final int exits; // When users left the story
  final int nextStoryTaps;
  final String createdTime;
  final String? thumbnailUrl;

  MetaStoryInsights({
    required this.storyId,
    required this.platform,
    required this.views,
    required this.replies,
    required this.exits,
    required this.nextStoryTaps,
    required this.createdTime,
    this.thumbnailUrl,
  });
}

/// Monthly analytics data for charts/graphs
class MetaMonthlyAnalytics {
  final String month; // Format: "Jan 2024"
  final int followers;
  final int reach;
  final int impressions;
  final int engagement;

  MetaMonthlyAnalytics({
    required this.month,
    required this.followers,
    required this.reach,
    required this.impressions,
    required this.engagement,
  });
}

/// Audience demographics
class MetaAudienceDemographics {
  final String ageGroup; // e.g., "18-24", "25-34"
  final double percentage;
  final String? genderPrimary; // "M", "F", or null for unknown

  MetaAudienceDemographics({
    required this.ageGroup,
    required this.percentage,
    this.genderPrimary,
  });
}

/// Top performing content categories
class MetaContentPerformance {
  final String contentType; // "Post", "Reel", "Story", "Video"
  final double averageEngagement;
  final int totalPosts;

  MetaContentPerformance({
    required this.contentType,
    required this.averageEngagement,
    required this.totalPosts,
  });
}