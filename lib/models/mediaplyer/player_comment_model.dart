/// PlayerComment — a single video comment, with nested replies and
/// per-reaction-type counts. Mirrors the shape returned by the gateway's
/// GET /player/video/comments/<videoId> (and .../replies/<parentId>) routes.
class PlayerComment {
  final String commentId;
  final String commentText;
  final String creatorUid;
  final String creatorName;
  final String createdAt;
  final String? parentCommentId;

  final int likesCount;
  final int heartCount;
  final int clapCount;
  final int laughCount;
  final int disagreeCount;

  final bool isDeleted;
  final bool isEdited;
  final String? editedAt;
  final bool isIncognito;

  /// This viewer's own reaction on the comment, if any: 'like'/'heart'/
  /// 'clap'/'laugh'/'disagree', or null if they haven't reacted.
  final String? viewerReaction;

  final List<PlayerComment> replies;

  const PlayerComment({
    required this.commentId,
    required this.commentText,
    required this.creatorUid,
    required this.creatorName,
    required this.createdAt,
    this.parentCommentId,
    this.likesCount = 0,
    this.heartCount = 0,
    this.clapCount = 0,
    this.laughCount = 0,
    this.disagreeCount = 0,
    this.isDeleted = false,
    this.isEdited = false,
    this.editedAt,
    this.isIncognito = false,
    this.viewerReaction,
    this.replies = const [],
  });

  factory PlayerComment.fromJson(Map<String, dynamic> json) {
    return PlayerComment(
      commentId: json['comment_id']?.toString() ?? '',
      commentText: json['comment_text']?.toString() ?? '',
      creatorUid: json['creator_uid']?.toString() ?? '',
      creatorName: json['creator_name']?.toString() ?? 'Creator',
      createdAt: json['created_at']?.toString() ?? '',
      parentCommentId: json['parent_comment_id']?.toString(),
      likesCount: _toInt(json['likes_count']),
      heartCount: _toInt(json['heart_count']),
      clapCount: _toInt(json['clap_count']),
      laughCount: _toInt(json['laugh_count']),
      disagreeCount: _toInt(json['disagree_count']),
      isDeleted: json['is_deleted'] == true,
      isEdited: json['is_edited'] == true,
      editedAt: json['edited_at']?.toString(),
      isIncognito: json['is_incognito'] == true,
      viewerReaction: json['viewer_reaction']?.toString(),
      replies: json['replies'] is List
          ? (json['replies'] as List)
              .map((r) => PlayerComment.fromJson(Map<String, dynamic>.from(r as Map)))
              .toList()
          : const [],
    );
  }

  PlayerComment copyWith({
    String? commentText,
    int? likesCount,
    int? heartCount,
    int? clapCount,
    int? laughCount,
    int? disagreeCount,
    bool? isDeleted,
    bool? isEdited,
    String? editedAt,
    String? viewerReaction,
    List<PlayerComment>? replies,
  }) {
    return PlayerComment(
      commentId: commentId,
      commentText: commentText ?? this.commentText,
      creatorUid: creatorUid,
      creatorName: creatorName,
      createdAt: createdAt,
      parentCommentId: parentCommentId,
      likesCount: likesCount ?? this.likesCount,
      heartCount: heartCount ?? this.heartCount,
      clapCount: clapCount ?? this.clapCount,
      laughCount: laughCount ?? this.laughCount,
      disagreeCount: disagreeCount ?? this.disagreeCount,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isIncognito: isIncognito,
      viewerReaction: viewerReaction,
      replies: replies ?? this.replies,
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}