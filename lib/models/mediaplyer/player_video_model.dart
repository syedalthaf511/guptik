class PlayerVideo {
  final String videoId;
  final String creatorUid;
  final String title;
  final String description;
  final String filePath; 
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final String createdAt;
  final String creatorUrl;
  final String channelName;
  final List<String> stickers;

  PlayerVideo({
    required this.videoId,
    required this.creatorUid,
    required this.title,
    required this.description,
    required this.filePath,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.creatorUrl,
    required this.channelName,
    this.stickers = const [],
  });

  factory PlayerVideo.fromJson(Map<String, dynamic> json, String gateway) {
    return PlayerVideo(
      // 🚀 THE FIX: We must prioritize 'video_id' over 'id' so it perfectly matches the Local Vault!
      videoId: json['video_id'] ?? json['id'] ?? '',
      creatorUid: json['creator_uid'] ?? '',
      title: json['title'] ?? 'Untitled Broadcast',
      description: json['description'] ?? '',
      filePath: json['file_path'] ?? '',
      viewCount: json['view_count_local'] ?? json['view_count'] ?? 0,
      likeCount: json['like_count_local'] ?? json['like_count'] ?? 0,
      commentCount: json['comment_count_local'] ?? json['comment_count'] ?? 0,
      createdAt: json['published_at'] ?? json['created_at'] ?? json['upload_timestamp'] ?? '',
      creatorUrl: gateway,
      channelName: json['channel_name'] ?? 'Guptik Node',
      stickers: [], 
    );
  }
}