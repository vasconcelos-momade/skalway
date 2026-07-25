import 'startup_tasks.dart';

/// Orquestra o arranque da aplicação antes do `runApp`.
abstract final class StartupService {
  StartupService._();

  static Future<void> run() => StartupTasks.runAll();
}
