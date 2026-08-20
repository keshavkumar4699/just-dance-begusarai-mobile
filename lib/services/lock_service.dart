/// Just Dance — App Lock via the device's own system authentication
/// (face / fingerprint / device PIN), Google-Photos-Locked-Folder style.
library;

import 'package:local_auth/local_auth.dart';

class LockService {
  LockService._();
  static final LockService instance = LockService._();

  final _auth = LocalAuthentication();

  /// True when the device has any system credential enrolled
  /// (biometric OR device PIN/pattern/password).
  Future<bool> available() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported && !canCheck) return false;
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty || supported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlock() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Just Dance',
        options: const AuthenticationOptions(
          biometricOnly: false, // device PIN/pattern/password allowed
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
