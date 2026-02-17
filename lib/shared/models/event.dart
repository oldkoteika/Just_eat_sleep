/// Тип события.
enum EventType {
  workoutInvitation,
  eventUpdate,
  eventCancellation,
}

/// Наименование тренировки (по плану).
enum WorkoutName {
  legs,   // Ноги
  shoulders,
  chest,  // Грудь
  back,   // Спина
  arms,   // Руки
  cardio, // Кардио
  other,  // Другое
}

/// Статус события.
enum EventStatus {
  pending,
  accepted,
  declined,
  completed,
}

/// Модель события (приглашение на тренировку, обновление, отмена).
class Event {
  final String id;
  final EventType type;
  final WorkoutName workoutName;
  final DateTime date;
  final String? location;
  final String? description;
  final int duration; // минуты
  final String sender;
  final String senderName;
  final String? recipient;
  final List<String> recipients;
  final EventStatus status;
  /// Ответы приглашённых: id получателя -> pending / accepted / declined.
  final Map<String, EventStatus> recipientResponses;
  /// Причины отклонения: id получателя -> текст (например "Не могу прийти", "Перенести на 16.02 в 18:00").
  final Map<String, String> recipientDeclineReasons;
  final int reminderTime; // минуты до события
  /// Периодичность повторения: 'never' | 'weekly' | 'biweekly' | 'monthly'. null = никогда (обратная совместимость).
  final String? repeat;
  final bool addedToCalendar;
  final DateTime createdAt;
  /// Время последнего обновления на сервере (для разрешения конфликтов).
  final DateTime? updatedAt;

