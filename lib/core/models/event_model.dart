/// Event data model for calendar screen.
class EventModel {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final DateTime? reminderAt;
  final bool hasReminder;
  final EventType type;
  final String? userId;

  const EventModel({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.reminderAt,
    this.hasReminder = false,
    this.type = EventType.general,
    this.userId,
  });

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? reminderAt,
    bool? hasReminder,
    EventType? type,
    String? userId,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      reminderAt: reminderAt ?? this.reminderAt,
      hasReminder: hasReminder ?? this.hasReminder,
      type: type ?? this.type,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'reminder_at': reminderAt?.toIso8601String(),
        'has_reminder': hasReminder,
        'type': type.name,
        'user_id': userId,
      };

  factory EventModel.fromMap(Map<String, dynamic> map) => EventModel(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        date: DateTime.parse(map['date'] as String),
        reminderAt: map['reminder_at'] != null
            ? DateTime.parse(map['reminder_at'] as String)
            : null,
        hasReminder: map['has_reminder'] as bool? ?? false,
        type: EventType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => EventType.general,
        ),
        userId: map['user_id'] as String?,
      );
}

enum EventType { general, task, habit, focus, reminder }

extension EventTypeX on EventType {
  String get label {
    switch (this) {
      case EventType.general:  return 'Event';
      case EventType.task:     return 'Task';
      case EventType.habit:    return 'Habit';
      case EventType.focus:    return 'Focus';
      case EventType.reminder: return 'Reminder';
    }
  }
}
