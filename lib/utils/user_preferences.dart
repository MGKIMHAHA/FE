import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const String _providerKey = 'provider';
  static const String _keyUserId = 'userId';
  static const String _keyUserNickname = 'userNickname';
  static const String _keyUserEmail = 'userEmail';  // 추가
  static const String _keyApiToken = 'apiToken';  // 이 줄 추가
  static const String _keyUserType = 'userType';

  // UserType 저장 메서드 추가
  static Future<void> setUserType(String userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserType, userType);
  }

  // UserType 가져오는 메서드 추가
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserType);

  }





  static Future<void> setProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, provider);
  }

  static Future<String?> getProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_providerKey);
  }




  // 이메일 저장
  static Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
  }


  // 이메일 가져오기
  static Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail) ?? '';
  }

  // 사용자 ID 저장
  static Future<void> setUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
  }

  // 사용자 ID 가져오기
  static Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId) ?? 0;  // 기본값 0
  }

  // 닉네임 저장
  static Future<void> setUserNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserNickname, nickname);
  }

  // 닉네임 가져오기
  static Future<String> getUserNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserNickname) ?? '';
  }

  // API 토큰 저장
  static Future<void> setApiToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiToken, token);
  }

  // API 토큰 가져오기
  static Future<String?> getApiToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiToken);
  }

  // API 토큰 삭제
  static Future<void> removeApiToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyApiToken);
  }

  // 모든 사용자 데이터 저장 (한 번에 저장하는 메서드)
  static Future<void> saveUserData({
    required int userId,
    required String nickname,
    required String apiToken,
    required String email,
    String? userType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUserNickname, nickname);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyApiToken, apiToken);
    if (userType != null) {
      await prefs.setString(_keyUserType, userType);
      print('UserType saved: $userType'); // 디버깅용
    }
  }

  // 모든 사용자 데이터 삭제 (로그아웃 시 사용)
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserNickname);
    await prefs.remove(_keyApiToken);
    await prefs.remove(_keyUserEmail);  // 이메일도 삭제
    await prefs.remove(_keyUserType);
  }
}
