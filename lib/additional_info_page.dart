import 'package:flutter/material.dart';
import 'package:eventers/services/auth_service.dart';
import 'utils/user_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AdditionalInfoPage extends StatefulWidget {
  final Map<String, dynamic> kakaoUserData;

  const AdditionalInfoPage({Key? key, required this.kakaoUserData}) : super(key: key);

  @override
  State<AdditionalInfoPage> createState() => _AdditionalInfoPageState();
}

class _AdditionalInfoPageState extends State<AdditionalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  bool _privacyPolicyAccepted = false;

  @override
  void initState() {
    super.initState();
    print('============ AdditionalInfoPage initState START ============');
    print('kakaoUserData: ${widget.kakaoUserData}');
    print('============ AdditionalInfoPage initState END ============');
  }

  bool _validateForm() {
    if (!_privacyPolicyAccepted) {
      _showSnackBar('개인정보 처리방침에 동의해주세요.', isError: true);
      return false;
    }

    if (_nicknameController.text.isEmpty ||
        _nicknameController.text.length < 2 ||
        _nicknameController.text.length > 10) {
      _showSnackBar('닉네임은 2-10자 사이여야 합니다.', isError: true);
      return false;
    }

    return true;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://level-browser-f2d.notion.site/1a9458e8eb2b8083846ad63b27fb4025';

    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        _showSnackBar('URL을 열 수 없습니다.', isError: true);
      }
    } catch (e) {
      _showSnackBar('URL을 여는 중 오류가 발생했습니다: $e', isError: true);
    }
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final userData = {
        'email': widget.kakaoUserData['email'],
        'nickname': _nicknameController.text.trim(),
        'profile_image': widget.kakaoUserData['profileImage'],
        'user_type': 'NORMAL',
        'enabled': true,
        'role': 'USER',
        'provider': 'kakao',
        'provider_id': widget.kakaoUserData['providerId']?.toString() ?? '',
        'updated_at': DateTime.now().toIso8601String()
      };

      print('Updating user with data: $userData');

      final updatedUser = await AuthService.updateUserInfo(userData);

      if (updatedUser == null) {
        throw Exception('사용자 정보 업데이트 실패');
      }

      print('Updated user data: $updatedUser');

      await UserPreferences.saveUserData(
        userId: updatedUser['id'],
        nickname: updatedUser['nickname'],
        email: updatedUser['email'],
        apiToken: '',
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.grey.shade700,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '정보 입력 완료',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '닉네임이 성공적으로 저장되었습니다.\n로그인 페이지로 이동합니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
                (route) => false,
          );
        });
      }
    } catch (error) {
      if (mounted) {
        print('Error in updating user info: $error');
        _showSnackBar('정보 저장 실패: $error', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPrivacyPolicyCheckbox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: _privacyPolicyAccepted,
              onChanged: (value) {
                setState(() {
                  _privacyPolicyAccepted = value ?? false;
                });
              },
              activeColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _privacyPolicyAccepted = !_privacyPolicyAccepted;
                });
              },
              child: Text(
                '개인정보 처리방침에 동의합니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _openPrivacyPolicy,
            child: Text(
              '보기',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNicknameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _nicknameController,
        keyboardType: TextInputType.text,
        maxLength: 10,
        enabled: _privacyPolicyAccepted,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _privacyPolicyAccepted ? Colors.black87 : Colors.grey.shade400,
        ),
        decoration: InputDecoration(
          hintText: _privacyPolicyAccepted ? '닉네임 (2-10자)' : '개인정보 처리방침에 동의해주세요',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(
            Icons.person_outline,
            color: _privacyPolicyAccepted ? Colors.black54 : Colors.grey.shade400,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback? onPressed,
    required String text,
    bool isLoading = false,
  }) {
    final bool isEnabled = onPressed != null && _privacyPolicyAccepted;

    return Container(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: isEnabled ? Colors.black87 : Colors.grey.shade300,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        )
            : Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          '프로필 설정',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // 제목
                  Text(
                    '서비스 이용을 위한 정보를 입력해주세요',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 카카오 계정 정보 카드
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '카카오 계정 정보',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${widget.kakaoUserData['email']}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 개인정보 처리방침 동의
                  Text(
                    '개인정보 처리방침',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPrivacyPolicyCheckbox(),
                  const SizedBox(height: 24),

                  // 닉네임 정보 입력
                  Text(
                    '닉네임 입력',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildNicknameField(),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      '다른 사용자에게 보여질 이름입니다',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  // 저장 버튼
                  _buildButton(
                    onPressed: _isLoading ? null : _submitForm,
                    text: '완료',
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}