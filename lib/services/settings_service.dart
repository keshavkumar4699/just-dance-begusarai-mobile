import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../constants.dart';
import '../database/db_helper.dart';
import '../models/models.dart';

/// Typed key-value access to the settings table.
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  Future<String?> get(String key) async {
    final d = await DbHelper.instance.db;
    final rows = await d.query('settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    final d = await DbHelper.instance.db;
    await d.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> getInt(String key, [int def = 0]) async {
    final v = await get(key);
    return v == null ? def : (int.tryParse(v) ?? def);
  }

  Future<bool> getBool(String key, [bool def = false]) async {
    final v = await get(key);
    return v == null ? def : v == '1';
  }

  Future<void> setBool(String key, bool value) => set(key, value ? '1' : '0');

  // ---- Theme -------------------------------------------------------------

  Future<bool> isDarkTheme() async {
    final v = await get(SettingsKeys.theme);
    if (v == null) return true; // default dark
    return v == 'dark';
  }

  Future<void> setTheme(bool dark) => set(SettingsKeys.theme, dark ? 'dark' : 'light');

  // ---- Studio info -------------------------------------------------------

  Future<StudioInfo> studioInfo() async {
    final v = await get(SettingsKeys.studioInfoJson);
    if (v == null) return StudioInfo();
    try {
      return StudioInfo.fromMap((jsonDecode(v) as Map).cast<String, Object?>());
    } catch (_) {
      return StudioInfo();
    }
  }

  Future<void> saveStudioInfo(StudioInfo info) =>
      set(SettingsKeys.studioInfoJson, jsonEncode(info.toMap()));

  // ---- WhatsApp templates -------------------------------------------------

  Future<List<WaTemplate>> templates() async {
    final v = await get(SettingsKeys.waTemplatesJson);
    if (v == null) {
      return [
        for (final e in TemplateKeys.defaults.entries) WaTemplate(key: e.key, text: e.value),
      ];
    }
    try {
      final list = (jsonDecode(v) as List).cast<Map>();
      final existing = {for (final m in list) m['key'] as String: m['text'] as String};
      return [
        for (final e in TemplateKeys.defaults.entries)
          WaTemplate(key: e.key, text: existing[e.key] ?? e.value),
      ];
    } catch (_) {
      return [for (final e in TemplateKeys.defaults.entries) WaTemplate(key: e.key, text: e.value)];
    }
  }

  Future<void> saveTemplates(List<WaTemplate> templates) =>
      set(SettingsKeys.waTemplatesJson, jsonEncode([for (final t in templates) t.toMap()]));

  /// Single template text by key (with defaults fallback).
  Future<String> templateText(String key) async {
    final list = await templates();
    for (final t in list) {
      if (t.key == key) return t.text;
    }
    return TemplateKeys.defaults[key] ?? '';
  }

  // ---- Backup meta --------------------------------------------------------

  Future<BackupMeta> backupMeta() async {
    final v = await get(SettingsKeys.backupMeta);
    if (v == null) return BackupMeta();
    try {
      return BackupMeta.fromMap((jsonDecode(v) as Map).cast<String, Object?>());
    } catch (_) {
      return BackupMeta();
    }
  }

  Future<void> saveBackupMeta(BackupMeta meta) =>
      set(SettingsKeys.backupMeta, jsonEncode(meta.toMap()));
}
