import 'package:flutter/material.dart';

enum WorkoutStatus {
  pending, // Не подтвержденная - желтый
  confirmed, // Подтвержденная - зеленый
  declined, // Все отменили - красный
  completed, // Выполненная - синий
}

enum WorkoutRepeat {
  never, // Никогда
  weekly, // Каждую неделю
  biweekly, // Каждые 2 недели
  monthly, // Каждый месяц
}

enum WorkoutType {
  legs, // Ноги
  back, // Спина
  shoulders, // Плечи
  arms, // Руки
  abs, // Пресс
  chest, // Грудь
  general, // Общая
  other, // Другое
}

class Workout {
  final String id;
  final String title;
  final DateTime dateTime;
  final WorkoutStatus status;
  final List<String> participants; // Имена участников
  final String? description; // Описание
  final int duration; // Продолжительность в минутах
  final WorkoutRepeat repeat; // Повтор
  final Duration? notification; // Уведомление (за сколько времени)
  final List<WorkoutType> workoutTypes; // Типы тренировок

  Workout({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.status,
    required this.participants,
    this.description,
    this.duration = 60,
    this.repeat = WorkoutRepeat.never,
    this.notification,
    this.workoutTypes = const [],
  });

  // Получить цвет статуса
  Color getStatusColor() {
    switch (status) {
      case WorkoutStatus.pending:
        return Colors.amber;
      case WorkoutStatus.confirmed:
        return Colors.green;
      case WorkoutStatus.declined:
        return Colors.red;
      case WorkoutStatus.completed:
        return Colors.blue;
    }
  }

  // Получить название типа тренировки
  static String getWorkoutTypeName(WorkoutType type) {
    switch (type) {
      case WorkoutType.legs:
        return 'Ноги';
      case WorkoutType.back:
        return 'Спина';
      case WorkoutType.shoulders:
        return 'Плечи';
      case WorkoutType.arms:
        return 'Руки';
      case WorkoutType.abs:
        return 'Пресс';
      case WorkoutType.chest:
        return 'Грудь';
      case WorkoutType.general:
        return 'Общая';
      case WorkoutType.other:
        return 'Другое';
    }
  }

  // Получить название повтора
  static String getRepeatName(WorkoutRepeat repeat) {
    switch (repeat) {
      case WorkoutRepeat.never:
        return 'Никогда';
      case WorkoutRepeat.weekly:
        return 'Каждую неделю';
      case WorkoutRepeat.biweekly:
        return 'Каждые 2 недели';
      case WorkoutRepeat.monthly:
        return 'Каждый месяц';
    }
  }
}
