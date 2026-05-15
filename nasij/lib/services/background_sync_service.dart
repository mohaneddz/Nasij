import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../data/offline_storage.dart';
import 'sync_action_dispatcher.dart';

class BackgroundSyncService {
  static const String taskName = 'supplier_outbox_sync';
  static const String periodicTaskUniqueName = 'nasij_supplier_periodic_sync';
  static const String oneOffTaskUniqueName = 'nasij_supplier_oneoff_sync';
  static const int _maxRetries = 5;

  static bool get _isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> initialize() async {
    if (!_isSupportedPlatform) return;
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> schedulePeriodicSync() async {
    if (!_isSupportedPlatform) return;
    await Workmanager().registerPeriodicTask(
      periodicTaskUniqueName,
      taskName,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 1),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
  }

  static Future<void> scheduleOneOffSync() async {
    if (!_isSupportedPlatform) return;
    await Workmanager().registerOneOffTask(
      oneOffTaskUniqueName,
      taskName,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(networkType: NetworkType.connected),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
      initialDelay: const Duration(minutes: 1),
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (task != BackgroundSyncService.taskName) {
      return Future.value(true);
    }

    final storage = OfflineStorage();
    await storage.init();

    final pending = storage.getPendingActions();
    if (pending.isEmpty) {
      return Future.value(true);
    }

    final session = storage.getSession();
    final accessToken = session?['accessToken'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      return Future.value(false);
    }

    for (final action in pending) {
      if (action.retryCount >= BackgroundSyncService._maxRetries) {
        continue;
      }
      try {
        await pushSyncAction(accessToken: accessToken, action: action);
        await storage.markSynced(action.id);
      } catch (_) {
        await storage.incrementRetry(action.id);
      }
    }

    await storage.clearSynced();
    return Future.value(true);
  });
}
