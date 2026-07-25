import '../../core/security/secure_storage_service.dart';
import '../background/background_sync.dart';

/// Tarefas de inicialização (Hive, env, DI, etc.).
abstract final class StartupTasks {
  StartupTasks._();

  static Future<void> runAll() async {
    final secure = SecureStorageService();
    await secure.getOrCreateDeviceId();

    try {
      await BackgroundSync.register();
    } catch (_) {
      // Workmanager pode falhar em desktop/web — ignorar em dev.
    }
  }
}
