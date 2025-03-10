import 'package:eventers/BoardType.dart';

class Comment {
  final String id;
  final String? postId;    // 옵셔널로 변경
  final String? userId;    // 옵셔널로 변경
  final String content;
  final String author;
  final String authorRole;
  final DateTime createdAt;
  final DateTime? updatedAt;  // 옵셔널로 변경
  final String? parentId;
  final BoardType? boardType;  // 옵셔널로 변경
  final List<Comment> replies;

  Comment({
    required this.id,
    this.postId,          // 옵셔널
    this.userId,          // 옵셔널
    required this.content,
    required this.author,
    this.authorRole = 'USER',
    required this.createdAt,
    this.updatedAt,       // 옵셔널
    this.boardType,       // 옵셔널
    this.parentId,
    List<Comment>? replies,
  }) : replies = replies ?? [];

  factory Comment.fromJson(Map<String, dynamic> json) {
    print('=== Parsing Comment JSON ===');
    print('Input JSON: $json');

    final comment = Comment(
      id: json['id'].toString(),
      postId: json['postId']?.toString(),
      userId: json['userId']?.toString(),  // 여기가 중요
      content: json['content'],
      author: json['nickname'] ?? 'Unknown',
      authorRole: json['role'] ?? 'USER',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      boardType: json['boardType'] != null
          ? BoardType.values.firstWhere(
            (e) => e.toString().split('.').last == json['boardType'],
      )
          : null,
      parentId: json['parentId']?.toString(),
      replies: (json['replies'] as List<dynamic>?)?.map((replyJson) {
        print('=== Parsing Reply JSON ===');
        print('Reply JSON: $replyJson');
        return Comment.fromJson(replyJson);
      }).toList() ?? [],
    );

    print('Parsed Comment: $comment');
    return comment;
  }
// toString 메서드 추가
  @override
  String toString() {
    return 'Comment{id: $id, userId: $userId, postId: $postId, content: $content, author: $author, authorRole: $authorRole, boardType: $boardType}';
  }


  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}