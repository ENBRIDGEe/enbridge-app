import 'dart:async';
import 'dart:convert';

import 'package:enbridge/core/models/aiva_chat_message.dart';
import 'package:enbridge/core/models/event_model.dart';
import 'package:enbridge/core/providers/calendar_provider.dart';
import 'package:enbridge/core/providers/focus_provider.dart';
import 'package:enbridge/core/services/nvidia_service.dart'
    show NvidiaService, ToolCall, ToolResultMessage;
import 'package:enbridge/core/supabase/supabase_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIVASession {
  final String id;
  final String topic;
  final String summary;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int messageCount;
  final bool isActive;

  const AIVASession({
    required this.id,
    required this.topic,
    required this.summary,
    required this.startedAt,
    this.endedAt,
    required this.messageCount,
    this.isActive = false,
  });

  Duration get duration => (endedAt ?? DateTime.now()).difference(startedAt);

  AIVASession copyWith({
    String? id,
    String? topic,
    String? summary,
    DateTime? startedAt,
    DateTime? endedAt,
    bool clearEndedAt = false,
    int? messageCount,
    bool? isActive,
  }) {
    return AIVASession(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      summary: summary ?? this.summary,
      startedAt: startedAt ?? this.startedAt,
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      messageCount: messageCount ?? this.messageCount,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'summary': summary,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'message_count': messageCount,
        'is_active': isActive,
      };

  factory AIVASession.fromJson(Map<String, dynamic> json) => AIVASession(
        id: json['id'] as String,
        topic: json['topic'] as String? ?? 'General Session',
        summary: json['summary'] as String? ?? 'AIVA is ready to help.',
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt: json['ended_at'] != null
            ? DateTime.parse(json['ended_at'] as String)
            : null,
        messageCount: json['message_count'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? false,
      );
}

class AIVASessionNotifier extends Notifier<List<AIVASession>> {
  static const _sessionsKey = 'aiva_sessions_v2';
  final Completer<void> _hydrated = Completer<void>();
  SharedPreferences? _prefs;

  @override
  List<AIVASession> build() {
    unawaited(_hydrate());
    return const [];
  }

  Future<void> _hydrate() async {
    if (_prefs != null) {
      if (!_hydrated.isCompleted) {
        _hydrated.complete();
      }
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      final raw = prefs.getString(_sessionsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        state = decoded
            .map((item) => AIVASession.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      state = const [];
    } finally {
      if (!_hydrated.isCompleted) {
        _hydrated.complete();
      }
    }
  }

  Future<void> _ensureHydrated() async {
    if (_hydrated.isCompleted) {
      return;
    }
    await _hydrated.future;
  }

  Future<SharedPreferences> _getPrefs() async {
    await _ensureHydrated();
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _persist() async {
    final prefs = await _getPrefs();
    final payload = jsonEncode(state.map((session) => session.toJson()).toList());
    await prefs.setString(_sessionsKey, payload);
  }

  Future<AIVASession> startNewSession(String topic) async {
    await _ensureHydrated();

    final now = DateTime.now();
    final normalizedTopic =
        topic.trim().isEmpty ? 'General Session' : topic.trim();

    final updatedSessions = state
        .map(
          (session) => session.isActive
              ? session.copyWith(
                  isActive: false,
                  endedAt: session.endedAt ?? now,
                )
              : session,
        )
        .toList();

    final newSession = AIVASession(
      id: now.microsecondsSinceEpoch.toString(),
      topic: normalizedTopic,
      summary: 'AIVA is ready to help.',
      startedAt: now,
      messageCount: 0,
      isActive: true,
    );

    state = [...updatedSessions, newSession];
    await _persist();
    return newSession;
  }

  Future<void> markSessionActive(String sessionId) async {
    await _ensureHydrated();

    final now = DateTime.now();
    bool changed = false;

    state = state.map((session) {
      if (session.id == sessionId) {
        changed = true;
        return session.copyWith(
          isActive: true,
          startedAt: session.isActive ? session.startedAt : now,
          clearEndedAt: true,
        );
      }
      if (session.isActive) {
        changed = true;
        return session.copyWith(
          isActive: false,
          endedAt: session.endedAt ?? now,
        );
      }
      return session;
    }).toList();

    if (changed) {
      await _persist();
    }
  }

  Future<void> recordSessionActivity(
    String sessionId,
    List<ChatMessage> messages,
  ) async {
    await _ensureHydrated();

    final summary = _buildSummary(messages);
    final messageCount = messages.where((message) => !message.isSystem).length;

    state = state.map((session) {
      if (session.id != sessionId) {
        return session;
      }
      return session.copyWith(
        summary: summary,
        messageCount: messageCount,
      );
    }).toList();

    await _persist();
  }

  String _buildSummary(List<ChatMessage> messages) {
    final conversational = messages
        .where((message) => !message.isSystem && message.text.trim().isNotEmpty)
        .toList();

    if (conversational.isEmpty) {
      return 'AIVA is ready to help.';
    }

    final assistantMessages =
        conversational.where((message) => !message.isUser).toList();
    final source = assistantMessages.isNotEmpty
        ? assistantMessages.last.text
        : conversational.last.text;
    final compact = source.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (compact.length <= 88) {
      return compact;
    }
    return '${compact.substring(0, 85)}...';
  }
}

final aivaSessionProvider =
    NotifierProvider<AIVASessionNotifier, List<AIVASession>>(
  AIVASessionNotifier.new,
);

final activeAIVASessionProvider = Provider<AIVASession?>((ref) {
  final sessions = ref.watch(aivaSessionProvider);
  try {
    return sessions.lastWhere((session) => session.isActive);
  } catch (_) {
    return null;
  }
});

class AivaChatState {
  final String? sessionId;
  final List<ChatMessage> messages;
  final bool isTyping;
  final bool isLoadingSession;
  final String? error;
  final String? navigateTo;

  const AivaChatState({
    this.sessionId,
    this.messages = const [],
    this.isTyping = false,
    this.isLoadingSession = false,
    this.error,
    this.navigateTo,
  });

  AivaChatState copyWith({
    String? sessionId,
    List<ChatMessage>? messages,
    bool? isTyping,
    bool? isLoadingSession,
    String? error,
    bool clearError = false,
    String? navigateTo,
    bool clearNavigate = false,
  }) {
    return AivaChatState(
      sessionId: sessionId ?? this.sessionId,
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      isLoadingSession: isLoadingSession ?? this.isLoadingSession,
      error: clearError ? null : (error ?? this.error),
      navigateTo: clearNavigate ? null : (navigateTo ?? this.navigateTo),
    );
  }
}

class _ToolExecutionResult {
  final String toolCallId;
  final String toolContent;
  final String confirmation;

  const _ToolExecutionResult({
    required this.toolCallId,
    required this.toolContent,
    required this.confirmation,
  });
}

class AivaChatNotifier extends Notifier<AivaChatState> {
  static const _messagesKeyPrefix = 'aiva_messages_v2_';
  SharedPreferences? _prefs;

  @override
  AivaChatState build() => const AivaChatState();

  Future<void> openSession(
    String sessionId, {
    required String topic,
  }) async {
    state = state.copyWith(
      sessionId: sessionId,
      messages: const [],
      isTyping: false,
      isLoadingSession: true,
      clearError: true,
      clearNavigate: true,
    );

    final storedMessages = await _loadMessages(sessionId);
    final messages = storedMessages.isEmpty
        ? [_buildWelcomeMessage(topic)]
        : storedMessages;

    if (storedMessages.isEmpty) {
      await _saveMessages(sessionId, messages);
    }

    await ref
        .read(aivaSessionProvider.notifier)
        .recordSessionActivity(sessionId, messages);

    state = state.copyWith(
      sessionId: sessionId,
      messages: messages,
      isTyping: false,
      isLoadingSession: false,
      clearError: true,
      clearNavigate: true,
    );
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    final sessionId = state.sessionId;

    if (trimmed.isEmpty || sessionId == null || state.isTyping) {
      return;
    }

    final userMessage = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final conversation = [...state.messages, userMessage];
    await ref.read(aivaSessionProvider.notifier).markSessionActive(sessionId);
    state = state.copyWith(
      messages: conversation,
      isTyping: true,
      clearError: true,
    );
    await _saveMessages(sessionId, conversation);
    await ref
        .read(aivaSessionProvider.notifier)
        .recordSessionActivity(sessionId, conversation);

    try {
      final userContext = await _buildUserContext();
      final result = await NvidiaService.instance.startChat(
        conversation,
        userContext: userContext,
      );

      final nextMessages = <ChatMessage>[...conversation];

      if (result.toolCalls.isEmpty) {
        if (result.text.isNotEmpty) {
          nextMessages.add(_assistantMessage(result.text));
        }
      } else {
        final executions = await _executeToolCalls(result.toolCalls);

        for (final execution in executions) {
          nextMessages.add(
            ChatMessage(
              id: '${DateTime.now().microsecondsSinceEpoch}_${execution.toolCallId}',
              text: execution.confirmation,
              isUser: false,
              isSystem: true,
              timestamp: DateTime.now(),
            ),
          );
        }

        String followUp = _buildFallbackToolReply(executions);
        if (result.assistantMessage != null) {
          try {
            final completion = await NvidiaService.instance.completeToolCalls(
              conversation,
              assistantMessage: result.assistantMessage!,
              toolResults: executions
                  .map(
                    (execution) => ToolResultMessage(
                      toolCallId: execution.toolCallId,
                      content: execution.toolContent,
                    ),
                  )
                  .toList(),
              userContext: userContext,
            );
            if (completion.trim().isNotEmpty) {
              followUp = completion.trim();
            }
          } catch (_) {
            // Keep the real tool confirmations even if the follow-up phrasing fails.
          }
        }

        if (followUp.isNotEmpty) {
          nextMessages.add(_assistantMessage(followUp));
        }
      }

      state = state.copyWith(
        messages: nextMessages,
        isTyping: false,
        clearError: true,
      );
      await _saveMessages(sessionId, nextMessages);
      await ref
          .read(aivaSessionProvider.notifier)
          .recordSessionActivity(sessionId, nextMessages);
    } catch (error) {
      state = state.copyWith(
        isTyping: false,
        error: _friendlyChatError(error),
      );
    }
  }

  Future<List<_ToolExecutionResult>> _executeToolCalls(List<ToolCall> calls) async {
    final results = <_ToolExecutionResult>[];

    for (final call in calls) {
      try {
        final confirmation = await _runToolCall(call);
        results.add(
          _ToolExecutionResult(
            toolCallId: call.id,
            toolContent: confirmation,
            confirmation: confirmation,
          ),
        );
      } catch (error) {
        final friendly = _friendlyToolError(call.name, error);
        results.add(
          _ToolExecutionResult(
            toolCallId: call.id,
            toolContent: 'Error: $friendly',
            confirmation: friendly,
          ),
        );
      }
    }

    return results;
  }

  Future<String> _runToolCall(ToolCall call) async {
    final arguments = call.arguments;

    switch (call.name) {
      case 'create_plan_items':
        return _doCreatePlanItems(arguments);
      case 'add_task':
        return _doAddTask(arguments);
      case 'update_task':
        return _doUpdateTask(arguments);
      case 'complete_task':
        return _doCompleteTask(arguments);
      case 'delete_task':
        return _doDeleteTask(arguments);
      case 'add_calendar_event':
        return _doAddEvent(arguments);
      case 'update_calendar_event':
        return _doUpdateEvent(arguments);
      case 'delete_calendar_event':
        return _doDeleteEvent(arguments);
      case 'add_habit':
        return _doAddHabit(arguments);
      case 'update_habit':
        return _doUpdateHabit(arguments);
      case 'delete_habit':
        return _doDeleteHabit(arguments);
      case 'start_focus_timer':
        return _doStartFocus(arguments);
      case 'stop_focus_timer':
        return _doStopFocus();
      default:
        throw Exception('Unsupported tool: ${call.name}');
    }
  }

  String _requireUserId() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not signed in');
    }
    return userId;
  }

  String? _nullableText(dynamic value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _normalizeDueDate(dynamic value) {
    final raw = _nullableText(value);
    if (raw == null) {
      return null;
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw Exception('Invalid task due date');
    }

    final normalized = raw.contains('T')
        ? parsed
        : DateTime(parsed.year, parsed.month, parsed.day, 9);
    return normalized.toIso8601String();
  }

  String? _normalizePriority(dynamic value) {
    final raw = _nullableText(value)?.toLowerCase();
    if (raw == null) {
      return null;
    }

    const allowed = {'low', 'medium', 'high', 'critical'};
    if (!allowed.contains(raw)) {
      throw Exception('Invalid priority "$raw"');
    }
    return raw;
  }

  List<Map<String, dynamic>> _rowsFrom(dynamic value) {
    return (value as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Map<String, dynamic> _pickBestTitleMatch(
    List<Map<String, dynamic>> rows,
    String query,
  ) {
    final loweredQuery = query.trim().toLowerCase();
    final sorted = [...rows];
    sorted.sort((a, b) {
      final aTitle = ((a['title'] as String?) ?? '').trim().toLowerCase();
      final bTitle = ((b['title'] as String?) ?? '').trim().toLowerCase();

      int score(String title) {
        if (title == loweredQuery) return 0;
        if (title.startsWith(loweredQuery)) return 1;
        if (title.contains(loweredQuery)) return 2;
        return 3;
      }

      final scoreCompare = score(aTitle).compareTo(score(bTitle));
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return aTitle.length.compareTo(bTitle.length);
    });
    return sorted.first;
  }

  Future<Map<String, dynamic>> _findSingleRecordByTitle({
    required String table,
    required String title,
    required String itemLabel,
  }) async {
    final userId = _requireUserId();
    final rows = _rowsFrom(
      await supabase
          .from(table)
          .select()
          .eq('user_id', userId)
          .ilike('title', '%${title.trim()}%')
          .limit(10),
    );

    if (rows.isEmpty) {
      throw Exception('No $itemLabel found matching "$title"');
    }

    return _pickBestTitleMatch(rows, title);
  }

  DateTime _resolveEventDateTime({
    required String? dateString,
    String? timeString,
    DateTime? fallback,
  }) {
    final base = dateString != null
        ? DateTime.tryParse(dateString)
        : fallback;
    if (base == null) {
      throw Exception('Invalid event date');
    }

    final parts = (timeString ?? '').split(':');
    final fallbackHour = fallback?.hour ?? 9;
    final fallbackMinute = fallback?.minute ?? 0;
    final hour = timeString == null || timeString.trim().isEmpty
        ? fallbackHour
        : (int.tryParse(parts[0]) ?? fallbackHour);
    final minute = timeString == null || timeString.trim().isEmpty
        ? fallbackMinute
        : (int.tryParse(parts.length > 1 ? parts[1] : '0') ?? fallbackMinute);

    return DateTime(base.year, base.month, base.day, hour, minute);
  }

  Future<void> _insertTask({
    required String userId,
    required String title,
    String? description,
    String? dueDate,
    String? category,
    String? priority,
  }) async {
    await supabase.from('tasks').insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'due_date': dueDate,
      'category': category,
      'priority': priority,
      'completed': false,
      'reminder': false,
    });
  }

  Future<void> _insertHabit({
    required String userId,
    required String title,
  }) async {
    await supabase.from('habits').insert({
      'user_id': userId,
      'title': title,
      'streak': 0,
    });
  }

  Future<String> _doCreatePlanItems(Map<String, dynamic> arguments) async {
    final userId = _requireUserId();
    final taskItems = arguments['tasks'];
    if (taskItems is! List<dynamic> || taskItems.isEmpty) {
      throw Exception('Plan tasks missing');
    }

    final createdTaskTitles = <String>[];
    final createdHabitTitles = <String>[];

    for (final rawTask in taskItems) {
      final task = Map<String, dynamic>.from(rawTask as Map);
      final title = _nullableText(task['title']);
      if (title == null) {
        throw Exception('Plan task title missing');
      }

      await _insertTask(
        userId: userId,
        title: title,
        description: _nullableText(task['description']),
        dueDate: _normalizeDueDate(task['due_date']),
        category: _nullableText(task['category']),
        priority: _normalizePriority(task['priority']),
      );
      createdTaskTitles.add(title);
    }

    final habitItems = arguments['habits'];
    if (habitItems is List<dynamic>) {
      for (final rawHabit in habitItems) {
        final habit = Map<String, dynamic>.from(rawHabit as Map);
        final title = _nullableText(habit['title']);
        if (title == null) {
          continue;
        }
        await _insertHabit(userId: userId, title: title);
        createdHabitTitles.add(title);
      }
    }

    final planTitle = _nullableText(arguments['plan_title']);
    final label = planTitle == null ? 'Plan created' : 'Plan created: "$planTitle"';
    final taskPart = '${createdTaskTitles.length} task${createdTaskTitles.length == 1 ? '' : 's'}';
    if (createdHabitTitles.isEmpty) {
      return '$label with $taskPart.';
    }

    final habitPart = '${createdHabitTitles.length} habit${createdHabitTitles.length == 1 ? '' : 's'}';
    return '$label with $taskPart and $habitPart.';
  }

  Future<String> _doAddTask(Map<String, dynamic> arguments) async {
    final title = _nullableText(arguments['title']);
    if (title == null) {
      throw Exception('Task title missing');
    }

    final userId = _requireUserId();
    final dueDate = _normalizeDueDate(arguments['due_date']);
    await _insertTask(
      userId: userId,
      title: title,
      description: _nullableText(arguments['description']),
      dueDate: dueDate,
      category: _nullableText(arguments['category']),
      priority: _normalizePriority(arguments['priority']),
    );

    final dueSuffix =
        dueDate == null ? '' : ' (due ${dueDate.split('T').first})';
    return 'Task added: "$title"$dueSuffix';
  }

  Future<String> _doUpdateTask(Map<String, dynamic> arguments) async {
    final matchTitle = _nullableText(arguments['match_title']);
    if (matchTitle == null) {
      throw Exception('Task match title missing');
    }

    final task = await _findSingleRecordByTitle(
      table: 'tasks',
      title: matchTitle,
      itemLabel: 'task',
    );

    final updates = <String, dynamic>{};
    if (_nullableText(arguments['new_title']) != null) {
      updates['title'] = _nullableText(arguments['new_title']);
    }
    if (arguments.containsKey('description')) {
      updates['description'] = _nullableText(arguments['description']);
    }
    if (arguments.containsKey('due_date')) {
      updates['due_date'] = _normalizeDueDate(arguments['due_date']);
    }
    if (arguments.containsKey('category')) {
      updates['category'] = _nullableText(arguments['category']);
    }
    if (arguments.containsKey('priority')) {
      updates['priority'] = _normalizePriority(arguments['priority']);
    }
    if (arguments['completed'] is bool) {
      final completed = arguments['completed'] as bool;
      updates['completed'] = completed;
      updates['completed_at'] = completed
          ? DateTime.now().toIso8601String()
          : null;
    }

    if (updates.isEmpty) {
      throw Exception('No task changes provided');
    }

    await supabase.from('tasks').update(updates).eq('id', task['id']);
    final updatedTitle =
        (updates['title'] as String?) ?? (task['title'] as String? ?? matchTitle);
    return 'Task updated: "$updatedTitle"';
  }

  Future<String> _doCompleteTask(Map<String, dynamic> arguments) async {
    final title = _nullableText(arguments['title']);
    if (title == null) {
      throw Exception('Task title missing');
    }

    final task = await _findSingleRecordByTitle(
      table: 'tasks',
      title: title,
      itemLabel: 'task',
    );

    await supabase
        .from('tasks')
        .update({
          'completed': true,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', task['id']);

    return 'Task completed: "${task['title']}"';
  }

  Future<String> _doDeleteTask(Map<String, dynamic> arguments) async {
    final title = _nullableText(arguments['title']);
    if (title == null) {
      throw Exception('Task title missing');
    }

    final task = await _findSingleRecordByTitle(
      table: 'tasks',
      title: title,
      itemLabel: 'task',
    );

    await supabase.from('tasks').delete().eq('id', task['id']);

    return 'Task deleted: "${task['title']}"';
  }

  Future<String> _doDeleteEvent(Map<String, dynamic> arguments) async {
    final title = _nullableText(arguments['title']);
    if (title == null) {
      throw Exception('Event title missing');
    }

    final event = await _findSingleRecordByTitle(
      table: 'calendar_events',
      title: title,
      itemLabel: 'event',
    );

    await supabase.from('calendar_events').delete().eq('id', event['id']);
    await ref.read(calendarProvider.notifier).refresh();

    return 'Event deleted: "${event['title']}"';
  }

  Future<String> _doAddEvent(Map<String, dynamic> arguments) async {
    final title = _nullableText(arguments['title']);
    final dateString = _nullableText(arguments['date']);
    if (title == null || dateString == null) {
      throw Exception('Event title or date missing');
    }

    final eventDate = _resolveEventDateTime(
      dateString: dateString,
      timeString: _nullableText(arguments['time']) ?? '09:00',
    );

    final event = EventModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      description: _nullableText(arguments['description']),
      date: eventDate,
      hasReminder: arguments['has_reminder'] as bool? ?? false,
      type: EventType.general,
      userId: null,
    );

    await ref.read(calendarProvider.notifier).addEvent(event);
    return 'Event added: "$title" on $dateString';
  }

  Future<String> _doUpdateEvent(Map<String, dynamic> arguments) async {
    final matchTitle = _nullableText(arguments['match_title']);
    if (matchTitle == null) {
      throw Exception('Event match title missing');
    }

    final event = await _findSingleRecordByTitle(
      table: 'calendar_events',
      title: matchTitle,
      itemLabel: 'event',
    );

    final existingDate = DateTime.tryParse(event['date'] as String? ?? '');
    final updates = <String, dynamic>{};
    if (_nullableText(arguments['new_title']) != null) {
      updates['title'] = _nullableText(arguments['new_title']);
    }
    if (arguments.containsKey('description')) {
      updates['description'] = _nullableText(arguments['description']);
    }
    if (arguments.containsKey('date') || arguments.containsKey('time')) {
      final updatedDate = _resolveEventDateTime(
        dateString: _nullableText(arguments['date']),
        timeString: _nullableText(arguments['time']),
        fallback: existingDate,
      );
      updates['date'] = updatedDate.toIso8601String();
    }

    if (updates.isEmpty) {
      throw Exception('No event changes provided');
    }

    await supabase.from('calendar_events').update(updates).eq('id', event['id']);
    await ref.read(calendarProvider.notifier).refresh();
    final updatedTitle =
        (updates['title'] as String?) ?? (event['title'] as String? ?? matchTitle);
    return 'Event updated: "$updatedTitle"';
  }

  Future<String> _doAddHabit(Map<String, dynamic> arguments) async {
    final title = _nullableText(arguments['title']);
    if (title == null) {
      throw Exception('Habit title missing');
    }

    final userId = _requireUserId();
    await _insertHabit(userId: userId, title: title);

    return 'Habit added: "$title"';
  }

  Future<String> _doUpdateHabit(Map<String, dynamic> arguments) async {
    final matchTitle = _nullableText(arguments['match_title']);
    if (matchTitle == null) {
      throw Exception('Habit match title missing');
    }

    final newTitle = _nullableText(arguments['new_title']);
    if (newTitle == null) {
      throw Exception('Habit new title missing');
    }

    final habit = await _findSingleRecordByTitle(
      table: 'habits',
      title: matchTitle,
      itemLabel: 'habit',
    );

    await supabase.from('habits').update({'title': newTitle}).eq('id', habit['id']);
    return 'Habit updated: "$newTitle"';
  }

  Future<String> _doDeleteHabit(Map<String, dynamic> arguments) async {
    final title = _nullableText(arguments['title']);
    if (title == null) {
      throw Exception('Habit title missing');
    }

    final habit = await _findSingleRecordByTitle(
      table: 'habits',
      title: title,
      itemLabel: 'habit',
    );

    await supabase.from('habit_logs').delete().eq('habit_id', habit['id']);
    await supabase.from('habits').delete().eq('id', habit['id']);
    return 'Habit deleted: "${habit['title']}"';
  }

  String _doStartFocus(Map<String, dynamic> arguments) {
    final minutes = (arguments['duration_minutes'] as int?) ?? 25;
    ref.read(focusTimerProvider.notifier).setDuration(minutes);
    ref.read(focusTimerProvider.notifier).start();
    state = state.copyWith(navigateTo: '/focus');
    return 'Focus timer started: $minutes min';
  }

  String _doStopFocus() {
    ref.read(focusTimerProvider.notifier).pause();
    state = state.copyWith(navigateTo: '/focus');
    return 'Focus timer paused';
  }

  Future<String> _buildUserContext() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        return '';
      }

      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final nextWeek = today.add(const Duration(days: 7));
      final nextWeekString =
          '${nextWeek.year}-${nextWeek.month.toString().padLeft(2, '0')}-${nextWeek.day.toString().padLeft(2, '0')}';

      final results = await Future.wait([
        supabase
            .from('tasks')
            .select('id,title,due_date,description,category,priority')
            .eq('user_id', userId)
            .eq('completed', false)
            .order('due_date', ascending: true)
            .limit(15),
        supabase
            .from('goals')
            .select('title,progress')
            .eq('user_id', userId)
            .eq('status', 'active')
            .limit(5),
        supabase
            .from('habits')
            .select('title,streak')
            .eq('user_id', userId)
            .limit(10),
        supabase
            .from('calendar_events')
            .select('title,date,type')
            .eq('user_id', userId)
            .gte('date', '${todayString}T00:00:00')
            .lte('date', '${nextWeekString}T23:59:59')
            .order('date', ascending: true)
            .limit(10),
        supabase
            .from('focus_sessions')
            .select('session_duration_minutes')
            .eq('user_id', userId)
            .eq('date', todayString),
        supabase
            .from('profiles')
            .select('name,avatar_url')
            .eq('id', userId)
            .maybeSingle(),
      ]);

      final tasks = results[0] as List<dynamic>;
      final goals = results[1] as List<dynamic>;
      final habits = results[2] as List<dynamic>;
      final events = results[3] as List<dynamic>;
      final focusSessions = results[4] as List<dynamic>;
      final profile = results[5] as Map<String, dynamic>?;

      final focusMinutes = focusSessions.fold<int>(
        0,
        (sum, session) =>
            sum + ((session['session_duration_minutes'] as int?) ?? 0),
      );

      final timerState = ref.read(focusTimerProvider);
      final buffer = StringBuffer()
        ..writeln('--- LIVE USER DATA ---')
        ..writeln('Date: $todayString');

      final profileName = profile?['name'] as String?;
      if (profileName != null && profileName.trim().isNotEmpty) {
        buffer.writeln('User: ${profileName.trim()}');
      }

      if (tasks.isEmpty) {
        buffer.writeln('\nPending Tasks: none');
      } else {
        buffer.writeln('\nPending Tasks (${tasks.length}):');
        for (final task in tasks) {
          final due = task['due_date'] != null
              ? ' [due ${(task['due_date'] as String).split('T').first}]'
              : '';
          final category = (task['category'] as String?)?.trim();
          final priority = (task['priority'] as String?)?.trim();
          final description = (task['description'] as String?)?.trim();
          final suffixes = <String>[
            if (category != null && category.isNotEmpty) category,
            if (priority != null && priority.isNotEmpty) priority,
          ];
          final meta = suffixes.isEmpty ? '' : ' {${suffixes.join(', ')}}';
          final detail = description == null || description.isEmpty
              ? ''
              : ' - ${description.length > 80 ? '${description.substring(0, 77)}...' : description}';
          buffer.writeln('  - [id:${task['id']}] ${task['title']}$due$meta$detail');
        }
      }

      if (goals.isNotEmpty) {
        buffer.writeln('\nActive Goals:');
        for (final goal in goals) {
          final progress = goal['progress'] != null ? ' - ${goal['progress']}%' : '';
          buffer.writeln('  - ${goal['title']}$progress');
        }
      }

      if (habits.isNotEmpty) {
        buffer.writeln('\nHabits:');
        for (final habit in habits) {
          buffer.writeln(
            '  - ${habit['title']} (${(habit['streak'] as int?) ?? 0}-day streak)',
          );
        }
      }

      if (events.isNotEmpty) {
        buffer.writeln('\nUpcoming Events (next 7 days):');
        for (final event in events) {
          buffer.writeln(
            '  - ${event['title']} on ${(event['date'] as String).split('T').first}',
          );
        }
      }

      if (focusMinutes > 0) {
        buffer.writeln('\nFocus today: $focusMinutes min');
      }

      if (timerState.running) {
        buffer.writeln(
          'Focus timer: RUNNING - ${timerState.remaining ~/ 60} min remaining',
        );
      } else if (timerState.remaining < timerState.totalSeconds) {
        buffer.writeln('Focus timer: paused at ${timerState.timeString}');
      }

      buffer.write('--- END ---');
      return buffer.toString();
    } catch (_) {
      return '';
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<ChatMessage>> _loadMessages(String sessionId) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString('$_messagesKeyPrefix$sessionId');
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveMessages(String sessionId, List<ChatMessage> messages) async {
    final prefs = await _getPrefs();
    final payload = jsonEncode(messages.map((message) => message.toJson()).toList());
    await prefs.setString('$_messagesKeyPrefix$sessionId', payload);
  }

  ChatMessage _buildWelcomeMessage(String topic) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text:
          'Hi, I\'m AIVA. I\'m ready to help with "$topic". Ask for a plan, a focus session, or help managing your tasks.',
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  ChatMessage _assistantMessage(String text) {
    return ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}_ai',
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  String _buildFallbackToolReply(List<_ToolExecutionResult> executions) {
    if (executions.isEmpty) {
      return 'I updated your workspace.';
    }

    if (executions.length == 1) {
      return executions.first.confirmation;
    }

    return executions.map((execution) => execution.confirmation).join('\n');
  }

  String _friendlyChatError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('failed to fetch') ||
        text.contains('network') ||
        text.contains('socket')) {
      return 'AIVA could not reach the server. Please check the connection and try again.';
    }
    if (text.contains('function') || text.contains('edge')) {
      return 'AIVA is temporarily unavailable. Please verify the Supabase edge function and try again.';
    }
    return 'AIVA: ${error.toString().split('\n').first}';
  }

  String _friendlyToolError(String toolName, Object error) {
    final prefix = switch (toolName) {
      'create_plan_items' => 'I could not create that plan.',
      'add_task' => 'I could not add that task.',
      'update_task' => 'I could not update that task.',
      'complete_task' => 'I could not complete that task.',
      'delete_task' => 'I could not delete that task.',
      'add_calendar_event' => 'I could not add that event.',
      'update_calendar_event' => 'I could not update that event.',
      'delete_calendar_event' => 'I could not delete that event.',
      'add_habit' => 'I could not add that habit.',
      'update_habit' => 'I could not update that habit.',
      'delete_habit' => 'I could not delete that habit.',
      'start_focus_timer' => 'I could not start the focus timer.',
      'stop_focus_timer' => 'I could not pause the focus timer.',
      _ => 'I could not finish that action.',
    };
    final detail = error.toString().split('\n').first;
    return '$prefix $detail';
  }

  void clearError() => state = state.copyWith(clearError: true);

  void clearNavigate() => state = state.copyWith(clearNavigate: true);
}

final aivaChatProvider =
    NotifierProvider<AivaChatNotifier, AivaChatState>(AivaChatNotifier.new);
