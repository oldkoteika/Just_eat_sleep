import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/repositories/abstract_events_repository.dart';
import '../../core/repositories/abstract_user_repository.dart';
import '../../core/repositories/repository_providers.dart';
import '../../core/utils/event_workout_utils.dart';
import '../../shared/models/event.dart';
import '../../shared/models/friend.dart';
import '../../shared/models/workout.dart';
import '../../core/friends/friends_storage.dart';

class AddWorkoutScreen extends ConsumerStatefulWidget {
  /// При открытии из «Пригласить на тренировку» — друг уже выбран.
  final Friend? initialFriend;

  const AddWorkoutScreen({super.key, this.initialFriend});

  @override
  ConsumerState<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends ConsumerState<AddWorkoutScreen> {
  // Выбранные типы тренировок
  final Set<WorkoutType> _selectedTypes = {};
  
  // Описание
  final TextEditingController _descriptionController = TextEditingController();
  
  // Дата и время начала
  late DateTime _startDate;
  late TimeOfDay _startTime;
  
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _startTime = TimeOfDay.now();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final list = await FriendsStorage.getFriends();
    if (!mounted) return;
    setState(() {
      _allFriends = list;
      if (widget.initialFriend != null) {
        _selectedFriendIds.add(widget.initialFriend!.id);
      }
    });
  }
  
  // Продолжительность в минутах
  int _duration = 60;
  
  // Повтор
  WorkoutRepeat _repeat = WorkoutRepeat.never;
  
  // Уведомление
  bool _hasNotification = false;
  int _notificationHours = 1;
  int _notificationMinutes = 0;
  
