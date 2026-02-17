import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/auth/auth_storage.dart';
import '../../main.dart';

/// Экран входа в приложение через PIN и (опционально) биометрию.
/// Визуально напоминает экран блокировки iOS: прозрачный размытный фон,
/// круглые кнопки с цифрами.
class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication _auth = LocalAuthentication();

  String _currentPin = '';
  bool _error = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _checkingBiometric = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    try {
      final enabled = await AuthStorage.isBiometricEnabled();
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      final biometrics = await _auth.getAvailableBiometrics();
      final available = canCheck && supported && biometrics.isNotEmpty;
      if (mounted) {
        setState(() {
          _biometricEnabled = enabled;
          _biometricAvailable = available;
          _checkingBiometric = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _biometricAvailable = false;
          _biometricEnabled = false;
          _checkingBiometric = false;
        });
      }
    }
  }

  void _onDigitTap(String digit) {
    if (_currentPin.length >= 6) return;
    setState(() {
      _error = false;
      _currentPin += digit;
    });
    if (_currentPin.length == 6) {
      _verify();
    }
  }

  void _onBackspace() {
    if (_currentPin.isEmpty) return;
    setState(() {
      _error = false;
      _currentPin = _currentPin.substring(0, _currentPin.length - 1);
    });
  }

  Future<void> _verify() async {
    final ok = await AuthStorage.verifyPin(_currentPin);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (_) => const MainScreen(),
        ),
      );
    } else {
      setState(() {
        _error = true;
        _currentPin = '';
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Войдите в приложение с помощью биометрии',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!mounted) return;
      if (authenticated) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (_) => const MainScreen(),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final background = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF020617),
                  const Color(0xFF0F172A),
                ]
              : [
                  const Color(0xFFE0F2FE),
                  const Color(0xFFF9FAFB),
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          background,
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.20),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Введите код доступа',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Для входа в Жми Ешь Спи',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 48),
                _buildPinDots(isDark),
                if (_error) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Неверный код. Попробуйте ещё раз.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.redAccent.shade200,
                    ),
                  ),
                ],
                const SizedBox(height: 60),
                if (!_checkingBiometric &&
                    _biometricEnabled &&
                    _biometricAvailable) ...[
                  CupertinoButton(
                    padding: const EdgeInsets.only(bottom: 8),
                    onPressed: _authenticateWithBiometrics,
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.personalhotspot,
                          color: isDark ? Colors.white : Colors.black87,
                          size: 34,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Войти по биометрии',
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildKeyboard(isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinDots(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final filled = index < _currentPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white24 : Colors.black12),
          ),
        );
      }),
    );
  }

  Widget _buildKeyboard(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;

    Widget buildButton(String label, {VoidCallback? onTap, IconData? icon}) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, color: textColor, size: 26)
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildButton('1', onTap: () => _onDigitTap('1')),
            buildButton('2', onTap: () => _onDigitTap('2')),
            buildButton('3', onTap: () => _onDigitTap('3')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildButton('4', onTap: () => _onDigitTap('4')),
            buildButton('5', onTap: () => _onDigitTap('5')),
            buildButton('6', onTap: () => _onDigitTap('6')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildButton('7', onTap: () => _onDigitTap('7')),
            buildButton('8', onTap: () => _onDigitTap('8')),
            buildButton('9', onTap: () => _onDigitTap('9')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80, height: 80),
            buildButton('0', onTap: () => _onDigitTap('0')),
            buildButton(
              '',
              onTap: _onBackspace,
              icon: CupertinoIcons.delete_left,
            ),
          ],
        ),
      ],
    );
  }
}

