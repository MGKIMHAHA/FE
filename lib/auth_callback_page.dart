import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../utils/user_preferences.dart';

final supabase = Supabase.instance.client;

class AuthCallbackPage extends StatefulWidget {
  const AuthCallbackPage({Key? key}) : super(key: key);

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  @override
  void initState() {
    super.initState();
    print('Auth callback page initialized');
    _handleAuthCallback();
  }

  Future<void> _handleAuthCallback() async {
    try {
      print('=============== AuthCallback Debug ===============');
      final uri = Uri.base;
      print('Current URL: $uri');

      // 현재 세션 가져오기
      final session = supabase.auth.currentSession;
      if (session != null) {
        print('Current session found: ${session.user.email}');
        await _processSignedInUser(session);
      } else {
        print('No session found, redirecting to login');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }

    } catch (error) {
      print('AuthCallback Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('인증 처리 중 오류가 발생했습니다: $error'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<void> _processSignedInUser(Session session) async {
    try {
      final email = session.user.email;
      if (email == null) {
        throw Exception('사용자 이메일을 찾을 수 없습니다.');
      }

      print('Processing user with email: $email');
      final userInfo = await AuthService.getUserByEmail(email);
      print('User info from server: $userInfo');

      if (!mounted) return;

      if (userInfo == null ||
          userInfo['phone'] == null ||
          userInfo['birth_date'] == null ||
          userInfo['gender'] == null ||
          userInfo['region'] == null ||
          userInfo['district'] == null) {
        // 추가 정보 입력 필요
        Navigator.of(context).pushReplacementNamed(
          '/additional-info',
          arguments: {
            'email': email,
            'nickname': session.user.userMetadata?['full_name'],
            'profileImage': session.user.userMetadata?['avatar_url'],
            'provider': 'kakao',
            'providerId': session.user.userMetadata?['provider_id'] ??
                session.user.userMetadata?['sub'],
            ...?userInfo
          },
        );
      } else {
        // 모든 정보가 있는 경우
        print('Saving user info to preferences...');
        await UserPreferences.saveUserData(
          userId: userInfo['id'],
          nickname: userInfo['nickname'],
          email: userInfo['email'],
          apiToken: session.accessToken,
        );
        print('User info saved to preferences');

        print('Navigating to home...');
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      print('Error processing signed in user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사용자 정보 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}