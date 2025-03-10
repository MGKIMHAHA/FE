// lib/pages/notice_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NoticePage extends StatefulWidget {
  const NoticePage({super.key});

  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('notices')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _notices = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공지사항을 불러오는데 실패했습니다: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotices,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notices.isEmpty
            ? Center(
          child: Text(
            '등록된 공지사항이 없습니다.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        )
            : ListView.builder(
          itemCount: _notices.length,
          itemBuilder: (context, index) {
            final notice = _notices[index];
            return Column(
              children: [
                ListTile(
                  title: Text(
                    notice['title'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(notice['content'] ?? ''),
                      const SizedBox(height: 4),
                      Text(
                        notice['created_at'] ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // 공지사항 상세 보기 다이얼로그
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(notice['title'] ?? ''),
                        content: SingleChildScrollView(
                          child: Text(notice['content'] ?? ''),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('닫기'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
              ],
            );
          },
        ),
      ),
    );
  }
}