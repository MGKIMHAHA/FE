import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'Comment.dart';
import 'CommentWidget.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/api_service.dart';
import 'utils/date_formatter.dart';
import 'WriteEventGroupPost.dart';
import 'post_options_menu.dart';
import 'utils/user_preferences.dart';
import 'Report.dart';
import 'BoardType.dart';

class AppTheme {
  // 이벤트 커넥트 스타일로 색상 변경
  static const Color primaryColor = Color(0xFF5D6BFF);  // 메인 파란색
  static const Color backgroundColor = Color(0xFFF8F9FA);  // 배경색
  static const Color textColor = Color(0xFF212529);  // 텍스트 색상
  static const Color secondaryTextColor = Color(0xFFADB5BD);  // 보조 텍스트 색상
  static const Color dividerColor = Color(0xFFE9ECEF);  // 구분선 색상
  static const Color likeColor = Colors.red; // 좋아요 보라색
}

class EventGroupBoardDetailPage extends StatefulWidget {
  final int postId;
  final bool? initialLikeStatus;
  final Function(bool)? onLikeChanged;
  const EventGroupBoardDetailPage({
    Key? key,
    required this.postId,
    this.initialLikeStatus,
    this.onLikeChanged,
  }) : super(key: key);

  @override
  _EventGroupBoardDetailPageState createState() => _EventGroupBoardDetailPageState();
}

