import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repositories/repository_providers.dart';
import '../../core/utils/event_workout_utils.dart';
import '../../shared/models/event.dart';
import '../../shared/models/friend.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/bottom_navigation.dart';
import '../../shared/widgets/workout_calendar_widget.dart';
import '../../shared/widgets/recent_contacts_widget.dart';
import '../workout/add_workout_screen.dart';
import '../workout/view_workout_screen.dart';
import '../friends/friend_detail_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToCalendar;
  final VoidCallback? onNavigateToFriends;

  const HomeScreen({
    super.key,
    this.onNavigateToCalendar,
    this.onNavigateToFriends,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Friend> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final friendsRepo = ref.read(friendsRepositoryProvider);
    final friends = await friendsRepo.getFriends();
    if (mounted) setState(() => _friends = friends);
  }

  List<WorkoutItem> _getWorkoutsForToday(List<Event> events) {
    final today = DateTime.now();
    final dayEvents = events
        .where((e) {
          final d = e.dateLocal;
          return d.year == today.year && d.month == today.month && d.day == today.day;
        })
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return dayEvents
        .take(3)
        .map((e) => WorkoutItem(
              id: e.id,
              name: Event.getWorkoutNameDisplay(e.workoutName),
              time: e.dateLocal,
              participants: [e.senderDisplayName],
              status: eventStatusToWorkoutStatus(e.status),
            ))
        .toList();
  }

  Event? _findEventById(List<Event> events, String id) {
    try {
      return events.firstWhere((e) => e.id == id);
    } on StateError {
      return null;
    }
  }

  List<ContactItem> _getRecentContacts() {
    final sorted = List<Friend>.from(_friends)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return sorted
        .take(3)
        .map((f) => ContactItem(
              id: f.id,
              name: f.name,
              avatarInitials: f.initials,
              lastActivityDate: f.addedAt,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(eventsRealtimeSubscriptionProvider);
    ref.watch(eventsOfflineSyncProvider);
    final eventsAsync = ref.watch(eventsListProvider);
    final events = eventsAsync.value ?? [];

    final today = DateTime.now();
    final workoutItems = _getWorkoutsForToday(events);
    final contactItems = _getRecentContacts();

    return AppScaffold(
      title: 'Главная',
      onHomePressed: () {},
      onAddPressed: () => _showAddWorkoutModal(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            top: AppScaffold.kTopBarHeight + AppScaffold.kContentTopGap,
            bottom:
                kBottomNavContentHeight + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              WorkoutCalendarWidget(
                selectedDate: today,
                workouts: workoutItems,
                onTap: () => widget.onNavigateToCalendar?.call(),
                onWorkoutTap: (workoutItem) {
                  final event = _findEventById(events, workoutItem.id);
                  if (event != null) {
                    _showWorkoutView(context, event);
                  }
                },
              ),
              RecentContactsWidget(
                contacts: contactItems,
                onTap: () => widget.onNavigateToFriends?.call(),
                onContactTap: (contact) {
                  Friend? friend;
                  try {
                    friend =
                        _friends.firstWhere((f) => f.id == contact.id);
                  } on StateError {
                    friend = null;
                  }
                  if (friend != null) {
                    _showFriendDetailCard(context, friend);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddWorkoutModal(BuildContext context) {
    showCupertinoModalPopup<Event?>(
      context: context,
      builder: (context) => const AddWorkoutScreen(),
    ).then((event) {
      if (event != null) {
        ref.invalidate(eventsListProvider);
      }
    });
  }

  void _showWorkoutView(BuildContext context, Event event) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => ViewWorkoutScreen(event: event),
    ).then((_) {
      ref.invalidate(eventsListProvider);
    });
  }

  /// События, в которых участвовали я и этот друг: я организатор и друг приглашён, или друг организатор и я приглашён.
  List<Event> _getEventsForFriend(List<Event> events, Friend friend, String? currentUserId) {
    return events
        .where((e) {
          final iAmSender = currentUserId != null && e.sender == currentUserId;
          final friendIsRecipient = e.recipient == friend.id || e.recipients.contains(friend.id);
          final friendIsSender = e.sender == friend.id;
          final iAmRecipient = currentUserId != null && e.recipients.contains(currentUserId);
          return (iAmSender && friendIsRecipient) || (friendIsSender && iAmRecipient);
        })
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _showFriendDetailCard(BuildContext context, Friend friend) async {
    final currentUser = await ref.read(userRepositoryProvider).getCurrentUser();
    final events = ref.read(eventsListProvider).value ?? [];
    final friendEvents = _getEventsForFriend(events, friend, currentUser?.id).take(10).toList();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => FriendDetailCard(
        friend: friend,
        friendEvents: friendEvents,
        onInviteToWorkout: () {
          Navigator.pop(context);
          _showAddWorkoutModal(context);
        },
      ),
    ).then((_) => ref.invalidate(eventsListProvider));
  }
}
