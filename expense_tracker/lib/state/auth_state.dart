import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/repository.dart';
import '../models/user.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState extends ChangeNotifier {
  final _repo = financeRepository;
  static const _tokenKey = 'auth_token';

  AuthStatus status = AuthStatus.loading;
  AppUser? user;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    _repo.client.token = token;
    try {
      user = await _repo.me();
      status = AuthStatus.authenticated;
    } catch (_) {
      _repo.client.token = null;
      await prefs.remove(_tokenKey);
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final result = await _repo.login(email: email, password: password);
    await _save(result.token, result.user);
  }

  Future<void> register(String name, String email, String password) async {
    final result = await _repo.register(
      name: name,
      email: email,
      password: password,
    );
    await _save(result.token, result.user);
  }

  Future<void> _save(String token, AppUser u) async {
    user = u;
    _repo.client.token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    user = null;
    _repo.client.token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
