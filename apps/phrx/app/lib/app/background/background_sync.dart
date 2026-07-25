import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

const backgroundSyncTaskName = 'pharmaErpBackgroundSync';

/// Ponto de entrada para tarefas em background (Workmanager).
@pragma('vm:entry-point')
void backgroundSyncDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (kDebugMode) {
      debugPrint('[Workmanager] task=$taskName data=$inputData');
    }
    // TODO: fila offline, heartbeat, sync central/pull
    return true;
  });
}

abstract final class BackgroundSync {
  BackgroundSync._();

  static Future<void> register() async {
    await Workmanager().initialize(backgroundSyncDispatcher);
    await Workmanager().registerPeriodicTask(
      backgroundSyncTaskName,
      backgroundSyncTaskName,
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
