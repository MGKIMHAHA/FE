import 'package:flutter/material.dart';
import 'package:eventers/Calendar.dart';
import './style.dart' as style;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'search_delegate.dart';
import 'LikedPostsPage.dart';
import 'TabScreen.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'utils/navigation_service.dart';
import 'additional_info_page.dart';
import 'widgets/loading_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eventers/KeyHashPage.dart';
import 'widgets/AuthCheckPage.dart';



import './post_model.dart';
import 'job.dart';
import './ReviewPage.dart';
import 'FreeBoardPage.dart';
import 'package:flutter/cupertino.dart';
import 'PopularPostsPage.dart';
import 'MyPage.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'auth_callback_page.dart';

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
  static const Color likeColor = Color(0xFFE74C3C);       // 좋아요 표시용 빨간색
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  // Supabase 초기화
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Kakao SDK 초기화
  kakao.KakaoSdk.init(
    javaScriptAppKey: 'd6ae5e44f126fae63ab66a6445b7914e',  // 웹용 앱 키
    nativeAppKey: '1a1f240ae5b41460756c0ac2d0784e1e',          // 네이티브 앱 키
  );

  // 키 해시 출력
  try {
    final keyHash = await kakao.KakaoSdk.origin;
    print("현재 사용 중인 키 해시: $keyHash");
  } catch (e) {
    print("키 해시를 가져오는 중 오류 발생: $e");
  }





  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Eventers',



      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: const Color(0xFFFAFAFA),  // 원래 배경색으로 복구
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
      home: const AuthCheckPage(),
      routes: {
        // routes에 추가
        '/key-hash': (context) => const KeyHashPage(),
        '/login': (context) {
          final uri = Uri.base;
          print('=============== Route Debug ===============');
          print('Current URL: $uri');
          print('Path: ${uri.path}');
          print('Query Parameters: ${uri.queryParameters}');
          print('Fragment: ${uri.fragment}');

          if (uri.path == '/auth/callback') {
            print('Routing to AuthCallbackPage from /auth/callback');
            return const AuthCallbackPage();
          }

          print('Routing to LoginPage');
          return const LoginPage();
        },
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const MainScreen(),
        '/additional-info': (context) {
          print('============ Routing to additional-info ============');
          final args = ModalRoute.of(context)?.settings.arguments;
          print('Route arguments: $args');

          if (args == null || args is! Map<String, dynamic>) {
            print('Invalid arguments, checking current session...');
            final session = Supabase.instance.client.auth.currentSession;

            if (session == null) {
              print('No session found, returning to login');
              return const LoginPage();
            }

            print('Session exists but no arguments, going to home');
            Future.microtask(() {
              Navigator.of(context).pushReplacementNamed('/home');
            });
            return const LoadingScreen();
          }

          return AdditionalInfoPage(kakaoUserData: args);
        },
      },
    );
  }
}

// MainScreen 위젯
class MainScreen extends StatefulWidget {

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    print('MainScreen initialized');
  }

  @override
  Widget build(BuildContext context) {

    final bool hideMainAppBar = _selectedIndex == 1;

    return Scaffold(
      appBar:hideMainAppBar
          ? null  // 좋아요 페이지일 때는 AppBar를 표시하지 않음
          : AppBar(
        title: Text(
          '이벤트 커넥트',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0, // 스크롤 시 elevation 변경 방지
        surfaceTintColor: Colors.transparent,
        centerTitle: false, // 좌측 정렬
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: Color(0xFF495057),
              size: 26,
            ),
            tooltip: '검색',
            onPressed: () async {
              final result = await showSearch(
                context: context,
                delegate: CustomSearchDelegate(),
              );

              if (result != null) {
                Navigator.pushNamed(
                  context,
                  '/post_detail',
                  arguments: result,
                );
              }
            },
          ),
          // IconButton(
          //   icon: Icon(
          //     Icons.notifications_none,
          //     color: Color(0xFF495057),
          //     size: 26,
          //   ),
          //   tooltip: '알림',
          //   onPressed: () {
          //     // 알림 기능
          //   },
          // ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Color(0xFFE9ECEF),
            height: 1.0,
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const TabScreen(),
          _selectedIndex == 1 ? const LikedPostsPage() : Container(),
          const Calendar(),
          const MyPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black, // 새로운 테마 색상 적용
            unselectedItemColor: Colors.grey.shade400,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
            ),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: const Icon(Icons.home_outlined, size: 24),
                ),
                activeIcon: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Color(0xFF5D6BFF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.home, size: 24),
                ),
                label: '홈',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: const Icon(Icons.favorite_border, size: 24),
                ),
                activeIcon: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF3B30).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.favorite, size: 24, color: Color(0xFFFF3B30)),
                ),
                label: '찜',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: const Icon(Icons.calendar_month_outlined, size: 24),
                ),
                activeIcon: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Color(0xFF5D6BFF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_month, size: 24),
                ),
                label: '캘린더',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: const Icon(Icons.person_outline, size: 24),
                ),
                activeIcon: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Color(0xFF5D6BFF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 24),
                ),
                label: '마이페이지',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EX extends StatefulWidget {
  const EX({Key? key,this.data,this.addData}): super(key:key);
  final data;
  final addData;

  @override
  State<EX> createState() => _EXState();
}

class _EXState extends State<EX> {

var scroll = ScrollController();

getMore() async{
  var result = await http.get(Uri.parse('https://codingapple1.github.io/app/more2.json'));

  var result2=jsonDecode(result.body);

  widget.addData(result2);




}

@override
  void initState() {
    // TODO: implement initState
    super.initState();
    scroll.addListener((){
        if(scroll.position.pixels==scroll.position.maxScrollExtent){
          getMore();

        }
    });
  }


  @override
  Widget build(BuildContext context) {




    if (widget.data.isNotEmpty){
      return ListView.builder(itemCount: widget.data.length
          ,controller: scroll,
          itemBuilder: (c, i) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 500,

              color: Colors.grey,
            ),
            Text('like ${widget.data[i]['likes']}'),
            Text('date ${widget.data[i]['date']}'),
            Text(widget.data[i]['content']),


          ],
        );
      }
      );
  }

    else{
      return Text('로딩중임');
    }

  }
}




class Upload extends StatelessWidget {
  const Upload({Key? key , this.userImage, this.setUserContent,this.addMyData}) : super(key:key);
  final userImage;
  final setUserContent;
  final addMyData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        actions: [
          IconButton(onPressed: (){
            addMyData();
          }, icon: Icon(Icons.send)),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미 userImage가 정의되어 있다고 가정하고, 그대로 사용
          Image.file(userImage),
          Text('이미지업로드화면'),
          TextField(onChanged: (text){
            setUserContent(text);
          },),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.close), // icons -> Icons로 수정
          ),
        ],
      ),
    );
  }
}