import 'package:flutter/material.dart';
import 'package:eventers/services/auth_service.dart';
import 'package:eventers/utils/user_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 앱 전체에서 사용할 통일된 색상 테마를 정의하는 클래스
class AppTheme {
  // 기본 테마 색상 - 앱 전체적으로 통일
  static const Color primaryColor = Color(0xFF5D6BFF);  // 메인 파란색
  static const Color primaryColorDark = Color(0xFF0653B6);  // 진한 파란색
  static const Color backgroundColor = Color(0xFFF8F9FA);  // 배경색
  static const Color textColor = Color(0xFF212529);  // 텍스트 색상
  static const Color secondaryTextColor = Color(0xFFADB5BD);  // 보조 텍스트 색상
  static const Color dividerColor = Color(0xFFE9ECEF);  // 구분선 색상

  // 각 기능별 태그 색상
  static const Color freeboardColor = Color(0xFF4A90E2);   // 자유게시판용 파란색
  static const Color reviewColor = Color(0xFF70AD47);      // 부드러운 초록색
  static const Color jobColor = Color(0xFFED7D31);         // 부드러운 주황색
  static const Color hotColor = Color(0xFFE74C3C);         // 인기글 표시용 빨간색
  static const Color defaultColor = Color(0xFF7F7F7F);     // 중간 톤 회색
  static const Color titleColor = Color(0xFF303030);       // 제목용 진한 회색
  static const Color contentColor = Color(0xFF505050);     // 내용용 중간 회색
  static const Color warningColor = Color(0xFFE74C3C);     // 경고 색상
  static const Color successColor = Color(0xFF4CAF50);     // 성공 색상

  // 텍스트 스타일
  static TextStyle get nicknameStyle => TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: textColor,
    letterSpacing: -0.2,
    fontFamily: 'Pretendard',
  );

  static TextStyle get titleStyle => TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: titleColor,
    letterSpacing: -0.3,
    height: 1.3,
    fontFamily: 'Pretendard',
  );

  static TextStyle get contentStyle => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: contentColor,
    letterSpacing: -0.1,
    height: 1.5,
    fontFamily: 'Pretendard',
  );
}

class AgencyVerificationPage extends StatefulWidget {
  const AgencyVerificationPage({super.key});

  @override
  State<AgencyVerificationPage> createState() => _AgencyVerificationPageState();
}

class _AgencyVerificationPageState extends State<AgencyVerificationPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _isUploading = false;
  String? _businessLicenseImageUrl;

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() => _isUploading = true);

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 80,
      );

      if (image == null) {
        setState(() => _isUploading = false);
        return;
      }

      final String fileName = 'business_license_${DateTime.now().millisecondsSinceEpoch}.${image.path.split('.').last}';
      final bytes = await image.readAsBytes();

      await supabase
          .storage
          .from('business_licenses')
          .uploadBinary(fileName, bytes);

      final imageUrl = supabase
          .storage
          .from('business_licenses')
          .getPublicUrl(fileName);

      setState(() {
        _businessLicenseImageUrl = imageUrl;
        _isUploading = false;
      });

    } catch (e) {
      print('이미지 업로드 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 업로드 중 오류가 발생했습니다.'),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '에이전시 인증',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 안내 배너
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              color: AppTheme.primaryColor.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.business_center_outlined,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '에이전시 인증 안내',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '사업자등록증을 업로드하시면 검토 후 에이전시로 인증해 드립니다. 인증 완료 시 추가 기능을 사용하실 수 있습니다.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '* 승인까지 최대 24시간이 소요될 수 있습니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.secondaryTextColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            // 구분선
            Divider(height: 1, thickness: 1, color: AppTheme.dividerColor),

            // 업로드 섹션
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '사업자등록증 업로드',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '사업자등록증 사본을 업로드해주세요. (필수)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 이미지 업로드 영역
                  if (_businessLicenseImageUrl != null)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.dividerColor,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                child: Image.network(
                                  _businessLicenseImageUrl!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: AppTheme.successColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '사업자등록증이 업로드되었습니다',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textColor,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _pickAndUploadImage,
                                      icon: Icon(
                                        Icons.refresh,
                                        size: 16,
                                      ),
                                      label: Text('변경'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.primaryColor,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _businessLicenseImageUrl = null;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.dividerColor,
                            width: 1,

                          ),
                        ),
                        child: _isUploading
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '업로드 중...',
                                style: TextStyle(
                                  color: AppTheme.secondaryTextColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_file,
                              size: 48,
                              color: AppTheme.secondaryTextColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '클릭하여 사업자등록증 업로드',
                              style: TextStyle(
                                color: AppTheme.textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '이미지 파일 형식 (JPG, PNG)',
                              style: TextStyle(
                                color: AppTheme.secondaryTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // 인증 신청 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _businessLicenseImageUrl == null)
                          ? null
                          : _submitVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[500],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        '인증 신청하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 안내 텍스트
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '인증 절차 안내',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem('업로드된 사업자등록증은 관리자 검토 후 승인됩니다.'),
                        _buildInfoItem('인증 완료 시 이메일로 알림이 발송됩니다.'),
                        _buildInfoItem('인증 상태는 마이페이지에서 확인 가능합니다.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: AppTheme.secondaryTextColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.secondaryTextColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitVerification() async {
    if (_businessLicenseImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('사업자등록증 사본을 업로드해주세요.'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw Exception('로그인된 사용자 정보가 없습니다.');
      }

      // 현재 사용자의 이메일로 업데이트
      final response = await supabase
          .from('users')
          .update({
        'business_license_url': _businessLicenseImageUrl,
        'agency_status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('email', currentUser.email!)
          .select()
          .single();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('에이전시 인증 신청이 완료되었습니다.\n승인까지 최대 24시간이 소요될 수 있습니다.'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error in _submitVerification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('에러가 발생했습니다: $e'),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
}