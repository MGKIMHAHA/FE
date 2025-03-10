import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'services/api_service.dart';
import 'utils/user_preferences.dart';
import 'package:intl/intl.dart'; // 날짜 형식 지정을 위한 패키지 추가
import 'package:table_calendar/table_calendar.dart';

class AppTheme {
  // 이벤트 커넥트 스타일로 색상 변경
  static const Color primaryColor = Color(0xFF5D6BFF);  // 메인 파란색
  static const Color backgroundColor = Color(0xFFF8F9FA);  // 배경색
  static const Color textColor = Color(0xFF212529);  // 텍스트 색상
  static const Color secondaryTextColor = Color(0xFFADB5BD);  // 보조 텍스트 색상
  static const Color dividerColor = Color(0xFFE9ECEF);  // 구분선 색상
}

class WriteReviewPost extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? post;

  const WriteReviewPost({
    super.key,
    this.isEditing = false,
    this.post,
  });

  @override
  State<WriteReviewPost> createState() => _WriteReviewPostState();
}

class _WriteReviewPostState extends State<WriteReviewPost> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _eventNameController = TextEditingController();
  final _eventDateController = TextEditingController();
  DateTime? _selectedDate;
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String _userNickname = '사용자';  // 기본값 설정

  // 최근 사용한 날짜 저장 (개선된 날짜 피커용)
  final List<DateTime> _recentDates = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    if (widget.isEditing && widget.post != null) {
      _titleController.text = widget.post!['title'];
      _contentController.text = widget.post!['content'];
      _eventNameController.text = widget.post!['eventName'] ?? '';
      _eventDateController.text = widget.post!['eventDate'] ?? '';

      // 편집 모드인 경우 날짜 파싱 시도
      try {
        if (widget.post!['eventDate'] != null && widget.post!['eventDate'].isNotEmpty) {
          // 날짜 형식에 따라 파싱 방식 조정 필요할 수 있음
          final dateParts = widget.post!['eventDate'].split('/');
          if (dateParts.length == 3) {
            _selectedDate = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2])
            );
          }
        }
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    // 최근 날짜 초기화 (오늘, 어제, 지난주 등)
    final now = DateTime.now();
    _recentDates.add(now); // 오늘
    _recentDates.add(now.subtract(const Duration(days: 1))); // 어제
    _recentDates.add(now.subtract(const Duration(days: 2))); // 그저께
    _recentDates.add(now.subtract(const Duration(days: 7))); // 1주일 전
    _recentDates.add(now.subtract(const Duration(days: 14))); // 2주일 전
    _recentDates.add(now.subtract(const Duration(days: 30))); // 한 달 전
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null && user.email != null) {
        final data = await _supabase
            .from('users')
            .select()
            .eq('email', user.email!)
            .single();

        if (data != null && data['nickname'] != null) {  // null 체크 추가
          setState(() {
            _userNickname = data['nickname'];
          });
        }
      }
    } catch (error) {
      print('Error loading user profile: $error');
      // 에러가 발생해도 기본값 유지
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _eventNameController.dispose();
    _eventDateController.dispose();
    super.dispose();
  }

  // 개선된 날짜 선택 다이얼로그
  Future<void> _showImprovedDatePicker(BuildContext context) async {
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 드래그 핸들
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '이벤트 날짜 선택',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          '취소',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 최근 날짜 빠른 선택 옵션
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.backgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '빠른 선택',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // 오늘 버튼
                      _quickDateButton(
                        '오늘',
                        DateTime.now(),
                        onTap: () => Navigator.pop(context, DateTime.now()),
                      ),
                      // 어제 버튼
                      _quickDateButton(
                        '어제',
                        DateTime.now().subtract(const Duration(days: 1)),
                        onTap: () => Navigator.pop(context, DateTime.now().subtract(const Duration(days: 1))),
                      ),
                      // 지난주 버튼
                      _quickDateButton(
                        '지난주',
                        DateTime.now().subtract(const Duration(days: 7)),
                        onTap: () => Navigator.pop(context, DateTime.now().subtract(const Duration(days: 7))),
                      ),
                      // 지난달 버튼
                      _quickDateButton(
                        '한 달 전',
                        DateTime.now().subtract(const Duration(days: 30)),
                        onTap: () => Navigator.pop(context, DateTime.now().subtract(const Duration(days: 30))),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 최근 사용한 날짜들
            if (_recentDates.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '최근 사용',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recentDates.length,
                        itemBuilder: (context, index) {
                          final date = _recentDates[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _quickDateButton(
                              DateFormat('MM/dd').format(date),
                              date,
                              small: true,
                              onTap: () => Navigator.pop(context, date),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // 캘린더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  DateTime tempDate = _selectedDate ?? DateTime.now();
                  CalendarFormat calendarFormat = CalendarFormat.month;

                  final result = await showModalBottomSheet<DateTime?>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => StatefulBuilder(
                      builder: (context, setState) => Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            // 헤더
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 1,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '날짜 선택',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      '취소',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // TableCalendar
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TableCalendar(
                                  locale: 'ko_KR',
                                  firstDay: DateTime(2000, 1, 1),
                                  lastDay: DateTime.now(),
                                  focusedDay: tempDate,
                                  calendarFormat: calendarFormat,
                                  selectedDayPredicate: (day) {
                                    return isSameDay(tempDate, day);
                                  },
                                  onDaySelected: (selectedDay, focusedDay) {
                                    setState(() {
                                      tempDate = selectedDay;
                                    });
                                  },
                                  onFormatChanged: (format) {
                                    setState(() {
                                      calendarFormat = format;
                                    });
                                  },
                                  calendarStyle: CalendarStyle(
                                    todayDecoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    selectedDecoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    markerDecoration: BoxDecoration(
                                      color: Colors.red.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                    outsideDaysVisible: false,
                                    weekendTextStyle: TextStyle(color: Colors.red.shade300),
                                    holidayTextStyle: TextStyle(color: Colors.red.shade400),
                                    markersMaxCount: 3,
                                    markersAnchor: 0.7,
                                    markerSize: 6,
                                    markerMargin: const EdgeInsets.symmetric(horizontal: 0.3),
                                  ),
                                  headerStyle: HeaderStyle(
                                    formatButtonVisible: true,
                                    titleCentered: true,
                                    formatButtonShowsNext: false,
                                    formatButtonDecoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    formatButtonTextStyle: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    titleTextStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    headerPadding: const EdgeInsets.symmetric(vertical: 16),
                                    leftChevronIcon: Icon(Icons.chevron_left, color: AppTheme.primaryColor),
                                    rightChevronIcon: Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                                  ),
                                  daysOfWeekStyle: DaysOfWeekStyle(
                                    weekdayStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    weekendStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade400,
                                    ),
                                    dowTextFormatter: (date, locale) {
                                      return DateFormat.E(locale).format(date)[0];
                                    },
                                  ),
                                  availableCalendarFormats: const {
                                    CalendarFormat.month: '월',
                                    CalendarFormat.week: '주',
                                  },
                                ),
                              ),
                            ),

                            // 하단 확인 버튼
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context, tempDate),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  '선택 완료',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      _selectedDate = result;
                      _eventDateController.text = DateFormat('yyyy/MM/dd').format(result);
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  elevation: 0,
                  side: BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '캘린더에서 날짜 선택하기',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            // 확인 버튼
            if (_selectedDate != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedDate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '${DateFormat('yyyy년 MM월 dd일').format(_selectedDate!)} 선택',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDate = result;
        _eventDateController.text = DateFormat('yyyy/MM/dd').format(result);

        // 선택된 날짜가 _recentDates에 없으면 추가
        if (!_recentDates.any((date) =>
        date.year == result.year &&
            date.month == result.month &&
            date.day == result.day)) {
          _recentDates.insert(0, result);
          // 최대 6개까지만 유지
          if (_recentDates.length > 6) {
            _recentDates.removeLast();
          }
        }
      });
    }
  }

  // 빠른 날짜 선택 버튼 위젯
  Widget _quickDateButton(String label, DateTime date, {required VoidCallback onTap, bool small = false}) {
    final isSelected = _selectedDate != null &&
        _selectedDate!.year == date.year &&
        _selectedDate!.month == date.month &&
        _selectedDate!.day == date.day;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 12 : 16,
          vertical: small ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: small ? 12 : 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Future<void> _getImage() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) {
      setState(() {
        _images.addAll(images);
      });
    }
  }

  Future<void> _saveReview() async {
    if (_formKey.currentState?.validate() != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('모든 필수 항목을 입력해주세요'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다');

      // 이미지 업로드 처리
      List<String> imageUrls = [];
      if (_images.isNotEmpty) {
        for (var image in _images) {
          final bytes = await image.readAsBytes();
          final fileExt = image.path.split('.').last;
          final fileName = 'review_${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}.$fileExt';
          final filePath = fileName;

          // 이미지를 storage에 업로드
          await _supabase.storage
              .from('review')  // 'review' 버킷 사용
              .uploadBinary(filePath, bytes);

          // 업로드된 이미지의 공개 URL 가져오기
          final imageUrl = _supabase.storage
              .from('review')
              .getPublicUrl(filePath);

          imageUrls.add(imageUrl);
        }
      }

      if (widget.isEditing) {
        // 수정 시
        final response = await ApiService.updateReview(
          id: widget.post!['id'],
          title: _titleController.text,
          content: _contentController.text,
          eventName: _eventNameController.text,
          eventDate: _eventDateController.text,
          images: imageUrls,  // 이미지 URL 배열 추가
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('글이 수정되었습니다'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
            ),
          );
          Navigator.pop(context, response);
        }
      } else {
        // 새 글 작성
        final response = await ApiService.createReview(
          title: _titleController.text,
          content: _contentController.text,
          eventName: _eventNameController.text,
          eventDate: _eventDateController.text,
          images: imageUrls,  // 이미지 URL 배열 추가
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('글이 작성되었습니다'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
            ),
          );
          Navigator.pop(context, response);
        }
      }
    } catch (error) {
      print('Error saving review: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${error.toString()}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? '글 수정' : '글쓰기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveReview,
              child: Text(
                '완료',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목 입력 필드
                      TextField(
                        controller: _titleController,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: '제목을 입력하세요',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.primaryColor),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 내용 입력 필드
                      TextField(
                        controller: _contentController,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        maxLines: null,
                        minLines: 10,
                        decoration: InputDecoration(
                          hintText: '내용을 입력하세요',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                        ),
                      ),

                      // 이미지 목록 보여주기
                      if (_images.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _images.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 10),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Image.file(
                                        File(_images[index].path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    // 삭제 버튼
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _images.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 하단 툴바 (사진 첨부 버튼)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.photo_camera,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: _getImage,
                ),
                Text(
                  '사진 첨부',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}