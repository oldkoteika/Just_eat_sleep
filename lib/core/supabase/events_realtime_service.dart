import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/supabase_auth_service.dart';
import '../config/supabase_config.dart';
import '../events/events_storage.dart';
import '../../shared/models/event.dart';

/// Подписка на таблицу [events] в Supabase Realtime.
/// При любом изменении (INSERT/UPDATE/DELETE) загружает актуальный список из Supabase
/// и сливает его с локальным хранилищем; затем вызывается [onEventsChanged].
/// RLS на сервере отдаёт только строки, где текущий пользователь — отправитель или получатель.
class EventsRealtimeService {
  EventsRealtimeService._();

  static RealtimeChannel? _channel;
  static void Function()? _onEventsChanged;

  /// Запускает подписку, если Supabase настроен и пользователь авторизован.
  /// [onEventsChanged] вызывается после каждого применения изменений к локальному хранилищу.
  static void subscribe(void Function() onEventsChanged) {
    if (!SupabaseConfig.isConfigured || !SupabaseAuthService.isSignedIn) {
      return;
    }
    _onEventsChanged = onEventsChanged;
    if (_channel != null) return;

    final client = Supabase.instance.client;
    _channel = client
        .channel('fit_app_events')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          callback: (_) => _onRealtimeChange(),
        )
        .subscribe((status, [err]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            _onRealtimeChange();
          }
        });
  }

  static void unsubscribe() {
    if (_channel == null) return;
    Supabase.instance.client.removeChannel(_channel!);
    _channel = null;
    _onEventsChanged = null;
  }

  static Future<void> _onRealtimeChange() async {
    try {
      await fetchAndMergeFromSupabase();
      _onEventsChanged?.call();
    } catch (_) {
      // Сеть или Supabase ошибка — не ломаем приложение
    }
  }

  /// Загружает события из Supabase (с учётом RLS) и сливает с локальным списком:
  /// локальные события, которых нет в Supabase, сохраняются; остальные — из Supabase.
  /// Вызывается при открытии приложения (репозиторий) и при Realtime-изменениях.
  static Future<void> fetchAndMergeFromSupabase() async {
    if (!SupabaseConfig.isConfigured || !SupabaseAuthService.isSignedIn) return;

    final client = Supabase.instance.client;
    final response = await client.from('events').select();
    final List<dynamic> rows = response as List<dynamic>? ?? [];
    final List<Event> fromSupabase = [];
    for (final row in rows) {
      if (row is Map<String, dynamic>) {
        try {
          fromSupabase.add(Event.fromSupabaseRow(row));
        } on Object {
          // пропускаем битые строки
        }
      }
    }

    final local = await EventsStorage.getEvents();
    final supabaseById = {for (final e in fromSupabase) e.id: e};
    final merged = <Event>[];
    for (final localEvent in local) {
      final serverEvent = supabaseById[localEvent.id];
      if (serverEvent == null) {
        merged.add(localEvent);
      } else {
        merged.add(serverEvent.effectiveUpdatedAt.isAfter(localEvent.effectiveUpdatedAt)
            ? serverEvent
            : localEvent);
        supabaseById.remove(localEvent.id);
      }
    }
    for (final e in supabaseById.values) {
      merged.add(e);
    }
    await EventsStorage.saveEvents(merged);
  }
}
