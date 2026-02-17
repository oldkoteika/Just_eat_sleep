import 'package:shared_preferences/shared_preferences.dart';

/// Простое хранилище для флагов онбординга и PIN-кода.
class AuthStorage {
  static const _keyProfileCompleted = 'profile_completed';
  static const _keyPinHash = 'pin_hash';
  static const _keyBiometricEnabled = 'biometric_enabled';

  AuthStorage._();

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<bool> isProfileCompleted() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyProfileCompleted) ?? false;
  }

  static Future<void> setProfileCompleted() async {
    final prefs = await _prefs();
    await prefs.setBool(_keyProfileCompleted, true);
  }

  static Future<bool> hasPin() async {
    final prefs = await _prefs();
    return (prefs.getString(_keyPinHash) ?? '').isNotEmpty;
  }

  static Future<void> savePin(String pin) async {
    // Для MVP сохраняем как есть; позже можно заменить на хэш.
    final prefs = await _prefs();
    await prefs.setString(_keyPinHash, pin);
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await _prefs();
    final stored = prefs.getString(_keyPinHash);
    if (stored == null) return false;
    return stored == pin;
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyBiometricEnabled, enabled);
  }
}

