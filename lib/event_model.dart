class Event {
  final int? id;
  final String title;
  final String location;
  final DateTime date;
  final int? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? authorNickname;

  Event({
    this.id,
    required this.title,
    required this.location,
    required this.date,
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.authorNickname,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing event JSON: $json'); // 디버깅용
      return Event(
        id: json['id'] as int?,
        title: json['title']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        date: DateTime.parse(json['date'].toString()),
        userId: json['user_id'] as int?,  // snake_case로 수정
        createdAt: json['created_at'] != null  // snake_case로 수정
            ? DateTime.parse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null  // snake_case로 수정
            ? DateTime.parse(json['updated_at'].toString())
            : null,
        authorNickname: json['author_nickname']?.toString(),  // 필요한 경우
      );
    } catch (e) {
      print('Error parsing event: $json');
      print('Error details: $e');
      rethrow;
    }
  }
}