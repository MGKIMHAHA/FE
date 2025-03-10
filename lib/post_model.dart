class Post {
  final String authorName;
  final String content;
  final String title;
  final DateTime createdAt;
  final List<String> hashtags;
  int likes;
  int comments;
  int views;
  final bool isHot;

  Post({
    required this.authorName,
    required this.content,
    required this.title,
    required this.createdAt,
    required this.hashtags,
    this.likes = 0,
    this.comments = 0,
    this.views = 0,
    this.isHot = false,
  });
} 