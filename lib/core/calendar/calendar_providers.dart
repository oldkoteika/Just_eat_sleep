import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'system_calendar_service.dart';

final systemCalendarServiceProvider = Provider<SystemCalendarService>((ref) {
  return SystemCalendarService();
});
