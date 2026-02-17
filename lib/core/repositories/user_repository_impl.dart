import '../auth/user_storage.dart';
import '../../shared/models/user.dart';
import 'abstract_user_repository.dart';

/// Локальная реализация репозитория пользователя (Hive).
class UserRepositoryImpl implements AbstractUserRepository {
  UserRepositoryImpl();

  @override
  Future<User?> getCurrentUser() => UserStorage.getCurrentUser();

  @override
  Future<void> saveCurrentUser(User user) => UserStorage.saveCurrentUser(user);

  @override
  Future<bool> hasCurrentUser() => UserStorage.hasCurrentUser();
}
