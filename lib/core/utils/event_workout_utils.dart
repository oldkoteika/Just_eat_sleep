import '../../shared/models/event.dart';
import '../../shared/models/workout.dart';

/// Маппинг EventStatus -> WorkoutStatus для UI-виджетов (WorkoutItem, календарь).
/// Для организатора: зелёный (хотя бы 1 подтвердил), жёлтый (нет подтверждений), красный (все отменили).
WorkoutStatus eventStatusToWorkoutStatus(EventStatus status) {
  switch (status) {
    case EventStatus.pending:
      return WorkoutStatus.pending;
    case EventStatus.accepted:
      return WorkoutStatus.confirmed;
    case EventStatus.declined:
      return WorkoutStatus.declined;
    case EventStatus.completed:
      return WorkoutStatus.completed;
  }
}

/// Маппинг WorkoutType (форма добавления) -> WorkoutName (модель Event).
WorkoutName workoutNameFromWorkoutType(WorkoutType type) {
  switch (type) {
    case WorkoutType.legs:
      return WorkoutName.legs;
    case WorkoutType.shoulders:
      return WorkoutName.shoulders;
    case WorkoutType.chest:
      return WorkoutName.chest;
    case WorkoutType.back:
      return WorkoutName.back;
    case WorkoutType.arms:
      return WorkoutName.arms;
    case WorkoutType.other:
      return WorkoutName.other;
    case WorkoutType.general:
      return WorkoutName.cardio;
    case WorkoutType.abs:
      return WorkoutName.other;
  }
}
