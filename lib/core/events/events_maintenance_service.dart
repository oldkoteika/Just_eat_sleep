import 'package:uuid/uuid.dart';

import '../../shared/models/event.dart';
import 'events_storage.dart';
import '../repositories/abstract_events_repository.dart';

/// Обработка завершённых тренировок: проставить статус "выполнено" и при периодичности — запланировать следующую.
/// Вызывается при загрузке событий (в фоне/при открытии приложения), без рекурсии через репозиторий.
class EventsMaintenanceService {
  EventsMaintenanceService._();

  /// Читает события из хранилища (напрямую), обрабатывает завершённые и сохраняет через репозиторий.
  /// Обрабатываются только события, где [currentUserId] совпадает с отправителем (создатель тренировки).
  /// Не вызывает [repo.getEvents()], чтобы избежать рекурсии при вызове из провайдера.
  static Future<void> processEndedWorkouts(
    AbstractEventsRepository repo, [
    String? currentUserId,
  ]) async {
    if (currentUserId == null || currentUserId.isEmpty) return;

    final events = await EventsStorage.getEvents();
    final now = DateTime.now();

    for (final event in events) {
      if (event.sender != currentUserId) continue;
      if (event.type != EventType.workoutInvitation) continue;
      if (event.status == EventStatus.declined) continue;
      if (event.status == EventStatus.completed) continue;

      final localDate = event.dateLocal;
      final endTime = localDate.add(Duration(minutes: event.duration));
      if (endTime.isAfter(now)) continue;

      // Тренировка закончилась — помечаем выполненной
      final completed = event.copyWith(status: EventStatus.completed);
      await repo.updateEvent(completed);

      final repeat = event.repeat;
      final shouldScheduleNext = repeat != null &&
          repeat != 'never' &&
          (repeat == 'weekly' || repeat == 'biweekly' || repeat == 'monthly');

      if (!shouldScheduleNext) continue;

      final nextDate = _nextOccurrence(localDate, repeat);
      final nextResponses = <String, EventStatus>{};
      for (final id in event.recipients) {
        nextResponses[id] = EventStatus.pending;
      }

      final nextEvent = Event(
        id: const Uuid().v4(),
        type: EventType.workoutInvitation,
        workoutName: event.workoutName,
        date: nextDate,
        location: event.location,
        description: event.description,
        duration: event.duration,
        sender: event.sender,
        senderName: event.senderName,
        recipient: event.recipient,
        recipients: List.from(event.recipients),
        status: EventStatus.pending,
        recipientResponses: nextResponses,
        recipientDeclineReasons: {},
        reminderTime: event.reminderTime,
        repeat: repeat,
        addedToCalendar: false,
        createdAt: DateTime.now(),
      );

      await repo.addEvent(nextEvent);
    }
  }

  static DateTime _nextOccurrence(DateTime from, String repeat) {
    switch (repeat) {
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'biweekly':
        return from.add(const Duration(days: 14));
      case 'monthly':
        return DateTime(from.year, from.month + 1, from.day, from.hour, from.minute);
      default:
        return from.add(const Duration(days: 7));
    }
  }
}
