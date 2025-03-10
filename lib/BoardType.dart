enum BoardType {
  freeboard,
  review,
  notice,
  eventGroup,
  job;

  String get value {
    if (this == BoardType.eventGroup) {
      return 'event_group';  // snake_case로 변환
    }
    return toString().split('.').last.toLowerCase();
  }
}