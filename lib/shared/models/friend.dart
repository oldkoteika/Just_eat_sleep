import 'dart:convert';

/// Статус друга (онлайн/офлайн), опционально.
enum FriendStatus {
  online,
  offline,
}

class Friend {
  final String id;
  final String name;
  final String? avatarUrl; // URL или локальный путь к аватару (опционально)
  final DateTime addedAt; // Дата добавления
  final FriendStatus? status; // Онлайн/офлайн (опционально)

  Friend({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.addedAt,
    this.status,
  });

  // Получить инициалы для отображения
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  /// Данные, которые кодируются в QR-коде для добавления друга.
  Map<String, dynamic> toQrPayload() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'addedAt': addedAt.toIso8601String(),
      'status': status?.name,
    };
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    final addedAtStr = json['addedAt'] as String?;
    if (id == null || name == null || addedAtStr == null) {
      throw FormatException('Friend.fromJson: отсутствуют обязательные поля');
    }
    FriendStatus? status;
    final statusStr = json['status'] as String?;
    if (statusStr != null) {
      status = FriendStatus.values.asNameMap()[statusStr];
    }
    return Friend(
      id: id,
      name: name,
      avatarUrl: json['avatarUrl'] as String?,
      addedAt: DateTime.parse(addedAtStr),
      status: status,
    );
  }

  Friend copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    DateTime? addedAt,
    FriendStatus? status,
  }) {
    return Friend(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      addedAt: addedAt ?? this.addedAt,
      status: status ?? this.status,
    );
  }

  /// Создать объект друга из декодированного JSON-пейлоада QR-кода.
  /// Поддерживает поля: id, name, avatarUrl, ts (временная метка для валидации).
  factory Friend.fromQrPayload(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];

    if (id is! String || name is! String) {
      throw const FormatException('Некорректный формат данных QR-кода друга');
    }

    return Friend(
      id: id,
      name: name,
      avatarUrl: json['avatarUrl'] as String?,
      addedAt: DateTime.now(),
    );
  }

  /// Максимальный возраст QR (дней): если в payload есть [ts], старше — считаем недействительным.
  static const int qrMaxAgeDays = 30;

  /// Попытаться распарсить и провалидировать строку из QR-кода в [Friend].
  /// Проверяет наличие id/name и при наличии [ts] — что QR не старше [qrMaxAgeDays].
  static Friend? tryParseFromQrString(
    String data, {
    int? maxAgeDays = qrMaxAgeDays,
  }) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) return null;

      final ts = decoded['ts'];
      if (ts != null) {
        final tsMs = ts is int ? ts : (ts is String ? int.tryParse(ts) : null);
        if (tsMs != null && maxAgeDays != null && maxAgeDays > 0) {
          final qrTime = DateTime.fromMillisecondsSinceEpoch(tsMs);
          final limit = DateTime.now().subtract(Duration(days: maxAgeDays));
          if (qrTime.isBefore(limit)) return null;
        }
      }

      return Friend.fromQrPayload(decoded);
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
