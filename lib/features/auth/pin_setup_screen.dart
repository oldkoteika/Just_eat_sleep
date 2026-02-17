import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/auth/auth_storage.dart';
import 'biometric_setup_screen.dart';
import '../../main.dart';

/// Экран настройки 6-значного PIN кода с подтверждением.
/// Визуально и по UX напоминает экран блокировки iOS.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({
    super.key,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _firstEntry = '';
  String _confirmEntry = '';
  bool _isConfirmStep = false;
  bool _error = false;

  void _onDigitTap(String digit) {
    setState(() {
      _error = false;
      if (!_isConfirmStep) {
        if (_firstEntry.length < 6) {
          _firstEntry += digit;
          if (_firstEntry.length == 6) {
            _isConfirmStep = true;
          }
        }
      } else {
        if (_confirmEntry.length < 6) {
          _confirmEntry += digit;
          if (_confirmEntry.length == 6) {
            _validate();
          }
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _error = false;
      if (_isConfirmStep) {
        if (_confirmEntry.isNotEmpty) {
          _confirmEntry = _confirmEntry.substring(0, _confirmEntry.length - 1);
        }
      } else {
        if (_firstEntry.isNotEmpty) {
          _firstEntry = _firstEntry.substring(0, _firstEntry.length - 1);
        }
      }
    });
  }

  Future<void> _validate() async {
    if (_firstEntry != _confirmEntry) {
      setState(() {
        _error = true;
        _confirmEntry = '';
      });
      return;
    }

    await AuthStorage.savePin(_firstEntry);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (_) => const BiometricSetupScreen(),
      ),
    );
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
                  const Color(0xFF0F172A),
                  const Color(0xFF020617),
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
                  _isConfirmStep ? 'Подтвердите код' : 'Создайте код доступа',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '6 цифр для входа в приложение',
                  style: TextStyle(
                    fontSize: 15,
                    color: (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
                const SizedBox(height: 48),
                _buildPinDots(isDark),
                if (_error) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Коды не совпадают. Попробуйте ещё раз.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.redAccent.shade200,
                    ),
                  ),
                ],
                const SizedBox(height: 60),
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
    final length = _isConfirmStep ? _confirmEntry.length : _firstEntry.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final filled = index < length;
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

