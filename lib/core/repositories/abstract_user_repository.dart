import '../../shared/models/user.dart';

/// Абстракция репозитория пользователя.
/// Позволяет подменить реализацию на P2P/облако в будущем.
abstract class AbstractUserRepository {
  Future<User?> getCurrentUser();
  Future<void> saveCurrentUser(User user);
  Future<bool> hasCurrentUser();
}
