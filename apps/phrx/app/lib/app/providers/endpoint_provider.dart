import 'package:flutter/foundation.dart';

/// URL base resolvida (multi-inquilino / ambiente).
class EndpointProvider extends ChangeNotifier {
  String _baseUrl = '';

  String get baseUrl => _baseUrl;

  void setBaseUrl(String value) {
    if (_baseUrl == value) return;
    _baseUrl = value;
    notifyListeners();
  }
}
