import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'FreeBoardDetailPage.dart';
import 'ReviewDetailPage.dart';
import 'JobDetailPage.dart';
import 'EventGroupBoardDetailPage.dart';
import 'utils/date_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

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
  static const Color rankBackgroundColor = Color(0xFFF2F2F7); // 순위 배경 색상
  static const Color rankHighlightColor = Color(0xFFE1E6FF); // 상위 순위 배경 색상
  static const Color countBackgroundColor = Color(0xFFF2F2F7); // 카운트 배경 색상

  // 텍스트 스타일
  static TextStyle get nicknameStyle => TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 13,
    color: textColor,
    letterSpacing: -0.2,
  );

  static TextStyle get titleStyle => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: titleColor,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static TextStyle get contentStyle => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: contentColor,
    letterSpacing: -0.1,
    height: 1.5,
  );

  static TextStyle get secondaryTextStyle => TextStyle(
    fontSize: 13,
    color: secondaryTextColor,
    fontWeight: FontWeight.w500,
  );
}

class PopularPostsPage extends StatefulWidget {
  const PopularPostsPage({super.key});

  @override
  State<PopularPostsPage> createState() => _PopularPostsPageState();

  static Future<void> refreshPopularPosts(BuildContext context) async {
    final state = context.findAncestorStateOfType<_PopularPostsPageState>();
    if (state != null) {
      await state._loadPopularPosts();
      state.setState(() {});
    }
  }
}

