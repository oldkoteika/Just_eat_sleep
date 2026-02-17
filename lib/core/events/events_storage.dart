import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/models/event.dart';

const _boxName = 'events_box';
const _keyList = 'events_list';
const _keyDismissedIds = 'dismissed_event_ids';

/// Локальное хранилище списка событий (Hive).
/// Схема: один ключ _keyList — список событий в виде JSON-массива.
class EventsStorage {
  EventsStorage._();

  static Future<Box<dynamic>> _openBox() => Hive.openBox(_boxName);

  /// Загрузить все события.
  static Future<List<Event>> getEvents() async {
    final box = await _openBox();
    final data = box.get(_keyList);
    if (data is! List) return [];
    final list = <Event>[];
    for (final item in data) {
      if (item is Map) {
        try {
          list.add(Event.fromJson(Map<String, dynamic>.from(item)));
        } on FormatException {
          // пропускаем битые записи
        }
      }
    }
    return list;
  }

  /// Сохранить список событий (полная перезапись).
  static Future<void> saveEvents(List<Event> events) async {
    final box = await _openBox();
    final encoded = events.map((e) => e.toJson()).toList();
    await box.put(_keyList, encoded);
  }

  /// Добавить событие. Если событие с таким id уже есть — не дублируем.
  static Future<void> addEvent(Event event) async {
    final list = await getEvents();
    if (list.any((e) => e.id == event.id)) return;
    list.add(event);
    await saveEvents(list);
  }

  /// Обновить событие по id. Если не найдено — ничего не делаем.
  static Future<void> updateEvent(Event event) async {
    final list = await getEvents();
    final index = list.indexWhere((e) => e.id == event.id);
    if (index < 0) return;
    list[index] = event;
    await saveEvents(list);
  }

  /// Удалить событие по id.
  static Future<void> removeEvent(String eventId) async {
    final list = await getEvents();
    list.removeWhere((e) => e.id == eventId);
    await saveEvents(list);
  }

  /// Получить событие по id.
  static Future<Event?> getEventById(String eventId) async {
    final list = await getEvents();
    try {
      return list.firstWhere((e) => e.id == eventId);
    } on StateError {
      return null;
    }
  }

  /// ID событий, которые приглашённый пользователь удалил из своего списка (локально скрыты).
  static Future<Set<String>> getDismissedEventIds() async {
    final box = await _openBox();
    final data = box.get(_keyDismissedIds);
    if (data is! List) return {};
    return data.map((e) => e.toString()).toSet();
  }

  /// Скрыть событие из списка для текущего пользователя (при удалении приглашённым).
  static Future<void> addDismissedEventId(String eventId) async {
    final box = await _openBox();
    final set = await getDismissedEventIds();
    set.add(eventId);
    await box.put(_keyDismissedIds, set.toList());
  }
}
