import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter/foundation.dart';
import '../utils/user_preferences.dart';
import '../utils/navigation_service.dart';
import 'dart:io' show Platform;

class AuthService {
  static final supabase = Supabase.instance.client;

  // 카카오 로그인
  static Future<User?> signInWithKakao() async {
    try {
      print('Starting Kakao login process...');

      if (kIsWeb) {
        print('Web platform detected');
        StreamSubscription? authSubscription;
        Completer<User?> completer = Completer();

        try {
          authSubscription = supabase.auth.onAuthStateChange.listen((data) async {
            print('Auth state changed: ${data.event}');
            print('Session: ${data.session?.user.email}');

            if (data.event == AuthChangeEvent.signedIn && data.session != null) {
              try {

                final user = data.session!.user;
                final metadata = user.userMetadata;
                print('User metadata: $metadata');

                final userData = await _saveUserToServer({
                  'email': user.email,
                  'nickname': metadata?['full_name'] ?? user.email?.split('@')[0],
                  'provider': 'kakao',
                  'providerId':  metadata?['id'],
                  'profileImage': metadata?['avatar_url'],
                  'password': null,
                  'phone': null,
                  'birthDate': null,
                  'gender': null,
                  'userType': 'user',
                });

                print('User data saved to server successfully');
                if (!completer.isCompleted) {
                  completer.complete(user);
                }
              } catch (error) {
                print('Error saving user data: $error');
                if (!completer.isCompleted) {
                  completer.completeError(error);
                }
              } finally {
                authSubscription?.cancel();
              }
            }
          });

          print('Starting Supabase OAuth login...');
          final result = await supabase.auth.signInWithOAuth(
            OAuthProvider.kakao,
            redirectTo: kIsWeb
                ? 'http://localhost:8081/auth/callback'
                : Platform.isAndroid
                ? 'com.eventers://login-callback'
                : 'eventers://login-callback',
          );

          print('OAuth result: $result');
          if (!result) {
            authSubscription?.cancel();
            throw Exception('OAuth 인증 실패');
          }

          return await completer.future;

        } catch (error) {
          authSubscription?.cancel();
          rethrow;
        }
      }else {
        try {
          // 1. 카카오 SDK로 로그인 (기존 코드 유지)
          final installed = await kakao.isKakaoTalkInstalled();
          if (installed) {
            await kakao.UserApi.instance.loginWithKakaoTalk();
          } else {
            await kakao.UserApi.instance.loginWithKakaoAccount();
          }
          final kakaoUser = await kakao.UserApi.instance.me();
          final email = kakaoUser.kakaoAccount?.email;

          // 2. 카카오 로그인 성공 후 Supabase 인증 추가
          if (email != null) {
            try {
              // 사용자가 이미 존재하는지 확인
              List<Map<String, dynamic>> existingUsers = await supabase
                  .from('users')
                  .select()
                  .eq('email', email);

              final existingUserData = existingUsers.isNotEmpty ? existingUsers.first : null;
              final randomPassword = 'kakao_${kakaoUser.id}';

              if (existingUserData != null) {
                // 사용자가 존재하면 Supabase 인증 로그인 시도
                try {
                  await supabase.auth.signInWithPassword(
                    email: email,
                    password: randomPassword,
                  );
                  print('Supabase Auth login successful');
                } catch (signInError) {
                  print('Supabase Auth login failed: $signInError');
                  // 로그인 실패해도 계속 진행
                }
              } else {
                // 사용자가 존재하지 않으면 Supabase 인증 회원가입만 시도
                // (실제 사용자 정보 저장은 _saveUserToServer에서 처리)
                try {
                  await supabase.auth.signUp(
                    email: email,
                    password: randomPassword,
                  );
                  print('Supabase Auth signup successful');
                } catch (signUpError) {
                  print('Supabase Auth signup failed: $signUpError');
                  // 회원가입 실패해도 계속 진행
                }
              }
            } catch (authError) {
              // Supabase 인증 실패해도 계속 진행
              print('Supabase Auth error: $authError');
            }
          }

          // 3. 기존 _saveUserToServer 호출 (변경 없음)
          await _saveUserToServer({
            'email': email,
            'nickname': kakaoUser.kakaoAccount?.profile?.nickname,
            'profileImage': kakaoUser.kakaoAccount?.profile?.profileImageUrl,
            'providerId': kakaoUser.id.toString(),
            'provider': 'kakao',
            'password': null,
            'phone': null,
            'birthDate': null,
            'gender': null,
            'userType': 'user',
            'enabled': true,
            'role': 'USER'
          });
        } catch (error) {
          print('Kakao login error: $error');
          throw Exception('카카오 로그인 실패: $error');
        }
      }
      return null;
    } catch (error) {
      print('Detailed error: $error');
      throw Exception('카카오 로그인 실패: $error');
    }
  }

