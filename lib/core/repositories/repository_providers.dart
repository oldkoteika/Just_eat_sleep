import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../events/events_offline_service.dart';
import '../events/events_maintenance_service.dart';
import '../events/events_storage.dart';
import '../supabase/events_realtime_service.dart';
import 'abstract_events_repository.dart';
import 'abstract_friends_repository.dart';
import 'abstract_user_repository.dart';
import 'events_repository_impl.dart';
import 'friends_repository_impl.dart';
import 'user_repository_impl.dart';
import '../../shared/models/event.dart';

/// Провайдер репозитория пользователя. Реализация — локальная (Hive).
final userRepositoryProvider = Provider<AbstractUserRepository>((ref) {
  return UserRepositoryImpl();
});

/// Провайдер репозитория друзей. Реализация — локальная (Hive).
final friendsRepositoryProvider = Provider<AbstractFriendsRepository>((ref) {
  return FriendsRepositoryImpl();
});

/// Провайдер репозитория событий. Реализация — локальная (Hive).
final eventsRepositoryProvider = Provider<AbstractEventsRepository>((ref) {
  return EventsRepositoryImpl();
});

/// Список событий (локальное хранилище + синхронизация из Supabase при Realtime).
/// Перед загрузкой выполняется обработка завершённых тренировок (статус «выполнено» + планирование следующей при повторении).
/// Инвалидируется при подписке Realtime и после добавления/редактирования.
final eventsListProvider = FutureProvider.autoDispose<List<Event>>((ref) async {
  final repo = ref.watch(eventsRepositoryProvider);
  final user = await ref.read(userRepositoryProvider).getCurrentUser();
  if (user != null) {
    await EventsMaintenanceService.processEndedWorkouts(repo, user.id);
  }
  final events = await repo.getEvents();
  final dismissed = await EventsStorage.getDismissedEventIds();
  return events.where((e) => !dismissed.contains(e.id)).toList();
});

/// Запускает подписку Realtime на таблицу events при первом обращении;
/// при изменении данных в Supabase инвалидирует [eventsListProvider].
/// Отписывается при dispose провайдера.
final eventsRealtimeSubscriptionProvider = Provider<void>((ref) {
  ref.onDispose(() => EventsRealtimeService.unsubscribe());
  EventsRealtimeService.subscribe(() => ref.invalidate(eventsListProvider));
});

/// Слушает восстановление сети и обрабатывает очередь неотправленных операций.
final eventsOfflineSyncProvider = Provider<void>((ref) {
  StreamSubscription<List<ConnectivityResult>>? sub;
  var wasOffline = false;

  sub = Connectivity().onConnectivityChanged.listen((results) {
    final hasConnection = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
    if (wasOffline && hasConnection) {
      EventsOfflineService.processPendingOps().then((_) {
        ref.invalidate(eventsListProvider);
      });
    }
    wasOffline = !hasConnection;
  });

  Connectivity().checkConnectivity().then((results) {
    wasOffline = !results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  });

  ref.onDispose(() => sub?.cancel());
});
