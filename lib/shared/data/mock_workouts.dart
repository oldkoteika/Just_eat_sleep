import '../models/workout.dart';

class MockWorkouts {
  static List<Workout> getWorkouts() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return [
      // Тренировки на сегодня
      Workout(
        id: '1',
        title: 'Тренировка ног',
        dateTime: today.add(const Duration(hours: 9, minutes: 0)),
        status: WorkoutStatus.pending,
        participants: ['Иван', 'Мария'],
      ),
      Workout(
        id: '2',
        title: 'Тренировка груди',
        dateTime: today.add(const Duration(hours: 14, minutes: 30)),
        status: WorkoutStatus.confirmed,
        participants: ['Алексей', 'Дмитрий', 'Елена'],
      ),
      Workout(
        id: '3',
        title: 'Кардио',
        dateTime: today.add(const Duration(hours: 18, minutes: 0)),
        status: WorkoutStatus.completed,
        participants: ['Ольга'],
      ),
      
      // Тренировки на завтра
      Workout(
        id: '4',
        title: 'Тренировка спины',
        dateTime: today.add(const Duration(days: 1, hours: 10, minutes: 0)),
        status: WorkoutStatus.pending,
        participants: ['Иван', 'Мария', 'Алексей'],
      ),
      Workout(
        id: '5',
        title: 'Тренировка плеч',
        dateTime: today.add(const Duration(days: 1, hours: 16, minutes: 0)),
        status: WorkoutStatus.confirmed,
        participants: ['Дмитрий'],
      ),
      
      // Тренировки на послезавтра
      Workout(
        id: '6',
        title: 'Тренировка рук',
        dateTime: today.add(const Duration(days: 2, hours: 11, minutes: 0)),
        status: WorkoutStatus.pending,
        participants: ['Елена', 'Ольга'],
      ),
      Workout(
        id: '7',
        title: 'Йога',
        dateTime: today.add(const Duration(days: 2, hours: 19, minutes: 0)),
        status: WorkoutStatus.confirmed,
        participants: ['Мария', 'Алексей'],
      ),
      
      // Тренировки на прошлой неделе
      Workout(
        id: '8',
        title: 'Тренировка ног',
        dateTime: today.subtract(const Duration(days: 3, hours: 2)),
        status: WorkoutStatus.completed,
        participants: ['Иван', 'Дмитрий'],
      ),
      Workout(
        id: '9',
        title: 'Кардио',
        dateTime: today.subtract(const Duration(days: 2, hours: 4)),
        status: WorkoutStatus.completed,
        participants: ['Ольга', 'Елена'],
      ),
    ];
  }

  static List<Workout> getWorkoutsForDate(DateTime date) {
    final workouts = getWorkouts();
    final targetDate = DateTime(date.year, date.month, date.day);
    
    return workouts.where((workout) {
      final workoutDate = DateTime(
        workout.dateTime.year,
        workout.dateTime.month,
        workout.dateTime.day,
      );
      return workoutDate.isAtSameMomentAs(targetDate);
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  static List<DateTime> getDatesWithWorkouts() {
    final workouts = getWorkouts();
    final dates = <DateTime>{};
    
    for (var workout in workouts) {
      final date = DateTime(
        workout.dateTime.year,
        workout.dateTime.month,
        workout.dateTime.day,
      );
      dates.add(date);
    }
    
    return dates.toList()..sort();
  }
}
