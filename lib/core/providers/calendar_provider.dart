import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enbridge/core/models/event_model.dart';
import 'package:enbridge/core/services/notification_service.dart';
import 'package:enbridge/core/supabase/supabase_client.dart';

/// State notifier managing calendar events.
class CalendarNotifier extends AsyncNotifier<List<EventModel>> {
  @override
  Future<List<EventModel>> build() async {
    return _fetchEvents();
  }

  Future<List<EventModel>> _fetchEvents() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];
      final data = await supabase
          .from('calendar_events')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: true);
      return (data as List).map((e) => EventModel.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addEvent(EventModel event) async {
    state = const AsyncLoading();
    try {
      await supabase.from('calendar_events').insert(event.toMap());

      // Schedule reminder if needed
      if (event.hasReminder && event.reminderAt != null) {
        await NotificationService.instance.scheduleEventReminder(
          id: event.id.hashCode,
          title: '🔔 ${event.title}',
          body: event.description ?? 'Your event is coming up!',
          scheduledAt: event.reminderAt!,
        );
      }

      final updated = await _fetchEvents();
      state = AsyncData(updated);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await supabase.from('calendar_events').delete().eq('id', id);
      await NotificationService.instance.cancelReminder(id.hashCode);
      final updated = await _fetchEvents();
      state = AsyncData(updated);
    } catch (_) {}
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final data = await _fetchEvents();
    state = AsyncData(data);
  }
}

final calendarProvider =
    AsyncNotifierProvider<CalendarNotifier, List<EventModel>>(
  CalendarNotifier.new,
);

/// Returns events for a specific day.
final eventsForDayProvider = Provider.family<List<EventModel>, DateTime>((ref, day) {
  final eventsAsync = ref.watch(calendarProvider);
  return eventsAsync.whenOrNull(
        data: (events) => events.where((e) {
          return e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day;
        }).toList(),
      ) ??
      [];
});

/// Returns a map of day → event list for the calendar marker dots.
final eventMapProvider = Provider<Map<DateTime, List<EventModel>>>((ref) {
  final eventsAsync = ref.watch(calendarProvider);
  final events = eventsAsync.whenOrNull(data: (e) => e) ?? [];
  final map = <DateTime, List<EventModel>>{};
  for (final e in events) {
    final key = DateTime(e.date.year, e.date.month, e.date.day);
    map[key] = [...(map[key] ?? []), e];
  }
  return map;
});
