import 'package:flutter/foundation.dart';

import '../core/models/auth_models.dart';
import '../core/network/backend_api.dart';
import '../core/storage/session_store.dart';

class AppController extends ChangeNotifier {
  AppController({SessionStore? sessionStore})
    : _sessionStore = sessionStore ?? SessionStore() {
    _api = BackendApi(_sessionStore);
  }

  final SessionStore _sessionStore;
  late final BackendApi _api;

  BackendApi get api => _api;

  bool _bootstrapping = true;
  bool get bootstrapping => _bootstrapping;

  String? _token;
  String? get token => _token;

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;

  bool get isSignedIn => _token != null && _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'ADMIN';

  Future<void> bootstrap() async {
    _bootstrapping = true;
    notifyListeners();
    try {
      final snapshot = await _sessionStore.read();
      _token = snapshot.token;
      _currentUser = snapshot.user;

      if (_token != null && _token!.isNotEmpty) {
        try {
          final freshUser = await _api.me();
          _currentUser = freshUser;
          await _sessionStore.save(token: _token!, user: freshUser);
        } catch (_) {
          await _sessionStore.clear();
          _token = null;
          _currentUser = null;
        }
      }
    } finally {
      _bootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> login({
    required String username,
    required String password,
    bool admin = false,
  }) async {
    final result = admin
        ? await _api.adminLogin(username: username, password: password)
        : await _api.login(username: username, password: password);
    _token = result.token;
    _currentUser = result.user;
    await _sessionStore.save(token: result.token, user: result.user);
    notifyListeners();
  }

  Future<void> register({
    required String username,
    required String password,
    String? nickname,
    String? phone,
    String? inviteCode,
    bool admin = false,
  }) async {
    final result = admin
        ? await _api.adminRegister(
            username: username,
            password: password,
            nickname: nickname?.trim() ?? '',
            phone: phone?.trim() ?? '',
            inviteCode: inviteCode?.trim() ?? '',
          )
        : await _api.register(
            username: username,
            password: password,
            nickname: nickname,
            phone: phone,
          );
    _token = result.token;
    _currentUser = result.user;
    await _sessionStore.save(token: result.token, user: result.user);
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    if (_token == null || _token!.isEmpty) {
      return;
    }
    final freshUser = await _api.me();
    _currentUser = freshUser;
    await _sessionStore.save(token: _token!, user: freshUser);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await _sessionStore.clear();
    notifyListeners();
  }
}
