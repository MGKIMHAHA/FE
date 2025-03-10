import 'package:flutter/material.dart';
import 'Comment.dart';
import 'CommentWidget.dart';
import 'dart:io';
import 'services/api_service.dart' ;
import 'utils/user_preferences.dart';
import 'post_options_menu.dart';
import 'Report.dart';
import '../BoardType.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventers/WriteJobPost.dart';
import 'post_options_menu.dart';
import 'utils/date_formatter.dart';

class AppTheme {
  // 이벤트 커넥트 스타일로 색상 변경
  static const Color primaryColor = Color(0xFF5D6BFF);  // 메인 파란색
  static const Color backgroundColor = Color(0xFFF8F9FA);  // 배경색
  static const Color textColor = Color(0xFF212529);  // 텍스트 색상
  static const Color secondaryTextColor = Color(0xFFADB5BD);  // 보조 텍스트 색상
  static const Color dividerColor = Color(0xFFE9ECEF);  // 구분선 색상
  static const Color likeColor = Colors.red;  // 좋아요 보라색
}

class JobDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final Function(bool)? onLikeChanged;

  const JobDetailPage({
    super.key,
    required this.post,
    this.onLikeChanged,
  });

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _job;
  bool _isLiked = false;
  List<Comment> _comments = [];
  final _commentController = TextEditingController();
  int _commentCount = 0;
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _job = widget.post;
    _isLiked = widget.post['isLiked'] ?? false;
    _commentCount = widget.post['commentCount'] ?? 0;
    print('JobDetailPage initState called');
    print('Initial comment count: ${widget.post['commentCount']}');
    _loadComments();
    _loadJobDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    try {
      final newLikeStatus = !_isLiked;
      await ApiService.toggleJobLike(_job!['id']);

      setState(() {
        _isLiked = newLikeStatus;
        _job!['likeCount'] = newLikeStatus
            ? (_job!['likeCount'] ?? 0) + 1
            : (_job!['likeCount'] ?? 1) - 1;
        _job!['isLiked'] = newLikeStatus;
      });

      widget.onLikeChanged?.call(newLikeStatus);

    } catch (e) {
      print('Error toggling like: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('좋아요 처리에 실패했습니다')),
        );
      }
    }
  }

  Future<void> _loadJobDetails() async {
    try {
      final jobData = await ApiService.getJobDetail(_job!['id']);
      final isLiked = await ApiService.isJobLiked(_job!['id']);
      print('Job details images: ${jobData['images']}');

      if (mounted) {
        setState(() {
          _job = {
            ...jobData,
            'isLiked': isLiked,
          };
          _isLiked = isLiked;
          _commentCount = jobData['commentCount'] ?? 0;
        });

        print('Loaded job details:');
        print('Job data: $_job');
        print('Comment count from server: $_commentCount');
      }
    } catch (e) {
      print('Error loading job details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글을 불러오는데 실패했습니다')),
        );
      }
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await ApiService.getComments(widget.post['id'], BoardType.job);

      if (mounted) {
        setState(() {
          _comments = comments;
          _commentCount = comments.length;
          if (_job != null) {
            _job!['commentCount'] = comments.length;
          }
        });

        print('Loaded comments count: ${comments.length}');
      }
    } catch (e) {
      print('Error loading comments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글을 불러오는데 실패했습니다.')),
        );
      }
    }
  }

  Future<void> _addComment(String content, String parentId) async {
    try {
      await ApiService.createComment(
        postId: widget.post['id'],
        content: content.trim(),
        boardType: BoardType.job,
        parentId: parentId.isEmpty ? null : parentId,
      );

      // 댓글 목록과 게시글 정보 새로고침
      await Future.wait([
        _loadComments(),
        _loadJobDetails(),
      ]);

      // 입력 필드 초기화
      _commentController.clear();

      // 스크롤 애니메이션 추가
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 작성되었습니다.')),
        );
      }
    } catch (e) {
      print('Error adding comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글 작성에 실패했습니다.')),
        );
      }
    }
  }

  void _handleReply(Comment parentComment, String content, BoardType boardType) async {
    try {
      await ApiService.createComment(
        postId: widget.post['id'],
        content: content.trim(),
        boardType: BoardType.job,
        parentId: parentComment.id,
      );

      // 댓글 목록과 게시글 정보 새로고침
      await Future.wait([
        _loadComments(),
        _loadJobDetails(),
      ]);

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
      print('Error creating reply: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('답글 작성에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('\n=== JobDetailPage build ===');
    print('Total comments: ${_comments.length}');

    // 각 댓글의 상세 정보 출력
    _comments.forEach((comment) {
      print('''
      Comment ID: ${comment.id}
      Parent ID: ${comment.parentId}
      Content: ${comment.content}
      Author: ${comment.author}
      Created At: ${comment.createdAt}
      ===================
    ''');
    });

    // 댓글을 원댓글과 대댓글로 구분
    final parentComments = _comments.where((comment) => comment.parentId == null).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '구인게시판',
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
            post: widget.post,
            boardType: BoardType.job,
            onPostDeleted: () {
              // 게시글이 삭제되면 이전 화면으로 돌아가기
              Navigator.pop(context);
            },
            onPostUpdated: () async {
              // 게시글이 업데이트되면 데이터 새로고침
              await _loadJobDetails();
              await _loadComments();
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
                          widget.post['title'] ?? '제목 없음',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        // 작성자 정보 및 날짜
                        // 작성자 정보 및 날짜
                        Row(
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.post['authorNickname'] ?? '작성자',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (widget.post['authorRole'] == 'MANAGER') ...[
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
                              widget.post['time'] ??
                                  (widget.post['created_at'] != null ? getTimeAgo(widget.post['created_at']) : '시간 정보 없음'),
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
                              '${_job?['viewCount'] ?? 0}',
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

                  // 본문 내용
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 본문 내용
                        Text(
                          widget.post['content'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),

                        // 이미지가 있는 경우 표시
                        if (_job != null && _job!['images'] != null && (_job!['images'] as List).isNotEmpty) ...[
                          SizedBox(height: 24),
                          Container(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: (_job!['images'] as List).length,
                              itemBuilder: (context, index) {
                                final imageUrl = _job!['images'][index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Scaffold(
                                          backgroundColor: Colors.black,
                                          appBar: AppBar(
                                            backgroundColor: Colors.black,
                                            iconTheme: const IconThemeData(color: Colors.white),
                                          ),
                                          body: Center(
                                            child: InteractiveViewer(
                                              child: Image.network(imageUrl),
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
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Error loading image: $error');
                                        return const Icon(Icons.error);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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
                              '${_job?['likeCount'] ?? 0}',
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_commentCount개의 댓글',
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
                            boardType: BoardType.job,
                            onReply: _handleReply,
                            onDelete: (deletedComment) async {
                              await Future.wait([
                                _loadComments(),
                                _loadJobDetails(),
                              ]);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('댓글이 삭제되었습니다'),
                                    duration: Duration(seconds: 2),
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
                await _addComment(_commentController.text, '');
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