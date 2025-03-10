import 'package:flutter/material.dart';
import 'WriteReviewPost.dart';
import 'WriteFreeBoardPost.dart';
import 'WriteJobPost.dart';
import '../Report.dart';
import '../utils/user_preferences.dart';
import 'services/api_service.dart';
import 'BoardType.dart';
import 'package:eventers/WriteEventGroupPost.dart';

/// 앱 전체에서 사용할 통일된 색상 테마를 정의하는 클래스
class AppTheme {
  // 기본 테마 색상 - 앱 전체적으로 통일
  static const Color primaryColor = Color(0xFF5D6BFF);  // 메인 파란색
  static const Color primaryColorDark = Color(0xFF0653B6);  // 진한 파란색
  static const Color backgroundColor = Color(0xFFF8F9FA);  // 배경색
  static const Color textColor = Color(0xFF212529);  // 텍스트 색상
  static const Color secondaryTextColor = Color(0xFFADB5BD);  // 보조 텍스트 색상
  static const Color dividerColor = Color(0xFFE9ECEF);  // 구분선 색상
  static const Color likeColor = Colors.red;  // 좋아요 색상

  // 각 게시판 태그 색상 (게시글 유형 구분용)
  static const Color freeboardColor = Color(0xFF41B5F9);  // 자유게시판용 하늘색
  static const Color reviewColor = Color(0xFF70AD47);     // 부드러운 초록색
  static const Color jobColor = Color(0xFFED7D31);        // 부드러운 주황색
  static const Color hotColor = Color(0xFFE74C3C);        // 인기글 표시용 빨간색
  static const Color defaultColor = Color(0xFF7F7F7F);    // 중간 톤 회색
  static const Color titleColor = Color(0xFF303030);      // 제목용 진한 회색
  static const Color contentColor = Color(0xFF505050);    // 내용용 중간 회색
  static const Color warningColor = Color(0xFFE74C3C);    // 경고 색상
  static const Color successColor = Color(0xFF4CAF50);    // 성공 색상
}

