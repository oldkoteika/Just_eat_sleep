import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repositories/repository_providers.dart';
import '../../shared/models/event.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/bottom_navigation.dart';
import '../workout/view_workout_screen.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => WorkoutScreenState();
}

class WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _timeLineController = ScrollController();
  DateTime? _currentTime;

  @override
  void initState() {
    super.initState();
    _updateCurrentTime();
    _startTimeUpdates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final events = ref.read(eventsListProvider).value ?? [];
      _scrollToCurrentTime(events);
    });
  }

  void refresh() {
    ref.invalidate(eventsListProvider);
  }

  void _updateCurrentTime() {
    setState(() {
      _currentTime = DateTime.now();
    });
  }

  void _startTimeUpdates() {
    // Обновляем время каждую минуту
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted) {
        _updateCurrentTime();
        _startTimeUpdates();
      }
    });
  }

  void _scrollToCurrentTime(List<Event> events) {
    if (!_timeLineController.hasClients) return;

    final dayEvents = events
        .where((e) {
          final d = e.dateLocal;
          return d.year == _selectedDate.year &&
              d.month == _selectedDate.month &&
              d.day == _selectedDate.day;
        })
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final isToday = _isSameDay(_selectedDate, DateTime.now());
    if (!isToday && dayEvents.isNotEmpty) {
      final firstEvent = dayEvents.first;
      final hours = firstEvent.dateLocal.hour;
      final minutes = firstEvent.dateLocal.minute;
      final scrollPosition = (hours * 60.0) + (minutes * 1.0);
      _timeLineController.animateTo(
        scrollPosition.clamp(0.0, _timeLineController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    // Прокручиваем к текущему времени
    final now = DateTime.now();
    final hours = now.hour;
    final minutes = now.minute;
    // Высота часовой метки (8 + 8 padding) + высота карточки тренировки
    // Примерно 60 пикселей на час
    final scrollPosition = (hours * 60.0) + (minutes * 1.0);
    _timeLineController.animateTo(
      scrollPosition.clamp(0.0, _timeLineController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  void dispose() {
    _timeLineController.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDate(List<Event> events, DateTime date) {
    return events
        .where((e) {
          final d = e.dateLocal;
          return d.year == date.year && d.month == date.month && d.day == date.day;
        })
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<DateTime> _getDatesWithEvents(List<Event> events) {
    final dates = <DateTime>{};
    for (final e in events) {
      final d = e.dateLocal;
      dates.add(DateTime(d.year, d.month, d.day));
    }
    return dates.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(eventsRealtimeSubscriptionProvider);
    ref.watch(eventsOfflineSyncProvider);
    final eventsAsync = ref.watch(eventsListProvider);
    final events = eventsAsync.value ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workouts = _getEventsForDate(events, _selectedDate);
    final datesWithWorkouts = _getDatesWithEvents(events);
    final timelineBottomPadding =
        kBottomNavContentHeight + MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        top: AppScaffold.kTopBarHeight + AppScaffold.kContentTopGap,
      ),
      child: Column(
        children: [
          // Календарь - верхняя часть
          _buildCalendar(datesWithWorkouts, isDark),
          // Разделитель
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? CupertinoColors.systemGrey4.darkColor
                : CupertinoColors.systemGrey4,
          ),
          // Временная шкала — прокручивается под нижнее меню
          Expanded(
            child: _buildTimeLine(workouts, isDark, timelineBottomPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(List<DateTime> datesWithWorkouts, bool isDark) {
    final now = DateTime.now();
    final currentMonth = _selectedDate.month;
    final currentYear = _selectedDate.year;
    
    // Получаем первый день месяца и количество дней
    final firstDay = DateTime(currentYear, currentMonth, 1);
    final lastDay = DateTime(currentYear, currentMonth + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday; // 1 = Monday, 7 = Sunday

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Заголовок с месяцем и годом
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
                  });
                },
                child: Icon(
                  CupertinoIcons.chevron_left,
                  color: isDark ? CupertinoColors.white : CupertinoColors.label,
                ),
              ),
              Text(
                '${_getMonthName(currentMonth)} $currentYear',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? CupertinoColors.white : CupertinoColors.label,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
                  });
                },
                child: Icon(
                  CupertinoIcons.chevron_right,
                  color: isDark ? CupertinoColors.white : CupertinoColors.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Дни недели
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.systemGrey2,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Календарная сетка
          ...List.generate(6, (weekIndex) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 2;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox());
                }

                final dayDate = DateTime(currentYear, currentMonth, dayNumber);
                final hasWorkout = datesWithWorkouts.any((date) =>
                    _isSameDay(date, dayDate));
                final isSelected = _isSameDay(dayDate, _selectedDate);
                final isToday = _isSameDay(dayDate, now);

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = dayDate;
                      });
                      // Прокручиваем к первой тренировке или текущему времени
                      Future.delayed(const Duration(milliseconds: 100), () {
                        final ev = ref.read(eventsListProvider).value ?? [];
                        _scrollToCurrentTime(ev);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CupertinoColors.activeBlue
                            : (hasWorkout
                                ? (isDark
                                    ? CupertinoColors.systemGrey6.darkColor
                                    : CupertinoColors.systemGrey6)
                                : Colors.transparent),
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(
                                color: CupertinoColors.activeBlue,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? CupertinoColors.white
                                : (isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.label),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Color _getEventStatusColor(Event e) {
    switch (e.status) {
      case EventStatus.pending:
        return Colors.amber;
      case EventStatus.accepted:
        return Colors.green;
      case EventStatus.declined:
        return Colors.red;
      case EventStatus.completed:
        return Colors.blue;
    }
  }

  Widget _buildTimeLine(
      List<Event> workouts, bool isDark, double bottomPadding) {
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final currentTime = _currentTime ?? DateTime.now();

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _timeLineController,
          child: Column(
            children: [
              ...List.generate(24, (hour) {
                final hourEvents = workouts
                    .where((e) => e.dateLocal.hour == hour)
                    .toList();
                hourEvents.sort((a, b) => a.dateLocal.minute.compareTo(b.dateLocal.minute));

                return Column(
                  children: [
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? CupertinoColors.systemGrey
                                    : CupertinoColors.systemGrey2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: isDark
                                  ? CupertinoColors.systemGrey4.darkColor
                                  : CupertinoColors.systemGrey4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...hourEvents.map((e) => _buildWorkoutCard(e, isDark)),
                    if (hourEvents.any((e) => e.dateLocal.minute >= 30))
                      Container(
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: Text(
                                '${hour.toString().padLeft(2, '0')}:30',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? CupertinoColors.systemGrey
                                      : CupertinoColors.systemGrey2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Divider(
                                height: 1,
                                thickness: 0.5,
                                color: isDark
                                    ? CupertinoColors.systemGrey5.darkColor
                                    : CupertinoColors.systemGrey5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }),
              // Отступ внизу, чтобы последние элементы можно было поднять выше нижнего меню
              SizedBox(height: bottomPadding),
            ],
          ),
        ),
        // Индикатор текущего времени (только для сегодня)
        if (isToday)
          Positioned(
            left: 0,
            right: 0,
            top: _getCurrentTimePosition(currentTime),
            child: Container(
              height: 2,
              color: CupertinoColors.activeBlue,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: CupertinoColors.activeBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  double _getCurrentTimePosition(DateTime currentTime) {
    final hours = currentTime.hour;
    final minutes = currentTime.minute;
    // Высота часовой метки (8 + 8 padding) + позиция внутри часа
    // Примерно 60 пикселей на час
    return (hours * 60.0) + (minutes * 1.0);
  }

  Widget _buildWorkoutCard(Event event, bool isDark) {
    final statusColor = _getEventStatusColor(event);
    final timeStr =
        '${event.dateLocal.hour.toString().padLeft(2, '0')}:${event.dateLocal.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => _showWorkoutDetails(event),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          border: Border.all(
            color: statusColor.withOpacity(0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : CupertinoColors.label,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Event.getWorkoutNameDisplay(event.workoutName),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.senderDisplayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: isDark
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemGrey2,
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkoutDetails(Event event) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => ViewWorkoutScreen(event: event),
    ).then((_) {
      refresh();
    });
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }
}
