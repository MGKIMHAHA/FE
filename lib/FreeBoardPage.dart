import 'package:flutter/material.dart';
import 'FreeBoardDetailPage.dart';
import 'WriteFreeBoardPost.dart';
import 'services/api_service.dart';
import 'PopularPostsPage.dart';
import 'utils/date_formatter.dart';
import 'package:shimmer/shimmer.dart';

class AppTheme {
  // 이벤트 커넥트 스타일로 색상 변경
  static const Color primaryColor = Color(0xFF5D6BFF);  // 메인 파란색
  static const Color backgroundColor = Color(0xFFF8F9FA);  // 배경색
  static const Color textColor = Color(0xFF212529);  // 텍스트 색상
  static const Color secondaryTextColor = Color(0xFFADB5BD);  // 보조 텍스트 색상
  static const Color dividerColor = Color(0xFFE9ECEF);  // 구분선 색상
  static const Color likeColor = Color(0xFFFF3B30);  // 좋아요 빨간색
}

class FreeBoardPage extends StatefulWidget {
  const FreeBoardPage({super.key});

  @override
  State<FreeBoardPage> createState() => _FreeBoardPageState();
}

class _FreeBoardPageState extends State<FreeBoardPage> with SingleTickerProviderStateMixin {
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
      print('Loading posts...');

      // 자유게시판 게시글만 로드
      final posts = await ApiService.getAllPosts();
      final updatedPosts = <Map<String, dynamic>>[];

      for (final post in posts) {
        print('개별 게시글 데이터: $post');
        print('댓글 수: ${post['commentCount']}');
        final isLiked = await ApiService.isPostLiked(post['id']);

        updatedPosts.add({
          'id': int.tryParse(post['id']?.toString() ?? '0') ?? 0,
          'title': (post['title'] ?? '(제목 없음)').toString(),
          'content': (post['content'] ?? '(내용 없음)').toString(),
          'author': (post['authorNickname'] ?? '익명').toString(),
          'created_at': (post['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
          'likes': (post['likeCount'] ?? '0').toString(),
          'likeCount': post['likeCount'] ?? 0,
          'isLiked': isLiked,
          'comments': (post['commentCount'] ?? '0').toString(),
          'category': (post['category'] ?? '자유게시판').toString(),
          'time': getTimeAgo(post['createdAt'] ?? DateTime.now().toIso8601String()),
          'authorNickname': (post['authorNickname'] ?? '익명').toString(),
          'commentCount': post['commentCount'] ?? 0,
          'authorRole': post['authorRole'] ?? 'USER',
          'viewCount': post['viewCount'] ?? 0,
        });
      }

      // 생성일 기준으로 정렬 (최신순)
      updatedPosts.sort((a, b) {
        final dateA = DateTime.parse(a['created_at']);
        final dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _posts = updatedPosts;
          _isLoading = false;
          _animationController.forward();
        });
      }
    } catch (e) {
      print('Error loading posts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addPost(Map<String, dynamic> post) async {
    try {
      print('Adding new post...');
      print('Post data: $post');

      final response = await ApiService.createPost({
        'title': post['title'],
        'content': post['content'],
      });

      print('API response: $response');

      if (response != null) {
        await _loadPosts();
      }
    } catch (error) {
      print('Error adding post: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글 작성에 실패했습니다: $error')),
        );
      }
    }
  }

  // 로딩 중 UI
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

  // 빈 상태 UI
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
          SizedBox(height: 16),
          Text(
            '등록된 게시글이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '첫 번째 게시글을 작성해보세요!',
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
          padding: EdgeInsets.zero,
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            final post = _posts[index];

            // 게시글 내용 자르기 (너무 길면 줄임)
            final content = post['content'] as String;
            final shortContent = content.length > 100
                ? '${content.substring(0, 100)}...'
                : content;

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FreeBoardDetailPage(postId: post['id']),
                  ),
                ).then((_) => _loadPosts());
              },
              child: Container(
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
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '자유',
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
                      post['title'] ?? '',
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
                                post['authorNickname'] ?? '익명',
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
                          post['viewCount']?.toString() ?? '0',
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
                          post['commentCount']?.toString() ?? '0',
                          style: TextStyle(
                            color: AppTheme.secondaryTextColor,
                            fontSize: 13,
                          ),
                        ),
                        Spacer(),
                        // 좋아요 버튼/카운트
                        GestureDetector(
                          onTap: () async {
                            try {
                              final result = await ApiService.toggleLike(post['id']);
                              setState(() {
                                post['isLiked'] = result['liked'];
                                post['likeCount'] = result['likeCount'];
                              });
                              await PopularPostsPage.refreshPopularPosts(context);
                            } catch (e) {
                              print('Error toggling like: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('좋아요 처리에 실패했습니다.')),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              Icon(
                                post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                                size: 16,
                                color: post['isLiked'] ? AppTheme.likeColor : AppTheme.secondaryTextColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                post['likeCount']?.toString() ?? '0',
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
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'createFreeBoardPost',
        backgroundColor: Colors.black,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WriteFreeBoardPost(),
            ),
          ).then((_) => _loadPosts());
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
}