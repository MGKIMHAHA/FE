import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Comment.dart';
import '../utils/user_preferences.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart'; // XFile을 위한 import 추가
import '../BoardType.dart';
import '../Report.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/date_formatter.dart';






class ApiService {
  // Flutter 웹에서 테스트할 때는 전체 URL을 사용
  // static const String baseUrl = 'http://localhost:8080/api/auth';  // 이전 경로
  static const String baseUrl = 'http://127.0.0.1:8080';
  static final supabase = Supabase.instance.client;



  // 행사팟 게시글 전체 조회
  static Future<List<Map<String, dynamic>>> getAllEventGroupPosts() async {
    try {
      print('Fetching all event group posts...');
      final now = DateTime.now();
      print('Current time (KST): $now');

      // 게시글과 작성자 정보만 JOIN
      final response = await supabase
          .from('event_group_posts')
          .select('''
          *,
          users!inner (
            nickname,
            role
          )
        ''')
          .lte('created_at', now.toIso8601String())
          .order('created_at', ascending: false);

      print('Raw response: $response');

      List<Map<String, dynamic>> formattedPosts = [];

      for (final post in response) {
        try {
          // 각 게시글의 댓글 수를 별도로 조회
          final comments = await supabase
              .from('comments')
              .select('id')
              .eq('post_id', post['id'])
              .eq('board_type', 'event_group');

          // 각 게시글의 좋아요 수를 별도로 조회
          final likes = await supabase
              .from('event_group_likes')
              .select('id')
              .eq('eventgroup_id', post['id']);

          final user = post['users'] as Map<String, dynamic>?;

          formattedPosts.add({
            'id': post['id'],
            'title': post['title'],
            'content': post['content'],
            'authorNickname': user?['nickname'] ?? '익명',
            'authorRole': user?['role'] ?? 'USER',
            'createdAt': post['created_at'],
            'event_date': post['event_date'],
            'event_location': post['event_location'],
            'likeCount': post['like_count'] ?? 0,
            'viewCount': post['view_count'] ?? 0,
            'commentCount': comments.length,
            'images': post['images'] ?? [],
            'time': getTimeAgo(post['created_at']),
          });

          print('Processed post ${post['id']} successfully');
        } catch (e) {
          print('Error processing post ${post['id']}: $e');
          continue;
        }
      }

      print('Total formatted posts: ${formattedPosts.length}');
      return formattedPosts;

    } catch (e, stackTrace) {
      print('Error in getAllEventGroupPosts: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to load event group posts: $e');
    }
  }
  // 특정 행사팟 게시글 조회
  static Future<Map<String, dynamic>> getEventGroupPost(int id) async {
  try {
  // 게시글 조회
  final response = await supabase
      .from('event_group_posts')
      .select('''
          *,
          user:user_id (
            id,
            nickname,
            role
          )
        ''')
      .eq('id', id)
      .single();

  // 조회수 증가
  await supabase
      .from('event_group_posts')
      .update({ 'view_count': (response['view_count'] ?? 0) + 1 })
      .eq('id', id);

  // 댓글 수 조회
  final comments = await supabase
      .from('comments')
      .select()
      .eq('post_id', id)
      .eq('board_type', 'event_group');

  final likes = await supabase
      .from('event_group_likes')
      .select('id')
      .eq('eventgroup_id', id);

  return {
  'id': response['id'],
  'title': response['title'],
  'content': response['content'],
  'authorNickname': response['user']['nickname'],
  'createdAt': response['created_at'],
  'event_date': response['event_date'],
  'event_location': response['event_location'],
  'likeCount': response['like_count'] ?? 0,
  'viewCount': (response['view_count'] ?? 0) + 1,
  'commentCount': comments.length,
  'userId': response['user_id'],
  'authorRole': response['user']['role'],
    'images': response['images'] ?? [],
  };
  } catch (e) {
  print('Error in getEventGroupPost: $e');
  rethrow;
  }
  }

  // 행사팟 게시글 작성
  static Future<Map<String, dynamic>> createEventGroupPost(Map<String, dynamic> postData) async {
  try {
  final user = supabase.auth.currentUser;
  final userEmail = user?.email;

  if (user == null || userEmail == null) {
  throw Exception('로그인이 필요합니다');
  }

  print('Creating event group post with data: $postData');

  // 이메일로 사용자 ID 조회
  final userData = await supabase
      .from('users')
      .select('id')
      .eq('email', userEmail)
      .single();

  if (userData == null) throw Exception('사용자 정보를 찾을 수 없습니다');

  final insertData = {
  'title': postData['title'],
  'content': postData['content'],
  'user_id': userData['id'],
  'view_count': 0,
  'like_count': 0,
  'event_date': postData['event_date'],
  'event_location': postData['event_location'],
    'images': postData['images'] ?? [],
  };

  final response = await supabase
      .from('event_group_posts')
      .insert(insertData)
      .select()
      .single();

  return {
  'id': response['id'],
  'title': response['title'],
  'content': response['content'],
  'userId': response['user_id'],
  'createdAt': response['created_at'],
  'event_date': response['event_date'],
  'event_location': response['event_location'],
  'likeCount': response['like_count'] ?? 0,
  'viewCount': response['view_count'] ?? 0,
    'images': response['images'] ?? [],
  };
  } catch (e) {
  print('Error in createEventGroupPost: $e');
  print('Insert data: $postData');
  print('Current user email: ${supabase.auth.currentUser?.email}');
  rethrow;
  }
  }

  // 행사팟 게시글 수정
  static Future<Map<String, dynamic>> updateEventGroupPost(int postId, Map<String, dynamic> postData) async {
  try {
  print('Updating event group post $postId with data: $postData');

  final updateData = {
  'title': postData['title'],
  'content': postData['content'],
  'updated_at': DateTime.now().toIso8601String(),
  'event_date': postData['event_date'],
  'event_location': postData['event_location'],
  };

  if (postData['images'] != null) {
  updateData['images'] = postData['images'];
  }

  final response = await supabase
      .from('event_group_posts')
      .update(updateData)
      .eq('id', postId)
      .select()
      .single();

  return {
  'id': response['id'],
  'title': response['title'],
  'content': response['content'],
  'userId': response['user_id'],
  'createdAt': response['created_at'],
  'updatedAt': response['updated_at'],
  'event_date': response['event_date'],
  'event_location': response['event_location'],
  'likeCount': response['like_count'] ?? 0,
  'viewCount': response['view_count'] ?? 0,
  'images': response['images'],
  };
  } catch (e) {
  print('Error updating event group post: $e');
  throw Exception('게시글 수정에 실패했습니다');
  }
  }

  // 행사팟 게시글 삭제
  static Future<void> deleteEventGroupPost(int postId) async {
  try {
  print('Deleting event group post $postId');

  await supabase
      .from('event_group_posts')
      .delete()
      .eq('id', postId);

  print('Event group post deleted successfully');
  } catch (e) {
  print('Error deleting event group post: $e');
  throw Exception('게시글 삭제에 실패했습니다');
  }
  }

  // 좋아요 상태 확인
  static Future<bool> isEventGroupPostLiked(int postId) async {
  try {
  final user = supabase.auth.currentUser;
  final userEmail = user?.email;
  if (user == null || userEmail == null) return false;

  // email로 users 테이블에서 실제 id를 조회
  final userData = await supabase
      .from('users')
      .select('id')
      .eq('email', userEmail)
      .maybeSingle();

  if (userData == null) return false;
  final userId = userData['id'];

  final response = await supabase
      .from('event_group_likes')
      .select()
      .eq('eventgroup_id', postId)
      .eq('user_id', userId)
      .maybeSingle();

  return response != null;
  } catch (e) {
  print('Error checking like status: $e');
  return false;
  }
  }

