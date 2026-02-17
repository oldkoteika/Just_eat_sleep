import 'dart:io';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../shared/models/event.dart' as app;

/// Результат попытки добавления события в системный календарь.
enum CalendarAddResult {
  /// Событие успешно добавлено (пользователь подтвердил в нативном UI).
  success,
  /// Пользователь отменил добавление в нативном календаре.
  cancelled,
  /// Нет разрешения на доступ к календарю.
  permissionDenied,
  /// Ошибка при добавлении.
  error,
}

/// Сервис интеграции с системным календарём (Android/iOS).
/// Запрос разрешений и добавление события через add_2_calendar.
class SystemCalendarService {
  /// Запрашивает разрешение на доступ к календарю.
  /// Возвращает true, если разрешение выдано или уже было выдано.
  Future<bool> requestCalendarPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }
    final status = await Permission.calendar.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      return false;
    }
    final result = await Permission.calendar.request();
    return result.isGranted;
  }

  /// Проверяет, есть ли разрешение на календарь (без запроса).
  Future<bool> hasCalendarPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    final status = await Permission.calendar.status;
    return status.isGranted;
  }

  /// Добавляет событие тренировки в системный календарь.
  /// Напоминание: за 1 час до события по умолчанию или по [event.reminderTime].
  /// Возвращает [CalendarAddResult].
  Future<CalendarAddResult> addWorkoutToCalendar(app.Event event) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return CalendarAddResult.error;
    }

    final hasPermission = await requestCalendarPermission();
    if (!hasPermission) {
      return CalendarAddResult.permissionDenied;
    }

    final reminderMinutes = event.reminderTime > 0 ? event.reminderTime : 60;
    final startDate = event.dateLocal;
    final endDate = startDate.add(Duration(minutes: event.duration));

    final calEvent = Event(
      title: app.Event.getWorkoutNameDisplay(event.workoutName),
      description: event.description ?? '',
      location: event.location,
      startDate: startDate,
      endDate: endDate,
      iosParams: IOSParams(
        reminder: Duration(minutes: reminderMinutes),
      ),
      androidParams: const AndroidParams(),
    );

    try {
      final added = await Add2Calendar.addEvent2Cal(calEvent);
      return added ? CalendarAddResult.success : CalendarAddResult.cancelled;
    } catch (_) {
      return CalendarAddResult.error;
    }
  }
}
