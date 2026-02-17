import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/user.dart';

const _boxName = 'user_box';
const _keyCurrentUser = 'current_user';

/// Локальное хранилище текущего пользователя (Hive).
class UserStorage {
  UserStorage._();

  static Future<Box<dynamic>> _openBox() => Hive.openBox(_boxName);

  /// Сохранить текущего пользователя.
  static Future<void> saveCurrentUser(User user) async {
    final box = await _openBox();
    await box.put(_keyCurrentUser, user.toJson());
  }

  /// Загрузить текущего пользователя. Возвращает `null`, если пользователь ещё не создан.
  static Future<User?> getCurrentUser() async {
    final box = await _openBox();
    final data = box.get(_keyCurrentUser);
    if (data is! Map) return null;
    try {
      return User.fromJson(Map<String, dynamic>.from(data));
    } on FormatException {
      return null;
    }
  }

  /// Есть ли сохранённый пользователь (профиль уже заполнялся).
  static Future<bool> hasCurrentUser() async {
    final user = await getCurrentUser();
    return user != null;
  }
}
