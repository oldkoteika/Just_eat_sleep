import '../friends/friends_storage.dart';
import '../../shared/models/friend.dart';
import 'abstract_friends_repository.dart';

/// Локальная реализация репозитория друзей (Hive).
/// В будущем можно заменить на P2P-синхронизированную реализацию.
class FriendsRepositoryImpl implements AbstractFriendsRepository {
  FriendsRepositoryImpl();

  @override
  Future<List<Friend>> getFriends() => FriendsStorage.getFriends();

  @override
  Future<void> saveFriends(List<Friend> friends) =>
      FriendsStorage.saveFriends(friends);

  @override
  Future<void> addFriend(Friend friend) => FriendsStorage.addFriend(friend);

  @override
  Future<void> removeFriend(String friendId) =>
      FriendsStorage.removeFriend(friendId);

  @override
  Future<Friend?> getFriendById(String friendId) async {
    final list = await getFriends();
    try {
      return list.firstWhere((f) => f.id == friendId);
    } on StateError {
      return null;
    }
  }
}
