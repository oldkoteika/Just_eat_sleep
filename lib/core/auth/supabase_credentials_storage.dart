import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Хранение логина и пароля Supabase (внутренние user-<uuid>@internal.fitapp.local)
/// в зашифрованном хранилище. Не для отображения пользователю.
class SupabaseCredentialsStorage {
  SupabaseCredentialsStorage._();

  static const _keyEmail = 'supabase_email';
  static const _keyPassword = 'supabase_password';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> save(String email, String password) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
  }

  static Future<String?> getEmail() => _storage.read(key: _keyEmail);
  static Future<String?> getPassword() => _storage.read(key: _keyPassword);

  static Future<bool> hasCredentials() async {
    final email = await getEmail();
    final password = await getPassword();
    return (email ?? '').isNotEmpty && (password ?? '').isNotEmpty;
  }

  static Future<void> clear() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
  }
}
