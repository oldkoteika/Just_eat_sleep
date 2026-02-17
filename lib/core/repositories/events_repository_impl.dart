import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/supabase_auth_service.dart';
import '../config/supabase_config.dart';
import '../events/events_storage.dart';
import '../events/events_offline_service.dart';
import '../events/pending_events_ops_storage.dart';
import '../supabase/events_realtime_service.dart';
import '../../shared/models/event.dart';
import 'abstract_events_repository.dart';

/// Реализация репозитория событий: локальный кэш (Hive) + синхронизация с Supabase
/// для событий с получателями (приглашения друзьям). Личные тренировки только в Hive.
/// При ошибке сети операции попадают в очередь и отправляются при появлении соединения.
class EventsRepositoryImpl implements AbstractEventsRepository {
  EventsRepositoryImpl();

  bool get _useSupabase =>
      SupabaseConfig.isConfigured && SupabaseAuthService.isSignedIn;

  @override
  Future<List<Event>> getEvents() async {
    if (_useSupabase) {
      await EventsOfflineService.processPendingOps();
      await EventsRealtimeService.fetchAndMergeFromSupabase();
    }
    return EventsStorage.getEvents();
  }

  @override
  Future<void> saveEvents(List<Event> events) =>
      EventsStorage.saveEvents(events);

  @override
  Future<void> addEvent(Event event) async {
    await EventsStorage.addEvent(event);
    if (_useSupabase && event.hasRecipients) {
      try {
        Event.validateEventData(event.toJson());
        await Supabase.instance.client
            .from('events')
            .insert(event.toSupabaseRow());
      } catch (_) {
        await PendingEventsOpsStorage.addAddOp(event.toJson());
      }
    }
  }

  @override
  Future<void> updateEvent(Event event) async {
    await EventsStorage.updateEvent(event);
    if (_useSupabase && event.hasRecipients) {
      try {
        Event.validateEventData(event.toJson());
        final row = event.toSupabaseRow();
        row.remove('id');
        row.remove('created_at');
        await Supabase.instance.client
            .from('events')
            .update(row)
            .eq('id', event.id);
      } catch (_) {
        await PendingEventsOpsStorage.addUpdateOp(event.toJson());
      }
    }
  }

  @override
  Future<void> removeEvent(String eventId) async {
    final event = await EventsStorage.getEventById(eventId);
    await EventsStorage.removeEvent(eventId);
    if (_useSupabase && event != null && event.hasRecipients) {
      try {
        await Supabase.instance.client.from('events').delete().eq('id', eventId);
      } catch (_) {
        await PendingEventsOpsStorage.addRemoveOp(eventId);
      }
    }
  }

  @override
  Future<Event?> getEventById(String eventId) =>
      EventsStorage.getEventById(eventId);
}
