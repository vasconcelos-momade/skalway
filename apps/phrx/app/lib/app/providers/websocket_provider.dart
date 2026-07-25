import 'package:flutter/foundation.dart';

/// Estado da ligação WebSocket (quando aplicável).
class WebSocketProvider extends ChangeNotifier {
  bool _connected = false;

  bool get connected => _connected;

  void setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    notifyListeners();
  }
}
