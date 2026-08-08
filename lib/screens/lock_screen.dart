import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../constants.dart';
import 'home_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({Key? key}) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  String _enteredPin = '';
  String _correctPin = AppConstants.defaultPin;
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPinAndBiometrics();
  }

  Future<void> _loadPinAndBiometrics() async {
    final pin = await SettingsService.getPin();
    setState(() {
      _correctPin = pin;
    });

    final isBioEnabled = await SettingsService.isBiometricsEnabled();
    if (isBioEnabled) {
      _authenticateBiometrics();
    }
  }

  Future<void> _authenticateBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (canCheck) {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to access Just Dance Academy Studio',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
        );
        if (authenticated) {
          _unlockApp();
        }
      }
    } catch (_) {}
  }

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _isError = false;
        _enteredPin += digit;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _isError = false;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _verifyPin() {
    if (_enteredPin == _correctPin) {
      _unlockApp();
    } else {
      setState(() {
        _isError = true;
        _errorMessage = 'Incorrect PIN. Default PIN is 2026.';
        _enteredPin = '';
      });
    }
  }

  void _unlockApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Logo & Header
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 2),
                boxShadow: const [
                  BoxShadow(color: AppColors.borderGold, blurRadius: 15),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  AppConstants.logoAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: AppColors.gold, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              style: AppFonts.displayHeader(fontSize: 24),
            ),
            Text(
              AppConstants.appTagline,
              style: AppFonts.subtitleText(fontSize: 12),
            ),
            const SizedBox(height: 32),

            // Security PIN Dots
            Text(
              'Enter Admin Security PIN',
              style: AppFonts.bodyText(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.gold : AppColors.surfaceLight,
                    border: Border.all(
                      color: _isError ? AppColors.overdueRed : AppColors.gold,
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),

            if (_isError) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: AppFonts.subtitleText(color: AppColors.overdueRed, fontSize: 12),
              ),
            ],

            const Spacer(),

            // Keypad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildKeyRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildKeyRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildKeyRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.fingerprint, color: AppColors.gold, size: 28),
                        onPressed: _authenticateBiometrics,
                      ),
                      _buildKeyButton('0'),
                      IconButton(
                        icon: const Icon(Icons.backspace_outlined, color: AppColors.textSecondary, size: 24),
                        onPressed: _onBackspace,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKeyButton(key)).toList(),
    );
  }

  Widget _buildKeyButton(String digit) {
    return InkWell(
      onTap: () => _onKeyPress(digit),
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 65,
        height: 65,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Text(
          digit,
          style: AppFonts.displayHeader(fontSize: 22, color: AppColors.ivory),
        ),
      ),
    );
  }
}
