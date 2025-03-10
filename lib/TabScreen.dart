import 'package:flutter/material.dart';
import 'ReviewPage.dart';
import 'FreeBoardPage.dart';
import 'job.dart';
import 'PopularPostsPage.dart';
import 'package:eventers/EventGroupBoardPage.dart';
import 'package:eventers/RecentPostsPage.dart';

class TabScreen extends StatefulWidget {
  const TabScreen({super.key});

  @override
  State<TabScreen> createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // 5개로 변경 (후기게시판 추가)
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 탭바
        Container(
          height: 45, // 높이 고정으로 간격 좁게 설정
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor:  Colors.black,
            labelColor:  Colors.black,
            // indicatorColor: Color(0xFF5D6BFF),
            // labelColor: Color(0xFF5D6BFF),
            unselectedLabelColor: Color(0xFF495057),
            indicatorWeight: 2, // 얇게 수정
            indicatorSize: TabBarIndicatorSize.tab, // 탭 전체 너비로 변경
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600, // 약간 얇게
              fontSize: 14, // 크기 줄임
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            padding: EdgeInsets.zero, // 패딩 제거
            labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0), // 좁게 수정
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            overlayColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                return states.contains(MaterialState.focused) ? null : Colors.transparent;
              },
            ),
            tabs: const [
              Tab(text: '전체'),
              Tab(text: '자유게시판'),
              Tab(text: '후기게시판'), // 후기게시판 추가
              Tab(text: '행사팟'),
              Tab(text: '구인'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              RecentPostsPage(),
              FreeBoardPage(),
              ReviewPage(), // 후기게시판 페이지 추가
              EventGroupBoardPage(),
              JobPage(),
            ],
          ),
        ),
      ],
    );
  }
}