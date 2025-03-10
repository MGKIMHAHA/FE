


class Report {
  final int reporterId;
  final String boardType;
  final int targetId;
  final String reason;
  final String status;
  final String? description;  // 추가

  Report({
    required this.reporterId,
    required this.boardType,
    required this.targetId,
    required this.reason,
    this.description,  // 추가
    this.status = 'pending',  // 기본값 설정
  });


  Map<String, dynamic> toJson() => {
    'reporter_id': reporterId,    // snake_case로 변경
    'board_type': boardType,      // snake_case로 변경
    'target_id': targetId,        // snake_case로 변경
    'reason': reason,
    'status': status,
    'description': description,  // 추가
  };


  factory Report.fromJson(Map<String, dynamic> json) => Report(
    reporterId: json['reporter_id'],    // snake_case로 변경
    boardType: json['board_type'],      // snake_case로 변경
    targetId: json['target_id'],        // snake_case로 변경
    reason: json['reason'],
    status: json['status'],
    description: json['description'],  // 추가
  );
}

// // 게시판 타입 enum
// enum BoardType {
//   freeboard,
//   review,
//   job;
//
//   String get value => toString().split('.').last;
// }

enum ReportReason {
  inappropriate('부적절한 내용'),
  spam('스팸'),
  hate('혐오 발언'),
  other('기타');

  final String label;
  const ReportReason(this.label);

  String get value => toString().split('.').last;
}