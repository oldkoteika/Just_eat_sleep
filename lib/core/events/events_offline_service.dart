import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/supabase_auth_service.dart';
import '../config/supabase_config.dart';
import '../supabase/events_realtime_service.dart';
import 'events_storage.dart';
import 'pending_events_ops_storage.dart';
import '../../shared/models/event.dart';

/// Обработка офлайна: очередь неотправленных операций и разрешение конфликтов.
class EventsOfflineService {
  EventsOfflineService._();

  static bool get _canUseSupabase =>
      SupabaseConfig.isConfigured && SupabaseAuthService.isSignedIn;

  /// Обрабатывает очередь: отправляет каждую операцию в Supabase, удаляет при успехе.
  /// Для update: если на сервере новее — пропускаем (server wins).
  static Future<void> processPendingOps() async {
    if (!_canUseSupabase) return;

    final ops = await PendingEventsOpsStorage.getOps();
    final client = Supabase.instance.client;
    bool changed = false;

    for (var i = 0; i < ops.length; i++) {
      final op = ops[i];
      final typeStr = op['type'] as String?;
      final payload = op['payload'];
      final createdAtStr = op['created_at'] as String?;
      final opTime = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;

      try {
        if (typeStr == 'add' && payload is Map) {
          await client.from('events').insert(Event.fromJson(Map<String, dynamic>.from(payload)).toSupabaseRow());
          await PendingEventsOpsStorage.removeOpAt(i);
          changed = true;
          i--;
        } else if (typeStr == 'update' && payload is Map) {
          final event = Event.fromJson(Map<String, dynamic>.from(payload));
          if (event.hasRecipients) {
            final row = await client.from('events').select('updated_at').eq('id', event.id).maybeSingle();
            if (row != null && row['updated_at'] != null) {
              final serverUpdated = row['updated_at'] is DateTime
                  ? row['updated_at'] as DateTime
                  : DateTime.tryParse(row['updated_at'].toString());
              if (serverUpdated != null && opTime != null && serverUpdated.isAfter(opTime)) {
                await PendingEventsOpsStorage.removeOpAt(i);
                changed = true;
                i--;
                continue;
              }
            }
            final updateRow = event.toSupabaseRow();
            updateRow.remove('id');
            updateRow.remove('created_at');
            await client.from('events').update(updateRow).eq('id', event.id);
            await PendingEventsOpsStorage.removeOpAt(i);
            changed = true;
            i--;
          }
        } else if (typeStr == 'remove' && payload is String) {
          await client.from('events').delete().eq('id', payload);
          await PendingEventsOpsStorage.removeOpAt(i);
          changed = true;
          i--;
        }
      } catch (_) {
        // Ошибка сети — оставляем в очереди
      }
    }

    if (changed) {
      await EventsRealtimeService.fetchAndMergeFromSupabase();
    }
  }
}
