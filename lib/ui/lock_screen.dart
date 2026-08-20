/// Just Dance — lock screen: logo + gold hairline, unlocks with the device
/// screen lock (face / fingerprint / PIN). No custom PIN anywhere.
library;

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../services/lock_service.dart';
import 'widgets/common.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  /// Test hooks — when provided, used instead of the device lock service.
  final Future<bool> Function()? unlockOverride;
  final Future<bool> Function()? availableOverride;
  const LockScreen(
      {super.key,
      required this.onUnlocked,
      this.unlockOverride,
      this.availableOverride});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _busy = false;
  bool _available = true;

  // No auto-prompt on mount: the lock screen appears silently after a
  // background, and biometrics are asked only when the owner taps Unlock.

  Future<bool> _unlock() => widget.unlockOverride?.call() ??
      LockService.instance.unlock();

  Future<bool> _availableCheck() => widget.availableOverride?.call() ??
      LockService.instance.available();

  Future<void> _prompt() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await _unlock();
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      final available = await _availableCheck();
      setState(() {
        _busy = false;
        _available = available;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 96),
              const SizedBox(height: 18),
              Text(kAppName.toUpperCase(),
                  style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                      fontSize: 14)),
              const SizedBox(height: 12),
              Container(width: 48, height: 1, color: c.gold),
              const SizedBox(height: 40),
              Icon(Icons.lock_outline, color: c.textMuted, size: 30),
              const SizedBox(height: 12),
              Text(
                _available ? 'Locked' : 'No device lock set up',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                _available
                    ? 'Use your phone lock (face, fingerprint or PIN) to open.'
                    : 'Set a screen lock in your phone settings to use App Lock.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 28),
              if (_available)
                TextButton.icon(
                  onPressed: _busy ? null : _prompt,
                  icon: Icon(Icons.fingerprint, color: c.gold),
                  label: Text('Unlock',
                      style: TextStyle(
                          color: c.gold, fontWeight: FontWeight.w700)),
                )
              else
                TextButton.icon(
                  onPressed: widget.onUnlocked,
                  icon: Icon(Icons.lock_open_outlined,
                      color: c.textMuted, size: 16),
                  label: Text('Continue without lock',
                      style: TextStyle(color: c.textMuted)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
