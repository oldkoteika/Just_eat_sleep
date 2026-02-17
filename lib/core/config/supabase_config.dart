import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Конфигурация Supabase: SUPABASE_URL и SUPABASE_ANON_KEY.
///
/// Источники (приоритет):
/// 1. [--dart-define](https://docs.flutter.dev/deployment/flutter-for-devs#dart-define) при сборке —
///    тогда .env не нужен в бандле (удобно для CI: секреты в переменных пайплайна).
/// 2. Файл .env (ассет) — для локальной разработки.
///
/// На Web [String.fromEnvironment] допустим только в const-контексте, поэтому
/// dart-define читается через константы.
///
/// Пример билда с dart-define:
/// ```bash
/// flutter build apk --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
/// ```
class SupabaseConfig {
  SupabaseConfig._();

  static const String _urlFromDefine =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String _anonKeyFromDefine =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static String get supabaseUrl =>
      _urlFromDefine.isNotEmpty ? _urlFromDefine : _fromDotenv('SUPABASE_URL');

  static String get supabaseAnonKey =>
      _anonKeyFromDefine.isNotEmpty ? _anonKeyFromDefine : _fromDotenv('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Чтение из dotenv без падения, если .env не загружен (например 500 на Web).
  static String _fromDotenv(String key) {
    try {
      return dotenv.env[key] ?? '';
    } on Object {
      return '';
    }
  }
}
