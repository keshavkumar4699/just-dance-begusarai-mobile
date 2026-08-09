import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';
import '../core/app_constants.dart';

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final DatabaseHelper _db = DatabaseHelper();

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'StudioCrow unlock karein',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  bool verifyPin(String pin) {
    return pin == AppConstants.defaultPin;
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _db.getSetting('biometricEnabled');
    return val == '1';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _db.setSetting('biometricEnabled', enabled ? '1' : '0');
  }
}