  // 서버에 사용자 정보 저장
  static Future<void> _saveUserToServer(Map<String, dynamic> kakaoUserData) async {
    try {
      print('============ _saveUserToServer START ============');
      print('Received kakaoUserData: $kakaoUserData');

      // users 테이블에서 이메일과 provider로 함께 검색
      List<Map<String, dynamic>> users = await supabase
          .from('users')
          .select()
          .eq('email', kakaoUserData['email'])
          .eq('provider', 'kakao'); // provider도 함께 체크

      final userData = users.isNotEmpty ? users.first : null;
      print('User data: $userData');

      if (userData != null) {
        print('Found existing user: ${userData['email']}');
        // 기존 사용자인 경우 바로 홈으로 이동
        await UserPreferences.setUserId(userData['id']);
        await UserPreferences.setUserNickname(userData['nickname']);
        await UserPreferences.setUserEmail(userData['email']);
        navigatorKey.currentState?.pushReplacementNamed('/home');
      } else {
        // 새로운 사용자인 경우에만 추가 정보 입력 페이지로 이동
        print('New user needs additional info');
        navigatorKey.currentState?.pushReplacementNamed(
            '/additional-info',
            arguments: {
              'email': kakaoUserData['email'],
              'nickname': kakaoUserData['nickname'],
              'profileImage': kakaoUserData['profileImage'],
              'provider': 'kakao',
              'providerId': kakaoUserData['providerId'],
            }
        );
      }

      print('============ _saveUserToServer END ============');
    } catch (e) {
      print('Error in _saveUserToServer: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('카카오 로그인 처리 실패: $e');
    }
  }
  // 로그아웃
  static Future<void> signOut() async {
    await supabase.auth.signOut();
    if (await kakao.isKakaoTalkInstalled()) {
      await kakao.UserApi.instance.unlink();
    }
  }

  // 일반 회원가입
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
      final existingUser = await getUserByEmail(email);

      if (existingUser != null) {
        try {
          final signInResponse = await supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );

          if (signInResponse.user != null) {
            final updatedUser = await supabase
                .from('users')
                .update({
              'nickname': nickname,
              'phone': phone,
              'birth_date': birthDate,
              'gender': gender,
              'user_type': userType,
              'updated_at': DateTime.now().toIso8601String()
            })
                .eq('email', email)
                .select()
                .single();

            await UserPreferences.setUserId(updatedUser['id']);
            await UserPreferences.setUserNickname(updatedUser['nickname']);
            await UserPreferences.setUserEmail(updatedUser['email']);

            return updatedUser;
          }
        } catch (loginError) {
          throw '로그인 실패: 이메일 또는 비밀번호가 올바르지 않습니다.';
        }
      }

      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw '회원가입 실패';
      }

      final userData = await supabase
          .from('users')
          .insert({
        'id': authResponse.user!.id,
        'email': email,
        'nickname': nickname,
        'phone': phone,
        'birth_date': birthDate,
        'gender': gender,
        'user_type': userType,
        'provider': 'email',
        'enabled': true,
        'role': 'USER',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .select()
          .single();

      await UserPreferences.setUserId(userData['id']);
      await UserPreferences.setUserNickname(userData['nickname']);
      await UserPreferences.setUserEmail(userData['email']);

      return userData;
    } catch (e) {
      print('Registration error: $e');
      if (e.toString().contains('user_already_exists')) {
        throw '이미 등록된 이메일입니다. 로그인을 시도해주세요.';
      }
      throw '회원가입 실패: $e';
    }
  }

  // 사용자 정보 업데이트
  static Future<Map<String, dynamic>?> updateUserInfo(Map<String, dynamic> userData) async {
    try {
      final response = await supabase
          .from('users')
          .upsert({
        'email': userData['email'],
        'nickname': userData['nickname'],
        'phone': userData['phone'],
        'birth_date': userData['birth_date'],
        'gender': userData['gender'],
        'user_type': userData['user_type'],
        'profile_image': userData['profile_image'],
        'provider': userData['provider'],
        'provider_id': userData['provider_id'],
        'role': userData['role'],
        'enabled': userData['enabled'],

        // 에이전시 인증 관련 필드 추가
        'business_license_url': userData['business_license_url'],
        'agency_status': userData['agency_status'],
        'updated_at': DateTime.now().toIso8601String()
      })
          .select()
          .single();

      print('UpdateUserInfo response: $response'); // 추가
      return response;
    } catch (e) {
      print('Error in updateUserInfo: $e');
      throw Exception('사용자 정보 업데이트 실패: $e');
    }
  }
  // 이메일로 사용자 조회
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('email', email)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }
}