  // Выбранные друзья
  final Set<String> _selectedFriendIds = {};
  List<Friend> _allFriends = [];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkout() async {
    final userRepo = ref.read(userRepositoryProvider);
    final eventsRepo = ref.read(eventsRepositoryProvider);
    final user = await userRepo.getCurrentUser();
    if (user == null || !mounted) return;

    final workoutName = _selectedTypes.isEmpty
        ? WorkoutName.other
        : workoutNameFromWorkoutType(_selectedTypes.first);
    final dateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final reminderMinutes = _hasNotification
        ? (_notificationHours * 60 + _notificationMinutes)
        : 0;

    final recipientIds = _selectedFriendIds.toList();
    final hasRecipients = recipientIds.isNotEmpty;
    final initialStatus = hasRecipients ? EventStatus.pending : EventStatus.accepted;
    final initialResponses = <String, EventStatus>{};
    for (final id in recipientIds) {
      initialResponses[id] = EventStatus.pending;
    }

    final event = Event(
      id: const Uuid().v4(),
      type: EventType.workoutInvitation,
      workoutName: workoutName,
      date: dateTime,
      location: null,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      duration: _duration,
      sender: user.id,
      senderName: user.name,
      recipient: recipientIds.length == 1 ? recipientIds.single : null,
      recipients: recipientIds,
      status: initialStatus,
      recipientResponses: initialResponses,
      reminderTime: reminderMinutes,
      repeat: _repeat.name,
      addedToCalendar: false,
      createdAt: DateTime.now(),
    );

    await eventsRepo.addEvent(event);
    if (!mounted) return;
    Navigator.of(context).pop(event);
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? CupertinoColors.systemBackground.darkColor
        : CupertinoColors.systemBackground;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Индикатор перетаскивания
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? CupertinoColors.systemGrey4.darkColor
                    : CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Заголовок с кнопками
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Кнопка отмены (X)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _cancel,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? CupertinoColors.systemGrey6.darkColor
                            : CupertinoColors.systemGrey6,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.xmark,
                        size: 18,
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.label,
                      ),
                    ),
                  ),
                  // Кнопка сохранения (V)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _saveWorkout(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CupertinoColors.activeBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.check_mark,
                        size: 18,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Контент с прокруткой
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Контекстный островок: Наименование
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildContextualIsland(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Наименование',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.label,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: WorkoutType.values.map((type) {
                                final isSelected = _selectedTypes.contains(type);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedTypes.remove(type);
                                      } else {
                                        _selectedTypes.add(type);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? CupertinoColors.activeBlue
                                          : (isDark
                                              ? CupertinoColors.systemGrey6.darkColor
                                              : CupertinoColors.systemGrey6),
                                      borderRadius: BorderRadius.circular(20),
                                      border: isSelected
                                          ? null
                                          : Border.all(
                                              color: isDark
                                                  ? CupertinoColors.systemGrey4.darkColor
                                                  : CupertinoColors.systemGrey4,
                                              width: 1,
                                            ),
                                    ),
                                    child: Text(
                                      Workout.getWorkoutTypeName(type),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? CupertinoColors.white
                                            : (isDark
                                                ? CupertinoColors.white
                                                : CupertinoColors.label),
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Контекстный островок: Описание
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildContextualIsland(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Описание',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? CupertinoColors.white
                                  : CupertinoColors.label,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CupertinoTextField(
                            controller: _descriptionController,
                            placeholder: 'Введите описание тренировки',
                            maxLines: 4,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? CupertinoColors.systemGrey6.darkColor
                                  : CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            style: TextStyle(
                              color: isDark
                                  ? CupertinoColors.white
                                  : CupertinoColors.label,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                    const SizedBox(height: 16),
                    // Контекстный островок: Друзья
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildContextualIsland(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Друзья',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? CupertinoColors.white
                                  : CupertinoColors.label,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              _showFriendsSelection(context, isDark);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? CupertinoColors.systemGrey5.darkColor
                                    : CupertinoColors.systemGrey5,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? CupertinoColors.systemGrey4.darkColor
                                      : CupertinoColors.systemGrey4,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: _selectedFriendIds.isEmpty
                                        ? Text(
                                            'Выберите друзей',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isDark
                                                  ? CupertinoColors.systemGrey
                                                  : CupertinoColors.systemGrey2,
                                              decoration: TextDecoration.none,
                                            ),
                                          )
                                        : Text(
                                            'Выбрано: ${_selectedFriendIds.length}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isDark
                                                  ? CupertinoColors.white
                                                  : CupertinoColors.label,
                                              decoration: TextDecoration.none,
                                            ),
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
                          ),
                          // Показываем выбранных друзей
                          if (_selectedFriendIds.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _buildSelectedFriendsChips(isDark),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ),
                    const SizedBox(height: 16),
                    // Контекстный островок: Начало, Продолжительность, Повтор
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildContextualIsland(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Начало
                            _buildSectionTitle('Начало'),
                          const SizedBox(height: 8),
                          // Поле выбора даты
                          GestureDetector(
                            onTap: () {
                              final now = DateTime.now();
                              final today = DateTime(now.year, now.month, now.day);
                              // Убеждаемся, что initialDateTime >= minimumDate
                              final initialDate = _startDate.isBefore(today) ? today : _startDate;
                              DateTime selectedDate = initialDate;
                              showCupertinoModalPopup(
                                context: context,
                                builder: (context) => Container(
                                  height: 300,
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          CupertinoButton(
                                            child: const Text('Отмена'),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                          CupertinoButton(
                                            child: const Text('Готово'),
                                            onPressed: () {
                                              setState(() {
                                                _startDate = DateTime(
                                                  selectedDate.year,
                                                  selectedDate.month,
                                                  selectedDate.day,
                                                );
                                              });
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: CupertinoDatePicker(
                                          mode: CupertinoDatePickerMode.date,
                                          initialDateTime: initialDate,
                                          minimumDate: today,
                                          onDateTimeChanged: (date) {
                                            selectedDate = date;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? CupertinoColors.systemGrey6.darkColor
                                    : CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${_startDate.day} ${_getMonthName(_startDate.month)} ${_startDate.year}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDark
                                            ? CupertinoColors.white
                                            : CupertinoColors.label,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.calendar,
                                    size: 20,
                                    color: isDark
                                        ? CupertinoColors.systemGrey
                                        : CupertinoColors.systemGrey2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Поле выбора времени
                          GestureDetector(
                            onTap: () {
                              int tempHours = _startTime.hour;
                              int tempMinutes = _startTime.minute;
                              showCupertinoModalPopup(
                                context: context,
                                builder: (context) => Container(
                                  height: 350,
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          CupertinoButton(
                                            child: const Text('Отмена'),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                          CupertinoButton(
                                            child: const Text('Готово'),
                                            onPressed: () {
                                              setState(() {
                                                _startTime = TimeOfDay(
                                                  hour: tempHours,
                                                  minute: tempMinutes,
                                                );
                                              });
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: CupertinoTimerPicker(
                                          mode: CupertinoTimerPickerMode.hm,
                                          initialTimerDuration: Duration(
                                            hours: tempHours,
                                            minutes: tempMinutes,
                                          ),
                                          onTimerDurationChanged: (duration) {
                                            tempHours = duration.inHours;
                                            tempMinutes = duration.inMinutes % 60;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? CupertinoColors.systemGrey6.darkColor
                                    : CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDark
                                            ? CupertinoColors.white
                                            : CupertinoColors.label,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.clock,
                                    size: 20,
                                    color: isDark
                                        ? CupertinoColors.systemGrey
                                        : CupertinoColors.systemGrey2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Продолжительность
                          _buildSectionTitle('Продолжительность'),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              // Показываем выбор продолжительности
                              int tempHours = _duration ~/ 60;
                              int tempMinutes = _duration % 60;
                              showCupertinoModalPopup(
                                context: context,
                                builder: (context) => Container(
                                  height: 350,
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          CupertinoButton(
                                            child: const Text('Отмена'),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                          CupertinoButton(
                                            child: const Text('Готово'),
                                            onPressed: () {
                                              setState(() {
                                                _duration = tempHours * 60 + tempMinutes;
                                              });
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: CupertinoTimerPicker(
                                          mode: CupertinoTimerPickerMode.hm,
                                          initialTimerDuration: Duration(
                                            hours: tempHours,
                                            minutes: tempMinutes,
                                          ),
                                          onTimerDurationChanged: (duration) {
                                            tempHours = duration.inHours;
                                            tempMinutes = duration.inMinutes % 60;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? CupertinoColors.systemGrey6.darkColor
                                    : CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_duration),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark
                                          ? CupertinoColors.white
                                          : CupertinoColors.label,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_down,
                                    size: 16,
                                    color: isDark
                                        ? CupertinoColors.systemGrey
                                        : CupertinoColors.systemGrey2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Повтор
                          _buildSectionTitle('Повтор'),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              showCupertinoModalPopup(
                                context: context,
                                builder: (context) => CupertinoActionSheet(
                                  actions: WorkoutRepeat.values.map((repeat) {
                                    return CupertinoActionSheetAction(
                                      onPressed: () {
                                        setState(() {
                                          _repeat = repeat;
                                        });
                                        Navigator.pop(context);
                                      },
                                      child: Text(Workout.getRepeatName(repeat)),
                                    );
                                  }).toList(),
                                  cancelButton: CupertinoActionSheetAction(
                                    onPressed: () => Navigator.pop(context),
                                    isDefaultAction: true,
                                    child: const Text('Отмена'),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? CupertinoColors.systemGrey6.darkColor
                                    : CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    Workout.getRepeatName(_repeat),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark
                                          ? CupertinoColors.white
                                          : CupertinoColors.label,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_down,
                                    size: 16,
                                    color: isDark
                                        ? CupertinoColors.systemGrey
                                        : CupertinoColors.systemGrey2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                    const SizedBox(height: 16),
                    // Контекстный островок: Уведомление
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildContextualIsland(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Уведомление',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? CupertinoColors.white
                                  : CupertinoColors.label,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              // Показываем выбор времени уведомления
                              int tempHours = _notificationHours;
                              int tempMinutes = _notificationMinutes;
                              showCupertinoModalPopup(
                                context: context,
                                builder: (context) => Container(
                                  height: 350,
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          CupertinoButton(
                                            child: const Text('Нет'),
                                            onPressed: () {
                                              setState(() {
                                                _hasNotification = false;
                                              });
                                              Navigator.pop(context);
                                            },
                                          ),
                                          CupertinoButton(
                                            child: const Text('Готово'),
                                            onPressed: () {
                                              setState(() {
                                                _hasNotification = true;
                                                _notificationHours = tempHours;
                                                _notificationMinutes = tempMinutes;
                                              });
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: CupertinoTimerPicker(
                                          mode: CupertinoTimerPickerMode.hm,
                                          initialTimerDuration: Duration(
                                            hours: _notificationHours,
                                            minutes: _notificationMinutes,
                                          ),
                                          onTimerDurationChanged: (duration) {
                                            tempHours = duration.inHours;
                                            tempMinutes = duration.inMinutes % 60;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? CupertinoColors.systemGrey6.darkColor
                                    : CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _hasNotification
                                        ? 'За $_notificationHours ч. $_notificationMinutes мин.'
                                        : 'Нет',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark
                                          ? CupertinoColors.white
                                          : CupertinoColors.label,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_down,
                                    size: 16,
                                    color: isDark
                                        ? CupertinoColors.systemGrey
                                        : CupertinoColors.systemGrey2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextualIsland({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark
            ? CupertinoColors.systemGrey
            : CupertinoColors.systemGrey2,
        decoration: TextDecoration.none,
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Января',
      'Февраля',
      'Марта',
      'Апреля',
      'Мая',
      'Июня',
      'Июля',
      'Августа',
      'Сентября',
      'Октября',
      'Ноября',
      'Декабря',
    ];
    return months[month - 1];
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) {
      return '$hours ч. $mins мин.';
    } else if (hours > 0) {
      return '$hours ч.';
    } else {
      return '$mins мин.';
    }
  }

  void _showFriendsSelection(BuildContext context, bool isDark) {
    final allFriends = _allFriends;
    final backgroundColor = isDark
        ? CupertinoColors.systemBackground.darkColor
        : CupertinoColors.systemBackground;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // Индикатор перетаскивания
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? CupertinoColors.systemGrey4.darkColor
                        : CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Заголовок
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Выберите друзей',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.label,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _selectedFriendIds.isNotEmpty
                                ? CupertinoColors.activeBlue
                                : (isDark
                                    ? CupertinoColors.systemGrey6.darkColor
                                    : CupertinoColors.systemGrey6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.check_mark,
                            size: 18,
                            color: _selectedFriendIds.isNotEmpty
                                ? CupertinoColors.white
                                : (isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.label),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Список друзей
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: allFriends.length,
                    itemBuilder: (context, index) {
                      final friend = allFriends[index];
                      final isSelected = _selectedFriendIds.contains(friend.id);
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedFriendIds.remove(friend.id);
                            } else {
                              _selectedFriendIds.add(friend.id);
                            }
                          });
                          // Обновляем состояние модального окна
                          setModalState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isDark
                                    ? CupertinoColors.systemGrey4.darkColor
                                    : CupertinoColors.systemGrey4,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Аватар/инициалы
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? CupertinoColors.activeBlue
                                      : (isDark
                                          ? CupertinoColors.systemGrey6.darkColor
                                          : CupertinoColors.systemGrey6),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    friend.initials,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? CupertinoColors.white
                                          : (isDark
                                              ? CupertinoColors.white
                                              : CupertinoColors.label),
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Имя
                              Expanded(
                                child: Text(
                                  friend.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? CupertinoColors.white
                                        : CupertinoColors.label,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                              // Чекбокс
                              Icon(
                                isSelected
                                    ? CupertinoIcons.check_mark_circled_solid
                                    : CupertinoIcons.circle,
                                size: 24,
                                color: isSelected
                                    ? CupertinoColors.activeBlue
                                    : (isDark
                                        ? CupertinoColors.systemGrey
                                        : CupertinoColors.systemGrey2),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSelectedFriendsChips(bool isDark) {
    final selectedFriends = _allFriends
        .where((friend) => _selectedFriendIds.contains(friend.id))
        .toList();

    return selectedFriends.map((friend) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.activeBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CupertinoColors.activeBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Инициалы
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  friend.initials,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Имя
            Text(
              friend.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? CupertinoColors.white
                    : CupertinoColors.label,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(width: 4),
            // Кнопка удаления
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFriendIds.remove(friend.id);
                });
              },
              child: Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 16,
                color: isDark
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey2,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
