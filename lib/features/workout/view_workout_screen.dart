import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/calendar/calendar_providers.dart';
import '../../core/calendar/system_calendar_service.dart';
import '../../core/events/events_storage.dart';
import '../../core/friends/friends_storage.dart';
import '../../core/repositories/repository_providers.dart';
import '../../shared/models/event.dart';
import '../../shared/models/friend.dart';
import '../../shared/models/workout.dart';

class ViewWorkoutScreen extends ConsumerStatefulWidget {
  final Event event;

  const ViewWorkoutScreen({
    super.key,
    required this.event,
  });

  @override
  ConsumerState<ViewWorkoutScreen> createState() => _ViewWorkoutScreenState();
}

class _ViewWorkoutScreenState extends ConsumerState<ViewWorkoutScreen> {
  int _reminderMinutes = 0;
  String? _currentUserId;
  Map<String, String> _recipientNames = {};

  @override
  void initState() {
    super.initState();
    _reminderMinutes = widget.event.reminderTime;
    _loadCurrentUserAndFriends();
  }

  Future<void> _loadCurrentUserAndFriends() async {
    final user = await ref.read(userRepositoryProvider).getCurrentUser();
    final friends = await ref.read(friendsRepositoryProvider).getFriends();
    if (!mounted) return;
    final names = <String, String>{};
    for (final f in friends) {
      if (widget.event.recipients.contains(f.id)) names[f.id] = f.name;
    }
    setState(() {
      _currentUserId = user?.id;
      _recipientNames = names;
    });
  }

  void _close() {
    Navigator.of(context).pop();
  }