  // 좋아요 토글 (좋아요/취소)
  static Future<Map<String, dynamic>> toggleEventGroupPostLike(int postId) async {
  try {
  final user = supabase.auth.currentUser;
  final userEmail = user?.email;
  if (user == null || userEmail == null) throw Exception('로그인이 필요합니다');

  // email로 users 테이블에서 실제 id를 조회
  final userData = await supabase
      .from('users')
      .select('id')
      .eq('email', userEmail)
      .maybeSingle();

  if (userData == null) throw Exception('사용자 정보를 찾을 수 없습니다');
  final userId = userData['id'];

  // 현재 좋아요 상태 확인
  final existingLike = await supabase
      .from('event_group_likes')
      .select()
      .eq('eventgroup_id', postId)
      .eq('user_id', userId)
      .maybeSingle();

  if (existingLike == null) {
  // 좋아요 추가
  await supabase.from('event_group_likes').insert({
    'eventgroup_id': postId,
  'user_id': userId,
  'created_at': DateTime.now().toIso8601String(),
  });

  // 게시글의 좋아요 수 증가
  await incrementEventGroupPostLikeCount(postId);

  return {
  'liked': true,
  'likeCount': await getEventGroupPostLikeCount(postId),
  };
  } else {
  // 좋아요 삭제
  await supabase
      .from('event_group_likes')
      .delete()
      .eq('eventgroup_id', postId)
      .eq('user_id', userId);

  // 게시글의 좋아요 수 감소
  await decrementEventGroupPostLikeCount(postId);

  return {
  'liked': false,
  'likeCount': await getEventGroupPostLikeCount(postId),
  };
  }
  } catch (e) {
  print('Error toggling like: $e');
  rethrow;
  }
  }

  // 게시글 좋아요 수 증가
  static Future<void> incrementEventGroupPostLikeCount(int postId) async {
  try {
  // 현재 좋아요 수 가져오기
  final response = await supabase
      .from('event_group_posts')
      .select('like_count')
      .eq('id', postId)
      .single();

  int currentLikeCount = response['like_count'] ?? 0;

  // 좋아요 수 1 증가
  await supabase
      .from('event_group_posts')
      .update({'like_count': currentLikeCount + 1})
      .eq('id', postId);
  } catch (e) {
  print('Error incrementing like count: $e');
  rethrow;
  }
  }

  // 게시글 좋아요 수 감소
  static Future<void> decrementEventGroupPostLikeCount(int postId) async {
  try {
  // 현재 좋아요 수 가져오기
  final response = await supabase
      .from('event_group_posts')
      .select('like_count')
      .eq('id', postId)
      .single();

  int currentLikeCount = response['like_count'] ?? 0;

  // 좋아요 수가 0보다 큰 경우에만 감소
  if (currentLikeCount > 0) {
  await supabase
      .from('event_group_posts')
      .update({'like_count': currentLikeCount - 1})
      .eq('id', postId);
  }
  } catch (e) {
  print('Error decrementing like count: $e');
  rethrow;
  }
  }

  // 게시글 좋아요 수 조회
  static Future<int> getEventGroupPostLikeCount(int postId) async {
  try {
  final response = await supabase
      .from('event_group_posts')
      .select('like_count')
      .eq('id', postId)
      .single();
  return response['like_count'] ?? 0;
  } catch (e) {
  print('Error getting post like count: $e');
  return 0;
  }
  }

  // 시간 차이를 문자열로 변환하는 함수
  static String getTimeAgo(String dateTimeStr) {
  final dateTime = DateTime.parse(dateTimeStr);
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays > 365) {
  return '${(difference.inDays / 365).floor()}년 전';
  } else if (difference.inDays > 30) {
  return '${(difference.inDays / 30).floor()}개월 전';
  } else if (difference.inDays > 0) {
  return '${difference.inDays}일 전';
  } else if (difference.inHours > 0) {
  return '${difference.inHours}시간 전';
  } else if (difference.inMinutes > 0) {
  return '${difference.inMinutes}분 전';
  } else {
  return '방금 전';
  }
  }






// 내가 쓴 모든 글 가져오기 (통합)
  static Future<List<Map<String, dynamic>>> getAllMyPosts(int userId) async {
    final supabase = Supabase.instance.client;
    try {
      // 자유게시판 게시글
      final freeboardPosts = await supabase
          .from('freeboard')
          .select('''
          *,
          profiles:user_id (*)
        ''')
          .eq('user_id', userId);

      // 리뷰 게시글
      final reviewPosts = await supabase
          .from('review')
          .select('''
          *,
          profiles:user_id (*)
        ''')
          .eq('user_id', userId);

      // 구인구직 게시글
      final jobPosts = await supabase
          .from('jobs')
          .select('''
          *,
          profiles:user_id (*)
        ''')
          .eq('user_id', userId);

      // 행사팟 게시글 추가
      final eventGroupPosts = await supabase
          .from('event_group_posts')
          .select('''
        *,
        profiles:user_id (*)
      ''')
          .eq('user_id', userId);

      // 댓글 수를 가져오는 함수
      Future<int> getCommentCount(String postId, String postType) async {
        final comments = await supabase
            .from('comments')
            .select('id')
            .eq('post_id', postId)
            .eq('board_type', postType);
        return comments.length;
      }

      List<Map<String, dynamic>> allPosts = [];

      // 자유게시판 게시글 포맷팅
      for (var post in freeboardPosts) {
        final commentCount = await getCommentCount(post['id'].toString(), 'freeboard');
        allPosts.add({
          ...post,
          'type': 'freeboard',
          'likeCount': post['like_count'] ?? 0,  // 테이블의 like_count 컬럼 사용
          'commentCount': commentCount,
          'createdAt': post['created_at'],
          'authorNickname': post['profiles']['nickname'] ?? post['profiles']['email'],
        });
      }

      // 리뷰 게시글 포맷팅
      for (var post in reviewPosts) {
        final commentCount = await getCommentCount(post['id'].toString(), 'review');
        allPosts.add({
          ...post,
          'type': 'review',
          'likeCount': post['like_count'] ?? 0,  // 테이블의 like_count 컬럼 사용
          'commentCount': commentCount,
          'createdAt': post['created_at'],
          'authorNickname': post['profiles']['nickname'] ?? post['profiles']['email'],
        });
      }

      // 구인구직 게시글 포맷팅
      for (var post in jobPosts) {
        final commentCount = await getCommentCount(post['id'].toString(), 'job');
        allPosts.add({
          ...post,
          'type': 'job',
          'likeCount': post['like_count'] ?? 0,  // 테이블의 like_count 컬럼 사용
          'commentCount': commentCount,
          'createdAt': post['created_at'],
          'authorNickname': post['profiles']['nickname'] ?? post['profiles']['email'],
        });
      }

      // 행사팟 게시글 포맷팅
      for (var post in eventGroupPosts) {
        final commentCount = await getCommentCount(post['id'].toString(), 'event_group');
        allPosts.add({
          ...post,
          'type': 'event_group',
          'likeCount': post['like_count'] ?? 0,
          'commentCount': commentCount,
          'createdAt': post['created_at'],
          'authorNickname': post['profiles']['nickname'] ?? post['profiles']['email'],
        });
      }

      // 날짜순으로 정렬
      allPosts.sort((a, b) {
        return DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt']));
      });

      return allPosts;
    } catch (e) {
      print('Error getting all posts: $e');
      rethrow;
    }
  }
