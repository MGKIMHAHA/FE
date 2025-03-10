import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'FreeBoardDetailPage.dart';
import 'ReviewDetailPage.dart';
import 'JobDetailPage.dart';
import 'EventGroupBoardDetailPage.dart';
import 'utils/date_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eventers/JobDetailPage.dart';
import 'package:eventers/ReviewDetailPage.dart';
import 'package:eventers/EventGroupBoardDetailPage.dart';
import 'package:eventers/FreeBoardDetailPage.dart';

/// 앱 전체에서 사용할 통일된 색상 테마를 정의하는 클래스
class AppTheme {
  // 기본 테마 색상 - 통일된 색상으로 변경
  static const Color primaryColor = Color(0xFF4A6FFF);  // 앱 전체 기본 파란색
  static const Color backgroundColor = Color(0xFFF9F9FB);  // 배경색 통일
  static const Color accentColor = Color(0xFF4A6FFF);     // 강조 색상 (파란색)
  static const Color likeColor = Color(0xFFFF3B30);       // 좋아요 빨간색 (유지)

  // 텍스트 색상
  static const Color textColor = Color(0xFF1A1A1A);       // 기본 텍스트 색상
  static const Color titleColor = Color(0xFF1A1A1A);      // 제목 색상
  static const Color contentColor = Color(0xFF505050);    // 내용 색상
  static const Color secondaryTextColor = Color(0xFF8E8E93); // 보조 텍스트 색상

  // 기타 UI 색상
  static const Color dividerColor = Color(0xFFF2F2F7);    // 구분선 색상
  static const Color cardBackgroundColor = Colors.white;  // 카드 배경 색상

  // 게시판 태그 색상
  static const Color freeboardColor = Color(0xFF5D6BFF);  // 파란색
  static const Color reviewColor = Color(0xFF36B37E);     // 초록색
  static const Color jobColor = Color(0xFFFF8A5D);        // 주황색
  static const Color eventGroupColor = Color(0xFFFF6B6B); // 빨간색
}

class RecentPostsPage extends StatefulWidget {
  const RecentPostsPage({super.key});

  @override
  State<RecentPostsPage> createState() => _RecentPostsPageState();
}

