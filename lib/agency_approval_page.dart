import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 앱 전체에서 사용할 통일된 색상 테마를 정의하는 클래스
class AppTheme {
  // 기본 테마 색상 - 앱 전체적으로 통일
  static const Color primaryColor = Color(0xFF0969F1);  // 인기 게시글용 파란색
  static const Color primaryColorDark = Color(0xFF0653B6);  // 진한 파란색
  static const Color backgroundColor = Color(0xFFF8FAFF);  // 살짝 푸른 흰색 배경

  // 각 게시판 태그 색상 (게시글 유형 구분용)
  static const Color freeboardColor = Color(0xFF4A90E2);  // 자유게시판용 파란색 (인기 게시글과 구분)
  static const Color reviewColor = Color(0xFF70AD47);     // 부드러운 초록색
  static const Color jobColor = Color(0xFFED7D31);        // 부드러운 주황색
  static const Color hotColor = Color(0xFFE74C3C);        // 인기글 표시용 빨간색
  static const Color defaultColor = Color(0xFF7F7F7F);    // 중간 톤 회색
  static const Color textColor = Color(0xFF212121);       // 닉네임용 검은색
  static const Color titleColor = Color(0xFF303030);      // 제목용 진한 회색
  static const Color contentColor = Color(0xFF505050);    // 내용용 중간 회색
  static const Color likeColor = Color(0xFFE74C3C);       // 좋아요 표시용 빨간색
  static const Color successColor = Color(0xFF4CAF50);    // 성공 표시용 녹색
  static const Color errorColor = Color(0xFFE53935);      // 에러 표시용 빨간색
}

class AgencyApprovalPage extends StatefulWidget {
  const AgencyApprovalPage({super.key});

  @override
  State<AgencyApprovalPage> createState() => _AgencyApprovalPageState();
}

class _AgencyApprovalPageState extends State<AgencyApprovalPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  List<Map<String, dynamic>> _pendingAgencies = [];
  bool _hasManagerAccess = false;

  @override
  void initState() {
    super.initState();
    _checkManagerAccess();
  }

  Future<void> _checkManagerAccess() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      final userData = await supabase
          .from('users')
          .select('role')
          .eq('email', user.email!)
          .single();

      if (userData['role'] != 'MANAGER') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('접근 권한이 없습니다'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      setState(() {
        _hasManagerAccess = true;
      });
      _loadPendingAgencies();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('에러가 발생했습니다: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }
  Future<void> _loadPendingAgencies() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('agency_status', 'pending')
          .order('updated_at', ascending: false);

      setState(() {
        _pendingAgencies = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('에러가 발생했습니다: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleApproval(Map<String, dynamic> agency, bool isApproved) async {
    try {
      final status = isApproved ? 'approved' : 'rejected';

      await supabase
          .from('users')
          .update({
        'agency_status': status,
        'user_type': isApproved ? 'agency' : 'normal',
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', agency['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApproved ? '승인되었습니다' : '거절되었습니다'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            backgroundColor: isApproved ? AppTheme.successColor : AppTheme.errorColor,
          ),
        );
        _loadPendingAgencies(); // 목록 새로고침
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('처리 중 오류가 발생했습니다: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasManagerAccess) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
        title: const Text(
        '에이전시 승인 관리',
        style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black,
    ),
    ),
    backgroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    iconTheme: const IconThemeData(color: Colors.black),
    ),
        body: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                '에이전시 정보를 불러오는 중...',
                style: TextStyle(
                  color: AppTheme.contentColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        )
            : _pendingAgencies.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business_center_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                '승인 대기 중인 에이전시가 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '새로운 에이전시 신청이 들어오면 여기에 표시됩니다',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
            : ListView.builder(
        padding: const EdgeInsets.all(16),
    itemCount: _pendingAgencies.length,
    itemBuilder: (context, index) {
    final agency = _pendingAgencies[index];
    return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 10,
    offset: const Offset(0, 2),
    ),
    ],
    ),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // 헤더 부분
    Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
    color: AppTheme.primaryColor.withOpacity(0.05),
    borderRadius: const BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
    ),
    ),
    child: Row(
    children: [
    CircleAvatar(
    radius: 20,
    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
    child: Text(
    (agency['nickname'] ?? '?')[0].toUpperCase(),
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppTheme.primaryColor,
    ),
    ),
    ),
    const SizedBox(width: 12),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    agency['nickname'] ?? '이름 없음',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppTheme.titleColor,
    ),
    ),
    const SizedBox(height: 4),
    Text(
    agency['email'] ?? '이메일 없음',
    style: TextStyle(
    fontSize: 14,
    color: AppTheme.contentColor,
    ),
    ),
    ],
    ),
    ),
    Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
    color: AppTheme.primaryColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
    '승인 대기',
    style: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppTheme.primaryColor,
    ),
    ),
    ),
    ],
    ),
    ),
    // 사업자등록증 부분
    if (agency['business_license_url'] != null)
    Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    '사업자등록증',
    style: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppTheme.titleColor,
    ),
    ),
    const SizedBox(height: 8),
    GestureDetector(
    onTap: () {
    // 이미지 상세보기 다이얼로그
    showDialog(
    context: context,
    builder: (context) => Dialog(
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    ClipRRect(
    borderRadius: const BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
    ),
    child: Image.network(
    agency['business_license_url'],
    fit: BoxFit.cover,
    loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Container(
    height: 300,
    width: double.infinity,
    alignment: Alignment.center,
    child: CircularProgressIndicator(
    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
    value: loadingProgress.expectedTotalBytes != null
    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
        : null,
    ),
    );
    },
    ),
    ),
    Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    TextButton(
    onPressed: () => Navigator.pop(context),
    style: TextButton.styleFrom(
    backgroundColor: Colors.grey.shade200,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
    child: Text(
    '닫기',
    style: TextStyle(
    color: AppTheme.contentColor,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    ],
    ),
    ),
    ],
    ),
    ),
    );
    },
    child: Container(
    padding: const EdgeInsets.all(12),
    width: double.infinity,
    decoration: BoxDecoration(
    color: Colors.grey.shade50,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Icon(
    Icons.description_outlined,
    size: 20,
    color: AppTheme.primaryColor,
    ),
    const SizedBox(width: 8),
    Text(
    '사업자등록증 확인하기',
    style: TextStyle(
    color: AppTheme.primaryColor,
    fontWeight: FontWeight.w600,
    ),
    ),
    ],
    ),
    ),
    ),
    ],
    ),
    ),
      // 승인/거부 버튼
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleApproval(agency, false),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.close,
                      size: 18,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '거부',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleApproval(agency, true),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '승인',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
    ),
    );
    },
        ),
    );
  }
}