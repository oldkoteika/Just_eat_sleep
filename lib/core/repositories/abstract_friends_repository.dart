import '../../shared/models/friend.dart';

/// Абстракция репозитория друзей.
/// Позволяет подменить реализацию на P2P/облако в будущем.
abstract class AbstractFriendsRepository {
  Future<List<Friend>> getFriends();
  Future<void> saveFriends(List<Friend> friends);
  Future<void> addFriend(Friend friend);
  Future<void> removeFriend(String friendId);
  Future<Friend?> getFriendById(String friendId);
}