class _RecentPostsPageState extends State<RecentPostsPage> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _recentPosts = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _loadRecentPosts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentPosts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = supabase.auth.currentUser;
      final userEmail = user?.email;

      int? userId;
      if (user != null && userEmail != null) {
        final userData = await supabase
            .from('users')
            .select('id')
            .eq('email', userEmail)
            .maybeSingle();
        userId = userData?['id'];
      }

      // 전체 게시글 최신순으로 조회 (기존 인기글 대신)
      final posts = await supabase.rpc('get_all_recent_posts');

      List<Map<String, dynamic>> processedPosts = [];

      for (final post in posts) {
        // 기본 정보 추가
        Map<String, dynamic> additionalInfo = {
          'created_at': post['created_at'],
          'createdAt': post['created_at'],
          'time': getTimeAgo(post['created_at']),
        };

        // 게시글 타입별 추가 정보
        if (post['type'] == 'job') {
          try {
            final jobData = await supabase
                .from('jobs')
                .select()
                .eq('id', post['id'])
                .single();

            print('Job data from database: $jobData');
            print('Job user_id: ${jobData['user_id']}'); // 디버깅 로그 추가

            additionalInfo.addAll({
              'wage': jobData['wage'],
              'event_date': jobData['event_date'],
              'location': jobData['location'],
              'region': jobData['region'],
              'images': jobData['images'] ?? [],
              'user_id': jobData['user_id'], // 작성자 ID 추가
              'authorId': jobData['user_id'], // 작
            });
            print('additionalInfo after adding user_id: $additionalInfo');
          } catch (e) {
            print('Error loading job details: $e');
          }
        } else if (post['type'] == 'event_group') {
          try {
            final eventGroupData = await supabase
                .from('event_group_posts')
                .select()
                .eq('id', post['id'])
                .single();

            additionalInfo.addAll({
              'event_date': eventGroupData['event_date'],
              'event_location': eventGroupData['event_location'],
            });
          } catch (e) {
            print('Error loading event group details: $e');
          }
        }

        // 각 게시글의 좋아요 상태 확인
        bool isLiked = false;
        if (userId != null) {
          String tableName = '';
          String columnName = '';

          switch (post['type']) {
            case 'freeboard':
              tableName = 'freeboard_likes';
              columnName = 'post_id';
              break;
            case 'review':
              tableName = 'review_likes';
              columnName = 'review_id';
              break;
            case 'job':
              tableName = 'job_likes';
              columnName = 'job_id';
              break;
            case 'event_group':
              tableName = 'event_group_likes';
              columnName = 'eventgroup_id';
              break;
          }

          final likeStatus = await supabase
              .from(tableName)
              .select()
              .eq(columnName, post['id'])
              .eq('user_id', userId)
              .maybeSingle();
          isLiked = likeStatus != null;
        }

        // 댓글 수 직접 조회
        int commentCount = 0;
        try {
          final comments = await supabase
              .from('comments')
              .select()
              .eq('post_id', post['id'])
              .eq('board_type', post['type']);

          commentCount = comments.length;
          print('Post ID: ${post['id']}, Type: ${post['type']}, Comment count: $commentCount');
        } catch (e) {
          print('Error loading comment count: $e');
        }
        // 타입 문제 해결을 위해 String 키를 가진 Map으로 명시적 변환
        final processedPost = Map<String, dynamic>.from({
          ...post,
          ...additionalInfo,
          'isLiked': isLiked,
          'authorNickname': post['author_nickname'],
          'authorRole': post['author_role'] ?? 'USER',
          'authorId': post['user_id'],
          'user_id': post['user_id'],
          'likeCount': post['like_count'] ?? 0,
            'commentCount': commentCount,
          'viewCount': post['view_count'] ?? 0,
        });

        print('Processed post: $processedPost');
        print('Processed post user_id: ${processedPost['user_id']}');
        print('Processed post authorId: ${processedPost['authorId']}');

        processedPosts.add(processedPost);
      }

      // 날짜순 정렬 (최신순)
      processedPosts.sort((a, b) {
        final aTime = DateTime.parse(a['created_at'].toString());
        final bTime = DateTime.parse(b['created_at'].toString());
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _recentPosts = processedPosts;
          _isLoading = false;
          _animationController.forward();
        });
      }
    } catch (e) {
      print('Error loading posts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }Widget _buildPostItem(Map<String, dynamic> post) {
    // 게시글 타입에 따라 다른 색상과 라벨 적용
    String category;
    Color categoryColor;
    String timeAgo = getTimeAgo(post['created_at']);
    String preview = post['content'] ?? '(내용 없음)';
    String title = post['title'] ?? '(제목 없음)';
    String author = post['authorNickname'] ?? '익명';

    // 내용 자르기 (너무 길면 줄임)
    final shortContent = preview.length > 100
        ? '${preview.substring(0, 100)}...'
        : preview;

    // 게시글 타입에 따라 카테고리, 색상 설정
    switch (post['type']) {
      case 'job':
        category = '구인';
        categoryColor = AppTheme.jobColor;
        break;
      case 'freeboard':
        category = '자유';
        categoryColor = AppTheme.freeboardColor;
        break;
      case 'review':
        category = '후기';
        categoryColor = AppTheme.reviewColor;
        break;
      case 'event_group':
        category = '행사팟';
        categoryColor = AppTheme.eventGroupColor;
        break;
      default:
        category = '기타';
        categoryColor = AppTheme.primaryColor;
    }

    // 게시글 선택 시 상세 페이지로 이동하는 함수
    void navigateToDetail() async {
      try {
        // 게시글 타입에 따라 조회수 증가 처리
        switch (post['type']) {
          case 'freeboard':
          // 먼저 현재 게시글 정보 가져오기
            final response = await supabase
                .from('freeboard')
                .select('view_count')
                .eq('id', post['id'])
                .single();

            // 조회수 증가
            await supabase
                .from('freeboard')
                .update({ 'view_count': (response['view_count'] ?? 0) + 1 })
                .eq('id', post['id']);
            break;

          case 'review':
            final response = await supabase
                .from('review')
                .select('view_count')
                .eq('id', post['id'])
                .single();

            await supabase
                .from('review')
                .update({ 'view_count': (response['view_count'] ?? 0) + 1 })
                .eq('id', post['id']);
            break;

          case 'job':
            final response = await supabase
                .from('jobs')
                .select('view_count')
                .eq('id', post['id'])
                .single();

            await supabase
                .from('jobs')
                .update({ 'view_count': (response['view_count'] ?? 0) + 1 })
                .eq('id', post['id']);
            break;

          case 'event_group':
            final response = await supabase
                .from('event_group_posts')
                .select('view_count')
                .eq('id', post['id'])
                .single();

            await supabase
                .from('event_group_posts')
                .update({ 'view_count': (response['view_count'] ?? 0) + 1 })
                .eq('id', post['id']);
            break;
        }

        // 게시글 타입에 따라 다른 상세 페이지로 이동
        switch (post['type']) {
          case 'freeboard':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FreeBoardDetailPage(postId: post['id']),
              ),
            ).then((_) => _loadRecentPosts());
            break;

          case 'review':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReviewDetailPage(post: post),
              ),
            ).then((_) => _loadRecentPosts());
            break;

          case 'job':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailPage(post: post),
              ),
            ).then((_) => _loadRecentPosts());
            break;

          case 'event_group':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventGroupBoardDetailPage(   postId: post['id']),
              ),
            ).then((_) => _loadRecentPosts());
            break;

          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('지원하지 않는 게시글 유형입니다.')),
            );
        }
      } catch (e) {
        print('Error navigating to detail: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글을 불러오는 중 오류가 발생했습니다.')),
        );
      }
    }



    return InkWell(
      onTap: navigateToDetail,
      child: Container(
        margin: EdgeInsets.only(bottom: 1),
        padding: EdgeInsets.all(15),
        // height 속성 제거 (FreeBoardPage와 같이 자동 높이 사용)
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 카테고리 + 시간
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  timeAgo,
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // 제목
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),

            // 내용 미리보기
            Text(
              shortContent,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor.withOpacity(0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),

            // 하단: 작성자 + 조회수 + 댓글수 + 좋아요
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        author,
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 13,
                        ),
                      ),
                      if (post['authorRole'] == 'MANAGER') ...[
                        SizedBox(width: 4),
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: AppTheme.secondaryTextColor,
                ),
                SizedBox(width: 4),
                Text(
                  '${post['viewCount'] ?? 0}',
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 12),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: AppTheme.secondaryTextColor,
                ),
                SizedBox(width: 4),
                Text(
                  '${post['commentCount'] ?? 0}',
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
                Spacer(),
                // 좋아요 버튼/카운트 - GestureDetector로 감싸기
                GestureDetector(
                  onTap: () => _toggleLike(post),
                  child: Row(
                    children: [
                      Icon(
                        post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: post['isLiked'] ? AppTheme.likeColor : AppTheme.secondaryTextColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${post['likeCount'] ?? 0}',
                        style: TextStyle(
                          color: post['isLiked'] ? AppTheme.likeColor : AppTheme.secondaryTextColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
// 좋아요 토글 메서드
  Future<void> _toggleLike(Map<String, dynamic> post) async {
    try {
      // 게시글 타입에 따라 다른 API 호출
      switch (post['type']) {
        case 'freeboard':
          final result = await ApiService.toggleLike(post['id']);
          setState(() {
            post['isLiked'] = result['liked'];
            post['likeCount'] = result['likeCount'];
          });
          break;

        case 'review':
          final result = await ApiService.toggleReviewLike(post['id']);
          setState(() {
            post['isLiked'] = result['liked'];
            post['likeCount'] = result['likeCount'];
          });
          break;

        case 'job':
          await ApiService.toggleJobLike(post['id']);
          setState(() {
            post['isLiked'] = !post['isLiked'];
            post['likeCount'] = post['isLiked']
                ? (post['likeCount'] ?? 0) + 1
                : (post['likeCount'] ?? 1) - 1;
          });
          break;

        case 'event_group':
          final result = await ApiService.toggleEventGroupPostLike(post['id']);
          setState(() {
            post['isLiked'] = result['liked'];
            post['likeCount'] = result['likeCount'];
          });
          break;
      }


    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('좋아요 처리에 실패했습니다.')),
      );
    }
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: EdgeInsets.only(bottom: 1),
          height: 125,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 60,
                      height: 12,
                      color: Colors.white,
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 16,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 14,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 14,
                  color: Colors.white,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      width: 20,
                      height: 12,
                      color: Colors.white,
                    ),
                    SizedBox(width: 12),
                    Container(
                      width: 20,
                      height: 12,
                      color: Colors.white,
                    ),
                    SizedBox(width: 12),
                    Container(
                      width: 20,
                      height: 12,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
            '게시글이 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 게시글을 작성해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadRecentPosts,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('새로고침'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: null, // 탭 화면에서는 앱바가 필요 없음
      body: _isLoading
          ? _buildShimmerLoading()
          : _recentPosts.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        color: AppTheme.accentColor,
        onRefresh: _loadRecentPosts,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: _recentPosts.length,
          itemBuilder: (context, index) {
            return _buildPostItem(_recentPosts[index]);
          },
        ),
      ),
    );
  }
}