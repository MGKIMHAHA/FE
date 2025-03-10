import 'package:eventers/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/user_preferences.dart';
import '../JobDetailPage.dart';
import '../FreeBoardDetailPage.dart';
import '../ReviewDetailPage.dart';
import './services/api_service.dart';
import './EventGroupBoardDetailPage.dart';

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

class LikedPostsPage extends StatefulWidget {
  const LikedPostsPage({super.key});

  @override
  State<LikedPostsPage> createState() => _LikedPostsPageState();
}

class _LikedPostsPageState extends State<LikedPostsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _likedPosts = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _filteredPosts = []; // 필터링된 게시글 목록
  List<Map<String, dynamic>> _freeboardPosts = [];
  List<Map<String, dynamic>> _reviewPosts = [];
  List<Map<String, dynamic>> _jobPosts = [];
  List<Map<String, dynamic>> _eventGroupPosts = [];
  String _currentFilter = '전체'; // 현재 선택된 필터
  final List<String> _filterCategories = ['전체', '구인', '자유', '후기', '행사팟'];

  @override
  void initState() {
    super.initState();
    _loadLikedPosts();
  }

  Future<void> _loadLikedPosts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userId = await UserPreferences.getUserId();

      // 구인글 좋아요
      final jobLikes = await supabase
          .from('job_likes')
          .select('*, jobs!job_likes_job_id_fkey(*)')
          .eq('user_id', userId);

      // 자유게시판 좋아요
      final freeboardLikes = await supabase
          .from('freeboard_likes')
          .select('*, freeboard!freeboard_likes_post_id_fkey(*)')
          .eq('user_id', userId);

      // 리뷰 좋아요
      final reviewLikes = await supabase
          .from('review_likes')
          .select('*, review!review_likes_review_id_fkey(*)')
          .eq('user_id', userId);

      // 이벤트 그룹 좋아요
      final eventGroupLikes = await supabase
          .from('event_group_likes')
          .select('*, event_group_posts!event_group_likes_eventgroup_id_fkey(*)')
          .eq('user_id', userId);

      List<Map<String, dynamic>> eventGroupPostsList = [];
      List<Map<String, dynamic>> allLikedPosts = [];
      List<Map<String, dynamic>> jobPostsList = [];
      List<Map<String, dynamic>> freeboardPostsList = [];
      List<Map<String, dynamic>> reviewPostsList = [];

      // 구인글 데이터 처리
      for (var like in jobLikes) {
        if (like['jobs'] != null) {
          final post = like['jobs'];
          post['type'] = 'job';
          final processedPost = Map<String, dynamic>.from(post);
          allLikedPosts.add(processedPost);
          jobPostsList.add(processedPost);
        }
      }

      // 자유게시판 데이터 처리
      for (var like in freeboardLikes) {
        if (like['freeboard'] != null) {
          final post = like['freeboard'];
          post['type'] = 'freeboard';
          final processedPost = Map<String, dynamic>.from(post);
          allLikedPosts.add(processedPost);
          freeboardPostsList.add(processedPost);
        }
      }

      // 리뷰 데이터 처리
      for (var like in reviewLikes) {
        if (like['review'] != null) {
          final post = like['review'];
          post['type'] = 'review';
          final processedPost = Map<String, dynamic>.from(post);
          allLikedPosts.add(processedPost);
          reviewPostsList.add(processedPost);
        }
      }

      // 이벤트 그룹 데이터 처리
      for (var like in eventGroupLikes) {
        if (like['event_group_posts'] != null) {
          final post = like['event_group_posts'];
          post['type'] = 'event_group';
          final processedPost = Map<String, dynamic>.from(post);
          allLikedPosts.add(processedPost);
          eventGroupPostsList.add(processedPost);
        }
      }

      // 날짜순 정렬
      allLikedPosts.sort((a, b) {
        final aTime = DateTime.parse(a['created_at'].toString());
        final bTime = DateTime.parse(b['created_at'].toString());
        return bTime.compareTo(aTime);
      });

      jobPostsList.sort((a, b) {
        final aTime = DateTime.parse(a['created_at'].toString());
        final bTime = DateTime.parse(b['created_at'].toString());
        return bTime.compareTo(aTime);
      });

      freeboardPostsList.sort((a, b) {
        final aTime = DateTime.parse(a['created_at'].toString());
        final bTime = DateTime.parse(b['created_at'].toString());
        return bTime.compareTo(aTime);
      });

      reviewPostsList.sort((a, b) {
        final aTime = DateTime.parse(a['created_at'].toString());
        final bTime = DateTime.parse(b['created_at'].toString());
        return bTime.compareTo(aTime);
      });

      eventGroupPostsList.sort((a, b) {
        final aTime = DateTime.parse(a['created_at'].toString());
        final bTime = DateTime.parse(b['created_at'].toString());
        return bTime.compareTo(aTime);
      });

      setState(() {
        _likedPosts = allLikedPosts;
        _jobPosts = jobPostsList;
        _freeboardPosts = freeboardPostsList;
        _reviewPosts = reviewPostsList;
        _eventGroupPosts = eventGroupPostsList;
        _applyFilter(_currentFilter); // 필터 적용
        _isLoading = false;
      });
    } catch (e) {
      print('좋아요 목록 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('좋아요 목록을 불러오는데 실패했습니다'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
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
        _filteredPosts = _likedPosts;
      } else if (filter == '구인') {
        _filteredPosts = _jobPosts;
      } else if (filter == '자유') {
        _filteredPosts = _freeboardPosts;
      } else if (filter == '후기') {
        _filteredPosts = _reviewPosts;
      } else if (filter == '행사팟') {
        _filteredPosts = _eventGroupPosts;
      }
    });
  }

  Future<void> _toggleJobLike(int postId) async {
    try {
      final userId = await UserPreferences.getUserId();

      final likes = await supabase
          .from('job_likes')
          .select()
          .eq('user_id', userId)
          .eq('job_id', postId);

      if (likes.isEmpty) {
        // 좋아요 추가
        await supabase.from('job_likes').insert({
          'user_id': userId,
          'job_id': postId,
        });

        // 즉시 UI 업데이트를 위해 게시글 정보 가져오기
        final jobData = await supabase
            .from('jobs')
            .select('*')
            .eq('id', postId)
            .single();

        setState(() {
          final newPost = {
            ...jobData,
            'type': 'job',
          };
          _likedPosts.add(newPost);
          _jobPosts.add(newPost);
          _applyFilter(_currentFilter);
        });
      } else {
        // 좋아요 취소
        await supabase
            .from('job_likes')
            .delete()
            .eq('user_id', userId)
            .eq('job_id', postId);

        setState(() {
          _likedPosts.removeWhere((post) => post['id'] == postId && post['type'] == 'job');
          _jobPosts.removeWhere((post) => post['id'] == postId);
          _applyFilter(_currentFilter);
        });
      }
    } catch (e) {
      print('Error toggling job like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('좋아요 처리에 실패했습니다'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
      // 에러 발생 시 목록 새로고침
      await _loadLikedPosts();
    }
  }

  Future<void> _toggleFreeboardLike(int postId) async {
    try {
      final userId = await UserPreferences.getUserId();

      final likes = await supabase
          .from('freeboard_likes')
          .select()
          .eq('user_id', userId)
          .eq('post_id', postId);

      if (likes.isEmpty) {
        // 좋아요 추가
        await supabase.from('freeboard_likes').insert({
          'user_id': userId,
          'post_id': postId,
        });

        // 즉시 UI 업데이트를 위해 게시글 정보 가져오기
        final postData = await supabase
            .from('freeboard')
            .select('*')
            .eq('id', postId)
            .single();

        setState(() {
          final newPost = {
            ...postData,
            'type': 'freeboard',
          };
          _likedPosts.add(newPost);
          _freeboardPosts.add(newPost);
          _applyFilter(_currentFilter);
        });
      } else {
        // 좋아요 취소
        await supabase
            .from('freeboard_likes')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', postId);

        setState(() {
          _likedPosts.removeWhere((post) => post['id'] == postId && post['type'] == 'freeboard');
          _freeboardPosts.removeWhere((post) => post['id'] == postId);
          _applyFilter(_currentFilter);
        });
      }
    } catch (e) {
      print('Error toggling freeboard like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('좋아요 처리에 실패했습니다'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
      await _loadLikedPosts();
    }
  }

  Future<void> _toggleReviewLike(int postId) async {
    try {
      final userId = await UserPreferences.getUserId();

      final likes = await supabase
          .from('review_likes')
          .select()
          .eq('user_id', userId)
          .eq('review_id', postId);

      if (likes.isEmpty) {
        // 좋아요 추가
        await supabase.from('review_likes').insert({
          'user_id': userId,
          'review_id': postId,
        });

        // 즉시 UI 업데이트를 위해 게시글 정보 가져오기
        final reviewData = await supabase
            .from('review')
            .select('*')
            .eq('id', postId)
            .single();

        setState(() {
          final newPost = {
            ...reviewData,
            'type': 'review',
          };
          _likedPosts.add(newPost);
          _reviewPosts.add(newPost);
          _applyFilter(_currentFilter);
        });
      } else {
        // 좋아요 취소
        await supabase
            .from('review_likes')
            .delete()
            .eq('user_id', userId)
            .eq('review_id', postId);

        setState(() {
          _likedPosts.removeWhere((post) => post['id'] == postId && post['type'] == 'review');
          _reviewPosts.removeWhere((post) => post['id'] == postId);
          _applyFilter(_currentFilter);
        });
      }
    } catch (e) {
      print('Error toggling review like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('좋아요 처리에 실패했습니다'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
      await _loadLikedPosts();
    }
  }

  // 이벤트 그룹 좋아요 토글 메서드
  Future<void> _toggleEventGroupLike(int postId) async {
    try {
      final userId = await UserPreferences.getUserId();
      final likes = await supabase
          .from('event_group_likes')
          .select()
          .eq('user_id', userId)
          .eq('eventgroup_id', postId);

      if (likes.isEmpty) {
        await supabase.from('event_group_likes').insert({
          'user_id': userId,
          'eventgroup_id': postId,
        });

        final postData = await supabase
            .from('event_group_posts')
            .select('*')
            .eq('id', postId)
            .single();

        setState(() {
          final newPost = {...postData, 'type': 'event_group'};
          _likedPosts.add(newPost);
          _eventGroupPosts.add(newPost);
          _applyFilter(_currentFilter);
        });
      } else {
        await supabase
            .from('event_group_likes')
            .delete()
            .eq('user_id', userId)
            .eq('eventgroup_id', postId);

        setState(() {
          _likedPosts.removeWhere((post) => post['id'] == postId && post['type'] == 'event_group');
          _eventGroupPosts.removeWhere((post) => post['id'] == postId);
          _applyFilter(_currentFilter);
        });
      }
    } catch (e) {
      print('Error toggling event group like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('좋아요 처리에 실패했습니다')),
      );
      await _loadLikedPosts();
    }
  }

  // 게시글 아이템 위젯
  Widget _buildPostItem(Map<String, dynamic> post) {
    // 게시글 타입에 따라 다른 색상과 라벨 적용
    String category;
    Color categoryColor;
    String timeAgo = getTimeAgo(post['created_at']);
    String preview = post['content'] ?? '(내용 없음)';
    String title = post['title'] ?? '(제목 없음)';

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
      switch (post['type']) {
        case 'job':
          try {
            final jobDetail = await supabase
                .from('jobs')
                .select('''
                  *,
                  profiles:user_id (
                    email,
                    nickname
                  )
                ''')
                .eq('id', post['id'])
                .single();

            final comments = await supabase
                .from('comments')
                .select('id')
                .eq('post_id', post['id'])
                .eq('board_type', 'job');

            final formattedJob = {
              ...jobDetail,
              'id': jobDetail['id'],
              'title': jobDetail['title'],
              'content': jobDetail['content'],
              'authorNickname': jobDetail['profiles']['nickname'] ?? jobDetail['profiles']['email'],
              'time': getTimeAgo(jobDetail['created_at']),
              'likeCount': jobDetail['like_count'] ?? 0,
              'commentCount': comments.length,
              'viewCount': jobDetail['view_count'] ?? 0,
              'wage': jobDetail['wage'],
              'region': jobDetail['region'],
              'district': jobDetail['district'],
              'location': jobDetail['location'],
              'date': jobDetail['work_date'],
              'isLiked': true,
              'user_id': jobDetail['user_id'],
              'type': 'job'
            };

            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobDetailPage(post: formattedJob),
                ),
              ).then((_) => _loadLikedPosts());
            }
          } catch (e) {
            print('Error loading job details: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('게시글을 불러오는데 실패했습니다')),
              );
            }
          }
          break;
        case 'freeboard':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FreeBoardDetailPage(postId: post['id']),
            ),
          ).then((_) => _loadLikedPosts());
          break;
        case 'review':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewDetailPage(post: post),
            ),
          ).then((_) => _loadLikedPosts());
          break;
        case 'event_group':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventGroupBoardDetailPage(postId: post['id']),
            ),
          ).then((_) => _loadLikedPosts());
          break;
      }
    }

    // 좋아요 취소 처리 함수
    void handleUnlike() async {
      // 즉시 UI 업데이트 (좋아요 취소)
      setState(() {
        _likedPosts.removeWhere((p) => p['id'] == post['id'] && p['type'] == post['type']);

        switch (post['type']) {
          case 'job':
            _jobPosts.removeWhere((p) => p['id'] == post['id']);
            break;
          case 'freeboard':
            _freeboardPosts.removeWhere((p) => p['id'] == post['id']);
            break;
          case 'review':
            _reviewPosts.removeWhere((p) => p['id'] == post['id']);
            break;
          case 'event_group':
            _eventGroupPosts.removeWhere((p) => p['id'] == post['id']);
            break;
        }

        _applyFilter(_currentFilter);
      });

      try {
        switch (post['type']) {
          case 'job':
            await _toggleJobLike(post['id']);
            break;
          case 'freeboard':
            await _toggleFreeboardLike(post['id']);
            break;
          case 'review':
            await _toggleReviewLike(post['id']);
            break;
          case 'event_group':
            await _toggleEventGroupLike(post['id']);
            break;
        }
      } catch (e) {
        // 실패 시 목록 새로고침
        await _loadLikedPosts();
      }
    }

    // 이미지와 유사한 UI로 카드 레이아웃 구성
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
              // 상단 정보: 카테고리 태그, 시간, 좋아요 버튼
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
                  // 좋아요 버튼
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: handleUnlike,
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
                    '${post['view_count'] ?? 0}',
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
                    '${post['like_count'] ?? 0}',
                    style: TextStyle(
                      color: AppTheme.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),

                  // // 댓글이 있는 경우 표시
                  // if (post['comment_count'] != null) ...[
                  //   const SizedBox(width: 12),
                  //   Icon(
                  //     Icons.chat_bubble_outline,
                  //     size: 14,
                  //     color: AppTheme.secondaryTextColor,
                  //   ),
                  //   const SizedBox(width: 4),
                  //   Text(
                  //     '${post['comment_count']}',
                  //     style: TextStyle(
                  //       color: AppTheme.secondaryTextColor,
                  //       fontSize: 12,
                  //     ),
                  //   ),
                  // ],
                ],
              ),
            ],
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
            Icons.favorite_border,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '좋아요한 게시글이 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '마음에 드는 게시글을 찾아 좋아요를 눌러보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(

        title: const Text(
          '좋아요 목록',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,

        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadLikedPosts,
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
                          color: isSelected ? Colors.black  : Colors.transparent,
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
              onRefresh: _loadLikedPosts,
              color: AppTheme.primaryColor,
              child: ListView.builder(
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