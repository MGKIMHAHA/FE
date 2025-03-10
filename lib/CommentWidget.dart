import 'package:flutter/material.dart';
import 'package:eventers/Comment.dart';
import 'BoardType.dart';
import 'utils/user_preferences.dart';
import 'CommentReportPage.dart';
import 'services/api_service.dart';

/// 앱 전체에서 사용할 통일된 색상 테마를 정의하는 클래스
class AppTheme {
  // 기본 테마 색상 - 앱 전체적으로 통일
  static const Color primaryColor = Color(0xFF5D6BFF);  // 메인 파란색
  static const Color primaryColorDark = Color(0xFF0653B6);  // 진한 파란색
  static const Color backgroundColor = Color(0xFFF8F9FA);  // 배경색

  // 각 기능별 태그 색상
  static const Color freeboardColor = Color(0xFF4A90E2);   // 자유게시판용 파란색
  static const Color reviewColor = Color(0xFF70AD47);      // 부드러운 초록색
  static const Color jobColor = Color(0xFFED7D31);         // 부드러운 주황색
  static const Color hotColor = Color(0xFFE74C3C);         // 인기글 표시용 빨간색
  static const Color defaultColor = Color(0xFF7F7F7F);     // 중간 톤 회색
  static const Color textColor = Color(0xFF212121);        // 닉네임용 검은색
  static const Color titleColor = Color(0xFF303030);       // 제목용 진한 회색
  static const Color contentColor = Color(0xFF505050);     // 내용용 중간 회색
  static const Color warningColor = Color(0xFFE74C3C);     // 경고 색상
  static const Color eventGroupColor = Color(0xFF9C27B0);

  // 텍스트 스타일
  static TextStyle get nicknameStyle => TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: Colors.black,
    letterSpacing: -0.2,
    fontFamily: 'Pretendard',
  );

  static TextStyle get smallNicknameStyle => TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 13,
    color: Colors.black,
    letterSpacing: -0.2,
    fontFamily: 'Pretendard',
  );

  static TextStyle get contentStyle => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
    letterSpacing: -0.1,
    height: 1.5,
    fontFamily: 'Pretendard',
  );

  static TextStyle get smallContentStyle => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
    letterSpacing: -0.1,
    height: 1.4,
    fontFamily: 'Pretendard',
  );

  static TextStyle get timeStyle => TextStyle(
    color: Colors.black54,
    fontSize: 11,
    fontFamily: 'Pretendard',
  );

  static TextStyle get actionStyle => TextStyle(
    color: Colors.black54,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: 'Pretendard',
  );
}