// 타입별 필터링 메서드들
  static Future<List<Map<String, dynamic>>> getMyPosts(int userId) async {
    final allPosts = await getAllMyPosts(userId);
    return allPosts.where((post) => post['type'] == 'freeboard').toList();
  }

  static Future<List<Map<String, dynamic>>> getMyReviews(int userId) async {
    final allPosts = await getAllMyPosts(userId);
    return allPosts.where((post) => post['type'] == 'review').toList();
  }

  static Future<List<Map<String, dynamic>>> getMyJobs(int userId) async {
    final allPosts = await getAllMyPosts(userId);
    return allPosts.where((post) => post['type'] == 'job').toList();
  }
  static Future<List<dynamic>> searchByBoard(String query, String boardType) async {
    final supabase = Supabase.instance.client;
    try {
      print('Searching for: $query in board: $boardType');

      // 게시판 테이블 이름 결정 (행사팟 추가)
      String tableName;
      if (boardType == 'job') {
        tableName = 'jobs';
      } else if (boardType == 'event_group') {
        tableName = 'event_group_posts'; // 행사팟 테이블명
      } else {
        tableName = boardType;
      }

      // 쿼리 실행
      final response = await supabase
          .from(tableName)
          .select('''
        *,
        profiles:user_id (nickname, email)
      ''')
          .or('title.ilike.%${query}%,content.ilike.%${query}%')
          .order('created_at', ascending: false);

      print('Raw response for $boardType: $response');

      // 검색 결과 포맷팅
      return response.map((post) => {
        'id': post['id'],
        'title': post['title'],
        'content': post['content'],
        'authorNickname': post['profiles']['nickname'] ?? post['profiles']['email'],
        'createdAt': post['created_at'],
        'likeCount': post['like_count'] ?? 0,
        'viewCount': post['view_count'] ?? 0,
        'boardType': boardType,

      }).toList();
    } catch (e) {
      print('게시판 검색 에러: $e');
      throw e;
    }
  }

  static Future<Map<String, dynamic>> searchAll(String query) async {
    final supabase = Supabase.instance.client;
    try {
      print('Searching all boards for: $query');

      // 각 게시판별로 검색 실행
      final freeboardResults = await searchByBoard(query, 'freeboard');
      final reviewResults = await searchByBoard(query, 'review');
      final jobResults = await searchByBoard(query, 'job');
      final eventGroupResults = await searchByBoard(query, 'event_group');

      Map<String, dynamic> results = {
        'freeboard': freeboardResults,
        'review': reviewResults,
        'job': jobResults,
        'event_group': eventGroupResults

      };

      print('Formatted search results: $results');
      return results;
    } catch (e) {
      print('전체 검색 에러: $e');
      throw e;
    }
  }
  // 검색 결과 포맷팅 헬퍼 메서드
  static Map<String, dynamic> formatSearchResult(dynamic post) {
    return {
      'id': post['id'],
      'title': post['title'],
      'content': post['content'],
      'authorNickname': post['authorNickname'],
      'createdAt': post['createdAt'],
      'likeCount': post['likeCount'],
      'viewCount': post['viewCount'],
      'boardType': post['boardType'],
    };
  }










/// 모든 이벤트 조회
  static Future<List<dynamic>> getAllEvents() async {
    final supabase = Supabase.instance.client;
    try {
      final userId = await UserPreferences.getUserId();

      if (userId <= 0) {
        throw Exception('User not logged in');
      }

      final response = await supabase
          .from('events')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      print('Events Response: $response');
      return response;
    } catch (e) {
      print('Error in getAllEvents: $e');
      throw e;
    }
  }

// 이벤트 생성
  static Future<Map<String, dynamic>> createEvent(Map<String, dynamic> eventData, String userId) async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('events')
          .insert({
        'title': eventData['title'],
        'location': eventData['location'],
        'date': eventData['date'],
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      })
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error creating event: $e');
      throw Exception('Failed to create event');
    }
  }


// 이벤트 삭제
  static Future<void> deleteEvent(int eventId) async {
    final supabase = Supabase.instance.client;
    try {
      print('Deleting event with ID: $eventId'); // 디버깅용 로그

      final response = await supabase
          .from('events')
          .delete()
          .eq('id', eventId);

      print('Delete response: $response'); // 디버깅용 로그
    } catch (e) {
      print('Error deleting event: $e');
      throw Exception('Failed to delete event: $e');
    }
  }

// 특정 날짜의 이벤트 조회
  static Future<List<dynamic>> getEventsByDate(String date) async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('events')
          .select()
          .eq('date', date)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      print('Error getting events by date: $e');
      throw Exception('Failed to load events for date');
    }
  }

  // 자유게시글 수정
  static Future<Map<String, dynamic>> updatePost(int postId, Map<String, dynamic> postData) async {
    try {
      final supabase = Supabase.instance.client;

      // created_at 필드가 있다면 제거 (수정 시 변경되지 않도록)
      final updateData = Map<String, dynamic>.from(postData);
      updateData.remove('created_at');

      // updated_at 필드 추가
      updateData['updated_at'] = DateTime.now().toIso8601String();

      print('Updating post $postId with data: $updateData');

      final response = await supabase
          .from('freeboard')
          .update(updateData)
          .eq('id', postId)
          .select()
          .single();

      print('Post updated successfully: $response');
      return response;
    } catch (e) {
      print('Error updating post: $e');
      if (e.toString().contains('Row not found')) {
        throw Exception('게시글을 찾을 수 없습니다');
      } else if (e.toString().contains('Permission denied')) {
        throw Exception('수정 권한이 없습니다');
      } else {
        throw Exception('게시글 수정에 실패했습니다: $e');
      }
    }
  }

  // 자유게시글 삭제
  static Future<void> deletePost(int postId) async {
    try {
      print('Deleting post $postId');
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('freeboard')
          .delete()
          .eq('id', postId);

      print('Delete response: $response');

    } catch (e) {
      print('Error deleting post: $e');
      throw Exception('게시글 삭제에 실패했습니다');
    }
  }


