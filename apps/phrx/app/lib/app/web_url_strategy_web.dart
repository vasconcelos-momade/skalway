import 'package:flutter_web_plugins/url_strategy.dart';

/// Must run before [WidgetsFlutterBinding.ensureInitialized].
/// After binding init, the engine locks the default [HashUrlStrategy].
void configureAppUrlStrategy() {
  usePathUrlStrategy();
}
