import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

class KeyHashPage extends StatefulWidget {
  const KeyHashPage({Key? key}) : super(key: key);

  @override
  State<KeyHashPage> createState() => _KeyHashPageState();
}

class _KeyHashPageState extends State<KeyHashPage> {
  String _keyHash = "로딩 중...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getKeyHash();
  }

  Future<void> _getKeyHash() async {
    try {
      final keyHash = await KakaoSdk.origin;
      setState(() {
        _keyHash = keyHash;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _keyHash = "오류: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카카오 키 해시'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '카카오 개발자 사이트에 등록할 키 해시:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _keyHash,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _keyHash));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('키 해시가 클립보드에 복사되었습니다'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('복사하기'),
              ),
              const SizedBox(height: 40),
              const Text(
                '참고: 웹 환경에서는 URL이 표시되고, 안드로이드 기기에서는 실제 키 해시가 표시됩니다.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}