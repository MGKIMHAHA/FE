import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/api_service.dart';
import 'FreeBoardDetailPage.dart';
import 'ReviewDetailPage.dart';
import 'package:eventers/JobDetailPage.dart';
import 'package:eventers/EventGroupBoardDetailPage.dart';

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

class CustomSearchDelegate extends SearchDelegate {
  // 현재 선택된 필터 카테고리
  String _currentFilter = '전체';
  // 필터 카테고리 목록
  final List<String> _filterCategories = ['전체', '자유', '후기', '구인', '행사팟'];

  // 검색 결과 캐시 (필터 변경 시 재검색 방지)
  Map<String, dynamic> _cachedResults = {};
  bool _isSearching = false;

  // 카테고리별 색상 매핑
  Map<String, Color> get _categoryColors => {
    '전체': AppTheme.primaryColor,
    '자유': AppTheme.freeboardColor,
    '후기': AppTheme.reviewColor,
    '구인': AppTheme.jobColor,
    '행사팟': AppTheme.eventGroupColor,
  };

  // 카테고리별 아이콘 매핑
  Map<String, IconData> get _categoryIcons => {
    '전체': Icons.search,
    '자유': Icons.forum_outlined,
    '후기': Icons.rate_review_outlined,
    '구인': Icons.work_outline,
    '행사팟': Icons.groups_outlined,
  };

  // 카테고리별 보드타입 매핑
  Map<String, String?> get _categoryBoardTypes => {
    '전체': null,
    '자유': 'freeboard',
    '후기': 'review',
    '구인': 'job',
    '행사팟': 'event_group',
  };

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppTheme.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 16,
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  String get searchFieldLabel => '검색어를 입력하세요';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          _cachedResults.clear();
          showResults(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  // 필터 변경 메서드 (StatefulBuilder와 함께 사용)
  void _changeFilter(StateSetter setState, String filter) {
    setState(() {
      _currentFilter = filter;
    });
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '검색어를 입력해주세요',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '게시글 내용 또는 제목으로 검색하면 찾아드립니다!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // StatefulBuilder를 사용하여 필터 변경 시 화면 갱신
    return StatefulBuilder(
        builder: (context, setState) {
          return Column(
            children: [
              // 카테고리 필터 탭 (좋아요 목록 페이지와 동일한 스타일)
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
                      onTap: () => _changeFilter(setState, filter),
                      child: Container(
                        width: width,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? AppTheme.primaryColor : Colors.black54,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 검색 결과 표시 영역
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: _buildSearchResults(context, query, _categoryBoardTypes[_currentFilter]),
                ),
              ),
            ],
          );
        }
    );
  }