class PostOptionsMenu extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onPostDeleted;
  final VoidCallback onPostUpdated;
  final BoardType boardType;

  const PostOptionsMenu({
    Key? key,
    required this.post,
    required this.onPostDeleted,
    required this.onPostUpdated,
    required this.boardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: UserPreferences.getUserId(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final currentUserId = snapshot.data!;
        final postAuthorId = post['authorId'];
        final isAuthor = postAuthorId.toString() == currentUserId.toString();

        print('Debug PostOptionsMenu:');
        print('현재 사용자 ID: $currentUserId');
        print('게시글 작성자 ID: $postAuthorId');
        print('작성자 여부: $isAuthor');

        return IconButton(
          icon: Icon(
            Icons.more_horiz,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) {
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      if (isAuthor) ...[
                        _buildOptionTile(
                          context,
                          icon: Icons.edit_outlined,
                          iconColor: AppTheme.primaryColor,
                          text: '수정하기',
                          onTap: () async {
                            Navigator.pop(context);
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  switch (boardType) {
                                    case BoardType.review:
                                      return WriteReviewPost(
                                        isEditing: true,
                                        post: post,
                                      );
                                    case BoardType.freeboard:
                                      return WriteFreeBoardPost(
                                        isEditing: true,
                                        post: post,
                                      );
                                    case BoardType.eventGroup:
                                      return WriteEventGroupPost(
                                        isEditing: true,
                                        post: post,
                                      );
                                    case BoardType.job:
                                      return WriteJobPost(
                                        isEditing: true,
                                        post: post,
                                      );
                                    default:
                                      return WriteFreeBoardPost(
                                        isEditing: true,
                                        post: post,
                                      );
                                  }
                                },
                              ),
                            );
                            if (result == true) {
                              onPostUpdated();
                            }
                          },
                        ),
                        _buildOptionTile(
                          context,
                          icon: Icons.delete_outline,
                          iconColor: AppTheme.warningColor,
                          text: '삭제하기',
                          onTap: () async {
                            Navigator.pop(context);
                            final confirmed = await _showDeleteConfirmationDialog(context);
                            if (confirmed == true) {
                              await _deletePost(context);
                            }
                          },
                        ),
                      ],
                      if (!isAuthor)
                        _buildOptionTile(
                          context,
                          icon: Icons.report_outlined,
                          iconColor: AppTheme.warningColor,
                          text: '신고하기',
                          onTap: () {
                            Navigator.pop(context);
                            _showReportDialog(context);
                          },
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // 옵션 타일 위젯
  Widget _buildOptionTile(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String text,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        text,
        style: TextStyle(
          color: AppTheme.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  // 게시글 삭제 확인 다이얼로그
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '게시글 삭제',
          style: TextStyle(
            color: AppTheme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          '정말 이 게시글을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
            ),
            child: const Text('삭제'),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // 게시글 삭제 로직
  Future<void> _deletePost(BuildContext context) async {
    try {
      switch (boardType) {
        case BoardType.review:
          await ApiService.deleteReview(post['id']);
          break;
        case BoardType.freeboard:
          await ApiService.deletePost(post['id']);
          break;
        case BoardType.job:
          await ApiService.deleteJob(post['id']);
          break;
        case BoardType.notice:
          break;
        case BoardType.eventGroup:
          await ApiService.deleteEventGroupPost(post['id']);
          break;
      }
      onPostDeleted();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${boardType == BoardType.review ? "리뷰" : boardType == BoardType.job ? "구인글" : "게시글"}이(가) 삭제되었습니다'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    } catch (e) {
      print('Error deleting post: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${boardType == BoardType.review ? "리뷰" : boardType == BoardType.job ? "구인글" : "게시글"} 삭제에 실패했습니다'),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  // 신고 기능을 외부에서 접근할 수 있도록 공개 메서드
  Future<void> showReportDialog(BuildContext context) async {
    return _showReportDialog(context);
  }

  // 신고 다이얼로그
// 신고 다이얼로그
  Future<void> _showReportDialog(BuildContext context) async {
    ReportReason? selectedReason;
    final TextEditingController otherReasonController = TextEditingController();

    // 스캐폴드 메신저 미리 참조
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '게시글 신고',
            style: TextStyle(
              color: AppTheme.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '신고 사유를 선택해주세요',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: ReportReason.values.map(
                          (reason) => _buildReasonTile(reason, selectedReason, (value) {
                        setState(() => selectedReason = value);
                      }),
                    ).toList(),
                  ),
                ),
                if (selectedReason == ReportReason.other) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: otherReasonController,
                    decoration: InputDecoration(
                      labelText: '신고 사유를 입력해주세요',
                      labelStyle: TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
              ),
              child: const Text('신고하기'),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );

    if (result == true && selectedReason != null) {
      try {
        // 신고 처리 중 로딩 표시
        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                ),
                SizedBox(width: 12),
                Text('신고 처리 중...'),
              ],
            ),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );

        final userId = await UserPreferences.getUserId();
        final report = Report(
          reporterId: userId,
          boardType: boardType.value,
          targetId: post['id'],
          reason: selectedReason == ReportReason.other
              ? otherReasonController.text.isNotEmpty
              ? otherReasonController.text
              : '기타 사유'
              : selectedReason?.label ?? '기타',
          description: selectedReason == ReportReason.other ? otherReasonController.text : '',
          status: 'pending',
        );

        print('신고 요청: ${report.toJson()}');
        await ApiService.reportPost(report);
        print('신고 성공');

        // 신고 완료 메시지 표시
        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('신고가 접수되었습니다'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      } catch (e) {
        print('신고 처리 오류: $e');

        final errorMessage = e.toString()
            .replaceAll('Exception: ', '')
            .replaceAll('Failed to report post: 400', '');

        // 오류 메시지 표시
        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.warningColor,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }
  // 신고 사유 라디오 타일 위젯 생성
  Widget _buildReasonTile(
      ReportReason reason,
      ReportReason? selectedReason,
      Function(ReportReason) onChanged,
      ) {
    // 신고 사유별 아이콘과 색상 정의
    IconData icon;
    Color color;

    // 각 ReportReason 값에 대한 아이콘과 색상 설정
    switch (reason) {
      case ReportReason.inappropriate:
        icon = Icons.block;
        color = AppTheme.warningColor;
        break;
      case ReportReason.spam:
        icon = Icons.label_important;
        color = AppTheme.jobColor;
        break;
      case ReportReason.hate:
        icon = Icons.sentiment_very_dissatisfied;
        color = Colors.purple;
        break;
      case ReportReason.other:
        icon = Icons.more_horiz;
        color = AppTheme.defaultColor;
        break;
      default:
        icon = Icons.report;
        color = AppTheme.defaultColor;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(reason),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              // 라디오 버튼
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedReason == reason ? color : Colors.grey[400]!,
                    width: 2,
                  ),
                  color: selectedReason == reason ? color : Colors.transparent,
                ),
                child: selectedReason == reason
                    ? Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                )
                    : null,
              ),
              const SizedBox(width: 12),

              // 아이콘
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),

              // 라벨
              Text(
                reason.label,
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}