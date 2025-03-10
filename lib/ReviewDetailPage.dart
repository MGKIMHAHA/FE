import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'Comment.dart';
import 'CommentWidget.dart';
import 'dart:io';
import 'services/api_service.dart';
import 'utils/date_formatter.dart';
import 'utils/user_preferences.dart';
import 'post_options_menu.dart';
import 'Report.dart';
import 'BoardType.dart';

class AppTheme {
  // 이벤트 커넥트 스타일로 색상 변경
  static const Color primaryColor = Color(0xFF5D6BFF);  // 메인 파란색
  static const Color backgroundColor = Color(0xFFF8F9FA);  // 배경색
  static const Color textColor = Color(0xFF212529);  // 텍스트 색상
  static const Color secondaryTextColor = Color(0xFFADB5BD);  // 보조 텍스트 색상
  static const Color dividerColor = Color(0xFFE9ECEF);  // 구분선 색상
  static const Color likeColor = Colors.red;// 좋아요 보라색
}

class ReviewDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;

  const ReviewDetailPage({super.key, required this.post});

  @override
  State<ReviewDetailPage> createState() => _ReviewDetailPageState();
}

class _ReviewDetailPageState extends State<ReviewDetailPage> {
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? _post;
  bool _isLoading = true;
  bool _isLiked = false;
  List<Comment> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  Set<String> _collapsedComments = {};

  @override
  void initState() {
    super.initState();
    print('ReviewDetailPage initState called');
    _loadPostAndLikeStatus();
  }

  Future<void> _loadPostAndLikeStatus() async {
    try {
      final post = await ApiService.getReview(widget.post['id']);
      final isLiked = await ApiService.isReviewLiked(widget.post['id']);

      print('Received post data: $post'); // 디버깅용

      if (mounted) {
        setState(() {
          _post = post; // 그대로 사용 (authorId가 이미 포함되어 있음)
          _isLiked = isLiked;
          _isLoading = false;
        });

        print('Updated post state: $_post'); // 디버깅용
        _loadComments();
      }
    } catch (e) {
      print('Error loading review and like status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('리뷰를 불러오는데 실패했습니다'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  // 댓글 로딩 함수
  Future<void> _loadComments() async {
    try {
      final comments = await ApiService.getComments(widget.post['id'], BoardType.review);
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

  // 댓글 작성 메서드
  Future<void> _addComment(String content, String? parentId) async {
    try {
      print('Adding comment to review: postId=${widget.post['id']}, content=$content, parentId=$parentId');

      await ApiService.createComment(
        postId: widget.post['id'],
        content: content,
        boardType: BoardType.review,
        parentId: parentId,
      );

      // 댓글 작성 후 데이터 새로고침
      await Future.wait([
        _loadComments(),
        _loadPostAndLikeStatus(),
      ]);

      // 입력 필드 초기화
      if (parentId == null) {  // 대댓글이 아닌 경우에만
        _commentController.clear();
      }

      // 스크롤 애니메이션 추가 (약간의 지연 후 실행)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
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

  // 대댓글 작성
  void _handleReply(Comment parentComment, String content, BoardType boardType) async {
    try {
      await _addComment(content, parentComment.id);

      // 대댓글 작성 후 약간의 지연을 두고 스크롤
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error creating reply: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('답글 작성에 실패했습니다'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          title: Text('후기게시판'),
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
          title: const Text('후기게시판'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          centerTitle: true,
        ),
        body: const Center(child: Text('리뷰를 찾을 수 없습니다')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '후기게시판',
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
            boardType: BoardType.review,
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
                      onTap: () async {
                        try {
                          final response = await ApiService.toggleReviewLike(widget.post['id']);
                          setState(() {
                            _isLiked = !_isLiked;
                            _post!['likeCount'] = response['likeCount'];
                          });
                        } catch (e) {
                          print('Error toggling like: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: const Text('좋아요 처리에 실패했습니다')),
                            );
                          }
                        }
                      },
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
                            boardType: BoardType.review,
                            onReply: _handleReply,
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

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}