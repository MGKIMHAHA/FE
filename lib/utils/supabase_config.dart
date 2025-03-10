// lib/utils/supabase_config.dart

import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase 클라이언트 전역 접근용
final supabase = Supabase.instance.client;

// 현재 사용자 ID를 쉽게 가져올 수 있는 getter
String? get currentUserId => supabase.auth.currentUser?.id;

// 현재 사용자가 로그인되어 있는지 확인하는 getter
bool get isAuthenticated => supabase.auth.currentUser != null;