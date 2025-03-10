import 'package:flutter/material.dart';
import 'package:eventers/BoardType.dart';
import 'package:eventers/services/api_service.dart';
import 'package:eventers/utils/user_preferences.dart';

/// 앱 전체에서 사용할 통일된 색상 테마를 정의하는 클래스
class AppTheme {
  // 기본 테마 색상 - 앱 전체적으로 통일
  static const Color primaryColor = Color(0xFF0969F1);  // 인기 게시글용 파란색
  static const Color primaryColorDark = Color(0xFF0653B6);  // 진한 파란색
  static const Color backgroundColor = Color(0xFFF8FAFF);  // 살짝 푸른 흰색 배경

  // 각 게시판 태그 색상 (게시글 유형 구분용)
  static const Color freeboardColor = Color(0xFF41B5F9);  // 자유게시판용 하늘색
  static const Color reviewColor = Color(0xFF70AD47);     // 부드러운 초록색
  static const Color jobColor = Color(0xFFED7D31);        // 부드러운 주황색
  static const Color hotColor = Color(0xFFE74C3C);        // 인기글 표시용 빨간색
  static const Color defaultColor = Color(0xFF7F7F7F);    // 중간 톤 회색
  static const Color textColor = Color(0xFF212121);       // 닉네임용 검은색
  static const Color titleColor = Color(0xFF303030);      // 제목용 진한 회색
  static const Color contentColor = Color(0xFF505050);    // 내용용 중간 회색
  static const Color warningColor = Color(0xFFE74C3C);    // 경고 색상
  static const Color successColor = Color(0xFF4CAF50);    // 성공 색상
}

class CommentReportPage extends StatefulWidget {
  final int commentId;
  final BoardType boardType;

  const CommentReportPage({
    Key? key,
    required this.commentId,
    required this.boardType,
  }) : super(key: key);

  @override
  State<CommentReportPage> createState() => _CommentReportPageState();
}

class _CommentReportPageState extends State<CommentReportPage> {
  String? selectedReason;
  final TextEditingController descriptionController = TextEditingController();
  bool _isSubmitting = false;

  // 신고 사유 옵션 정의
  final List<Map<String, dynamic>> reportReasons = [
    {
      'value': 'inappropriate',
      'title': '부적절한 내용',
      'subtitle': '음란물, 불법 정보 등 부적절한 내용을 포함하고 있습니다',
      'icon': Icons.block,
      'color': AppTheme.warningColor,
    },
    {
      'value': 'spam',
      'title': '스팸',
      'subtitle': '광고성 콘텐츠나 도배 등의 스팸 활동입니다',
      'icon': Icons.label_important,
      'color': AppTheme.jobColor,
    },
    {
      'value': 'hate',
      'title': '혐오 발언',
      'subtitle': '차별, 인종, 성별 등에 대한 혐오 발언을 포함하고 있습니다',
      'icon': Icons.sentiment_very_dissatisfied,
      'color': Colors.purple,
    },
    {
      'value': 'other',
      'title': '기타',
      'subtitle': '다른 이유로 신고하고 싶습니다',
      'icon': Icons.more_horiz,
      'color': AppTheme.defaultColor,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '댓글 신고하기',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: AppTheme.primaryColor),
      ),
      body: _buildReportContent(),
    );
  }

  // 신고 화면
  Widget _buildReportContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 안내 카드
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.report_problem_outlined,
                          color: AppTheme.warningColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '신고 사유를 선택해주세요',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.titleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '신고된 댓글은 검토 후 커뮤니티 가이드라인에 위반되는 경우 조치됩니다. 허위 신고는 제재 대상이 될 수 있습니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.contentColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 신고 사유 선택 라디오 버튼
            ...reportReasons.map((reason) => _buildReasonCard(reason)),

            const SizedBox(height: 24),

            // 상세 설명 입력 필드
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '상세 설명 (선택사항)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.titleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.contentColor,
                    ),
                    decoration: InputDecoration(
                      hintText: '신고 사유에 대해 자세히 설명해주세요',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
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
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 신고하기 버튼
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: selectedReason == null || _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  '신고하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 각 신고 사유 카드 위젯
  Widget _buildReasonCard(Map<String, dynamic> reason) {
    final bool isSelected = selectedReason == reason['value'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? reason['color'].withOpacity(0.2)
                : AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedReason = reason['value'];
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 라디오 버튼 및 아이콘
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? reason['color'] : Colors.grey[400]!,
                      width: 2,
                    ),
                    color: isSelected ? reason['color'] : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                      : null,
                ),
                const SizedBox(width: 16),

                // 아이콘
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: reason['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    reason['icon'],
                    color: reason['color'],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),

                // 제목 및 설명
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reason['title'],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reason['subtitle'],
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.contentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 신고 로직
  Future<void> _submitReport() async {
    if (selectedReason == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = await UserPreferences.getUserId();

      final response = await ApiService.createCommentReport(
        reporterId: userId,
        commentId: widget.commentId,
        boardType: widget.boardType,
        reason: selectedReason!,
        description: descriptionController.text,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('신고가 접수되었습니다'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('신고 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }
}