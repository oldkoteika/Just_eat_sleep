import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/auth/auth_storage.dart';
import '../../core/auth/user_storage.dart';
import '../../core/auth/supabase_auth_service.dart';
import '../../main.dart';

/// Экран предложения включить вход по биометрии после настройки PIN.
class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({
    super.key,
  });

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _checking = false;
  bool _available = false;
  bool _checkedOnce = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    setState(() {
      _checking = true;
    });
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      final biometrics = await _auth.getAvailableBiometrics();
      // На Android/iOS: биометрия доступна, если устройство поддерживает и есть хотя бы один зарегистрированный метод
      final available = canCheck && supported && biometrics.isNotEmpty;
      if (mounted) {
        setState(() {
          _available = available;
          _checkedOnce = true;
        });
      }
    } catch (_) {
      // Web, симулятор без биометрии и др. платформы
      if (mounted) {
        setState(() {
          _available = false;
          _checkedOnce = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  Future<void> _enableBiometric() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Подтвердите биометрию для быстрого входа в приложение',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!mounted) return;
      if (authenticated) {
        await AuthStorage.setBiometricEnabled(true);
        await _goToMain();
      }
    } catch (e) {
      debugPrint('BiometricSetup: ошибка аутентификации $e');
      if (mounted) {
        // Пользователь отменил или ошибка — остаёмся на экране
        setState(() {});
      }
    }
  }

  Future<void> _skip() async {
    await _goToMain();
  }

  /// Переход в главный экран и регистрация в Supabase (если ещё не зарегистрирован).
  Future<void> _goToMain() async {
    final user = await UserStorage.getCurrentUser();
    if (user != null) {
      try {
        await SupabaseAuthService.ensureSession(user.id, user.displayName);
      } catch (e, st) {
        debugPrint('SupabaseAuth ОШИБКА при регистрации/входе: $e');
        debugPrint('$st');
      }
    } else {
      debugPrint('SupabaseAuth: UserStorage.getCurrentUser() == null, пропуск ensureSession.');
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (_) => const MainScreen(),
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
                  const Color(0xFF020617),
                  const Color(0xFF0F172A),
                ]
              : [
                  const Color(0xFFE0F2FE),
                  const Color(0xFFF1F5F9),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    CupertinoIcons.lock_rotation_open,
                    size: 48,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Вход по биометрии',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Используйте Face ID или Touch ID (или аналог на Android), '
                    'чтобы входить быстрее и безопаснее.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_checking)
                    const CupertinoActivityIndicator()
                  else if (!_available && _checkedOnce)
                    Text(
                      'Биометрия недоступна на этом устройстве.\nВы сможете использовать вход по PIN-коду.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  const Spacer(),
                  if (_available) ...[
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        borderRadius: BorderRadius.circular(12),
                        onPressed: _enableBiometric,
                        child: const Text(
                          'Включить биометрию',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _skip,
                      child: const Text(
                        'Позже',
                        style: TextStyle(fontSize: 17),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

