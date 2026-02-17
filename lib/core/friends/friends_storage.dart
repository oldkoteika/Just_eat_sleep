import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/models/friend.dart';

const _boxName = 'friends_box';
const _keyList = 'friends_list';

/// Локальное хранилище списка друзей (Hive).
class FriendsStorage {
  FriendsStorage._();

  static Future<Box<dynamic>> _openBox() => Hive.openBox(_boxName);

  /// Загрузить список друзей.
  static Future<List<Friend>> getFriends() async {
    final box = await _openBox();
    final data = box.get(_keyList);
    if (data is! List) return [];
    final list = <Friend>[];
    for (final item in data) {
      if (item is Map) {
        try {
          list.add(Friend.fromJson(Map<String, dynamic>.from(item)));
        } on Exception {
          // пропускаем битые записи
        }
      }
    }
    return list;
  }

  /// Сохранить список друзей.
  static Future<void> saveFriends(List<Friend> friends) async {
    final box = await _openBox();
    final encoded =
        friends.map((f) => f.toJson()).toList();
    await box.put(_keyList, encoded);
  }

  /// Добавить друга и сохранить.
  static Future<void> addFriend(Friend friend) async {
    final list = await getFriends();
    if (list.any((f) => f.id == friend.id)) return;
    list.add(friend);
    await saveFriends(list);
  }

  /// Удалить друга по id и сохранить.
  static Future<void> removeFriend(String friendId) async {
    final list = await getFriends();
    list.removeWhere((f) => f.id == friendId);
    await saveFriends(list);
  }
}
