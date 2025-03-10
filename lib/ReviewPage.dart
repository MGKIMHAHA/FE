import 'package:flutter/material.dart';
import 'ReviewDetailPage.dart';
import 'WriteReviewPost.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/api_service.dart';
import 'PopularPostsPage.dart';
import 'utils/date_formatter.dart';
import 'package:shimmer/shimmer.dart'; // 프리보드 페이지처럼 shimmer 효과 추가

class AppTheme {
  // 이벤트 커넥트 스타일로 색상 변경
  static const Color primaryColor = Color(0xFF5D6BFF);  // 메인 파란색
  static const Color backgroundColor = Color(0xFFF8F9FA);  // 배경색
  static const Color textColor = Color(0xFF212529);  // 텍스트 색상
  static const Color secondaryTextColor = Color(0xFFADB5BD);  // 보조 텍스트 색상
  static const Color dividerColor = Color(0xFFE9ECEF);  // 구분선 색상
  static const Color likeColor = Color(0xFFFF3B30);  // 좋아요 빨간색 추가

  // 카테고리별 태그 색상
  static const Color freeTagColor = Color(0xFF5D6BFF);  // 자유 태그 색상
  static const Color reviewTagColor = Color(0xFF36B37E);  // 후기 태그 색상
  static const Color recruitTagColor = Color(0xFFFF8A5D);  // 구인 태그 색상
  static const Color partyTagColor = Color(0xFFFF6B6B);  // 파티원 구함 태그 색상
}

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _posts = [];
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
    _loadPosts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      print('Loading reviews...');
      final response = await ApiService.getReviews();

      final updatedPosts = <Map<String, dynamic>>[];

      for (final post in response) {
        updatedPosts.add({
          'id': post['id'],
          'title': post['title'] ?? '(제목 없음)',
          'content': post['content'] ?? '(내용 없음)',
          'author': post['authorNickname'] ?? '작성자',
          'time': getTimeAgo(post['createdAt']),
          'likeCount': post['likeCount'] ?? 0,
          'isLiked': post['isLiked'] ?? false,
          'commentCount': post['commentCount'] ?? 0,
          'eventName': post['eventName'] ?? '',
          'eventDate': post['eventDate'] ?? '',
          'authorNickname': post['authorNickname'] ?? '작성자',
          'authorRole': post['authorRole'] ?? 'USER',
          'createdAt': post['createdAt'],
          'view_count': post['viewCount'] ?? 0,
        });
      }

      if (mounted) {
        setState(() {
          _posts = updatedPosts;
          _isLoading = false;
          _animationController.forward();
        });
      }

      print('Reviews loaded: ${_posts.length}');

    } catch (error) {
      print('Error loading reviews: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    // 낙관적 업데이트를 위한 이전 상태 저장
    final previousIsLiked = post['isLiked'];
    final previousLikeCount = post['likeCount'];

    try {
      // UI 즉시 업데이트 (낙관적 업데이트)
      setState(() {
        post['isLiked'] = !previousIsLiked;
        post['likeCount'] = previousIsLiked ?
        previousLikeCount - 1 : previousLikeCount + 1;
      });

      // 서버 요청
      final result = await ApiService.toggleReviewLike(post['id']);

      // 인기글 목록 새로고침
      PopularPostsPage.refreshPopularPosts(context);

      // 서버 응답으로 상태 동기화
      if (mounted) {
        setState(() {
          post['isLiked'] = result['liked'];
          post['likeCount'] = result['likeCount'];
        });
      }

    } catch (e) {
      print('Error toggling like: $e');
      // 에러 발생 시 이전 상태로 복원
      if (mounted) {
        setState(() {
          post['isLiked'] = previousIsLiked;
          post['likeCount'] = previousLikeCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('좋아요 처리에 실패했습니다.')),
        );
      }
    }
  }

  // 로딩 중 UI - 프리보드 페이지와 동일하게 구현
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 10),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: EdgeInsets.only(bottom: 1),
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
            ),
          ),
        ),
      ),
    );
  }

  // 빈 상태 UI - 프리보드 페이지와 비슷하게 구현
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            '등록된 후기가 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '참여했던 행사에 대한 후기를 작성해보세요!',
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
              _loadPosts();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _loadPosts,
        child: _isLoading
            ? _buildShimmerLoading()
            : _posts.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          padding: EdgeInsets.zero, // 여기를 수정: 상단 패딩 제거
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            final post = _posts[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewDetailPage(post: post),
                  ),
                ).then((_) {
                  _loadPosts();
                });
              },
              child: _buildPostItem(post),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'createReviewPost',
        backgroundColor: Colors.black,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WriteReviewPost()),
          );
          _loadPosts();  // 새 글 작성 후 목록 새로고침
        },
        child: const Icon(
          Icons.edit,
          color: Colors.white,
        ),
        elevation: 4,
        shape: CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildPostItem(Map<String, dynamic> post) {
    // 게시글 내용 자르기 (너무 길면 줄임)
    final content = post['content'] as String;
    final shortContent = content.length > 100
        ? '${content.substring(0, 100)}...'
        : content;

    return Container(
      margin: EdgeInsets.only(bottom: 1),
      padding: EdgeInsets.all(15),
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
                  color: AppTheme.reviewTagColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '후기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                post['time'] ?? '',
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
            post['title'] ?? '(제목 없음)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
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

          // 하단: 작성자 + 조회수 + 댓글수
// 하단: 작성자 + 조회수 + 댓글수
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      post['authorNickname'] ?? '작성자',
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
                '${post['view_count'] ?? 0}',
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
              // 좋아요 버튼/카운트
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}