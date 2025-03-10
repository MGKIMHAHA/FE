String getTimeAgo(String dateString) {
  final now = DateTime.now();
  final date = DateTime.parse(dateString);
  final difference = now.difference(date);

  if (difference.inMinutes < 1) {
    return '방금 전';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}분 전';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}시간 전';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}일 전';
  } else {
    // 년도가 다른 경우와 같은 경우를 구분
    if (now.year != date.year) {
      return '${date.year}년 ${date.month}월 ${date.day}일';
    } else {
      return '${date.month}월 ${date.day}일';
    }
  }
}