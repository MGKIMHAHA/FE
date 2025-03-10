import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import '../utils/user_preferences.dart';
import 'my_posts_page.dart';
import 'agency_verification_page.dart';
import 'agency_approval_page.dart';
import 'notice_page.dart';
import 'contact_developer_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eventers/ReportManagementScreen.dart';


/// 앱 전체에서 사용할 통일된 색상 테마를 재사용
class AppTheme {
  // 이벤트 커넥트 스타일로 색상 변경
  static const Color primaryColor = Color(0xFF5D6BFF);  // 메인 파란색
  static const Color backgroundColor = Color(0xFFF8F9FA);  // 배경색
  static const Color textColor = Color(0xFF212529);  // 텍스트 색상
  static const Color secondaryTextColor = Color(0xFFADB5BD);  // 보조 텍스트 색상
  static const Color dividerColor = Color(0xFFE9ECEF);  // 구분선 색상
  static const Color likeColor = Color(0xFFFF3B30);  // 좋아요 빨간색

  // 각 기능별 태그 색상
  static const Color freeTagColor = Color(0xFF5D6BFF);  // 자유 태그 색상 (파란색)
  static const Color reviewTagColor = Color(0xFF36B37E);  // 후기 태그 색상 (초록색)
  static const Color recruitTagColor = Color(0xFFFF8A5D);  // 구인 태그 색상 (주황색)
  static const Color partyTagColor = Color(0xFFFF6B6B);  // 파티원 구함 태그 색상 (빨간색)
  static const Color warningColor = Color(0xFFFF3B30);  // 경고 색상 (빨간색)
}

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Map<String, dynamic> _userProfile = {
    'email': '',
    'nickname': '',
    'user_type': 'normal',
    'agency_status': null,
    'role': '',
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _loadUserProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    print('========= MyPage _loadUserProfile 시작 =========');
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw Exception('로그인된 사용자 정보가 없습니다.');
      }

      print('Current user email: ${currentUser.email}');

      final userData = await supabase
          .from('users')
          .select('email, nickname, user_type, id, agency_status, role')
          .eq('email', currentUser.email!)
          .single();

      print('Fetched user data: $userData');

      if (userData != null) {
        setState(() {
          _userProfile = {
            'email': userData['email'] ?? 'No email',
            'nickname': userData['nickname'] ?? '사용자',
            'user_type': userData['user_type']?.toLowerCase() ?? 'normal',
            'agency_status': userData['agency_status'],
            'role': userData['role'] ?? 'USER',
          };
          _isLoading = false;
          _animationController.forward();
        });
      }

      print('업데이트된 _userProfile: $_userProfile');

    } catch (error) {
      print('프로필 로드 에러: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필을 불러오는데 실패했습니다.'),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
    print('========= MyPage _loadUserProfile 종료 =========');
  }

  Future<void> _handleLogout() async {
    try {
      await supabase.auth.signOut();
      await UserPreferences.clearUserData();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 중 오류가 발생했습니다.'),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // 로딩 중 UI
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 카드 쉬머
            Container(
              margin: const EdgeInsets.all(16),
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),

            // 섹션 제목 쉬머
            Container(
              margin: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
              height: 20,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // 메뉴 아이템 쉬머
            for (int i = 0; i < 3; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

            // 두 번째 섹션 제목 쉬머
            Container(
              margin: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
              height: 20,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // 추가 메뉴 아이템 쉬머
            for (int i = 0; i < 2; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

            // 로그아웃 버튼 쉬머
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 빈 상태 UI (프로필 로드 실패)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            '프로필을 불러올 수 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '다시 시도해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _animationController.reset();
              });
              _loadUserProfile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('새로고침'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgencyMenuItem() {
    if (_userProfile['user_type']?.toLowerCase() != 'normal') {
      return const SizedBox.shrink();
    }

    switch (_userProfile['agency_status']) {
      case 'pending':
        return _buildMenuCard(
          icon: Icons.business,
          iconColor: AppTheme.recruitTagColor,
          title: '에이전시 승인 심사중',
          subtitle: '승인까지 최대 24시간이 소요될 수 있습니다',
          trailing: Icon(Icons.hourglass_empty, color: AppTheme.recruitTagColor),
          onTap: null,
        );
      case 'approved':
        return const SizedBox.shrink();
      default:
        return _buildMenuCard(
          icon: Icons.business,
          iconColor: AppTheme.primaryColor,
          title: '에이전시 추가인증',
          subtitle: '에이전시로 활동하기 위한 인증을 진행합니다',
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AgencyVerificationPage(),
              ),
            ).then((_) => _loadUserProfile());
          },
        );
    }
  }

  Widget _buildManagerMenu() {
    if (_userProfile['role'] != 'MANAGER') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          width: double.infinity,
          color: AppTheme.backgroundColor,
          child: Text(
            '관리자 메뉴',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        _buildMenuCard(
          icon: Icons.admin_panel_settings,
          iconColor: AppTheme.reviewTagColor,
          title: '에이전시 승인 관리',
          subtitle: '에이전시 신청을 승인하거나 거절합니다',
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AgencyApprovalPage()),
            ).then((_) => _loadUserProfile());
          },
        ),
        _buildMenuCard(
          icon: Icons.report_problem,
          iconColor: AppTheme.warningColor,
          title: '신고 관리',
          subtitle: '사용자 신고를 확인하고 처리합니다',
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportManagementScreen()),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    print('MyPage build 호출됨');
    print('현재 _userProfile 상태: $_userProfile');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '마이페이지',
          style: TextStyle(
            color: AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _loadUserProfile,
        child: _isLoading
            ? _buildShimmerLoading()
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 카드
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 사용자 정보
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _userProfile['nickname'] ?? '사용자',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              if (_userProfile['role'] == 'MANAGER') ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _userProfile['email'] ?? '',
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
              ),

              // 구분선
              Divider(height: 1, thickness: 1, color: AppTheme.dividerColor),

              // 내 활동
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                width: double.infinity,
                color: AppTheme.backgroundColor,
                child: Text(
                  '내 활동',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              _buildMenuCard(
                icon: Icons.article_outlined,
                iconColor: AppTheme.freeTagColor,
                title: '내가 쓴 글',
                subtitle: '작성한 게시글을 확인합니다',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyPostsPage()),
                  );
                },
              ),

              _buildAgencyMenuItem(),

              _buildManagerMenu(),

              // 고객지원
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                width: double.infinity,
                color: AppTheme.backgroundColor,
                child: Text(
                  '고객지원',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              _buildMenuCard(
                icon: Icons.announcement_outlined,
                iconColor: AppTheme.recruitTagColor,
                title: '공지사항',
                subtitle: '중요한 공지사항을 확인합니다',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        '공지사항',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const Text('아직 공지가 없습니다.'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            '확인',
                            style: TextStyle(color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              _buildMenuCard(
                icon: Icons.help_outline,
                iconColor: AppTheme.reviewTagColor,
                title: '개발자에게 문의하기',
                subtitle: '문의사항이나 버그를 신고합니다',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        '개발자 문의',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const SelectableText('이메일주소: kimg3598@naver.com'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            '확인',
                            style: TextStyle(color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),



              // 로그아웃 버튼
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                width: double.infinity,
                color: AppTheme.backgroundColor,
                child: Text(
                  '계정',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              _buildMenuCard(
                icon: Icons.logout,
                iconColor: AppTheme.warningColor,
                title: '로그아웃',
                subtitle: '계정에서 로그아웃합니다',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: _handleLogout,
              ),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}