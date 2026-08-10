import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import '../constants.dart';
import 'backup_service.dart';
import 'settings_service.dart';

/// Registers the daily 4AM silent backup task (Android).
class BackupWorker {
  static const _taskId = 'studio_crow_daily_backup';

  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);
    final on = await SettingsService.instance.getBool(SettingsKeys.dailyBackupOn, true);
    if (on) await register();
  }

  static Future<void> register() async {
    // Schedule to the next 4 AM, repeating daily (Android minimum is 15 min).
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, 4);
    if (!now.isBefore(next)) next = next.add(const Duration(days: 1));
    final delay = next.difference(now);
    await Workmanager().registerPeriodicTask(
      _taskId,
      _taskId,
      frequency: const Duration(hours: 24),
      initialDelay: delay,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  static Future<void> unregister() async {
    await Workmanager().cancelByUniqueName(_taskId);
  }
}

/// Workmanager entry point (background isolate).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final on = await SettingsService.instance.getBool(SettingsKeys.dailyBackupOn, true);
      if (!on) return true;
      final wifiOnly = await SettingsService.instance.getBool(SettingsKeys.wifiOnlyBackup, false);
      if (wifiOnly && !await BackupService.instance.isWifiNative()) return true;
      final res = await BackupService.instance.backupNow(force: true);
      return res.ok;
    } catch (_) {
      return false;
    }
  });
}
