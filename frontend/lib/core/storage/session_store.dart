import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_models.dart';

class SessionSnapshot {
  const SessionSnapshot({required this.token, required this.user});

  final String? token;
  final AuthUser? user;
}

class SessionStore {
  static const String _tokenKey = 'campus_runner_token';
  static const String _userKey = 'campus_runner_user';

  Future<SessionSnapshot> read() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userText = prefs.getString(_userKey);
    AuthUser? user;
    if (userText != null && userText.isNotEmpty) {
      try {
        user = AuthUser.fromJson(
          Map<String, dynamic>.from(jsonDecode(userText) as Map),
        );
      } catch (_) {
        user = null;
      }
    }
    return SessionSnapshot(token: token, user: user);
  }

  Future<void> save({required String token, required AuthUser user}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
