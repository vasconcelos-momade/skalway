import 'package:flutter/foundation.dart';

import '../../core/network/connectivity/connection_status.dart';

class ConnectivityProvider extends ChangeNotifier {
  ConnectionStatus _status = ConnectionStatus.unknown;

  ConnectionStatus get status => _status;

  void setStatus(ConnectionStatus value) {
    if (_status == value) return;
    _status = value;
    notifyListeners();
  }
}
