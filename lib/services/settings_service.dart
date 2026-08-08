import '../database/database_helper.dart';
import '../constants.dart';

class SettingsService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static Future<String> getPin() async {
    final pin = await _dbHelper.getSetting(AppConstants.pinKey);
    return pin ?? AppConstants.defaultPin;
  }

  static Future<bool> setPin(String newPin) async {
    if (newPin.length != 4) return false;
    final res = await _dbHelper.setSetting(AppConstants.pinKey, newPin);
    return res > 0;
  }

  static Future<String> getStudioName() async {
    final name = await _dbHelper.getSetting('studio_name');
    return name ?? AppConstants.appName;
  }

  static Future<bool> setStudioName(String name) async {
    final res = await _dbHelper.setSetting('studio_name', name);
    return res > 0;
  }

  static Future<bool> isBiometricsEnabled() async {
    final val = await _dbHelper.getSetting('enable_biometrics');
    return val == 'true';
  }

  static Future<void> setBiometricsEnabled(bool enabled) async {
    await _dbHelper.setSetting('enable_biometrics', enabled ? 'true' : 'false');
  }
}
