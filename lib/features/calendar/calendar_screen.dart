import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../shared/models/event.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'workout_screen.dart';
import '../workout/add_workout_screen.dart';

class CalendarScreen extends StatefulWidget {
  final VoidCallback? onNavigateHome;

  const CalendarScreen({
    super.key,
    this.onNavigateHome,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final GlobalKey<WorkoutScreenState> _workoutScreenKey =
      GlobalKey<WorkoutScreenState>();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Тренировки',
      onHomePressed: widget.onNavigateHome,
      onAddPressed: () => _showAddWorkoutModal(context),
      body: WorkoutScreen(key: _workoutScreenKey),
    );
  }

  void _showAddWorkoutModal(BuildContext context) {
    showCupertinoModalPopup<Event?>(
      context: context,
      builder: (context) => const AddWorkoutScreen(),
    ).then((event) {
      if (event != null) {
        _workoutScreenKey.currentState?.refresh();
      }
    });
  }
}