// 게시글 신고
  static Future<void> reportPost(Report report) async {
    final supabase = Supabase.instance.client;
    try {
      print('Reporting post with data: ${report.toJson()}');

      // BoardType에 따른 테이블 이름 매핑
      String tableName;
      switch (report.boardType) {
        case 'job':
          tableName = 'jobs';
          break;
        case 'review':
          tableName = 'review';
          break;
        case 'freeboard':
          tableName = 'freeboard';
          break;
        case 'event_group':
          tableName = 'event_group_posts';
          break;
        default:
          throw Exception('잘못된 게시판 타입입니다');
      }

      // 자신의 글인지 확인
      final post = await supabase
          .from(tableName)
          .select('user_id')
          .eq('id', report.targetId)
          .single();

      // 자신의 글이면 신고 불가
      if (post['user_id'] == report.reporterId) {
        throw Exception('자신의 글은 신고할 수 없습니다');
      }

      // 이미 신고했는지 확인
      final existingReport = await supabase
          .from('reports')
          .select()
          .eq('reporter_id', report.reporterId)
          .eq('board_type', report.boardType)  // 이미 String이므로 그대로 사용
          .eq('target_id', report.targetId);

      if (existingReport.isNotEmpty) {
        throw Exception('이미 신고한 게시글입니다');
      }

      // 신고 생성
      await supabase
          .from('reports')
          .insert({
        'reporter_id': report.reporterId,
        'board_type': report.boardType,  // 이미 String이므로 그대로 사용
        'target_id': report.targetId,
        'reason': report.reason,
        'description': report.description,
        'status': report.status,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('Report created successfully');
    } catch (e) {
      print('Error reporting post: $e');
      if (e.toString().contains('Exception:')) {
        throw e;
      }
      throw Exception('게시글 신고에 실패했습니다');
    }
  }

// 신고 상태 조회 (옵션)
  static Future<bool> hasReported(int reporterId, String boardType, int targetId) async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('reports')
          .select()
          .eq('reporter_id', reporterId)
          .eq('board_type', boardType)
          .eq('target_id', targetId);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking report status: $e');
      throw Exception('신고 상태 확인에 실패했습니다');
    }
  }





  // 회원가입
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String nickname,
    required String phone,
    required String birthDate,
    required String gender,
    required String userType,
    String? agencyName,
    String? agencyAddress,
    String? businessNumber,
  }) async {
    try {
      // 이메일 중복 체크
      final emailCheck = await supabase
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (emailCheck != null) {
        throw Exception('이미 사용 중인 이메일입니다');
      }

      // 닉네임 중복 체크
      final nicknameCheck = await supabase
          .from('users')
          .select('nickname')
          .eq('nickname', nickname)
          .maybeSingle();

      if (nicknameCheck != null) {
        throw Exception('이미 사용 중인 닉네임입니다');
      }

      // 1. Supabase Auth로 회원가입
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('회원가입 실패');
      }

      // 2. Supabase users 테이블에 추가 정보 저장
      final userData = await supabase.from('users').insert({
        'email': email,
        'password': password,  // 해시된 비밀번호
        'nickname': nickname,
        'phone': phone,
        'birth_date': birthDate,
        'gender': gender,
        'user_type': userType,
        'enabled': true,
        'role': 'USER',
        'provider': 'email',
        'provider_id': authResponse.user!.id,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      // 3. UserPreferences에 사용자 정보 저장
      await UserPreferences.setUserId(userData['id']);
      await UserPreferences.setUserNickname(userData['nickname']);
      await UserPreferences.setUserEmail(userData['email']);

      return userData;
    } catch (e) {
      print('Registration error: $e');
      // 에러 메시지를 그대로 전달
      throw Exception(e.toString().contains('Exception:')
          ? e.toString().split('Exception: ')[1]
          : '회원가입 실패: $e');
    }
  }
  // 로그인
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('로그인 시도: $email');

      // 1. Supabase Auth로 로그인
      final authResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('로그인 실패: 인증 실패');
      }

      print('Supabase 인증 성공');

      // 2. users 테이블에서 사용자 정보 가져오기 (provider_id로 조회)
      final userData = await supabase
          .from('users')
          .select()
          .eq('provider_id', authResponse.user!.id)  // email 대신 provider_id 사용
          .single();

      print('사용자 데이터 조회 성공: $userData');

      // 3. UserPreferences에 한 번에 저장
      await UserPreferences.saveUserData(
        userId: userData['id'],
        nickname: userData['nickname'] ?? email,
        apiToken: authResponse.session?.accessToken ?? '',
        email: email,
        userType: userData['user_type'],
      );

      print('UserPreferences 저장 완료');

      return userData;

    } catch (e) {
      print('Login error: $e');
      throw Exception('로그인 실패: 이메일 또는 비밀번호를 확인해주세요');
    }
  }


  // 사용자 정보 수정
  static Future<Map<String, dynamic>> updateUser(int userId, String nickname, String? profileImage) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/auth/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nickname': nickname,
        'profileImage': profileImage,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }

  // 자유게시글 작성
  static Future<Map<String, dynamic>> createPost(Map<String, dynamic> postData) async {
    try {
      final user = supabase.auth.currentUser;
      final userEmail = user?.email;

      if (user == null || userEmail == null) {
        throw Exception('로그인이 필요합니다');
      }

      print('Creating post with data: $postData');

      // 이메일로 사용자 ID 조회 (null이 아닌 email 사용)
      final userData = await supabase
          .from('users')
          .select('id')
          .eq('email', userEmail)  // null이 아님이 보장된 userEmail 사용
          .single();

      if (userData == null) throw Exception('사용자 정보를 찾을 수 없습니다');

      final insertData = {
        'title': postData['title'],
        'content': postData['content'],
        'user_id': userData['id'],
        'view_count': 0,
        'like_count': 0,
        'images': postData['images'],
      };

      final response = await supabase
          .from('freeboard')
          .insert(insertData)
          .select()
          .single();

      return {
        'id': response['id'],
        'title': response['title'],
        'content': response['content'],
        'userId': response['user_id'],
        'createdAt': response['created_at'],
        'likeCount': response['like_count'] ?? 0,
        'viewCount': response['view_count'] ?? 0,
        'images': response['images'] ?? [],
      };
    } catch (e) {
      print('Error in createPost: $e');
      print('Insert data: $postData');
      print('Current user email: ${supabase.auth.currentUser?.email}');
      rethrow;
    }
  }
  // 자유게시판 목록 조회
  static Future<List<Map<String, dynamic>>> getAllPosts() async {
    try {
      print('Fetching all posts...');

      // 현재 시간 (KST) 출력
      final now = DateTime.now();
      print('Current time (KST): $now');

      // 기본 게시글 데이터 조회
      final response = await supabase
          .from('freeboard')
          .select('*')
          .lte('created_at', now.toIso8601String()) // 현재 시간 이전의 게시글만
          .order('created_at', ascending: false);

      print('Total posts found: ${response.length}');

      List<Map<String, dynamic>> formattedPosts = [];

      for (final post in response) {
        try {
          print('Processing post ID: ${post['id']}');
          print('Created at (KST): ${post['created_at']}');

          DateTime createdAt;
          try {
            createdAt = DateTime.parse(post['created_at']);
            print('Parsed created_at: $createdAt');

            // 시간 차이 계산 (디버깅용)
            final timeDiff = now.difference(createdAt);
            print('Time difference for post ${post['id']}: ${timeDiff.inMinutes} minutes');
          } catch (e) {
            print('Error parsing date for post ${post['id']}: $e');
            continue;
          }

          // 작성자 정보 조회
          final authorData = await supabase
              .from('users')
              .select('nickname, role')
              .eq('id', post['user_id'])
              .maybeSingle();

          if (authorData == null) {
            print('Author not found for post ${post['id']}');
          }

          // 댓글 수 조회
          final comments = await supabase
              .from('comments')
              .select()
              .eq('post_id', post['id'])
              .eq('board_type', 'freeboard');

          formattedPosts.add({
            'id': post['id'],
            'title': post['title'],
            'content': post['content'],
            'authorNickname': authorData?['nickname'] ?? '익명',
            'createdAt': post['created_at'],
            'time': getTimeAgo(post['created_at']), // getTimeAgo 함수 사용
            'likeCount': post['like_count'] ?? 0,
            'viewCount': post['view_count'] ?? 0,
            'commentCount': comments.length,
            'authorRole': authorData?['role'] ?? 'USER',  // role 정보 추가
          });

          print('Successfully processed post ${post['id']}');
        } catch (e) {
          print('Error processing post ${post['id']}: $e');
          continue;
        }
      }

      print('Successfully formatted posts: ${formattedPosts.length}');

      // 시간순 정렬 한번 더 확인
      formattedPosts.sort((a, b) {
        final aDate = DateTime.parse(a['createdAt']);
        final bDate = DateTime.parse(b['createdAt']);
        return bDate.compareTo(aDate);
      });

      // 디버깅을 위해 첫 번째와 마지막 게시글의 시간 출력
      if (formattedPosts.isNotEmpty) {
        print('First post time: ${formattedPosts.first['createdAt']}');
        print('Last post time: ${formattedPosts.last['createdAt']}');
      }

      return formattedPosts;
    } catch (e) {
      print('Error in getAllPosts: $e');
      throw Exception('Failed to load posts: $e');
    }
  }

  // 특정 자유게시글 조회
  static Future<Map<String, dynamic>> getPost(int id) async {
    try {
      // 게시글 조회
      final response = await supabase
          .from('freeboard')
          .select('''
          *,
          user:user_id (
            id,
            nickname,
            role  // role 필드 추가
          ),
          likes:freeboard_likes (count)
        ''')
          .eq('id', id)
          .single();

      // 조회수 증가
      await supabase
          .from('freeboard')
          .update({ 'view_count': (response['view_count'] ?? 0) + 1 })
          .eq('id', id);

      return {
        'id': response['id'],
        'title': response['title'],
        'content': response['content'],
        'authorNickname': response['user']['nickname'],
        'createdAt': response['created_at'],
        'likeCount': response['likes'][0]['count'] ?? 0,
        'viewCount': response['view_count'] + 1,
        'userId': response['user_id'],
        'authorRole': response['user']['role'],  // role 정보 추가
        'images': response['images'] ?? [],
      };
    } catch (e) {
      print('Error in getPost: $e');
      rethrow;
    }
  }





