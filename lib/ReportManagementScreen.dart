import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Report.dart';
import 'BoardType.dart';
import 'FreeBoardDetailPage.dart';
import 'ReviewDetailPage.dart';
import 'JobDetailPage.dart';
import 'EventGroupBoardDetailPage.dart';

/// 앱 전체에서 사용할 통일된 색상 테마를 재사용
class AppTheme {
  static const Color primaryColor = Color(0xFF5D6BFF);  // 메인 파란색
  static const Color backgroundColor = Color(0xFFF8F9FA);  // 배경색
  static const Color textColor = Color(0xFF212529);  // 텍스트 색상
  static const Color secondaryTextColor = Color(0xFFADB5BD);  // 보조 텍스트 색상
  static const Color dividerColor = Color(0xFFE9ECEF);  // 구분선 색상
  static const Color likeColor = Colors.red;  // 좋아요 색상
  static const Color warningColor = Color(0xFFFF3B30);  // 경고 색상
  static const Color successColor = Color(0xFF4CAF50);  // 성공 색상
  static const Color contentColor = Color(0xFF505050);  // 내용용 중간 회색
}

class ReportManagementScreen extends StatefulWidget {
  const ReportManagementScreen({Key? key}) : super(key: key);

  @override
  _ReportManagementScreenState createState() => _ReportManagementScreenState();
}