class CommentWidget extends StatefulWidget {
  final Comment comment;
  final List<Comment> replies;
  final Function(Comment, String, BoardType) onReply;
  final BoardType boardType;
  final Function(Comment)? onDelete;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.replies,
    required this.onReply,
    required this.boardType,
    this.onDelete,
  });

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> with SingleTickerProviderStateMixin {
  bool _isReplyVisible = false;
  final _replyController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _toggleReply() {
    setState(() {
      _isReplyVisible = !_isReplyVisible;
      if (_isReplyVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 본 댓글
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 사용자 아바타
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 작성자 및 시간
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.comment.author,
                            style: AppTheme.smallNicknameStyle,
                          ),
                          if (widget.comment.authorRole == 'MANAGER') ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        widget.comment.timeAgo,
                        style: AppTheme.timeStyle,
                      ),
                    ],
                  ),

                  const Spacer(),

                  // 메뉴 버튼
                  IconButton(
                    icon: Icon(
                        Icons.more_horiz,
                        size: 18,
                        color: Colors.black54
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showOptionsMenu(context),
                  ),
                ],
              ),

              // 댓글 내용
              Padding(
                padding: const EdgeInsets.only(left: 36, top: 8, bottom: 8),
                child: Text(
                  widget.comment.content,
                  style: AppTheme.smallContentStyle,
                ),
              ),

              // 답글 버튼
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: InkWell(
                  onTap: _toggleReply,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isReplyVisible ? Icons.close : Icons.reply,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isReplyVisible ? '답글 취소' : '답글',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 대댓글 목록 표시
        if (widget.comment.replies.isNotEmpty) ...[
          ...widget.comment.replies.map((reply) => Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.only(
              left: 38.0,
              right: 16.0,
              top: 12.0,
              bottom: 12.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 8.0, top: 2.0),
                  child: Icon(
                    Icons.subdirectory_arrow_right,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // 대댓글 작성자 아바타
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 대댓글 작성자 및 시간
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    reply.author,
                                    style: AppTheme.smallNicknameStyle,
                                  ),
                                  if (reply.authorRole == 'MANAGER') ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.verified,
                                      size: 14,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                reply.timeAgo,
                                style: AppTheme.timeStyle,
                              ),
                            ],
                          ),

                          const Spacer(),

                          // 대댓글 메뉴 버튼
                          IconButton(
                            icon: Icon(
                              Icons.more_horiz,
                              size: 18,
                              color: Colors.black54,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _showOptionsMenu(context, reply),
                          ),
                        ],
                      ),

                      // 대댓글 내용
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 8),
                        child: Text(
                          reply.content,
                          style: AppTheme.smallContentStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ],

        // 답글 입력창
        if (_isReplyVisible)
          SizeTransition(
            sizeFactor: _animation,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
              ),
              padding: const EdgeInsets.only(
                left: 38.0,
                right: 16.0,
                top: 12.0,
                bottom: 12.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8.0, top: 2.0),
                    child: Icon(
                      Icons.subdirectory_arrow_right,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyController,
                              style: AppTheme.smallContentStyle,
                              decoration: InputDecoration(
                                hintText: '답글을 입력하세요.',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: TextButton(
                              onPressed: () {
                                if (_replyController.text.trim().isNotEmpty) {
                                  widget.onReply(
                                    widget.comment,
                                    _replyController.text,
                                    widget.boardType,
                                  );
                                  _replyController.clear();
                                  _toggleReply();
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                minimumSize: Size.zero,
                                foregroundColor: AppTheme.primaryColor,
                              ),
                              child: Text(
                                '등록',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showOptionsMenu(BuildContext context, [Comment? reply]) async {
    final currentUserId = await UserPreferences.getUserId();

    // 현재 처리할 댓글 (원댓글 또는 대댓글)
    final Comment currentComment = reply ?? widget.comment;

    // isMyComment 체크 부분 수정
    final isMyComment = currentComment.userId != null &&
        currentComment.userId == currentUserId.toString();

    print('=== Comment Widget Data ===');
    print('Comment object: ${currentComment}');
    print('All fields:');
    print('- id: ${currentComment.id}');
    print('- userId: ${currentComment.userId}');
    print('- postId: ${currentComment.postId}');
    print('- content: ${currentComment.content}');
    print('- author: ${currentComment.author}');
    print('- boardType: ${currentComment.boardType}');
    print('========================');

    print('현재 사용자 ID: $currentUserId');
    print('댓글 작성자 ID: ${currentComment.userId}');
    print('isMyComment: $isMyComment');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 바텀시트 헤더
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              if (isMyComment) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.delete_outline, color: AppTheme.warningColor, size: 20),
                  ),
                  title: Text(
                    '삭제',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    '이 댓글을 삭제합니다',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);

                    try {
                      if (reply != null) {
                        // 대댓글 삭제
                        print('Deleting reply: ${reply.id}');
                        await ApiService.deleteComment(
                          commentId: int.parse(reply.id),
                          userId: currentUserId,
                          boardType: widget.boardType,
                        );

                        if (context.mounted) {
                          // 대댓글만 삭제
                          widget.onDelete?.call(reply);
                        }
                      } else {
                        // 원댓글 삭제
                        print('Deleting parent comment: ${widget.comment.id}');
                        await ApiService.deleteComment(
                          commentId: int.parse(widget.comment.id),
                          userId: currentUserId,
                          boardType: widget.boardType,
                        );

                        if (context.mounted) {
                          // 원댓글과 대댓글 모두 삭제
                          widget.onDelete?.call(widget.comment);
                          for (var replyComment in widget.replies) {
                            widget.onDelete?.call(replyComment);
                          }
                        }
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('댓글이 삭제되었습니다'),
                            duration: Duration(seconds: 2),
                            backgroundColor: Colors.green[600],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('댓글 삭제 실패: $e'),
                            backgroundColor: AppTheme.warningColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],

              // 모든 경우에 신고 버튼 표시 (자신의 댓글이어도 신고 가능)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.freeboardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.report, color: AppTheme.freeboardColor, size: 20),
                ),
                title: Text(
                  '신고',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                subtitle: Text(
                  '부적절한 댓글을 신고합니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);  // 바텀시트 닫기

                  try {
                    final currentUserId = await UserPreferences.getUserId();
                    final targetId = reply?.id ?? widget.comment.id;

                    // 이미 신고한 댓글인지 확인
                    final alreadyReported = await ApiService.checkCommentAlreadyReported(
                      reporterId: currentUserId.toString(),  // int를 String으로 변환
                      commentId: targetId,
                    );

                    if (alreadyReported) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('이미 신고한 댓글입니다'),
                            duration: Duration(seconds: 2),
                            backgroundColor: AppTheme.warningColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    // 신고하지 않은 경우 신고 페이지로 이동
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommentReportPage(
                            commentId: int.parse(targetId),
                            boardType: widget.boardType,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('신고 상태 확인 실패: $e'),
                          backgroundColor: AppTheme.warningColor,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),

              // 취소 버튼
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.close, color: Colors.grey[700], size: 20),
                ),
                title: Text(
                  '취소',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}