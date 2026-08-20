/// Just Dance — entry point. Offline-first studio manager.
library;

import 'package:flutter/material.dart';

import 'app.dart';
import 'data/store.dart';
import 'services/backup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.load();

  // Backup engine: debounced uploads after changes + daily 4AM task.
  BackupService.instance.attach(store);
  await BackupService.instance.initWorkManager();
  await BackupService.instance
      .scheduleDaily(enabled: store.dailyBackupOn, wifiOnly: store.wifiOnlyBackup);

  runApp(JustDanceApp(store: store));
}
