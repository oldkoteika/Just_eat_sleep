import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/workout.dart';

/// Модель тренировки для виджета
class WorkoutItem {
  final String id;
  final String name;
  final DateTime time;
  final List<String> participants;
  final WorkoutStatus status;

  WorkoutItem({
    required this.id,
    required this.name,
    required this.time,
    required this.participants,
    this.status = WorkoutStatus.pending,
  });
}

/// Виджет календаря тренировок для главной страницы
class WorkoutCalendarWidget extends StatelessWidget {
  final DateTime selectedDate;
  final List<WorkoutItem> workouts;
  final VoidCallback onTap;
  final Function(WorkoutItem)? onWorkoutTap;

  const WorkoutCalendarWidget({
    super.key,
    required this.selectedDate,
    required this.workouts,
    required this.onTap,
    this.onWorkoutTap,
  });

  // Месяцы на русском языке
  static const List<String> _months = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  // Дни недели на русском языке
  static const List<String> _weekDays = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime date) {
    final dayOfWeek = _weekDays[date.weekday - 1];
    final month = _months[date.month - 1];
    return '$dayOfWeek, ${date.day} $month';
  }

  Color _getStatusColor(WorkoutStatus status) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.systemGrey6;
    final textColor = isDark
        ? CupertinoColors.white
        : CupertinoColors.label;
    final secondaryTextColor = isDark
        ? CupertinoColors.systemGrey
        : CupertinoColors.systemGrey2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Шапка с датой и иконкой календаря
          GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.calendar,
                    color: CupertinoColors.activeBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(selectedDate),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Список тренировок
          if (workouts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Нет тренировок',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: workouts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final workout = entry.value;
                  final isLast = index == workouts.length - 1;

                  // Получаем цвет статуса
                  final statusColor = _getStatusColor(workout.status);
                  
                  return Column(
                    children: [
                      // Тренировка
                      GestureDetector(
                        onTap: () {
                          onWorkoutTap?.call(workout);
                        },
                        child: Container(
                          margin: EdgeInsets.only(
                            left: 8,
                            right: 8,
                            top: index == 0 ? 0 : 8,
                            bottom: isLast ? 0 : 8,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Индикатор статуса
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Время
                              Text(
                                _formatTime(workout.time),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Название тренировки
                              Expanded(
                                child: Text(
                                  workout.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              // Стрелка
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 16,
                                color: secondaryTextColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
