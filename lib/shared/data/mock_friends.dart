import '../models/friend.dart';

class MockFriends {
  static List<Friend> getFriends() {
    final now = DateTime.now();
    
    return [
      Friend(
        id: '1',
        name: 'Иван Петров',
        addedAt: now.subtract(const Duration(days: 30)),
      ),
      Friend(
        id: '2',
        name: 'Мария Сидорова',
        addedAt: now.subtract(const Duration(days: 25)),
      ),
      Friend(
        id: '3',
        name: 'Алексей Иванов',
        addedAt: now.subtract(const Duration(days: 20)),
      ),
      Friend(
        id: '4',
        name: 'Дмитрий Смирнов',
        addedAt: now.subtract(const Duration(days: 15)),
      ),
      Friend(
        id: '5',
        name: 'Елена Козлова',
        addedAt: now.subtract(const Duration(days: 10)),
      ),
      Friend(
        id: '6',
        name: 'Ольга Новикова',
        addedAt: now.subtract(const Duration(days: 5)),
      ),
      Friend(
        id: '7',
        name: 'Анна Волкова',
        addedAt: now.subtract(const Duration(days: 3)),
      ),
      Friend(
        id: '8',
        name: 'Сергей Лебедев',
        addedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