// 게시글 좋아요 상태 확인
  static Future<bool> isPostLiked(int postId) async {
    try {
      final user = supabase.auth.currentUser;
      final userEmail = user?.email;
      if (user == null || userEmail == null) return false;

      // email로 users 테이블에서 실제 id를 조회
      final userData = await supabase
          .from('users')
          .select('id')
          .eq('email', userEmail)
          .maybeSingle();

      if (userData == null) return false;
      final userId = userData['id'];

      final response = await supabase
          .from('freeboard_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

// 좋아요 토글 (좋아요/취소)
  static Future<Map<String, dynamic>> toggleLike(int postId) async {
    try {
      final user = supabase.auth.currentUser;
      final userEmail = user?.email;
      if (user == null || userEmail == null) throw Exception('로그인이 필요합니다');

      // email로 users 테이블에서 실제 id를 조회
      final userData = await supabase
          .from('users')
          .select('id')
          .eq('email', userEmail)
          .maybeSingle();

      if (userData == null) throw Exception('사용자 정보를 찾을 수 없습니다');
      final userId = userData['id'];

      // 현재 좋아요 상태 확인
      final existingLike = await supabase
          .from('freeboard_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike == null) {
        // 좋아요 추가
        await supabase.from('freeboard_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });

        // 게시글의 좋아요 수 증가
        await supabase.rpc('increment_freeboard_like_count', params: {
          'post_id_param': postId
        });

        return {
          'liked': true,
          'likeCount': await getPostLikeCount(postId),
        };
      } else {
        // 좋아요 삭제
        await supabase
            .from('freeboard_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);

        // 게시글의 좋아요 수 감소
        await supabase.rpc('decrement_freeboard_like_count', params: {
          'post_id_param': postId
        });

        return {
          'liked': false,
          'likeCount': await getPostLikeCount(postId),
        };
      }
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

// 게시글 좋아요 수 조회
  static Future<int> getPostLikeCount(int postId) async {
    try {
      final response = await supabase
          .from('freeboard')  // 게시판 테이블 이름에 맞게 수정
          .select('like_count')
          .eq('id', postId)
          .single();
      return response['like_count'] ?? 0;
    } catch (e) {
      print('Error getting post like count: $e');
      return 0;
    }
  }


// 댓글 목록 가져오기 (대댓글 포함)
  static Future<List<Comment>> getComments(int postId, BoardType boardType) async {
    try {
      print('Fetching comments for post: $postId');
      final response = await supabase
          .from('comments')
          .select('''
          *,
           profiles:user_id(
            nickname,
            role 
          )
        ''')
          .eq('post_id', postId)
          .eq('board_type', boardType.value)
          .order('created_at', ascending: true);

      print('Response data: $response');

      // 모든 댓글을 맵으로 변환
      Map<String, Comment> commentMap = {};
      List<Comment> topLevelComments = [];

      // 먼저 모든 댓글을 Comment 객체로 변환
      for (var json in response as List) {
        Comment comment = Comment(
          id: json['id'].toString(),
          postId: postId.toString(),
          userId: json['user_id']?.toString(),
          content: json['content'] ?? '',
          author: json['profiles']['nickname'] ?? 'Anonymous',
          authorRole: json['profiles']?['role'] ?? 'USER',    // profiles 객체에서 role 가져오기
          createdAt: DateTime.parse(json['created_at']),
          parentId: json['parent_id']?.toString(),
          boardType: boardType,
          replies: [],
        );

        commentMap[comment.id] = comment;
      }

      // 댓글 구조화 (부모-자식 관계 설정)
      for (var comment in commentMap.values) {
        if (comment.parentId == null) {
          // 최상위 댓글
          topLevelComments.add(comment);
        } else {
          // 대댓글
          Comment? parentComment = commentMap[comment.parentId];
          if (parentComment != null) {
            parentComment.replies.add(comment);
          }
        }
      }

      return topLevelComments;
    } catch (e) {
      print('Error getting comments: $e');
      rethrow;
    }
  }
// 댓글/대댓글 작성 통합
  static Future<Comment> createComment({
    required int postId,
    required String content,
    required BoardType boardType,
    String? parentId,
  }) async {
    if (content.trim().isEmpty) {
      throw Exception('Comment content cannot be empty');
    }

    try {
      final user = supabase.auth.currentUser;  // supabase 인스턴스 사용
      final userEmail = user?.email;

      if (user == null || userEmail == null) {
        throw Exception('로그인이 필요합니다');
      }



      // email로 users 테이블에서 실제 id를 조회
      final userData = await supabase
          .from('users')
          .select('id')
          .eq('email', userEmail)
          .maybeSingle();

      if (userData == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다');
      }

      final userId = userData['id'];  // userId 한 번만 선언

      print('=== Creating Comment Debug Info ===');
      print('Post ID: $postId');
      print('User ID: $userId');
      print('Board Type: ${boardType}');
      print('Board Type Value: ${boardType.value}');
      print('Parent ID: $parentId');
      print('Content: ${content.trim()}');
      print('===============================');


      final now = DateTime.now(); // 현재 시간 (이미 KST)
      print('Current time when creating comment: $now');

      final data = await supabase
          .from('comments')
          .insert({
        'post_id': postId,
        'content': content.trim(),
        'user_id': userId,
        'board_type': boardType.value,
        'created_at': now.toIso8601String(), // 현재 시간 저장
        if (parentId != null) 'parent_id': int.parse(parentId),
      })
          .select('''
          *,
          users:user_id(nickname)
        ''')
          .single();

      print('Response from database: $data');

      return Comment(
        id: data['id'].toString(),
        postId: postId.toString(),
        userId: data['user_id']?.toString(),
        content: data['content'],
        author: data['users']['nickname'] ?? 'Anonymous',
        createdAt: DateTime.parse(data['created_at']),
        parentId: data['parent_id']?.toString(),
        boardType: boardType,
        replies: [],
      );
    } catch (e) {
      print('Error creating comment: $e');
      print('BoardType value being used: ${boardType.value}');
      rethrow;
    }
  }


  // 좋아요한 게시글 목록 가져오기
  static Future<List<String>> getLikedPosts() async {
    try {
      final userId = await UserPreferences.getUserId();
      final supabase = Supabase.instance.client;

      // 각 테이블에서 좋아요 데이터 가져오기
      final jobLikes = await supabase
          .from('job_likes')
          .select('job_id')
          .eq('user_id', userId);

      final freeboardLikes = await supabase
          .from('freeboard_likes')
          .select('post_id')
          .eq('user_id', userId);

      final reviewLikes = await supabase
          .from('review_likes')
          .select('review_id')
          .eq('user_id', userId);

      // 모든 좋아요 ID를 하나의 리스트로 합치기
      List<String> allLikedPosts = [
        ...jobLikes.map((like) => like['job_id'].toString()),
        ...freeboardLikes.map((like) => like['post_id'].toString()),
        ...reviewLikes.map((like) => like['review_id'].toString()),
      ];

      return allLikedPosts;
    } catch (e) {
      print('Error getting liked posts: $e');
      return [];
    }
  }

  // 리뷰 삭제
// 리뷰 삭제
  static Future<void> deleteReview(int id) async {
    try {
      final supabase = Supabase.instance.client;

      // 현재 로그인한 사용자 확인
      final user = supabase.auth.currentUser;
      final userEmail = user?.email;

      if (user == null || userEmail == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 사용자 정보 가져오기
      final userData = await supabase
          .from('users')
          .select('id')
          .eq('email', userEmail)
          .maybeSingle();

      if (userData == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다');
      }

      // 리뷰 정보 가져오기
      final review = await supabase
          .from('review')
          .select('user_id')
          .eq('id', id)
          .single();

      // 작성자 확인
      if (review['user_id'] != userData['id']) {
        throw Exception('삭제 권한이 없습니다');
      }

      print('Deleting review $id');
      await supabase
          .from('review')
          .delete()
          .eq('id', id);

      print('Review deleted successfully');
    } catch (e) {
      print('Error deleting review: $e');
      if (e.toString().contains('로그인이 필요합니다')) {
        throw Exception('로그인이 필요합니다');
      } else if (e.toString().contains('삭제 권한이 없습니다')) {
        throw Exception('삭제 권한이 없습니다');
      } else if (e.toString().contains('Row not found')) {
        throw Exception('리뷰를 찾을 수 없습니다');
      } else {
        throw Exception('리뷰 삭제에 실패했습니다: $e');
      }
    }
  }

// 리뷰 수정
  static Future<Map<String, dynamic>> updateReview({
    required int id,
    required String title,
    required String content,
    String? eventName,
    String? eventDate,
    List<String>? images,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // 현재 로그인한 사용자 확인
      final user = supabase.auth.currentUser;
      final userEmail = user?.email;

      if (user == null || userEmail == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 사용자 정보 가져오기
      final userData = await supabase
          .from('users')
          .select('id')
          .eq('email', userEmail)
          .maybeSingle();

      if (userData == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다');
      }
      // 리뷰 정보 가져오기
      final review = await supabase
          .from('review')
          .select('user_id')
          .eq('id', id)
          .single();

      // 작성자 확인
      if (review['user_id'] != userData['id']) {
        throw Exception('수정 권한이 없습니다');
      }

      print('Updating review $id');
      final response = await supabase
          .from('review')
          .update({
        'title': title,
        'content': content,
        'event_name': eventName,
        'event_date': eventDate,
        'images': images,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', id)
          .select('''
          *,
          users!inner (
            nickname
          )
        ''')
          .single();

      print('Review updated successfully: $response');

      return {
        'id': response['id'],
        'title': response['title'],
        'content': response['content'],
        'eventName': response['event_name'],
        'eventDate': response['event_date'],
        'authorNickname': response['users']['nickname'],
        'createdAt': response['created_at'],
        'updatedAt': response['updated_at'],
        'likeCount': response['like_count'] ?? 0,
        'viewCount': response['view_count'] ?? 0,
        'images': response['images'] ?? [],
      };
    } catch (e) {
      print('Error updating review: $e');
      if (e.toString().contains('로그인이 필요합니다')) {
        throw Exception('로그인이 필요합니다');
      } else if (e.toString().contains('수정 권한이 없습니다')) {
        throw Exception('수정 권한이 없습니다');
      } else if (e.toString().contains('Row not found')) {
        throw Exception('리뷰를 찾을 수 없습니다');
      } else {
        throw Exception('리뷰 수정에 실패했습니다: $e');
      }
    }
  }


// 구인글 수정
  static Future<void> updateJob(int id, Map<String, dynamic> jobData) async {
    try {
      final supabase = Supabase.instance.client;

      print('Updating job with ID: $id');

      // created_at 필드를 제외하고 updated_at 필드만 업데이트
      final updateData = Map<String, dynamic>.from(jobData);
      updateData.remove('created_at'); // created_at 필드 제거
      updateData['updated_at'] = DateTime.now().toIso8601String(); // updated_at 필드 업데이트

      print('Update data: $updateData');

      await supabase
          .from('jobs')
          .update(updateData)
          .eq('id', id);

      print('Job updated successfully');

    } catch (e) {
      print('Error in updateJob: $e');
      if (e.toString().contains('Row not found')) {
        throw Exception('게시글을 찾을 수 없습니다');
      } else if (e.toString().contains('Permission denied')) {
        throw Exception('수정 권한이 없습니다');
      } else {
        throw Exception('구인글 수정에 실패했습니다');
      }
    }
  }

// 구인글 삭제
  static Future<void> deleteJob(int jobId) async {
    try {
      final supabase = Supabase.instance.client;

      print('Deleting job with ID: $jobId');

      await supabase
          .from('jobs')
          .delete()
          .eq('id', jobId);

      print('Job deleted successfully');

    } catch (e) {
      print('Error deleting job post: $e');
      if (e.toString().contains('Row not found')) {
        throw Exception('존재하지 않는 게시글입니다');
      } else if (e.toString().contains('Permission denied')) {
        throw Exception('삭제 권한이 없습니다');
      } else {
        throw Exception('게시글 삭제에 실패했습니다');
      }
    }
  }



  // 구인글 목록 조회
  static Future<List<Map<String, dynamic>>> getJobs() async {
    try {
      // 현재 사용자 ID 조회
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

      // 현재 시간 (KST) 출력
      final now = DateTime.now();


      // 기본 게시글 데이터 조회 - created_at이 현재 시간보다 이전인 것만 조회
      final jobs = await supabase
          .from('jobs')
          .select('*')
          .lte('created_at', now.toIso8601String()) // 현재 시간 이전의 게시글만
          .order('created_at', ascending: false);

      print('Total jobs found: ${jobs.length}');

      List<Map<String, dynamic>> formattedJobs = [];
      for (final job in jobs) {
        try {
          print('Processing job ID: ${job['id']}');
          print('Created at (KST): ${job['created_at']}');

          DateTime createdAt;
          try {
            createdAt = DateTime.parse(job['created_at']);
            print('Parsed created_at: $createdAt');
          } catch (e) {
            print('Error parsing date for job ${job['id']}: $e');
            continue;
          }

          // 작성자 정보 조회
          final authorData = await supabase
              .from('users')
              .select('nickname, id, role')
              .eq('id', job['user_id'])
              .maybeSingle();

          if (authorData == null) {
            print('Author not found for job ${job['id']}');
            continue;
          }

          final likes = await supabase
              .from('job_likes')
              .select('user_id')
              .eq('job_id', job['id']);

          final comments = await supabase
              .from('comments')
              .select()
              .eq('post_id', job['id'])
              .eq('board_type', 'job');

          // 시간 차이 계산 (디버깅용)
          final timeDiff = now.difference(createdAt);
          print('Time difference for job ${job['id']}: ${timeDiff.inMinutes} minutes');

          formattedJobs.add({
            'id': job['id'],
            'title': job['title'],
            'content': job['content'],
            'user_id': job['user_id'],
            'wage': job['wage']?.toString() ?? '0',
            'location': job['location'] ?? '',
            'region': job['region'] ?? '',
            'district': job['district'] ?? '',
            'date': job['event_date'] ?? '',
            'authorNickname': authorData['nickname'],
            'authorId': authorData['id'],
            'created_at': job['created_at'],
            'time': getTimeAgo(job['created_at']),
            'status': job['status'],
            'likeCount': job['like_count'],
            'viewCount': job['view_count'],
            'commentCount': comments.length,
            'isLiked': userId != null && likes.any((like) => like['user_id'] == userId),
            'authorRole': authorData['role'],
          });
        } catch (e) {
          print('Error processing job ${job['id']}: $e');
          continue;
        }
      }

      print('Successfully formatted jobs: ${formattedJobs.length}');

      // 시간순 정렬 한번 더 확인
      formattedJobs.sort((a, b) {
        final aDate = DateTime.parse(a['created_at']);
        final bDate = DateTime.parse(b['created_at']);
        return bDate.compareTo(aDate);
      });

      return formattedJobs;
    } catch (e) {
      print('Error getting jobs: $e');
      throw Exception('Failed to load jobs: $e');
    }
  }
// 구인글 상세 조회
  static Future<Map<String, dynamic>> getJobDetail(int jobId) async {
    try {
      final supabase = Supabase.instance.client;

      // 게시글 기본 정보 가져오기
      final response = await supabase
          .from('jobs')
          .select('''
          *,
          users!inner (
            id,
            nickname,
            profile_image,
            role 
          )
        ''')
          .eq('id', jobId)
          .single();

      // 전체 댓글 수를 별도로 조회 (본댓글 + 대댓글)
      final commentsCount = await supabase
          .from('comments')
          .count()
          .eq('post_id', jobId)
          .eq('board_type', 'job');

      // 조회수 증가
      await supabase
          .from('jobs')
          .update({ 'view_count': (response['view_count'] ?? 0) + 1 })
          .eq('id', jobId);

      return {
        'id': response['id'],
        'title': response['title'],
        'content': response['content'],
        'authorId': response['user_id'],
        'authorNickname': response['users']['nickname'],
        'createdAt': response['created_at'],
        'likeCount': response['like_count'] ?? 0,
        'viewCount': (response['view_count'] ?? 0) + 1,
        'status': response['status'],
        'location': response['location'],
        'salary': response['salary'],
        'workingHours': response['working_hours'],
        'requirements': response['requirements'],
        'benefits': response['benefits'],
        'contactInfo': response['contact_info'],
        'deadline': response['deadline'],
        'commentCount': commentsCount,  // 전체 댓글 수
        'images': response['images'] ?? [],
        'event_date': response['event_date'],  // event_date 필드 추가
        'authorRole': response['users']['role'],
      };
    } catch (e) {
      print('Error getting job detail: $e');
      throw Exception('구인글을 불러오는데 실패했습니다');
    }
  }

// 구인글 좋아요 토글

  static Future<void> toggleJobLike(int jobId) async {
    try {
      final user = supabase.auth.currentUser;
      final userEmail = user?.email;

      if (user == null || userEmail == null) {
        throw Exception('로그인이 필요합니다');
      }

      final userData = await supabase
          .from('users')
          .select('id')
          .eq('email', userEmail)
          .maybeSingle();

      if (userData == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다');
      }

      final userId = userData['id'];

      // 현재 좋아요 상태 확인
      final likeStatus = await supabase
          .from('job_likes')
          .select()
          .eq('job_id', jobId)
          .eq('user_id', userId)
          .maybeSingle();

      if (likeStatus == null) {
        // 좋아요 추가
        await supabase
            .from('job_likes')
            .insert({
          'job_id': jobId,
          'user_id': userId,
        });
        await supabase.rpc('increment_job_like_count', params: {
          'job_id_param': jobId
        });
      } else {
        // 좋아요 취소
        await supabase
            .from('job_likes')
            .delete()
            .eq('job_id', jobId)
            .eq('user_id', userId);
        await supabase.rpc('decrement_job_like_count', params: {
          'job_id_param': jobId
        });
      }
    } catch (e) {
      print('Error in toggleJobLike: $e');
      rethrow;
    }
  }
// 구인글 좋아요 상태 확인
  static Future<bool> isJobLiked(int jobId) async {
    try {
      final user = supabase.auth.currentUser;
      final userEmail = user?.email;
      if (user == null || userEmail == null) return false;

      final userData = await supabase
          .from('users')
          .select('id')
          .eq('email', userEmail)
          .maybeSingle();

      if (userData == null) return false;
      final userId = userData['id'];

      final response = await supabase
          .from('job_likes')
          .select()
          .eq('job_id', jobId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking job like status: $e');
      return false;
    }
  }

// 구인글 좋아요 수 조회
  static Future<int> getJobLikeCount(int jobId) async {
    try {
      // 직접 좋아요 레코드를 카운트
      final likes = await supabase
          .from('job_likes')
          .select()
          .eq('job_id', jobId);

      return likes.length;
    } catch (e) {
      print('Error getting job like count: $e');
      return 0;
    }
  }




  // 구인글 작성
  static Future<Map<String, dynamic>> createJob(Map<String, dynamic> jobData) async {
    String debugInfo = '';  // 디버깅 정보를 저장할 변수
    try {
      final user = supabase.auth.currentUser;
      final userEmail = user?.email;

      debugInfo += '유저 이메일: $userEmail\n';

      if (user == null || userEmail == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 이메일로 사용자 ID 조회 시도
      final userData = await supabase
          .from('users')
          .select('id, email, provider')
          .eq('email', userEmail)
          .maybeSingle();

      debugInfo += '유저 데이터: ${userData?.toString()}\n';

      if (userData == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다. 이메일: $userEmail');
      }

      final jobWithMetadata = {
        ...jobData,
        'user_id': userData['id'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'like_count': 0,
        'view_count': 0,
        'status': jobData['status'] ?? 'OPEN',
      };

      debugInfo += '저장할 데이터: ${jobWithMetadata.toString()}\n';

      final response = await supabase
          .from('jobs')
          .insert(jobWithMetadata)
          .select('*, users!inner(nickname)')
          .single();

      debugInfo += '저장 성공: ${response.toString()}\n';

      final authorData = await supabase
          .from('users')
          .select('nickname')
          .eq('id', response['user_id'])
          .single();

      return {
        'id': response['id'],
        'title': response['title'],
        'content': response['content'],
        'wage': response['wage']?.toString() ?? '0',
        'location': response['location'] ?? '',
        'region': response['region'] ?? '',
        'district': response['district'] ?? '',
        'date': response['event_date'] ?? '',
        'status': response['status'] ?? 'OPEN',
        'contact_info': response['contact_info'] ?? '',
        'created_at': response['created_at'],
        'updated_at': response['updated_at'],
        'like_count': response['like_count'] ?? 0,
        'view_count': response['view_count'] ?? 0,
        'authorNickname': authorData['nickname'],
        'debugInfo': debugInfo,  // 디버깅 정보 포함
      };
    } catch (e) {
      debugInfo += '에러 발생: $e\n';
      throw Exception('$debugInfo');  // 에러와 함께 디버깅 정보 전달
    }
  }

  Future<int?> getCurrentUserId() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final userData = await supabase
          .from('users')
          .select('id')
          .eq('provider_id', user.id)  // auth.uid()와 매칭되는 provider_id 사용
          .single();

      return userData['id'];
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }


  static Future<Map<String, dynamic>> createReview({
    required String title,
    required String content,
    required String eventName,
    required String eventDate,
    List<String>? images,  // XFile 대신 String(URL) 배열로 변경
  }) async {
    try {
      final user = supabase.auth.currentUser;
      final userEmail = user?.email;
      if (user == null || userEmail == null) throw Exception('로그인이 필요합니다');

      // provider_id로 users 테이블에서 사용자 정보 조회
      final userData = await supabase
          .from('users')
          .select('id, nickname')
          .eq('email', userEmail)
          .single();

      print('Creating review with data: {title: $title, content: $content, event_name: $eventName, event_date: $eventDate, images: $images}');

      // 리뷰 데이터 저장
      final response = await supabase
          .from('review')
          .insert({
        'title': title,
        'content': content,
        'event_name': eventName,
        'event_date': eventDate,
        'user_id': userData['id'],
        'view_count': 0,
        'like_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'images': images,  // 이미지 URL 배열 추가
      })
          .select('''
          *,
          users!inner (
            nickname
          )
        ''')
          .single();

      print('Review created successfully: ${response.toString()}');

      return {
        'id': response['id'],
        'title': response['title'],
        'content': response['content'],
        'eventName': response['event_name'],
        'eventDate': response['event_date'],
        'authorNickname': response['users']['nickname'],
        'createdAt': response['created_at'],
        'likeCount': response['like_count'] ?? 0,
        'viewCount': response['view_count'] ?? 0,
        'commentCount': 0,
        'images': response['images'] ?? [],  // 이미지 URL 배열 추가
      };
    } catch (e) {
      print('Error in createReview: $e');
      rethrow;
    }
  }



// 리뷰 전체 목록 조회

      static Future<List<Map<String, dynamic>>> getReviews() async {
        try {
          final userId = await UserPreferences.getUserId();

          // 현재 시간 (KST) 출력
          final now = DateTime.now();
          print('Current time (KST): $now');

          // 리뷰 기본 정보 가져오기
          final response = await supabase
              .from('review')
              .select('''
          *,
          users!inner (
            nickname,
            profile_image,
            role  
          ),
          review_likes!review_likes_review_id_fkey (
            user_id
          )
        ''')
              .lte('created_at', now.toIso8601String()) // 현재 시간 이전의 리뷰만
              .order('created_at', ascending: false);

          print('Total reviews found: ${response.length}');

          // 각 리뷰의 댓글 수를 개별적으로 가져오기
          final commentCounts = await Future.wait(
              response.map((review) async {
                final comments = await supabase
                    .from('comments')
                    .select()
                    .eq('post_id', review['id'])
                    .eq('board_type', 'review');
                return MapEntry(review['id'], comments.length);
              })
          );

          // 댓글 수를 Map으로 변환
          final commentCountMap = Map.fromEntries(commentCounts);

          List<Map<String, dynamic>> formattedReviews = [];

          for (final review in response) {
            try {
              print('Processing review ID: ${review['id']}');
              print('Created at (KST): ${review['created_at']}');

              DateTime createdAt;
              try {
                createdAt = DateTime.parse(review['created_at']);
                print('Parsed created_at: $createdAt');

                // 시간 차이 계산 (디버깅용)
                final timeDiff = now.difference(createdAt);
                print('Time difference for review ${review['id']}: ${timeDiff.inMinutes} minutes');
              } catch (e) {
                print('Error parsing date for review ${review['id']}: $e');
                continue;
              }

              // 현재 사용자의 좋아요 여부 확인
              final likes = review['review_likes'] as List;
              final isLiked = likes.any((like) => like['user_id'] == userId);

              formattedReviews.add({
                'id': review['id'],
                'title': review['title'],
                'content': review['content'],
                'authorNickname': review['users']['nickname'],
                'authorRole': review['users']['role'] ?? 'USER',  // role 정보 추가
                'createdAt': review['created_at'],
                'time': getTimeAgo(review['created_at']), // getTimeAgo 함수 사용
                'likeCount': review['like_count'] ?? 0,
                'isLiked': isLiked,
                'viewCount': review['view_count'] ?? 0,
                'eventName': review['event_name'],
                'eventDate': review['event_date'],
                'commentCount': commentCountMap[review['id']] ?? 0,
                'viewCount': review['view_count'] ?? 0,
              });
            } catch (e) {
              print('Error processing review ${review['id']}: $e');
              continue;
            }
          }

          print('Successfully formatted reviews: ${formattedReviews.length}');

          // 시간순 정렬 한번 더 확인
          formattedReviews.sort((a, b) {
            final aDate = DateTime.parse(a['createdAt']);
            final bDate = DateTime.parse(b['createdAt']);
            return bDate.compareTo(aDate);
          });

          return formattedReviews;
        } catch (e) {
          print('Error getting reviews: $e');
          throw Exception('Failed to load reviews: $e');
        }
      }

// 리뷰 상세 조회
      static Future<Map<String, dynamic>> getReview(int reviewId) async {
        try {
          // 리뷰 기본 정보 가져오기
          final response = await supabase
              .from('review')
              .select('''
          *,
          users!inner (
            id,
            nickname,
            profile_image,
            role  
          )
        ''')
              .eq('id', reviewId)
              .single();

          // 전체 댓글 수를 별도로 조회 (본댓글 + 대댓글)
          final commentsCount = await supabase
              .from('comments')
              .count()
              .eq('post_id', reviewId)
              .eq('board_type', 'review');

          // 조회수 증가
          await supabase
              .from('review')
              .update({ 'view_count': (response['view_count'] ?? 0) + 1 })
              .eq('id', reviewId);

          return {
            'id': response['id'],
            'title': response['title'],
            'content': response['content'],
            'authorId': response['user_id'],
            'authorNickname': response['users']['nickname'],
            'authorRole': response['users']['role'] ?? 'USER',
            'createdAt': response['created_at'],
            'likeCount': response['like_count'] ?? 0,
            'viewCount': (response['view_count'] ?? 0) + 1,
            'eventName': response['event_name'],
            'eventDate': response['event_date'],
            'commentCount': commentsCount,  // 전체 댓글 수
            'images': response['images'] ?? [],  // 이미지 URL 배열 추가
            'user_id': response['user_id'],  // user_id 추가 (PostOptionsMenu에 필요)
          };
        } catch (e) {
          print('Error in getReview: $e');
          rethrow;
        }
      }

// 리뷰 좋아요 상태 확인
      static Future<bool> isReviewLiked(int reviewId) async {
        try {
          final user = supabase.auth.currentUser;
          final userEmail = user?.email;
          if (user == null || userEmail == null) return false;
      // email로 users 테이블에서 실제 id를 조회
      final userData = await supabase
          .from('users')
          .select('id')
          .eq('email', userEmail)
          .maybeSingle();

      if (userData == null) return false;
      final userId = userData['id'];

      final response = await supabase
          .from('review_likes')
          .select()
          .eq('review_id', reviewId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking review like status: $e');
      return false;
    }
  }

// 리뷰 좋아요 토글
  static Future<Map<String, dynamic>> toggleReviewLike(int reviewId) async {
    try {
      final user = supabase.auth.currentUser;
      final userEmail = user?.email;
      if (user == null || userEmail == null) throw Exception('로그인이 필요합니다');

      // email로 users 테이블에서 실제 id를 조회
      final userData = await supabase
          .from('users')
          .select('id')
          .eq('email', userEmail)
          .maybeSingle();

      if (userData == null) throw Exception('사용자 정보를 찾을 수 없습니다');
      final userId = userData['id'];

      final existingLike = await supabase
          .from('review_likes')
          .select()
          .eq('review_id', reviewId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike == null) {
        // 좋아요 추가
        await supabase
            .from('review_likes')
            .insert({
          'review_id': reviewId,
          'user_id': userId,
        });

        // 리뷰의 좋아요 수 증가
        await supabase.rpc('increment_review_like_count', params: {
          'review_id_param': reviewId
        });

        return {
          'liked': true,
          'likeCount': (await getReviewLikeCount(reviewId)),
        };
      } else {
        // 좋아요 삭제
        await supabase
            .from('review_likes')
            .delete()
            .eq('review_id', reviewId)
            .eq('user_id', userId);

        // 리뷰의 좋아요 수 감소
        await supabase.rpc('decrement_review_like_count', params: {
          'review_id_param': reviewId
        });

        return {
          'liked': false,
          'likeCount': (await getReviewLikeCount(reviewId)),
        };
      }
    } catch (e) {
      print('Error toggling review like: $e');
      rethrow;
    }
  }
// 리뷰의 현재 좋아요 수 조회
  static Future<int> getReviewLikeCount(int reviewId) async {
    try {
      final response = await supabase
          .from('review')
          .select('like_count')
          .eq('id', reviewId)
          .single();

      return response['like_count'] ?? 0;
    } catch (e) {
      print('Error getting review like count: $e');
      return 0;
    }
  }




  static Future<void> createCommentReport({
    required int reporterId,
    required int commentId,
    required BoardType boardType,
    required String reason,
    String description = '',
  }) async {
    try {
      // RLS 정책을 위한 사용자 확인
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }

      // insert 후에 select를 하지 않도록 수정
      await supabase
          .from('comment_reports')
          .insert({
        'reporter_id': reporterId,
        'comment_id': commentId,
        'board_type': boardType.value,
        'reason': reason,
        'description': description,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('Comment report created successfully');

    } catch (e) {
      print('Error creating comment report: $e');
      if (e.toString().contains('duplicate key')) {
        throw Exception('이미 신고한 댓글입니다.');
      }
      throw Exception('댓글 신고 처리에 실패했습니다.');
    }
  }

  static Future<bool> checkCommentAlreadyReported({
    required String reporterId,
    required String commentId,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('comment_reports')
          .select()
          .eq('reporter_id', reporterId)
          .eq('comment_id', commentId)
          .maybeSingle();

      return response != null;  // 신고 기록이 있으면 true, 없으면 false
    } catch (e) {
      print('Error checking comment report: $e');
      throw Exception('신고 상태 확인에 실패했습니다.');
    }
  }

  static Future<void> deleteComment({
    required int commentId,
    required int userId,
    required BoardType boardType,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // 댓글 작성자 확인
      final comment = await supabase
          .from('comments')
          .select()
          .eq('id', commentId)
          .single();

      if (comment['user_id'] != userId) {
        throw Exception('댓글을 삭제할 권한이 없습니다.');
      }

      // 먼저 대댓글들을 삭제
      await supabase
          .from('comments')
          .delete()
          .eq('parent_id', commentId);

      // 그 다음 원본 댓글 삭제
      await supabase
          .from('comments')
          .delete()
          .eq('id', commentId);

    } catch (e) {
      print('Error deleting comment: $e');
      throw Exception('댓글 삭제에 실패했습니다.');
    }
  }

} 