  Widget _buildSearchResults(BuildContext context, String query, String? boardType) {
    // 이미 검색 중이거나 캐시된 결과가 있으면 재검색하지 않음
    if (!_isSearching && _cachedResults.isEmpty) {
      _isSearching = true;

      if (boardType == null) {
        // 전체 검색
        ApiService.searchAll(query).then((results) {
          _cachedResults = results;
          _isSearching = false;
        });
      } else {
        // 특정 게시판 검색
        ApiService.searchByBoard(query, boardType).then((results) {
          _cachedResults = {boardType: results};
          _isSearching = false;
        });
      }
    }

    return FutureBuilder<Map<String, dynamic>>(
      // 캐시된 결과가 있으면 사용, 없으면 API 호출
      future: _cachedResults.isNotEmpty
          ? Future.value(_cachedResults)
          : (boardType == null
          ? ApiService.searchAll(query)
          : ApiService.searchByBoard(query, boardType).then((results) => {boardType: results})),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _cachedResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  '검색 중...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  '검색 중 오류가 발생했습니다',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final results = snapshot.data ?? _cachedResults;

        // 필터링된 결과 표시
        Map<String, dynamic> filteredResults = {};
        if (boardType == null) {
          // 전체 결과 표시
          filteredResults = results;
        } else {
          // 특정 게시판 결과만 표시
          if (results.containsKey(boardType)) {
            filteredResults = {boardType: results[boardType]};
          }
        }

        if (filteredResults.isEmpty || filteredResults.values.every((posts) => (posts as List).isEmpty)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                    '검색 결과가 없습니다',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    )
                ),
                const SizedBox(height: 8),
                Text(
                  '다른 검색어로 시도해보세요',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            if (filteredResults['freeboard']?.isNotEmpty ?? false)
              _buildBoardResults(context, '자유게시판', filteredResults['freeboard']),
            if (filteredResults['review']?.isNotEmpty ?? false)
              _buildBoardResults(context, '후기게시판', filteredResults['review']),
            if (filteredResults['job']?.isNotEmpty ?? false)
              _buildBoardResults(context, '구인게시판', filteredResults['job']),
            if (filteredResults['event_group']?.isNotEmpty ?? false)
              _buildBoardResults(context, '행사팟', filteredResults['event_group']),
          ],
        );
      },
    );
  }

  Widget _buildBoardResults(BuildContext context, String boardTitle, List<dynamic> posts) {
    // 보드별 색상과 아이콘 가져오기
    String categoryKey;
    switch (boardTitle) {
      case '자유게시판':
        categoryKey = '자유';
        break;
      case '후기게시판':
        categoryKey = '후기';
        break;
      case '구인게시판':
        categoryKey = '구인';
        break;
      case '행사팟':
        categoryKey = '행사팟';
        break;
      default:
        categoryKey = '전체';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                boardTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _categoryColors[categoryKey]!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${posts.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _categoryColors[categoryKey],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 게시글 목록
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _buildSearchResultItem(context, post, boardTitle, _categoryColors[categoryKey]!);
          },
        ),
      ],
    );
  }

  // 게시글 아이템 위젯 (이벤트 커넥트 스타일)
  Widget _buildSearchResultItem(BuildContext context, Map<String, dynamic> post, String boardTitle, Color categoryColor) {
    return InkWell(
      onTap: () => _navigateToDetail(context, boardTitle, post),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 정보: 카테고리 태그, 시간
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
                    boardTitle == '자유게시판' ? '일반자유' :
                    boardTitle == '후기게시판' ? '후기' :
                    boardTitle == '구인게시판' ? '구인' : '행사팟',
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
                  _formatDate(post['createdAt']),
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            // 제목
            const SizedBox(height: 8),
            Text(
              post['title'] ?? '(제목 없음)',
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
              post['content'] ?? '(내용 없음)',
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
                  '${post['viewCount'] ?? 0}',
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
                  '${post['likeCount'] ?? 0}',
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),

                // 댓글이 있는 경우 표시
                if (post['commentCount'] != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 14,
                    color: AppTheme.secondaryTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post['commentCount']}',
                    style: TextStyle(
                      color: AppTheme.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String boardTitle, dynamic post) async {
    switch (boardTitle) {
      case '자유게시판':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FreeBoardDetailPage(
              postId: post['id'],
            ),
          ),
        );
        break;

      case '후기게시판':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewDetailPage(
              post: post,
            ),
          ),
        );
        break;

      case '구인게시판':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailPage(
              post: post,
            ),
          ),
        );
        break;

      case '행사팟':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventGroupBoardDetailPage(
              postId: post['id'],
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '검색어를 입력해주세요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '게시글 제목이나 내용으로 검색하면 찾을 수 있어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _filterCategories.map((category) {
                if (category == '전체') return SizedBox.shrink();
                final categoryColor = _categoryColors[category]!;
                final categoryIcon = _categoryIcons[category]!;

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 6),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: categoryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(categoryIcon, size: 16, color: categoryColor),
                      SizedBox(width: 4),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: categoryColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).where((widget) => widget is! SizedBox).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}일 전';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}시간 전';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}분 전';
      } else {
        return '방금 전';
      }
    } catch (e) {
      return '';
    }
  }
}