  const Event({
    required this.id,
    required this.type,
    required this.workoutName,
    required this.date,
    this.location,
    this.description,
    required this.duration,
    required this.sender,
    required this.senderName,
    this.recipient,
    this.recipients = const [],
    this.status = EventStatus.pending,
    this.recipientResponses = const {},
    this.recipientDeclineReasons = const {},
    this.reminderTime = 0,
    this.repeat,
    this.addedToCalendar = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Время для сравнения при слиянии: updated_at или created_at.
  DateTime get effectiveUpdatedAt => updatedAt ?? createdAt;

  /// Есть ли приглашённые друзья (ожидаем их ответы).
  bool get hasRecipients => recipients.isNotEmpty;

  /// Дата/время события в таймзоне устройства (для отображения и сравнения по дню).
  /// На сервере хранится UTC; при отображении используйте [dateLocal].
  DateTime get dateLocal => date.isUtc ? date.toLocal() : date;

  /// Имя организатора для отображения. Если [senderName] пустое (например, пользователь удалён из друзей),
  /// возвращает нейтральную подпись, чтобы не показывать пустое место или технический ID.
  String get senderDisplayName =>
      senderName.trim().isNotEmpty ? senderName : 'Участник';

  /// Человекочитаемое название типа тренировки.
  static String getWorkoutNameDisplay(WorkoutName name) {
    switch (name) {
      case WorkoutName.legs:
        return 'Ноги';
      case WorkoutName.shoulders:
        return 'Плечи';
      case WorkoutName.chest:
        return 'Грудь';
      case WorkoutName.back:
        return 'Спина';
      case WorkoutName.arms:
        return 'Руки';
      case WorkoutName.cardio:
        return 'Кардио';
      case WorkoutName.other:
        return 'Другое';
    }
  }

  Map<String, dynamic> toJson() {
    final responses = <String, String>{};
    for (final e in recipientResponses.entries) {
      responses[e.key] = e.value.name;
    }
    return {
      'id': id,
      'type': type.name,
      'workout_name': workoutName.name,
      'date': date.toIso8601String(),
      'location': location,
      'description': description,
      'duration': duration,
      'sender': sender,
      'sender_name': senderName,
      'recipient': recipient,
      'recipients': List<String>.from(recipients),
      'status': status.name,
      'recipient_responses': responses,
      'recipient_decline_reasons': Map<String, String>.from(recipientDeclineReasons),
      'reminder_time': reminderTime,
      if (repeat != null) 'repeat': repeat,
      'added_to_calendar': addedToCalendar,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Тип события в формате Supabase (snake_case).
  static String _eventTypeToSupabase(EventType t) {
    switch (t) {
      case EventType.workoutInvitation:
        return 'workout_invitation';
      case EventType.eventUpdate:
        return 'event_update';
      case EventType.eventCancellation:
        return 'event_cancellation';
    }
  }

  /// Тип события из Supabase (snake_case) в имя enum для fromJson.
  static String _eventTypeFromSupabase(String? s) {
    switch (s) {
      case 'workout_invitation':
        return 'workoutInvitation';
      case 'event_update':
        return 'eventUpdate';
      case 'event_cancellation':
        return 'eventCancellation';
      default:
        return 'workoutInvitation';
    }
  }

  /// Строка для INSERT/UPDATE в таблицу events Supabase (sender_id, snake_case type и т.д.).
  Map<String, dynamic> toSupabaseRow() {
    final responses = <String, String>{};
    for (final e in recipientResponses.entries) {
      responses[e.key] = e.value.name;
    }
    return {
      'id': id,
      'type': _eventTypeToSupabase(type),
      'workout_name': workoutName.name,
      'date': date.toUtc().toIso8601String(),
      'location': location,
      'description': description,
      'duration': duration,
      'sender_id': sender,
      'sender_name': senderName,
      'recipients': List<String>.from(recipients),
      'recipient_responses': responses,
      'recipient_decline_reasons': Map<String, String>.from(recipientDeclineReasons),
      'status': status.name,
      'reminder_time': reminderTime,
      if (repeat != null) 'repeat': repeat,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  /// Строка из Supabase (колонки: sender_id, workout_name, recipient_responses и т.д.).
  static Event fromSupabaseRow(Map<String, dynamic> row) {
    final date = row['date'];
    final createdAt = row['created_at'];
    return Event.fromJson({
      'id': row['id']?.toString() ?? '',
      'type': _eventTypeFromSupabase(row['type'] as String?),
      'workout_name': row['workout_name'],
      'date': date is DateTime ? date.toIso8601String() : date?.toString() ?? '',
      'location': row['location'],
      'description': row['description'],
      'duration': row['duration'],
      'sender': row['sender_id'] ?? '',
      'sender_name': row['sender_name'] ?? '',
      'recipient': null,
      'recipients': row['recipients'] ?? [],
      'status': row['status'] ?? 'pending',
      'recipient_responses': row['recipient_responses'] ?? {},
      'recipient_decline_reasons': row['recipient_decline_reasons'] ?? {},
      'reminder_time': row['reminder_time'] ?? 0,
      'repeat': row['repeat'],
      'added_to_calendar': false,
      'created_at': createdAt is DateTime ? createdAt.toIso8601String() : createdAt?.toString() ?? DateTime.now().toIso8601String(),
      'updated_at': _parseUpdatedAt(row['updated_at']),
    });
  }

  static String? _parseUpdatedAt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v.toIso8601String();
    return v.toString();
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    Event.validateEventData(json);

    final typeStr = json['type'] as String?;
    final type = EventType.values.asNameMap()[typeStr] ?? EventType.workoutInvitation;

    final workoutStr = json['workout_name'] as String?;
    final workoutName = WorkoutName.values.asNameMap()[workoutStr] ?? WorkoutName.other;

    final statusStr = json['status'] as String?;
    final status = EventStatus.values.asNameMap()[statusStr] ?? EventStatus.pending;

    final recipientsRaw = json['recipients'];
    final recipients = recipientsRaw is List
        ? recipientsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final responsesRaw = json['recipient_responses'];
    final recipientResponses = <String, EventStatus>{};
    if (responsesRaw is Map) {
      for (final e in responsesRaw.entries) {
        final key = e.key?.toString();
        final val = e.value?.toString();
        if (key != null && val != null) {
          final st = EventStatus.values.asNameMap()[val];
          if (st != null) recipientResponses[key] = st;
        }
      }
    }

    final reasonsRaw = json['recipient_decline_reasons'];
    final recipientDeclineReasons = <String, String>{};
    if (reasonsRaw is Map) {
      for (final e in reasonsRaw.entries) {
        final key = e.key?.toString();
        final val = e.value?.toString();
        if (key != null && val != null) recipientDeclineReasons[key] = val;
      }
    }

    return Event(
      id: json['id'] as String,
      type: type,
      workoutName: workoutName,
      date: DateTime.parse(json['date'] as String),
      location: json['location'] as String?,
      description: json['description'] as String?,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      sender: json['sender'] as String,
      senderName: json['sender_name'] as String,
      recipient: json['recipient'] as String?,
      recipients: recipients,
      status: status,
      recipientResponses: recipientResponses,
      recipientDeclineReasons: recipientDeclineReasons,
      reminderTime: (json['reminder_time'] as num?)?.toInt() ?? 0,
      repeat: json['repeat'] as String?,
      addedToCalendar: json['added_to_calendar'] == true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  /// Валидация данных события. Выбрасывает [FormatException] при ошибке.
  static void validateEventData(Map<String, dynamic> json) {
    final id = json['id'];
    if (id == null || id is! String || id.isEmpty) {
      throw FormatException('Event: отсутствует или неверен id');
    }
    final date = json['date'];
    if (date == null || date is! String) {
      throw FormatException('Event: отсутствует date');
    }
    if (DateTime.tryParse(date) == null) {
      throw FormatException('Event: неверный формат date');
    }
    final sender = json['sender'];
    if (sender == null || sender is! String || sender.isEmpty) {
      throw FormatException('Event: отсутствует sender');
    }
    final senderName = json['sender_name'];
    if (senderName == null || senderName is! String) {
      throw FormatException('Event: отсутствует sender_name');
    }
    final createdAt = json['created_at'];
    if (createdAt == null || createdAt is! String) {
      throw FormatException('Event: отсутствует created_at');
    }
    if (DateTime.tryParse(createdAt) == null) {
      throw FormatException('Event: неверный формат created_at');
    }
  }

  Event copyWith({
    String? id,
    EventType? type,
    WorkoutName? workoutName,
    DateTime? date,
    String? location,
    String? description,
    int? duration,
    String? sender,
    String? senderName,
    String? recipient,
    List<String>? recipients,
    EventStatus? status,
    Map<String, EventStatus>? recipientResponses,
    Map<String, String>? recipientDeclineReasons,
    int? reminderTime,
    String? repeat,
    DateTime? updatedAt,
    bool? addedToCalendar,
    DateTime? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      type: type ?? this.type,
      workoutName: workoutName ?? this.workoutName,
      date: date ?? this.date,
      location: location ?? this.location,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      sender: sender ?? this.sender,
      senderName: senderName ?? this.senderName,
      recipient: recipient ?? this.recipient,
      recipients: recipients ?? this.recipients,
      status: status ?? this.status,
      recipientResponses: recipientResponses ?? this.recipientResponses,
      recipientDeclineReasons: recipientDeclineReasons ?? this.recipientDeclineReasons,
      reminderTime: reminderTime ?? this.reminderTime,
      repeat: repeat ?? this.repeat,
      addedToCalendar: addedToCalendar ?? this.addedToCalendar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
