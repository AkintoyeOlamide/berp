import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/biometric_lock.dart';

/// Locks the signed-in experience until fingerprint / Face ID succeeds.
class BiometricGate extends StatefulWidget {
  const BiometricGate({super.key, required this.child});

  final Widget child;

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate>
    with WidgetsBindingObserver {
  bool _ready = false;
  bool _locked = false;
  bool _checking = false;
  String _label = 'Biometrics';
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final paused = _pausedAt;
      _pausedAt = null;
      if (paused == null) return;
      if (DateTime.now().difference(paused) >= const Duration(seconds: 8)) {
        unawaited(_maybeLock(prompt: true));
      }
    }
  }

  Future<void> _bootstrap() async {
    final enabled = await BiometricLock.isEnabled();
    final available = enabled && await BiometricLock.isAvailable();
    final label = await BiometricLock.label();
    if (!mounted) return;
    setState(() {
      _label = label;
      _locked = available;
      _ready = true;
    });
    if (available) await _unlock();
  }

  Future<void> _maybeLock({required bool prompt}) async {
    final enabled = await BiometricLock.isEnabled();
    final available = enabled && await BiometricLock.isAvailable();
    if (!mounted) return;
    if (!available) {
      setState(() => _locked = false);
      return;
    }
    setState(() => _locked = true);
    if (prompt) await _unlock();
  }

  Future<void> _unlock() async {
    if (_checking) return;
    setState(() => _checking = true);
    HapticFeedback.selectionClick();
    final ok = await BiometricLock.authenticate(
      reason: 'Unlock BERP with $_label',
    );
    if (!mounted) return;
    setState(() {
      _checking = false;
      _locked = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (!_locked) return widget.child;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2C2C2E)),
                  ),
                  child: Icon(
                    _label.toLowerCase().contains('face')
                        ? Icons.face_retouching_natural_rounded
                        : Icons.fingerprint_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Unlock BERP',
                  style: TextStyle(
                    fontFamily: 'Panchang',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use $_label to continue where you left off.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _checking ? null : _unlock,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white54,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _checking ? 'Waiting…' : 'Unlock with $_label',
                      style: const TextStyle(
                        fontFamily: 'Panchang',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
