/// Модель текущего пользователя приложения.
class User {
  final String id;
  final String name;
  final String? avatarPath;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    this.avatarPath,
    required this.createdAt,
  });

  /// Полное имя (ФИО) для отображения.
  String get displayName => name.trim();

  /// Инициалы для аватара (первые буквы слов).
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.length == 1 && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return '?';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    final createdAtStr = json['createdAt'] as String?;
    if (id == null || name == null || createdAtStr == null) {
      throw FormatException('User.fromJson: отсутствуют обязательные поля');
    }
    return User(
      id: id,
      name: name,
      avatarPath: json['avatarPath'] as String?,
      createdAt: DateTime.parse(createdAtStr),
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? avatarPath,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
