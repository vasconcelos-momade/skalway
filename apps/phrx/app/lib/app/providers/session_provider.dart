import 'package:flutter/foundation.dart';

/// Sessão de utilizador (tokens, expiração, tenant).
class SessionProvider extends ChangeNotifier {
  String? _userId;

  String? get userId => _userId;

  void setUserId(String? value) {
    if (_userId == value) return;
    _userId = value;
    notifyListeners();
  }
}
