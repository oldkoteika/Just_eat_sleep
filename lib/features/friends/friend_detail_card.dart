import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../shared/models/event.dart';
import '../../shared/models/friend.dart';
import '../../shared/widgets/avatar_with_initials.dart';
import '../workout/view_workout_screen.dart';
import 'edit_friend_screen.dart';

class FriendDetailCard extends StatelessWidget {
  final Friend friend;
  /// События (тренировки), в которых участвует этот друг.
  final List<Event> friendEvents;
  /// Вызывается при подтверждённом удалении; после вызова карточка закрывается.
  final Future<void> Function()? onDeleted;
  /// Быстрое приглашение на тренировку — закрывает карточку и открывает экран добавления тренировки с выбранным другом.
  final VoidCallback? onInviteToWorkout;

  const FriendDetailCard({
    super.key,
    required this.friend,
    this.friendEvents = const [],
    this.onDeleted,
    this.onInviteToWorkout,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Удалить друга?'),
        content: Text(
          '${friend.name} будет удалён из списка друзей.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await onDeleted?.call();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  void _openWorkoutDetails(BuildContext context, Event event) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => ViewWorkoutScreen(event: event),
    );
  }

  Color _getEventStatusColor(EventStatus status) {
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

  String _formatEventDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final workoutDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    if (workoutDate.isAtSameMomentAs(today)) {
      return 'Сегодня, $timeStr';
    } else if (workoutDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'Вчера, $timeStr';
    } else {
      final months = [
        'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
        'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
      ];
      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.systemGrey6;
    final cardBackgroundColor = isDark
        ? CupertinoColors.black
        : CupertinoColors.white;
    final textColor = isDark
        ? CupertinoColors.white
        : CupertinoColors.label;
    final secondaryTextColor = isDark
        ? CupertinoColors.systemGrey
        : CupertinoColors.systemGrey2;

    final friendWorkouts = friendEvents;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Верхняя панель с кнопками
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Кнопка закрыть (левая круглая)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: textColor,
                      size: 18,
                    ),
                  ),
                ),
                // Группа кнопок справа (редактировать/удалить)
                Row(
                  children: [
                    // Кнопка редактировать
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          final updatedFriend = await showCupertinoModalPopup<Friend>(
                            context: context,
                            builder: (context) => EditFriendScreen(friend: friend),
                          );
                          if (updatedFriend != null && context.mounted) {
                            Navigator.of(context).pop(updatedFriend);
                          }
                        },
                        child: Icon(
                          CupertinoIcons.pencil,
                          color: textColor,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Кнопка удалить
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _confirmDelete(context),
                        child: Icon(
                          CupertinoIcons.delete,
                          color: CupertinoColors.destructiveRed,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Контент карточки
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  // Аватар (как в профиле)
                  AvatarWithInitials(initials: friend.initials, size: 110),
                  const SizedBox(height: 16),
                  // ФИО
                  Text(
                    friend.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (onInviteToWorkout != null) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: CupertinoColors.activeBlue,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: onInviteToWorkout,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.calendar_badge_plus,
                              color: CupertinoColors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Пригласить на тренировку',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Заголовок истории тренировок
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'История тренировок',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Список тренировок
                  if (friendWorkouts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'Нет тренировок',
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    )
                  else
                    ...friendWorkouts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final event = entry.value;
                      final isLast = index == friendWorkouts.length - 1;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _openWorkoutDetails(context, event),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 6, right: 12),
                                    decoration: BoxDecoration(
                                      color: _getEventStatusColor(event.status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          Event.getWorkoutNameDisplay(event.workoutName),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: textColor,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatEventDate(event.dateLocal),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: secondaryTextColor,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                        ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Организатор: ${event.senderDisplayName}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: secondaryTextColor,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 16,
                                    color: secondaryTextColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: secondaryTextColor.withValues(alpha: 0.3),
                            ),
                        ],
                      );
                    }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
