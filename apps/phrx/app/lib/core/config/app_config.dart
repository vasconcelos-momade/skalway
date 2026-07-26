import 'env.dart';

class AppConfig {
  const AppConfig({this.appName = 'Pharma ERP'});

  final String appName;

  static AppConfig fromEnv() => AppConfig(appName: Env.appName);
}
