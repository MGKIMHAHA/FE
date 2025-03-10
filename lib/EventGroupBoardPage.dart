import 'package:flutter/material.dart';
import 'package:eventers/EventGroupBoardDetailPage.dart';
import 'WriteEventGroupPost.dart';
import 'services/api_service.dart';
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
  static const Color tagBackgroundColor = Color(0xFFFF8A5D);  // 태그 배경색 (주황색)
  static const Color eventGroupColor = Color(0xFFFF6B6B); // 빨간색
}

/// 행사팟(모임게시판) 페이지
class EventGroupBoardPage extends StatefulWidget {
  const EventGroupBoardPage({Key? key}) : super(key: key);

  @override
  State<EventGroupBoardPage> createState() => _EventGroupBoardPageState();
}

class _EventGroupBoardPageState extends State<EventGroupBoardPage> with SingleTickerProviderStateMixin {
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
      print('행사팟 게시글 로딩 중...');
      final posts = await ApiService.getAllEventGroupPosts();
      print('서버 응답 데이터: $posts');

      final updatedPosts = <Map<String, dynamic>>[];

      for (final post in posts) {
        print('개별 게시글 데이터: $post');
        final isLiked = await ApiService.isEventGroupPostLiked(post['id']);

        updatedPosts.add({
          'id': post['id'],
          'title': post['title'] ?? '(제목 없음)',
          'content': post['content'] ?? '(내용 없음)',
          'author': post['authorNickname'] ?? '익명',
          'created_at': post['createdAt'],
          'likeCount': post['likeCount'] ?? 0,
          'isLiked': isLiked,
          'commentCount': post['commentCount'] ?? 0,
          'category': '행사팟 구함',
          'time': getTimeAgo(post['createdAt'] ?? DateTime.now().toIso8601String()),
          'authorRole': post['authorRole'] ?? 'USER',
          'event_date': post['event_date'],
          'event_location': post['event_location'],
          'view_count': (post['viewCount'] ?? 0)
        });

        print('처리된 게시글 ID ${post['id']}: ${updatedPosts.last}');
      }

      print('변환된 게시글 데이터: $updatedPosts');

      if (mounted) {
        setState(() {
          _posts = updatedPosts;
          _isLoading = false;
          _animationController.forward();
        });
      }
    } catch (e, stackTrace) {
      print('행사팟 게시글 로딩 에러: $e');
      print('스택 트레이스: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게시글을 불러오는데 실패했습니다'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _addPost(Map<String, dynamic> post) async {
    try {
      print('새 행사팟 게시글 추가 중...');
      print('게시글 데이터: $post');

      final response = await ApiService.createEventGroupPost({
        'title': post['title'],
        'content': post['content'],
        'event_date': post['event_date'],
        'event_location': post['event_location'],
      });
      print('API 응답: $response');

      if (response != null) {
        await _loadPosts();
      }
    } catch (error) {
      print('게시글 추가 에러: $error');
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
            Icons.groups_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            '등록된 행사팟이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '첫 번째 행사팟을 만들어보세요!',
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
      // 게시글 목록
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
                final postId = post['id'] as int? ?? 0;
                print('선택된 게시글 ID: $postId');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventGroupBoardDetailPage(postId: postId),
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
                            color: AppTheme.eventGroupColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '행사팟 구함',
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
                                post['author'] ?? '익명',
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

                        // 조회수
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

                        // 댓글
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
                          onTap: () async {
                            try {
                              // 낙관적 UI 업데이트 (즉시 반응)
                              setState(() {
                                post['isLiked'] = !post['isLiked'];
                                post['likeCount'] = post['isLiked']
                                    ? (post['likeCount'] + 1)
                                    : (post['likeCount'] - 1);
                              });

                              print('좋아요 토글 시도 - 게시글 ID: ${post['id']}');
                              final result = await ApiService.toggleEventGroupPostLike(post['id']);
                              print('토글 결과: $result');

                              // 서버 응답으로 UI 다시 업데이트 (실제 상태 반영)
                              setState(() {
                                post['isLiked'] = result['liked'];
                                post['likeCount'] = result['likeCount'];
                              });
                            } catch (e) {
                              print('좋아요 토글 오류: $e');

                              // 오류 발생 시 UI 원상복구
                              setState(() {
                                post['isLiked'] = !post['isLiked'];
                                post['likeCount'] = post['isLiked']
                                    ? (post['likeCount'] + 1)
                                    : (post['likeCount'] - 1);
                              });

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
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'createEventGroupPost',
        backgroundColor: Colors.black,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WriteEventGroupPost(),
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