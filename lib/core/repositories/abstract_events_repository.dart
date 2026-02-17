import '../../shared/models/event.dart';

/// Абстракция репозитория событий.
/// Позволяет подменить реализацию на P2P/облако в будущем.
abstract class AbstractEventsRepository {
  Future<List<Event>> getEvents();
  Future<void> saveEvents(List<Event> events);
  Future<void> addEvent(Event event);
  Future<void> updateEvent(Event event);
  Future<void> removeEvent(String eventId);
  Future<Event?> getEventById(String eventId);
}