class _ReportManagementScreenState extends State<ReportManagementScreen> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _checkUserRole();
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  // 탭 변경 시 데이터 새로고침
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  // 사용자 권한 확인
  Future<void> _checkUserRole() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw Exception('로그인된 사용자 정보가 없습니다.');
      }

      final userData = await supabase
          .from('users')
          .select('role')
          .eq('email', currentUser.email!)
          .single();

      setState(() {
        _userRole = userData['role'] ?? 'USER';
      });

      // MANAGER가 아니면 뒤로 가기
      if (_userRole != 'MANAGER') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('관리자 권한이 필요합니다.'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('사용자 권한 확인 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('권한을 확인하는데 실패했습니다.'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  // 신고 목록 불러오기
  Future<void> _loadReports() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // options 메서드 대신 일반 select 쿼리 사용
      final response = await supabase
          .from('reports')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _reports = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      print('Reports loaded: ${_reports.length}');
      _reports.forEach((report) {
        print('Report ID: ${report['id']}, Status: ${report['status']}');
      });
    } catch (e) {
      setState(() {
        _errorMessage = '신고 목록을 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
      print('Error loading reports: $e');
    }
  }

  // 게시글 확인하기
  Future<void> _viewPostDetail(Map<String, dynamic> report) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final boardType = report['board_type'];
      final targetId = report['target_id'];

      // 해당 게시판 테이블에서 게시글 불러오기
      String tableName;
      switch (boardType) {
        case 'review':
          tableName = 'review';
          break;
        case 'freeboard':
          tableName = 'freeboard';
          break;
        case 'job':
          tableName = 'jobs';
          break;
        case 'event_group':
          tableName = 'event_group_posts';
          break;
        default:
          throw Exception('잘못된 게시판 타입입니다');
      }

      final postData = await supabase
          .from(tableName)
          .select('*')
          .eq('id', targetId)
          .maybeSingle();

      if (postData == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('게시글이 존재하지 않습니다'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        return;
      }

      // 작성자 정보도 함께 가져오기
      final authorData = await supabase
          .from('users')
          .select('nickname, role')
          .eq('id', postData['user_id'])
          .single();

      // 게시글 데이터를 완성하기
      final fullPostData = {
        ...postData,
        'authorNickname': authorData['nickname'],
        'authorRole': authorData['role'],
        'authorId': postData['user_id'],
      };

      setState(() {
        _isLoading = false;
      });

      // 게시판 유형별 상세 페이지로 이동
      switch (boardType) {
        case 'freeboard':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FreeBoardDetailPage(
                postId: targetId,
                initialLikeStatus: false,
              ),
            ),
          );
          break;
        case 'review':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewDetailPage(
                post: fullPostData,
              ),
            ),
          );
          break;
        case 'job':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailPage(
                post: fullPostData,
              ),
            ),
          );
          break;
        case 'event_group':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventGroupBoardDetailPage(
                postId: targetId,
                initialLikeStatus: false,
              ),
            ),
          );
          break;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('게시글을 불러오는 중 오류가 발생했습니다: $e'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      print('Error loading post detail: $e');
    }
  }

  // 신고 처리 함수
  Future<void> _processReport(Map<String, dynamic> report, String newStatus) async {
    try {
      // 로딩 표시
      setState(() {
        _isLoading = true;
      });

      // 신고 ID 확인
      final reportId = report['id'];
      if (reportId == null) {
        throw Exception('신고 ID가 없습니다');
      }

      // 상태값 확인 및 수정 (approved -> processed)
      if (newStatus == 'approved') {
        newStatus = 'processed'; // enum에 맞게 값 변경
      }

      print('Processing report: $reportId to status: $newStatus');
      print('Report data: $report');

      // 처리 중임을 표시하는 로딩 인디케이터
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('처리 중...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

// RPC 함수를 사용하여 enum 타입 변환 처리
      await supabase.rpc('update_report_status', params: {
        'p_report_id': reportId,
        'p_new_status': newStatus,
      });

      print('Report status updated to: $newStatus');

      // 승인된 신고의 경우 게시글도 함께 삭제
      if (newStatus == 'processed') {
        try {
          String tableName;
          switch (report['board_type']) {
            case 'review':
              tableName = 'review';
              break;
            case 'freeboard':
              tableName = 'freeboard';
              break;
            case 'job':
              tableName = 'jobs';
              break;
            case 'event_group':
              tableName = 'event_group_posts';
              break;
            default:
              throw Exception('잘못된 게시판 타입입니다');
          }

          await supabase
              .from(tableName)
              .delete()
              .eq('id', report['target_id']);

          print('신고된 게시글 삭제 완료: ${report['target_id']}');
        } catch (e) {
          print('신고된 게시글 삭제 실패: $e');
        }
      }

      // 직접 확인을 위해 업데이트된 신고 데이터 조회
      final updatedReport = await supabase
          .from('reports')
          .select('*')
          .eq('id', reportId)
          .single();

      print('직접 확인한 업데이트된 신고 상태: ${updatedReport['status']}');

      // 목록 새로고침
      await _loadReports();

      // 로딩 상태 해제
      setState(() {
        _isLoading = false;
      });

      // 피드백 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'processed'
                ? '신고가 승인되었습니다. 게시글이 삭제되었습니다.'
                : '신고가 거부되었습니다.'),
            backgroundColor: newStatus == 'processed'
                ? AppTheme.successColor
                : AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      print('Error processing report: $e');

      // 오류 발생 시 로딩 상태 해제
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('신고 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    }
  }
  // 게시판 타입에 따른 이름 반환
  String _getBoardTypeName(String boardType) {
    switch (boardType) {
      case 'review':
        return '리뷰';
      case 'freeboard':
        return '자유게시판';
      case 'job':
        return '구인구직';
      case 'event_group':
        return '행사팟 구함';
      default:
        return '기타';
    }
  }

  // 신고 상태에 따른 배지 색상 반환
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
      case 'processed': // processed 상태 추가
        return AppTheme.successColor;
      case 'rejected':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  // 신고 상태에 따른 한글 텍스트 반환
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '처리 대기';
      case 'approved':
      case 'processed': // processed 상태 추가
        return '승인됨';
      case 'rejected':
        return '거부됨';
      default:
        return '알 수 없음';
    }
  }
  // 필터링된 신고 목록 가져오기
  List<Map<String, dynamic>> _getFilteredReports() {
    final currentTab = _tabController.index;

    if (currentTab == 0) {
      return _reports; // 전체 보기
    } else if (currentTab == 1) {
      return _reports.where((report) => report['status'] == 'pending').toList(); // 처리 대기 목록
    } else {
      // 'processed' 상태 추가
      return _reports.where((report) =>
      report['status'] == 'approved' ||
          report['status'] == 'rejected' ||
          report['status'] == 'processed'
      ).toList(); // 처리 완료 목록
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _getFilteredReports();

    return Scaffold(
        appBar: AppBar(
        title: const Text('신고 관리', style: TextStyle(fontWeight: FontWeight.bold)),
    centerTitle: true,
    backgroundColor: Colors.white,
    foregroundColor: AppTheme.textColor,
    elevation: 0.5,
    actions: [
    // 새로고침 버튼 추가
    IconButton(
    icon: Icon(Icons.refresh),
    onPressed: _loadReports,
    tooltip: '새로고침',
    ),
    ],
    bottom: TabBar(
    controller: _tabController,
    labelColor: AppTheme.primaryColor,
    unselectedLabelColor: AppTheme.secondaryTextColor,
    indicatorColor: AppTheme.primaryColor,
    onTap: (_) => setState(() {}), // 탭 변경 시 UI 갱신
    tabs: const [
    Tab(text: '전체'),
    Tab(text: '처리 대기'),
    Tab(text: '처리 완료'),
    ],
    ),
    ),
    body: _isLoading
    ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
    ? Center(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Text(_errorMessage, style: const TextStyle(color: AppTheme.warningColor)),
    const SizedBox(height: 16),
    ElevatedButton(
    onPressed: _loadReports,
    child: const Text('다시 시도'),
    ),
    ],
    ),
    )
        : filteredReports.isEmpty
    ? Center(
    child: Text(
    '신고 내역이 없습니다',
    style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 16),
    ),
    )
        : RefreshIndicator(
    onRefresh: _loadReports,
    child: ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: filteredReports.length,
    separatorBuilder: (context, index) => const SizedBox(height: 12),
    itemBuilder: (context, index) {
    final report = filteredReports[index];
    final isPending = report['status'] == 'pending';

    return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
    color: _getStatusColor(report['status']).withOpacity(0.1),
    borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
    _getStatusText(report['status']),
    style: TextStyle(
    color: _getStatusColor(report['status']),
    fontSize: 12,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    const SizedBox(width: 8),
    Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
    color: AppTheme.primaryColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
    _getBoardTypeName(report['board_type']),
    style: const TextStyle(
    color: AppTheme.primaryColor,
    fontSize: 12,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    ],
    ),
    const SizedBox(height: 12),
    Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    '신고 사유: ${report['reason']}',
    style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppTheme.textColor,
    ),
    ),
    if (report['description'] != null && report['description'] != '') ...[
    const SizedBox(height: 8),
    Text(
    '상세 설명: ${report['description']}',
    style: const TextStyle(
    fontSize: 14,
    color: AppTheme.contentColor,
    ),
    ),
    ],
    const SizedBox(height: 8),
    Text(
    '신고자 ID: ${report['reporter_id']}',
    style: TextStyle(
    fontSize: 14,
    color: AppTheme.secondaryTextColor,
    ),
    ),
    Text(
    '대상 게시글 ID: ${report['target_id']}',
    style: TextStyle(
    fontSize: 14,
    color: AppTheme.secondaryTextColor,
    ),
    ),
    ],
    ),
    ),
    ],
    ),
    const SizedBox(height: 16),

    // 버튼 영역
    Column(
    children: [
    // 게시글 확인하기 버튼
    SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: (report['status'] == 'approved' || report['status'] == 'processed')
          ? null // 승인된 경우 게시글이 삭제되었으므로 비활성화
          : () => _viewPostDetail(report),
    icon: const Icon(Icons.visibility, size: 18),
    label: const Text('작성글 확인하기'),
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blueGrey[100],
    foregroundColor: Colors.blueGrey[800],
    disabledBackgroundColor: Colors.grey[300],
    disabledForegroundColor: Colors.grey[500],
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    ),
    ),
    ),
    ),

      // 처리 버튼들 (대기 상태인 경우에만 표시)
      if (isPending) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _processReport(report, 'rejected'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('거부하기'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _processReport(report, 'approved'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('승인 및 삭제'),
              ),
            ),
          ],
        ),
      ],
    ],
    ),
    ],
    ),
    ),
    );
    },
    ),
    ),
    );
  }
}