class _PopularPostsPageState extends State<PopularPostsPage> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  Map<String, List<dynamic>> _categorizedPosts = {
    'freeboard': [],
    'review': [],
    'job': [],
    'event_group': [],
  };
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
    _loadPopularPosts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPopularPosts() async {
    try {
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

      // 인기글 조회
      final posts = await supabase.rpc('get_weekly_top_posts');

      // 카테고리별로 게시글 분류
      Map<String, List<dynamic>> categorizedPosts = {
        'freeboard': [],
        'review': [],
        'job': [],
        'event_group': [],
      };

      for (final post in posts) {
        Map<String, dynamic> additionalInfo = {};
        if (post['type'] == 'job') {
          final jobData = await supabase
              .from('jobs')
              .select()
              .eq('id', post['id'])
              .single();

          additionalInfo = {
            'wage': jobData['wage'],
            'event_date': jobData['event_date'],
            'location': jobData['location'],
            'contact_info': jobData['contact_info'],
            'region': jobData['region'],
            'status': jobData['status'],
            'images': jobData['images'] ?? [],
            'created_at': jobData['created_at'],
            'createdAt': jobData['created_at'],
            'time': getTimeAgo(jobData['created_at']),
          };
        } else if (post['type'] == 'event_group') {
          try {
            final eventGroupData = await supabase
                .from('event_group_posts')
                .select()
                .eq('id', post['id'])
                .single();

            additionalInfo = {
              'event_date': eventGroupData['event_date'],
              'event_location': eventGroupData['event_location'],
              'created_at': eventGroupData['created_at'],
              'createdAt': eventGroupData['created_at'],
              'time': getTimeAgo(eventGroupData['created_at']),
            };
          } catch (e) {
            additionalInfo = {
              'created_at': post['created_at'],
              'createdAt': post['created_at'],
              'time': getTimeAgo(post['created_at']),
            };
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

        final processedPost = {
          ...post,
          ...additionalInfo,
          'isLiked': isLiked,
          'authorNickname': post['author_nickname'],
          'authorRole': post['author_role'] ?? 'USER',
          'createdAt': post['created_at'],
          'likeCount': post['like_count'] ?? 0,
          'commentCount': post['comment_count'] ?? 0,
        };

        // 카테고리별로 분류
        if (categorizedPosts.containsKey(post['type'])) {
          categorizedPosts[post['type']]!.add(processedPost);
        }
      }

      if (mounted) {
        setState(() {
          _categorizedPosts = categorizedPosts;
          _isLoading = false;
          _animationController.forward();
        });
      }
    } catch (e) {
      print('Error loading popular posts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 게시글 유형별 아이콘 지정
  IconData _getPostTypeIcon(String type) {
    switch (type) {
      case 'freeboard':
        return Icons.forum_rounded;
      case 'review':
        return Icons.rate_review_rounded;
      case 'job':
        return Icons.work_rounded;
      case 'event_group':
        return Icons.groups_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  String _getPostTypeName(String type) {
    switch (type) {
      case 'freeboard':
        return '자유게시판';
      case 'review':
        return '후기';
      case 'job':
        return '구인';
      case 'event_group':
        return '행사팟 구함';
      default:
        return '게시글';
    }
  }

  void _navigateToPostDetail(BuildContext context, dynamic post) {
    // post 데이터를 Map<String, dynamic>으로 명시적 변환
    Map<String, dynamic> processedPost = {};
    post.forEach((key, value) {
      processedPost[key.toString()] = value;
    });

    switch (post['type']) {
      case 'freeboard':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FreeBoardDetailPage(
              postId: post['id'],
              initialLikeStatus: post['isLiked'],
              onLikeChanged: (bool newLikeStatus) {
                setState(() {
                  post['isLiked'] = newLikeStatus;
                  post['likeCount'] = newLikeStatus
                      ? (post['likeCount'] + 1)
                      : (post['likeCount'] - 1);
                });
              },
            ),
          ),
        ).then((_) => _loadPopularPosts());
        break;
      case 'review':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewDetailPage(post: processedPost),
          ),
        ).then((_) => _loadPopularPosts());
        break;
      case 'job':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailPage(post: processedPost),
          ),
        ).then((_) => _loadPopularPosts());
        break;
      case 'event_group':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventGroupBoardDetailPage(postId: post['id']),
          ),
        ).then((_) => _loadPopularPosts());
        break;
    }
  }
  Widget _buildCategorySection(String type, String title, IconData icon) {
    final posts = _categorizedPosts[type] ?? [];

    if (posts.isEmpty) {
      return SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 헤더
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  // 카테고리 아이콘
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: AppTheme.accentColor, size: 20),
                  ),
                  SizedBox(width: 16),

                  // 카테고리 제목
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppTheme.titleColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '이번 주 인기 ${title}',
                        style: AppTheme.secondaryTextStyle,
                      ),
                    ],
                  ),

                  Spacer(),

                  // 더보기 버튼
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '더보기',
                          style: TextStyle(
                            color: AppTheme.accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.accentColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 게시글 목록
            ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: posts.length > 5 ? 5 : posts.length, // 최대 5개만 표시
              itemBuilder: (context, index) {
                final post = posts[index];
                return InkWell(
                  onTap: () => _navigateToPostDetail(context, post),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      border: index < posts.length - 1
                          ? Border(bottom: BorderSide(color: AppTheme.dividerColor, width: 1))
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 순위 표시 - 통일된 색상으로 변경
                        Container(
                          width: 28,
                          height: 28,
                          margin: EdgeInsets.only(top: 2),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: index < 3
                                ? AppTheme.rankHighlightColor
                                : AppTheme.rankBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: index < 3
                                  ? AppTheme.accentColor
                                  : AppTheme.secondaryTextColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),

                        // 게시글 내용
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 게시글 제목 (왼쪽에 배치)
                              Expanded(
                                child: Text(
                                  post['title'] ?? '제목 없음',
                                  style: AppTheme.titleStyle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              SizedBox(width: 10), // 제목과 카운터 사이의 간격

                              // 좋아요 수 (원래 색상 유지)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.likeColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.favorite_rounded,
                                      color: AppTheme.likeColor,
                                      size: 12,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '${post['likeCount']}',
                                      style: TextStyle(
                                        color: AppTheme.likeColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(width: 8),

                              // 댓글 수
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.countBackgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_rounded,
                                      color: AppTheme.secondaryTextColor,
                                      size: 12,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '${post['commentCount']}',
                                      style: TextStyle(
                                        color: AppTheme.secondaryTextColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          margin: EdgeInsets.only(bottom: 20),
          height: 280,
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(24),
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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.article_rounded,
              size: 60,
              color: Color(0xFFC7C7CC),
            ),
          ),
          SizedBox(height: 24),
          Text(
            '인기 게시글이 없습니다',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.titleColor,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              '게시글을 작성하거나 다른 사람의 게시글에 반응해보세요!',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.secondaryTextColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _animationController.reset();
              });
              _loadPopularPosts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              '새로고침',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Column(
            children: [
              SizedBox(height: 8),
              Text(
                '인기 게시글',
                style: TextStyle(
                  color: AppTheme.titleColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: AppTheme.accentColor,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _animationController.reset();
                  });
                  _loadPopularPosts();
                },
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _categorizedPosts.values.every((list) => list.isEmpty)
          ? _buildEmptyState()
          : RefreshIndicator(
        color: AppTheme.accentColor,
        onRefresh: _loadPopularPosts,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // 각 카테고리별 섹션 구성 (통일된 색상으로)
            _buildCategorySection(
                'freeboard',
                '자유게시판',
                Icons.forum_rounded
            ),
            _buildCategorySection(
                'job',
                '구인게시판',
                Icons.work_rounded
            ),
            _buildCategorySection(
                'review',
                '후기게시판',
                Icons.rate_review_rounded
            ),
            _buildCategorySection(
                'event_group',
                '행사팟',
                Icons.groups_rounded
            ),
          ],
        ),
      ),
    );
  }
}