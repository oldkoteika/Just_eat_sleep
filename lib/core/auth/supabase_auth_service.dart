import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'supabase_credentials_storage.dart';

/// Обеспечивает сессию Supabase: signUp при первом запуске, signIn при следующих.
/// Используется для доступа к БД и Realtime с учётом RLS.
class SupabaseAuthService {
  SupabaseAuthService._();

  static const _internalEmailDomain = '@internal.fitapp.local';
  static const _passwordLength = 32;

  static bool get isSignedIn {
    if (!SupabaseConfig.isConfigured) return false;
    return Supabase.instance.client.auth.currentSession != null;
  }

  /// Обеспечивает сессию: при наличии сохранённых учётных данных — signIn,
  /// иначе signUp с email user-<appUuid>@internal.fitapp.local и случайным паролем.
  static Future<void> ensureSession(String appUuid, String displayName) async {
    if (!SupabaseConfig.isConfigured) return;

    final client = Supabase.instance.client;
    if (client.auth.currentSession != null) return;

    final email = await SupabaseCredentialsStorage.getEmail();
    final password = await SupabaseCredentialsStorage.getPassword();

    if (email != null && password != null && email.isNotEmpty && password.isNotEmpty) {
      await client.auth.signInWithPassword(email: email, password: password);
      return;
    }

    final internalEmail = 'user-$appUuid$_internalEmailDomain';
    final newPassword = _randomPassword();
    await client.auth.signUp(
      email: internalEmail,
      password: newPassword,
      data: {
        'app_uuid': appUuid,
        'display_name': displayName,
      },
    );
    await SupabaseCredentialsStorage.save(internalEmail, newPassword);
  }

  static String _randomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final r = Random.secure();
    return List.generate(_passwordLength, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
