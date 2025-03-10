import 'package:eventers/BoardType.dart';
import 'package:flutter/material.dart';
import 'JobDetailPage.dart';
import 'WriteJobPost.dart';
import 'services/api_service.dart';
import 'PopularPostsPage.dart';
import 'utils/date_formatter.dart';
import 'utils/user_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
}

class JobPage extends StatefulWidget {
  const JobPage({super.key});

  @override
  State<JobPage> createState() => _JobPageState();
}

class _JobPageState extends State<JobPage> {
  final supabase = Supabase.instance.client;
  final _posts = <Map<String, dynamic>>[];
  bool _isLoading = false;
  bool _isLiked = false;
  List<dynamic> _comments = [];
  String? _userType;

  @override
  void initState() {
    super.initState();
    print('Calling initState');
    _loadUserType();
    _loadPosts();
    print('============ JobPage initState END ============');
  }

  // 사용자 타입 로드 메서드
  Future<void> _loadUserType() async {
    print('============ _loadUserType START ============');
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser?.email != null) {
        final userData = await supabase
            .from('users')
            .select('user_type')
            .eq('email', currentUser!.email!)
            .single();

        print('Loaded user data: $userData');
        print('User type from database: ${userData['user_type']}');

        setState(() {
          _userType = userData['user_type'];
        });
      }
    } catch (e) {
      print('Error loading user type: $e');
    }
    print('Final user type: $_userType');
    print('============ _loadUserType END ============');
  }

  Future<void> _loadComments(int postId) async {
    try {
      _comments = await ApiService.getComments(postId, BoardType.job);

      if (mounted) {
        setState(() {
          // 현재 게시글 찾기
          final post = _posts.firstWhere((p) => p['id'] == postId);
          // 댓글 수 업데이트
          post['commentCount'] = _comments.length;
        });
      }

      print('Loaded ${_comments.length} comments');
      // 디버깅을 위한 댓글 정보 출력
      _comments.forEach((comment) {
        print('''
        Comment ID: ${comment.id}
        Content: ${comment.content}
        Author: ${comment.author}
        Replies: ${comment.replies.length}
        Created At: ${comment.createdAt}
        ==================
      ''');
      });

    } catch (e) {
      print('Error loading comments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('댓글을 불러오는데 실패했습니다'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  Future<void> _loadPosts() async {
    print('Starting _loadPosts');
    setState(() {
      _isLoading = true;
    });

    try {
      final jobs = await ApiService.getJobs();

      if (mounted) {
        setState(() {
          _posts.clear();
          _posts.addAll(jobs);
          _isLoading = false;
        });
      }

      print('Final posts data: $_posts');

    } catch (e) {
      print('Error loading jobs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('글 목록을 불러오는데 실패했습니다.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  void _navigateToWrite() async {
    // WriteJobPost로 이동하고 결과를 기다림
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WriteJobPost(),
      ),
    );

    // 글 작성이 완료되면 (result가 true이면) 목록 새로고침
    if (result == true) {
      _loadPosts();  // 목록 새로고침 메서드 호출
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
            Icons.work_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            '등록된 채용 정보가 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _userType == 'agency'
                ? '첫 번째 채용 정보를 등록해보세요!'
                : '아직 등록된 채용 정보가 없습니다.',
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
            final content = post['content'] as String? ?? '';
            final shortContent = content.length > 100
                ? '${content.substring(0, 100)}...'
                : content;

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobDetailPage(
                      post: Map<String, dynamic>.from(post),
                      onLikeChanged: (bool newLikeStatus) {
                        setState(() {
                          post['isLiked'] = newLikeStatus;
                          post['likeCount'] = newLikeStatus
                              ? (post['likeCount'] ?? 0) + 1
                              : (post['likeCount'] ?? 1) - 1;
                        });
                      },
                    ),
                  ),
                ).then((_) => _loadPosts()); // 페이지 복귀 시 전체 목록 새로고침
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
                            color: AppTheme.tagBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '구인',
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

                        // 조회수
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
                              await ApiService.toggleJobLike(post['id']);
                              setState(() {
                                post['isLiked'] = !post['isLiked'];
                                post['likeCount'] = post['isLiked']
                                    ? (post['likeCount'] ?? 0) + 1
                                    : (post['likeCount'] ?? 1) - 1;
                              });
                              // 인기 게시글 새로고침 요청
                              PopularPostsPage.refreshPopularPosts(context);
                            } catch (e) {
                              print('좋아요 토글 오류: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('좋아요 처리에 실패했습니다.')),
                                );
                              }
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
      floatingActionButton: _userType?.toLowerCase() == 'agency' || _userType?.toLowerCase() == 'AGENCY'
          ? Container(
        height: 60,
        width: 60,
        child: FloatingActionButton(
          heroTag: 'createJobPost',
          backgroundColor: Colors.black,
          onPressed: _navigateToWrite,
          child: const Icon(
            Icons.edit,
            color: Colors.white,
            size: 24,
          ),
          elevation: 4,
          shape: CircleBorder(),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}