  Future<void> _deleteWorkout() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Удалить тренировку?'),
        content: const Text(
            'Вы уверены, что хотите удалить эту тренировку?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(eventsRepositoryProvider).removeEvent(widget.event.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  /// Удаление приглашённым: из списка локально скрывается, на сервере — статус «отклонено».
  Future<void> _deleteWorkoutAsRecipient() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Удалить тренировку?'),
        content: const Text(
          'Тренировка будет удалена из вашего списка. Для организатора будет отмечена как отклонённая.',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final uid = _currentUserId;
    if (uid == null) return;
    final updated = Map<String, EventStatus>.from(widget.event.recipientResponses)
      ..[uid] = EventStatus.declined;
    final newReasons = Map<String, String>.from(widget.event.recipientDeclineReasons)
      ..[uid] = 'Удалено из списка';
    final newStatus = _statusFromResponses(updated);
    await ref.read(eventsRepositoryProvider).updateEvent(
          widget.event.copyWith(
            recipientResponses: updated,
            recipientDeclineReasons: newReasons,
            status: newStatus,
          ),
        );
    await EventsStorage.addDismissedEventId(widget.event.id);
    if (!mounted) return;
    ref.invalidate(eventsListProvider);
    Navigator.of(context).pop(true);
  }

  Future<void> _addToCalendar() async {
    final service = ref.read(systemCalendarServiceProvider);
    final result = await service.addWorkoutToCalendar(widget.event);
    if (!mounted) return;
    switch (result) {
      case CalendarAddResult.success:
        await ref.read(eventsRepositoryProvider).updateEvent(
              widget.event.copyWith(addedToCalendar: true),
            );
        if (!mounted) return;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Добавлено'),
            content: const Text(
                'Тренировка добавлена в системный календарь. При отмене события удалите его из календаря вручную.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(context),
                child: const Text('ОК'),
              ),
            ],
          ),
        );
        break;
      case CalendarAddResult.permissionDenied:
        _showPermissionDeniedDialog();
        break;
      case CalendarAddResult.cancelled:
        // Пользователь закрыл нативный экран без сохранения — ничего не делаем
        break;
      case CalendarAddResult.error:
        _showCalendarErrorDialog();
        break;
    }
  }

  void _showPermissionDeniedDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Нет доступа к календарю'),
        content: const Text(
            'Разрешите доступ к календарю в настройках, чтобы добавлять тренировки.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Настройки'),
          ),
        ],
      ),
    );
  }

  void _showCalendarErrorDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Ошибка'),
        content: const Text(
            'Не удалось добавить тренировку в календарь. Проверьте разрешения в настройках.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmWorkout() async {
    final uid = _currentUserId;
    if (uid == null) return;
    // При принятии приглашения добавляем отправителя в друзья локально, если его ещё нет.
    final friends = await ref.read(friendsRepositoryProvider).getFriends();
    final senderInFriends = friends.any((f) => f.id == widget.event.sender);
    if (!senderInFriends) {
      final inviterAsFriend = Friend(
        id: widget.event.sender,
        name: widget.event.senderDisplayName,
        addedAt: DateTime.now(),
      );
      await FriendsStorage.addFriend(inviterAsFriend);
    }
    final updated = Map<String, EventStatus>.from(widget.event.recipientResponses)
      ..[uid] = EventStatus.accepted;
    final newStatus = _statusFromResponses(updated);
    await ref.read(eventsRepositoryProvider).updateEvent(
          widget.event.copyWith(
            recipientResponses: updated,
            status: newStatus,
          ),
        );
    if (mounted) Navigator.of(context).pop(true);
  }

  /// Можно отменить запланированную тренировку не позднее чем за час до начала.
  bool _canCancelPlannedWorkout(Event event) {
    final now = DateTime.now();
    final start = event.dateLocal;
    return start.difference(now) > const Duration(hours: 1);
  }

  /// Тренировка прошедшая (уже прошла по времени или помечена completed).
  bool _isPastWorkout(Event event) {
    if (event.status == EventStatus.completed) return true;
    final end = event.dateLocal.add(Duration(minutes: event.duration));
    return end.isBefore(DateTime.now()) || end.isAtSameMomentAs(DateTime.now());
  }

  /// Тренировка подтверждена (хотя бы один принял).
  bool _isConfirmedWorkout(Event event) => event.status == EventStatus.accepted;

  void _cancelWorkout() {
    _showCancelDialog(isOrganizerCancel: false);
  }

  void _cancelWorkoutAsOrganizer() {
    _showCancelDialog(isOrganizerCancel: true);
  }

  void _showCancelDialog({bool isOrganizerCancel = false}) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _CancelWorkoutDialog(
        addedToCalendar: widget.event.addedToCalendar,
        isOrganizerCancel: isOrganizerCancel,
        onReasonSelected: (reason) async {
          if (isOrganizerCancel) {
            await ref.read(eventsRepositoryProvider).removeEvent(widget.event.id);
          } else {
            final uid = _currentUserId;
            if (uid != null) {
              final updated = Map<String, EventStatus>.from(widget.event.recipientResponses)
                ..[uid] = EventStatus.declined;
              final newReasons = Map<String, String>.from(widget.event.recipientDeclineReasons)
                ..[uid] = reason;
              final newStatus = _statusFromResponses(updated);
              await ref.read(eventsRepositoryProvider).updateEvent(
                    widget.event.copyWith(
                      recipientResponses: updated,
                      recipientDeclineReasons: newReasons,
                      status: newStatus,
                    ),
                  );
            }
          }
          if (context.mounted) Navigator.pop(context);
          if (context.mounted) Navigator.pop(context, true);
        },
      ),
    );
  }

  Color _getStatusColor(EventStatus status) {
    switch (status) {
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

  String _formatReminder(int minutes) {
    if (minutes <= 0) return 'Нет';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) {
      return 'За $hours ч. $mins мин.';
    } else if (hours > 0) {
      return 'За $hours ч.';
    } else {
      return 'За $mins мин.';
    }
  }

  String _getRepeatDisplayName(String repeat) {
    final e = WorkoutRepeat.values.asNameMap()[repeat];
    return e != null ? Workout.getRepeatName(e) : repeat;
  }

  String _getMonthName(int month) {
    const months = [
      'Января', 'Февраля', 'Марта', 'Апреля', 'Мая', 'Июня',
      'Июля', 'Августа', 'Сентября', 'Октября', 'Ноября', 'Декабря',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? CupertinoColors.systemBackground.darkColor
        : CupertinoColors.systemBackground;
    final event = widget.event;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLeftButton(isDark),
                  _buildRightButtons(isDark, event),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContextualIsland(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Наименование',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? CupertinoColors.systemGrey
                                    : CupertinoColors.systemGrey2,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              Event.getWorkoutNameDisplay(event.workoutName),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.label,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (event.description != null &&
                          event.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildContextualIsland(
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Описание',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? CupertinoColors.systemGrey
                                      : CupertinoColors.systemGrey2,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                event.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? CupertinoColors.white
                                      : CupertinoColors.label,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildContextualIsland(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              isDark: isDark,
                              label: 'Начало',
                              value:
                                  '${event.dateLocal.day} ${_getMonthName(event.dateLocal.month)} ${event.dateLocal.year}, '
                                  '${event.dateLocal.hour.toString().padLeft(2, '0')}:${event.dateLocal.minute.toString().padLeft(2, '0')}',
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              isDark: isDark,
                              label: 'Продолжительность',
                              value: _formatDuration(event.duration),
                            ),
                            if (event.repeat != null && event.repeat != 'never') ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                isDark: isDark,
                                label: 'Повтор',
                                value: _getRepeatDisplayName(event.repeat!),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildContextualIsland(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Уведомление',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? CupertinoColors.systemGrey
                                    : CupertinoColors.systemGrey2,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _formatReminder(_reminderMinutes),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.label,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildContextualIsland(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Организатор',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? CupertinoColors.systemGrey
                                    : CupertinoColors.systemGrey2,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 12),
                                Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.activeBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      event.senderDisplayName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  event.senderDisplayName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? CupertinoColors.white
                                        : CupertinoColors.label,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (event.hasRecipients &&
                          _currentUserId == event.sender) ...[
                        const SizedBox(height: 16),
                        _buildContextualIsland(
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Приглашённые',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? CupertinoColors.systemGrey
                                      : CupertinoColors.systemGrey2,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...event.recipients.map((recipientId) {
                                final name = _recipientNames[recipientId]?.trim().isNotEmpty == true
                                    ? _recipientNames[recipientId]!
                                    : 'Участник';
                                final status = event.recipientResponses[recipientId] ?? EventStatus.pending;
                                final statusColor = _getStatusColor(status);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDark
                                                    ? CupertinoColors.white
                                                    : CupertinoColors.label,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                            if (status == EventStatus.declined) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                event.recipientDeclineReasons[recipientId] ?? '',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? CupertinoColors.systemGrey
                                                      : CupertinoColors.systemGrey2,
                                                  decoration: TextDecoration.none,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _recipientStatusText(status),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: statusColor,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftButton(bool isDark) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _close,
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
    );
  }

  Widget _buildRightButtons(bool isDark, Event event) {
    final uid = _currentUserId;
    if (uid == null) return const SizedBox(width: 32);

    final isPast = _isPastWorkout(event);
    final isConfirmed = _isConfirmedWorkout(event);
    final canCancel = _canCancelPlannedWorkout(event);

    // Прошедшая тренировка — кнопок нет ни у организатора, ни у приглашённого.
    if (isPast) return const SizedBox(width: 32);

    // Организатор
    if (uid == event.sender) {
      // Не подтверждённая: только «Удалить».
      if (!isConfirmed) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _deleteWorkout,
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
                  CupertinoIcons.delete,
                  size: 18,
                  color: CupertinoColors.systemRed,
                ),
              ),
            ),
          ],
        );
      }
      // Подтверждённая: «Отклонить», «Удалить», «Добавить в календарь».
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canCancel)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _cancelWorkoutAsOrganizer,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? CupertinoColors.systemRed.darkColor
                      : CupertinoColors.systemRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.hand_thumbsdown,
                  size: 18,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          if (canCancel) const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _deleteWorkout,
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
                CupertinoIcons.delete,
                size: 18,
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: event.addedToCalendar ? null : _addToCalendar,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: event.addedToCalendar
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.activeBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.calendar_badge_plus,
                size: 18,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ],
      );
    }

    // Приглашённый
    if (event.recipients.contains(uid)) {
      final myResponse = event.recipientResponses[uid] ?? EventStatus.pending;
      // Не подтверждённая: только «Отклонить» и «Подтвердить».
      if (!isConfirmed) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (myResponse != EventStatus.declined)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _cancelWorkout,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? CupertinoColors.systemRed.darkColor
                        : CupertinoColors.systemRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.hand_thumbsdown,
                    size: 18,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            if (myResponse != EventStatus.declined) const SizedBox(width: 8),
            if (myResponse == EventStatus.pending)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _confirmWorkout,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? CupertinoColors.systemGreen.darkColor
                        : CupertinoColors.systemGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.hand_thumbsup,
                    size: 18,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
          ],
        );
      }
      // Подтверждённая: «Отклонить», «Удалить», «Добавить в календарь».
      final showDecline = myResponse != EventStatus.declined &&
          (myResponse == EventStatus.pending || (myResponse == EventStatus.accepted && canCancel));
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDecline) ...[
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _cancelWorkout,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? CupertinoColors.systemRed.darkColor
                      : CupertinoColors.systemRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.hand_thumbsdown,
                  size: 18,
                  color: CupertinoColors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _deleteWorkoutAsRecipient,
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
                CupertinoIcons.delete,
                size: 18,
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: event.addedToCalendar ? null : _addToCalendar,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: event.addedToCalendar
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.activeBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.calendar_badge_plus,
                size: 18,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox(width: 32);
  }

  /// Общий статус события по ответам получателей: при первом accepted — accepted,
  /// если все ответили и все declined — declined, иначе pending.
  EventStatus _statusFromResponses(Map<String, EventStatus> responses) {
    if (responses.values.any((s) => s == EventStatus.accepted)) {
      return EventStatus.accepted;
    }
    final recipients = widget.event.recipients;
    if (recipients.isEmpty) return EventStatus.pending;
    final allResponded = recipients.every((id) {
      final s = responses[id];
      return s == EventStatus.accepted || s == EventStatus.declined;
    });
    return allResponded ? EventStatus.declined : EventStatus.pending;
  }

  String _recipientStatusText(EventStatus status) {
    switch (status) {
      case EventStatus.pending:
        return 'Ожидает';
      case EventStatus.accepted:
        return 'Подтверждён';
      case EventStatus.declined:
        return 'Отклонён';
      case EventStatus.completed:
        return 'Завершён';
    }
  }

  Widget _buildContextualIsland({
    required bool isDark,
    required Widget child,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.systemGrey6.darkColor
              : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }

  Widget _buildInfoRow({
    required bool isDark,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey2,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? CupertinoColors.white
                : CupertinoColors.label,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}

class _CancelWorkoutDialog extends StatefulWidget {
  final bool addedToCalendar;
  final bool isOrganizerCancel;
  final Future<void> Function(String reason) onReasonSelected;

  const _CancelWorkoutDialog({
    this.addedToCalendar = false,
    this.isOrganizerCancel = false,
    required this.onReasonSelected,
  });

  @override
  State<_CancelWorkoutDialog> createState() => _CancelWorkoutDialogState();
}

class _CancelWorkoutDialogState extends State<_CancelWorkoutDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isCustomReason = false;

  static const _months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  void _showReschedulePicker() {
    final now = DateTime.now();
    DateTime selectedDate = now;
    int hour = now.hour;
    int minute = now.minute;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark
              ? CupertinoColors.systemBackground.darkColor
              : CupertinoColors.systemBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Отмена'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                CupertinoButton(
                  child: const Text('Готово'),
                  onPressed: () {
                    final reason =
                        'Перенести на ${selectedDate.day} ${_months[selectedDate.month - 1]} в '
                        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                    Navigator.pop(ctx);
                    widget.onReasonSelected(reason);
                  },
                ),
              ],
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: selectedDate,
                      minimumDate: now,
                      onDateTimeChanged: (d) => selectedDate = d,
                    ),
                  ),
                  Expanded(
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration:
                          Duration(hours: hour, minutes: minute),
                      onTimerDurationChanged: (d) {
                        hour = d.inHours;
                        minute = d.inMinutes % 60;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Отменить тренировку?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? CupertinoColors.white
                      : CupertinoColors.label,
                  decoration: TextDecoration.none,
                ),
              ),
              if (widget.isOrganizerCancel) ...[
                const SizedBox(height: 12),
                Text(
                  'Тренировка будет отменена для всех приглашённых.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
              if (widget.addedToCalendar) ...[
                const SizedBox(height: 12),
                Text(
                  'Если событие было добавлено в календарь — удалите его вручную в приложении «Календарь».',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (!_isCustomReason) ...[
                _buildReasonOption(
                  isDark: isDark,
                  text: 'Не могу прийти',
                  onTap: () => widget.onReasonSelected('Не могу прийти'),
                ),
                const SizedBox(height: 12),
                _buildReasonOption(
                  isDark: isDark,
                  text: 'Перенести на другое время',
                  onTap: _showReschedulePicker,
                ),
                const SizedBox(height: 12),
                _buildReasonOption(
                  isDark: isDark,
                  text: 'Другая причина',
                  onTap: () => setState(() => _isCustomReason = true),
                ),
              ] else if (_isCustomReason) ...[
                CupertinoTextField(
                  controller: _reasonController,
                  placeholder: 'Введите причину',
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
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Назад'),
                      onPressed: () =>
                          setState(() => _isCustomReason = false),
                    ),
                    CupertinoButton(
                      child: const Text('Отменить'),
                      onPressed: () {
                        widget.onReasonSelected(_reasonController.text.isEmpty
                            ? 'Другая причина'
                            : _reasonController.text);
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonOption({
    required bool isDark,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
              text,
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? CupertinoColors.white
                    : CupertinoColors.label,
                decoration: TextDecoration.none,
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
}
