import 'package:flutter/foundation.dart';
import '../Services/auth_service.dart';
import '../Services/pos_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final PosService _posService = PosService();
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkAuthStatus() async {
    final token = await _authService.getToken();
    _isAuthenticated = token != null;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    try {
      await _posService.login(username, password);
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.deleteToken();
    _isAuthenticated = false;
    notifyListeners();
  }
}