class _EventGroupBoardDetailPageState extends State<EventGroupBoardDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _post;
  bool _isLoading = true;
  bool _isLiked = false;
  List<Comment> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  Set<String> _collapsedComments = {};

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialLikeStatus ?? false;
    _loadPostAndLikeStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPostAndLikeStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      final userEmail = user?.email;
      if (user == null || userEmail == null) throw Exception('로그인이 필요합니다');

      // provider_id로 users 테이블에서 실제 id를 조회
      final userData = await _supabase
          .from('users')
          .select('id')
          .eq('email', userEmail)
          .single();

      // 좋아요 상태 확인 (행사팟의 경우 event_group_likes 테이블 사용)
      final likeStatus = await _supabase
          .from('event_group_likes')
          .select()
          .eq('eventgroup_id', widget.postId)
          .eq('user_id', userData['id'])
          .maybeSingle();

      // 게시글 조회 (행사팟 테이블 사용)
      final post = await _supabase
          .from('event_group_posts')
          .select('*, images')
          .eq('id', widget.postId)
          .single();

      // 댓글 조회 (board_type을 이벤트 모임 게시판(BoardType.eventGroup)으로 지정)
      final comments = await _supabase
          .from('comments')
          .select()
          .eq('post_id', widget.postId)
          .eq('board_type', 'event_group');

      // 작성자 정보 조회
      final authorData = await _supabase
          .from('users')
          .select('nickname, role')
          .eq('id', post['user_id'])
          .single();

      // 조회수 증가
      await _supabase
          .from('event_group_posts')
          .update({ 'view_count': (post['view_count'] ?? 0) + 1})
          .eq('id', widget.postId);

      if (mounted) {
        setState(() {
          _post = {
            'id': post['id'],
            'title': post['title'],
            'content': post['content'],
            'authorNickname': authorData['nickname'] ?? '익명',
            'authorRole': authorData['role'] ?? 'USER',
            'authorId': post['user_id'],
            'createdAt': post['created_at'],
            'likeCount': post['like_count'] ?? 0,
            'commentCount': comments.length,
            'viewCount': (post['view_count'] ?? 0) + 1,
            'images': post['images'] ?? [],
            'event_date': post['event_date'], // 행사 날짜 추가
            'event_location': post['event_location'], // 행사 장소 추가
          };
          _isLiked = likeStatus != null;
          _isLoading = false;
        });

        _loadComments();
      }
    } catch (e) {
      print('Error loading post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('게시글을 불러오는데 실패했습니다'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await ApiService.getComments(widget.postId, BoardType.eventGroup);
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
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

  Future<void> _addComment(String content, String? parentId) async {
    try {
      await ApiService.createComment(
        postId: widget.postId,
        content: content,
        boardType: BoardType.eventGroup,
        parentId: parentId,
      );

      await Future.wait([
        _loadComments(),
        _loadPostAndLikeStatus(),
      ]);
      _commentController.clear();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + bottomPadding,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error adding comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('댓글 작성에 실패했습니다'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    try {
      final user = _supabase.auth.currentUser;
      final userEmail = user?.email;
      if (user == null || userEmail == null) throw Exception('로그인이 필요합니다');

      final userData = await _supabase
          .from('users')
          .select('id')
          .eq('email', userEmail)
          .single();

      final userId = userData['id'];

      // UI 즉시 업데이트
      setState(() {
        _isLiked = !_isLiked;
        if (_post != null) {
          _post!['likeCount'] = _isLiked
              ? (_post!['likeCount'] + 1)
              : (_post!['likeCount'] - 1);
        }
      });

      widget.onLikeChanged?.call(_isLiked);

      if (_isLiked) {
        // 좋아요 추가
        await _supabase
            .from('event_group_likes')
            .insert({
          'eventgroup_id': widget.postId,
          'user_id': userId,
        });

        // 좋아요 수 증가
        await _supabase
            .from('event_group_posts')
            .update({ 'like_count': _post!['likeCount'] })
            .eq('id', widget.postId);
      } else {
        // 좋아요 제거
        await _supabase
            .from('event_group_likes')
            .delete()
            .eq('eventgroup_id', widget.postId)
            .eq('user_id', userId);

        // 좋아요 수 감소
        await _supabase
            .from('event_group_posts')
            .update({ 'like_count': _post!['likeCount'] })
            .eq('id', widget.postId);
      }
    } catch (e) {
      print('Error toggling like: $e');
      // UI 상태 되돌리기
      setState(() {
        _isLiked = !_isLiked;
        if (_post != null) {
          _post!['likeCount'] = _isLiked
              ? (_post!['likeCount'] + 1)
              : (_post!['likeCount'] - 1);
        }
      });
      widget.onLikeChanged?.call(_isLiked);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('좋아요 처리에 실패했습니다'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  // 이미지 갤러리 위젯 추가
  Widget _buildImageGallery() {
    final images = _post?['images'];
    final List<String> imageUrls = (images as List?)?.map((e) => e.toString()).toList() ?? [];
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 200,
      margin: EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    backgroundColor: Colors.black,
                    appBar: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      iconTheme: const IconThemeData(color: Colors.white),
                    ),
                    body: Center(
                      child: InteractiveViewer(
                        child: Image.network(
                          imageUrls[index],
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return const Icon(Icons.error);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.error_outline, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // 행사 정보 표시 위젯
  Widget _buildEventInfo() {
    if (_post == null || _post!['event_date'] == null || _post!['event_location'] == null) {
      return SizedBox.shrink();
    }

    final DateTime eventDate = DateTime.parse(_post!['event_date']);
    final String formattedDate = '${eventDate.year}년 ${eventDate.month}월 ${eventDate.day}일';

    return Container(
      margin: EdgeInsets.only(top: 20, bottom: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '행사 정보',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 8),
              Text(
                '일시: $formattedDate',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '장소: ${_post!['event_location']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          title: Text('행사팟 구함'),
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    }

    if (_post == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('행사팟 구함'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          centerTitle: true,
        ),
        body: const Center(child: Text('게시글을 찾을 수 없습니다.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '행사팟 구함',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        centerTitle: true,
        actions: [
          PostOptionsMenu(
            post: _post!,
            boardType: BoardType.eventGroup,
            onPostDeleted: () {
              // 게시글이 삭제되면 이전 화면으로 돌아가기
              Navigator.pop(context);
            },
            onPostUpdated: () async {
              // 게시글이 업데이트되면 데이터 새로고침
              await _loadPostAndLikeStatus();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 섹션
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 제목
                        Text(
                          _post!['title'] ?? '제목 없음',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        // 작성자 정보 및 날짜
                        Row(
                          children: [
                            Row(
                              children: [
                                Text(
                                  _post!['authorNickname'] ?? '작성자',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (_post!['authorRole'] == 'MANAGER') ...[
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: AppTheme.primaryColor,
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(width: 10),
                            Text(
                              '·',
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(width: 10),
                            Text(
                              getTimeAgo(_post!['createdAt'] ?? ''),
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${_post!['viewCount'] ?? 0}',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 구분선
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade200,
                  ),

                  // 행사 정보 표시
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildEventInfo(),
                  ),

                  // 본문 내용
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 본문 내용
                        Text(
                          _post!['content'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),

                        // 이미지가 있는 경우 표시
                        if (_post!['images'] != null && (_post!['images'] as List).isNotEmpty)
                          _buildImageGallery(),
                      ],
                    ),
                  ),

                  // 하트 버튼 (우측 하단에 배치)
                  Container(
                    padding: EdgeInsets.only(right: 20, bottom: 10),
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: _toggleLike,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              color: _isLiked ? AppTheme.likeColor : Colors.grey,
                              size: 24,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${_post!['likeCount'] ?? 0}',
                              style: TextStyle(
                                color: _isLiked ? AppTheme.likeColor : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 구분선
                  Divider(
                    height: 1,
                    thickness: 8,
                    color: Colors.grey.shade100,
                  ),

                  // 댓글 섹션
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_post!['commentCount'] ?? 0}개의 댓글',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        SizedBox(height: 16),
                        ..._comments
                            .where((comment) => comment.parentId == null)
                            .map((comment) {
                          return CommentWidget(
                            comment: comment,
                            replies: comment.replies,
                            boardType: BoardType.eventGroup,
                            onReply: (comment, content, boardType) async {
                              await _addComment(content, comment.id);

                              Future.delayed(const Duration(milliseconds: 300), () {
                                if (_scrollController.hasClients) {
                                  final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
                                  _scrollController.animateTo(
                                    _scrollController.position.maxScrollExtent + bottomPadding,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOut,
                                  );
                                }
                              });
                            },
                            onDelete: (deletedComment) async {
                              await Future.wait([
                                _loadComments(),
                                _loadPostAndLikeStatus(),
                              ]);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('댓글이 삭제되었습니다'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    margin: const EdgeInsets.all(10),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          );
                        }).toList(),
                        if (_comments.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    '아직 댓글이 없습니다.',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 하단 여백 추가 (댓글 입력창 공간 확보)
                  SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // 댓글 입력창
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, -1),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 8,
          left: 16,
          right: 16,
          top: 8,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: '댓글을 남겨주세요',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 8),
            InkWell(
              onTap: () async {
                if (_commentController.text.trim().isEmpty) return;
                await _addComment(_commentController.text, null);
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}