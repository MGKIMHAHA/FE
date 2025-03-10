import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'utils/user_preferences.dart';
import 'utils/date_formatter.dart';
import 'FreeBoardDetailPage.dart';
import 'ReviewDetailPage.dart';
import 'JobDetailPage.dart';
import 'post_options_menu.dart';
import 'BoardType.dart';
import 'package:eventers/EventGroupBoardDetailPage.dart';

/// 앱 전체에서 사용할 통일된 색상 테마를 정의하는 클래스
class AppTheme {
  // 이벤트 커넥트 스타일로 색상 변경
  static const Color primaryColor = Color(0xFF5D6BFF);  // 메인 파란색
  static const Color backgroundColor = Color(0xFFF8F9FA);  // 배경색
  static const Color textColor = Color(0xFF212529);  // 텍스트 색상
  static const Color secondaryTextColor = Color(0xFFADB5BD);  // 보조 텍스트 색상
  static const Color dividerColor = Color(0xFFE9ECEF);  // 구분선 색상

  // 게시판 태그 색상
  static const Color freeboardColor = Color(0xFF5D6BFF);  // 파란색
  static const Color reviewColor = Color(0xFF36B37E);     // 초록색
  static const Color jobColor = Color(0xFFFF8A5D);        // 주황색
  static const Color eventGroupColor = Color(0xFFFF6B6B); // 빨간색
  static const Color likeColor = Color(0xFFE74C3C);       // 좋아요 표시용 빨간색
}

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  List<Map<String, dynamic>> _myPosts = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _filteredPosts = []; // 필터링된 게시글 목록
  String _currentFilter = '전체'; // 현재 선택된 필터
  final List<String> _filterCategories = ['전체', '자유', '후기', '행사팟', '구인'];

  @override
  void initState() {
    super.initState();
    _loadMyPosts();
  }

  Future<void> _loadMyPosts() async {
    try {
      setState(() => _isLoading = true);

      final userId = await UserPreferences.getUserId();
      final allPosts = await ApiService.getAllMyPosts(userId);

      setState(() {
        _myPosts = allPosts;
        _applyFilter(_currentFilter); // 필터 적용
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading my posts: $e');
      setState(() {
        _myPosts = [];
        _filteredPosts = [];
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게시글을 불러오는데 실패했습니다'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // 필터 적용 메서드
  void _applyFilter(String filter) {
    setState(() {
      _currentFilter = filter;

      if (filter == '전체') {
        _filteredPosts = _myPosts;
      } else {
        String postType;
        switch (filter) {
          case '자유':
            postType = 'freeboard';
            break;
          case '후기':
            postType = 'review';
            break;
          case '행사팟':
            postType = 'event_group';
            break;
          case '구인':
            postType = 'job';
            break;
          default:
            postType = '';
        }

        _filteredPosts = _myPosts.where((post) => post['type'] == postType).toList();
      }
    });
  }

  // 게시판 타입별 색상 설정
  Color _getBoardColor(String type) {
    switch (type) {
      case 'freeboard':
        return AppTheme.freeboardColor;
      case 'review':
        return AppTheme.reviewColor;
      case 'job':
        return AppTheme.jobColor;
      case 'event_group':
        return AppTheme.eventGroupColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  BoardType _getBoardType(String type) {
    switch (type) {
      case 'freeboard':
        return BoardType.freeboard;
      case 'review':
        return BoardType.review;
      case 'job':
        return BoardType.job;
      case 'event_group':
        return BoardType.eventGroup;
      default:
        return BoardType.freeboard;
    }
  }

  String _getBoardName(String type) {
    switch (type) {
      case 'freeboard':
        return '자유';
      case 'review':
        return '후기';
      case 'job':
        return '구인';
      case 'event_group':
        return '행사팟';
      default:
        return '게시글';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '작성한 게시글이 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새로운 게시글을 작성해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 게시글 아이템 위젯
  Widget _buildPostItem(Map<String, dynamic> post) {
    String category = _getBoardName(post['type']);
    Color categoryColor = _getBoardColor(post['type']);
    String timeAgo = getTimeAgo(post['createdAt']);
    String preview = post['content'] ?? '(내용 없음)';
    String title = post['title'] ?? '(제목 없음)';

    void navigateToDetail() {
      switch (post['type']) {
        case 'freeboard':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FreeBoardDetailPage(postId: post['id']),
            ),
          ).then((_) => _loadMyPosts());
          break;
        case 'review':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewDetailPage(post: post),
            ),
          ).then((_) => _loadMyPosts());
          break;
        case 'job':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailPage(post: post),
            ),
          ).then((_) => _loadMyPosts());
          break;
        case 'event_group':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventGroupBoardDetailPage(postId: post['id']),
            ),
          ).then((_) => _loadMyPosts());
          break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: InkWell(
        onTap: navigateToDetail,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 정보: 카테고리 태그, 시간, 옵션 메뉴
              Row(
                children: [
                  // 카테고리 태그
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 시간
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: AppTheme.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  // 옵션 메뉴
                  PostOptionsMenu(
                    post: post,
                    onPostDeleted: () {
                      setState(() {
                        _myPosts.removeWhere((p) => p['id'] == post['id'] && p['type'] == post['type']);
                        _applyFilter(_currentFilter);
                      });
                    },
                    onPostUpdated: () {
                      _loadMyPosts();
                    },
                    boardType: _getBoardType(post['type']),
                  ),
                ],
              ),

              // 제목
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // 내용
              const SizedBox(height: 4),
              Text(
                preview,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // 하단 정보: 조회수, 좋아요 수, 댓글 수
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 14,
                    color: AppTheme.secondaryTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post['viewCount'] ?? 0}',
                    style: TextStyle(
                      color: AppTheme.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Icon(
                    Icons.favorite_border,
                    size: 14,
                    color: AppTheme.secondaryTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post['likeCount'] ?? 0}',
                    style: TextStyle(
                      color: AppTheme.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Icon(
                    Icons.chat_bubble_outline,
                    size: 14,
                    color: AppTheme.secondaryTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post['commentCount'] ?? 0}',
                    style: TextStyle(
                      color: AppTheme.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          '내가 쓴 글',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.black87,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadMyPosts,
          ),
        ],
      ),
      body: Column(
        children: [
          // 카테고리 탭 바 - 꽉 채우기 위해 Row로 변경
          Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppTheme.dividerColor),
              ),
            ),
            child: Row(
              children: _filterCategories.map((filter) {
                final isSelected = filter == _currentFilter;
                // 동적 너비 계산 (전체 화면 너비를 카테고리 개수로 나눔)
                final width = MediaQuery.of(context).size.width / _filterCategories.length;

                return GestureDetector(
                  onTap: () => _applyFilter(filter),
                  child: Container(
                    width: width,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.black  : Colors.black54,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 게시글 목록
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
                : _filteredPosts.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _loadMyPosts,
              color: AppTheme.primaryColor,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: _filteredPosts.length,
                itemBuilder: (context, index) {
                  return _buildPostItem(_filteredPosts[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}