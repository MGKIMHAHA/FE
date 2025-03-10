import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'services/api_service.dart';
import 'utils/user_preferences.dart';

class AppTheme {
  // 이벤트 커넥트 스타일로 색상 변경
  static const Color primaryColor = Color(0xFF5D6BFF);  // 메인 파란색
  static const Color backgroundColor = Color(0xFFF8F9FA);  // 배경색
  static const Color textColor = Color(0xFF212529);  // 텍스트 색상
  static const Color secondaryTextColor = Color(0xFFADB5BD);  // 보조 텍스트 색상
  static const Color dividerColor = Color(0xFFE9ECEF);  // 구분선 색상
}

/// 행사팟 게시글 작성 페이지
class WriteEventGroupPost extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? post;  // 수정할 게시글 데이터

  const WriteEventGroupPost({
    super.key,
    this.isEditing = false,  // 기본값은 false (새 글 작성)
    this.post,  // 수정 시 기존 게시글 데이터
  });

  @override
  State<WriteEventGroupPost> createState() => _WriteEventGroupPostState();
}

class _WriteEventGroupPostState extends State<WriteEventGroupPost> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String _userNickname = '사용자';  // 기본값 설정
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    // 수정 모드일 경우 기존 데이터로 초기화
    if (widget.isEditing && widget.post != null) {
      _titleController.text = widget.post!['title'] ?? '';
      _contentController.text = widget.post!['content'] ?? '';
      _locationController.text = widget.post!['event_location'] ?? '';

      if (widget.post!['event_date'] != null) {
        try {
          _selectedDate = DateTime.parse(widget.post!['event_date']);
        } catch (e) {
          print('Error parsing date: $e');
        }
      }
    }
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

  Future<void> _selectDate(BuildContext context) async {
    final initialDate = _selectedDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitPost() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }

    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('내용을 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.email == null) throw Exception('로그인이 필요합니다');

      // 1. 이미지들을 먼저 업로드하고 URL 리스트 얻기
      List<String> imageUrls = [];
      for (XFile image in _images) {
        final String fileName = 'eventgroup_${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}.${image.path.split('.').last}';
        final bytes = await image.readAsBytes();

        // Supabase Storage에 이미지 업로드
        await _supabase
            .storage
            .from('eventgroup')  // 'event_group' 버킷 사용
            .uploadBinary(fileName, bytes);

        // 업로드된 이미지의 공개 URL 가져오기
        final imageUrl = _supabase
            .storage
            .from('eventgroup')
            .getPublicUrl(fileName);

        imageUrls.add(imageUrl);
      }

      // 2. 게시글 데이터 준비
      final postData = {
        'title': _titleController.text,
        'content': _contentController.text,
        'event_date': _selectedDate?.toIso8601String(),
        'event_location': _locationController.text,
        'images': imageUrls,
      };

      if (widget.isEditing) {
        // 게시글 수정
        await ApiService.updateEventGroupPost(widget.post!['id'], postData);
      } else {
        // 새 게시글 작성
        await ApiService.createEventGroupPost(postData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? '게시글이 수정되었습니다' : '게시글이 작성되었습니다'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    } catch (e) {
      print('Error submitting post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게시글 ${widget.isEditing ? '수정' : '작성'}에 실패했습니다: $e'),
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

  Future<void> _getImage() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) {
      setState(() {
        _images.addAll(images);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
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
              onPressed: _submitPost,
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