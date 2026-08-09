import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/app_constants.dart';
import '../services/auth_service.dart';
import 'main_scaffold.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final AuthService _auth = AuthService();
  final List<String> _pin = [];
  String _error = '';
  bool _showPinPad = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometric();
    });
  }

  Future<void> _tryBiometric() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    final canCheck = await _auth.canCheckBiometrics();
    if (!canCheck) {
      setState(() {
        _showPinPad = true;
        _isAuthenticating = false;
      });
      return;
    }
    final success = await _auth.authenticateWithBiometric();
    setState(() => _isAuthenticating = false);
    if (success) _unlock();
  }

  void _onPinDigit(String digit) {
    if (_pin.length >= AppConstants.pinLength) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin.add(digit);
      _error = '';
    });
    if (_pin.length == AppConstants.pinLength) {
      final pinStr = _pin.join();
      if (_auth.verifyPin(pinStr)) {
        _unlock();
      } else {
        setState(() {
          _error = 'Galat PIN. Default: ${AppConstants.defaultPin}';
          _pin.clear();
        });
        HapticFeedback.heavyImpact();
      }
    }
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_pin.isNotEmpty) _pin.removeLast();
    });
  }

  void _unlock() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScaffold(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.darkSurface,
                        child: const Icon(
                          Icons.fitness_center,
                          color: AppColors.gold,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(AppConstants.appName,
                    style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Unlock karein', style: theme.textTheme.bodySmall),
                const SizedBox(height: 48),
                if (!_showPinPad && !_isAuthenticating) ...[
                  ElevatedButton.icon(
                    onPressed: _tryBiometric,
                    icon: const Icon(Icons.fingerprint, size: 22),
                    label: const Text('Fingerprint / Face ID'),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => setState(() => _showPinPad = true),
                    child: Text('PIN se unlock karein',
                        style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.6))),
                  ),
                ],
                if (_isAuthenticating)
                  const CircularProgressIndicator(color: AppColors.gold),
                if (_showPinPad) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(AppConstants.pinLength, (i) {
                      final filled = i < _pin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? AppColors.gold : Colors.transparent,
                          border: Border.all(
                            color: filled
                                ? AppColors.gold
                                : theme.colorScheme.onSurface
                                    .withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (_error.isNotEmpty)
                    Text(_error,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12)),
                  const SizedBox(height: 40),
                  _buildPinPad(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinPad() {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return Column(
      children: [
        for (int row = 0; row < 4; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int col = 0; col < 3; col++)
                  _pinKey(keys[row * 3 + col]),
              ],
            ),
          ),
      ],
    );
  }

  Widget _pinKey(String key) {
    if (key.isEmpty) return const SizedBox(width: 80, height: 60);
    final isBackspace = key == '⌫';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        width: 70,
        height: 60,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => isBackspace ? _onBackspace() : _onPinDigit(key),
            child: Center(
              child: isBackspace
                  ? Icon(Icons.backspace_outlined,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7))
                  : Text(key,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Manrope',
                          color: Theme.of(context).colorScheme.onSurface)),
            ),
          ),
        ),
      ),
    );
  }
}