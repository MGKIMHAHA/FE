import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppTheme {
  // 기본 테마 색상 - 앱 전체적으로 통일
  static const Color primaryColor = Color(0xFF0969F1);  // 인기 게시글용 파란색
  static const Color primaryColorDark = Color(0xFF0653B6);  // 진한 파란색
  static const Color backgroundColor = Color(0xFFF8FAFF);  // 살짝 푸른 흰색 배경

  // 각 게시판 태그 색상 (게시글 유형 구분용)
  static const Color freeboardColor = Color(0xFF4A90E2);  // 자유게시판용 파란색 (인기 게시글과 구분)
  static const Color reviewColor = Color(0xFF70AD47);     // 부드러운 초록색
  static const Color jobColor = Color(0xFFED7D31);        // 부드러운 주황색
  static const Color hotColor = Color(0xFFE74C3C);        // 인기글 표시용 빨간색
  static const Color defaultColor = Color(0xFF7F7F7F);    // 중간 톤 회색
  static const Color textColor = Color(0xFF212121);       // 닉네임용 검은색
  static const Color titleColor = Color(0xFF303030);      // 제목용 진한 회색
  static const Color contentColor = Color(0xFF505050);    // 내용용 중간 회색

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


class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({Key? key}) : super(key: key);

  @override
  _AuthCheckPageState createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // 약간의 지연 시간 추가 (스플래시 화면 효과)
    await Future.delayed(Duration(milliseconds: 500));

    // 현재 Supabase 세션 확인
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null && mounted) {
      // 세션이 있으면 (로그인 상태) 메인 화면으로 이동
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      // 세션이 없으면 로그인 화면으로 이동
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 간단한 로딩 화면 표시
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      ),
    );
  }
}