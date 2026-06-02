import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enbridge/core/services/nvidia_service.dart' show NvidiaService, ToolCall;
import 'package:enbridge/core/supabase/supabase_client.dart';
import 'package:enbridge/core/providers/calendar_provider.dart';
import 'package:enbridge/core/providers/focus_provider.dart';
import 'package:enbridge/core/models/event_model.dart';

// ── AIVA Session ──────────────────────────────────────────────────────────────

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
}

class AIVASessionNotifier extends Notifier<List<AIVASession>> {
  @override
  List<AIVASession> build() => _mockSessions;

  void startNewSession(String topic) {
    final newSession = AIVASession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      topic: topic,
      summary: 'New session started',
      startedAt: DateTime.now(),
      messageCount: 0,
      isActive: true,
    );
    state = [
      ...state.map((s) => s.isActive
          ? AIVASession(
              id: s.id,
              topic: s.topic,
              summary: s.summary,
              startedAt: s.startedAt,
              endedAt: DateTime.now(),
              messageCount: s.messageCount,
              isActive: false,
            )
          : s),
      newSession,
    ];
  }
}

final aivaSessionProvider =
    NotifierProvider<AIVASessionNotifier, List<AIVASession>>(
  AIVASessionNotifier.new,
);

final activeAIVASessionProvider = Provider<AIVASession?>((ref) {
  final sessions = ref.watch(aivaSessionProvider);
  try {
    return sessions.lastWhere((s) => s.isActive);
  } catch (_) {
    return null;
  }
});

// ── Chat message ──────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final bool isSystem; // action confirmation bubbles
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.isSystem = false,
    required this.timestamp,
  });
}

// ── Chat state ────────────────────────────────────────────────────────────────

class AivaChatState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final String? error;
  final String? navigateTo; // route AIVA wants to open (e.g. '/focus')

  const AivaChatState({
    this.messages = const [],
    this.isTyping = false,
    this.error,
    this.navigateTo,
  });

  AivaChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? error,
    String? navigateTo,
    bool clearNavigate = false,
  }) =>
      AivaChatState(
        messages: messages ?? this.messages,
        isTyping: isTyping ?? this.isTyping,
        error: error,
        navigateTo: clearNavigate ? null : (navigateTo ?? this.navigateTo),
      );
}


// ── Chat notifier ─────────────────────────────────────────────────────────────

class AivaChatNotifier extends Notifier<AivaChatState> {
  @override
  AivaChatState build() => const AivaChatState();

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
      error: null,
    );

    try {
      final context = await _buildUserContext();
      final result = await NvidiaService.instance.chat(
        [...state.messages],
        userContext: context,
      );

      // Execute any tool calls the model made
      final confirmations = await _executeToolCalls(result.toolCalls);

      final newMessages = <ChatMessage>[...state.messages];

      if (result.text.isNotEmpty) {
        newMessages.add(ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_ai',
          text: result.text,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }

      for (final c in confirmations) {
        newMessages.add(ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_sys_${confirmations.indexOf(c)}',
          text: c,
          isUser: false,
          isSystem: true,
          timestamp: DateTime.now(),
        ));
      }

      state = state.copyWith(messages: newMessages, isTyping: false);
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      String errorMsg;
      if (errStr.contains('xmlhttp') || errStr.contains('cors') ||
          errStr.contains('failed to fetch')) {
        errorMsg = 'Browser blocked the request (CORS). Deploy the edge function or run with --disable-web-security.';
      } else {
        errorMsg = 'AIVA: ${e.toString().split('\n').first}';
      }
      state = state.copyWith(isTyping: false, error: errorMsg);
    }
  }

  // ── Tool call dispatcher ────────────────────────────────────────────────────

  Future<List<String>> _executeToolCalls(List<ToolCall> calls) async {
    final confirmations = <String>[];
    for (final call in calls) {
      try {
        final a = call.arguments;
        switch (call.name) {
          case 'add_task':
            await _doAddTask(a, confirmations);
          case 'complete_task':
            await _doCompleteTask(a, confirmations);
          case 'delete_task':
            await _doDeleteTask(a, confirmations);
          case 'add_calendar_event':
            await _doAddEvent(a, confirmations);
          case 'add_habit':
            await _doAddHabit(a, confirmations);
          case 'start_focus_timer':
            _doStartFocus(a, confirmations);
          case 'stop_focus_timer':
            _doStopFocus(confirmations);
        }
      } catch (_) {}
    }
    return confirmations;
  }

  Future<void> _doAddTask(
      Map<String, dynamic> a, List<String> out) async {
    final title = a['title'] as String?;
    if (title == null || title.isEmpty) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase.from('tasks').insert({
      'user_id': userId,
      'title': title,
      'completed': false,
      if (a['due_date'] != null) 'due_date': a['due_date'],
    });
    final due = a['due_date'] != null ? ' (due ${a['due_date']})' : '';
    out.add('Task added: "$title"$due');
  }

  Future<void> _doCompleteTask(
      Map<String, dynamic> a, List<String> out) async {
    final title = a['title'] as String?;
    if (title == null) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase
        .from('tasks')
        .update({
          'completed': true,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .ilike('title', '%$title%');
    out.add('Task completed: "$title"');
  }

  Future<void> _doDeleteTask(
      Map<String, dynamic> a, List<String> out) async {
    final title = a['title'] as String?;
    if (title == null) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase
        .from('tasks')
        .delete()
        .eq('user_id', userId)
        .ilike('title', '%$title%');
    out.add('Task deleted: "$title"');
  }


  Future<void> _doAddEvent(
      Map<String, dynamic> a, List<String> out) async {
    final title = a['title'] as String?;
    final dateStr = a['date'] as String?;
    if (title == null || dateStr == null) return;

    final timeParts = ((a['time'] as String?) ?? '09:00').split(':');
    final hour = int.tryParse(timeParts[0]) ?? 9;
    final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;

    final baseDate = DateTime.tryParse(dateStr);
    if (baseDate == null) return;
    final eventDate =
        DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);

    final event = EventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: a['description'] as String?,
      date: eventDate,
      hasReminder: a['has_reminder'] as bool? ?? false,
      type: EventType.general,
      userId: null,
    );

    await ref.read(calendarProvider.notifier).addEvent(event);
    // Force fresh fetch so CalendarScreen shows the new event immediately
    ref.invalidate(calendarProvider);
    out.add('Event added: "$title" on $dateStr');
  }

  Future<void> _doAddHabit(
      Map<String, dynamic> a, List<String> out) async {
    final title = a['title'] as String?;
    if (title == null || title.isEmpty) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase.from('habits').insert({
      'user_id': userId,
      'title': title,
      'streak': 0,
    });
    out.add('Habit added: "$title"');
  }

  void _doStartFocus(Map<String, dynamic> a, List<String> out) {
    final mins = (a['duration_minutes'] as int?) ?? 25;
    ref.read(focusTimerProvider.notifier).setDuration(mins);
    ref.read(focusTimerProvider.notifier).start();
    out.add('Focus timer started: $mins min');
    // Navigate to Focus tab so the user sees the running timer
    state = state.copyWith(navigateTo: '/focus');
  }

  void _doStopFocus(List<String> out) {
    ref.read(focusTimerProvider.notifier).pause();
    out.add('Focus timer paused');
    state = state.copyWith(navigateTo: '/focus');
  }

  // ── User context builder ────────────────────────────────────────────────────

  Future<String> _buildUserContext() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return '';

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final nextWeek = today.add(const Duration(days: 7));
      final nextWeekStr =
          '${nextWeek.year}-${nextWeek.month.toString().padLeft(2, '0')}-${nextWeek.day.toString().padLeft(2, '0')}';

      final results = await Future.wait([
        supabase
            .from('tasks')
            .select('id,title,due_date')
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
            .select('name,streak')
            .eq('user_id', userId)
            .limit(10),
        supabase
            .from('calendar_events')
            .select('title,date,type')
            .eq('user_id', userId)
            .gte('date', '${todayStr}T00:00:00')
            .lte('date', '${nextWeekStr}T23:59:59')
            .order('date', ascending: true)
            .limit(10),
        supabase
            .from('focus_sessions')
            .select('session_duration_minutes')
            .eq('user_id', userId)
            .eq('date', todayStr),
        supabase
            .from('profiles')
            .select('full_name,username')
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
        (sum, s) => sum + ((s['session_duration_minutes'] as int?) ?? 0),
      );

      final timerState = ref.read(focusTimerProvider);

      final sb = StringBuffer();
      sb.writeln('--- LIVE USER DATA ---');
      sb.writeln('Date: $todayStr');

      if (profile != null) {
        final name = profile['full_name'] ?? profile['username'] ?? '';
        if (name.toString().isNotEmpty) sb.writeln('User: $name');
      }

      if (tasks.isNotEmpty) {
        sb.writeln('\nPending Tasks (${tasks.length}):');
        for (final t in tasks) {
          final due = t['due_date'] != null
              ? ' [due ${(t['due_date'] as String).split('T').first}]'
              : '';
          sb.writeln('  • [id:${t['id']}] ${t['title']}$due');
        }
      } else {
        sb.writeln('\nPending Tasks: none');
      }

      if (goals.isNotEmpty) {
        sb.writeln('\nActive Goals:');
        for (final g in goals) {
          final pct = g['progress'] != null ? ' — ${g['progress']}%' : '';
          sb.writeln('  • ${g['title']}$pct');
        }
      }

      if (habits.isNotEmpty) {
        sb.writeln('\nHabits:');
        for (final h in habits) {
          sb.writeln('  • ${h['name']} (${(h['streak'] as int?) ?? 0}-day streak)');
        }
      }

      if (events.isNotEmpty) {
        sb.writeln('\nUpcoming Events (next 7 days):');
        for (final e in events) {
          sb.writeln(
              '  • ${e['title']} on ${(e['date'] as String).split('T').first}');
        }
      }

      if (focusMinutes > 0) sb.writeln('\nFocus today: $focusMinutes min');

      if (timerState.running) {
        sb.writeln(
            'Focus timer: RUNNING — ${timerState.remaining ~/ 60} min remaining');
      } else if (timerState.remaining < timerState.totalSeconds) {
        sb.writeln('Focus timer: paused at ${timerState.timeString}');
      }

      sb.write('--- END ---');
      return sb.toString();
    } catch (_) {
      return '';
    }
  }

  void clearError() => state = state.copyWith(error: null);
  void clearNavigate() => state = state.copyWith(clearNavigate: true);
  void reset() => state = const AivaChatState();
}

final aivaChatProvider =
    NotifierProvider<AivaChatNotifier, AivaChatState>(AivaChatNotifier.new);

// ── Mock sessions ─────────────────────────────────────────────────────────────

final _mockSessions = [
  AIVASession(
    id: '1',
    topic: 'Deep Work Strategy',
    summary: 'Discussed Cal Newport\'s deep work principles.',
    startedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
    endedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    messageCount: 18,
    isActive: false,
  ),
  AIVASession(
    id: '2',
    topic: 'Goal Setting for Q2',
    summary: 'Broke down quarterly goals into weekly milestones.',
    startedAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
    endedAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
    messageCount: 32,
    isActive: false,
  ),
  AIVASession(
    id: '3',
    topic: 'Focus Session — Productivity',
    summary: 'Exploring why mornings are best for creative work.',
    startedAt: DateTime.now().subtract(const Duration(minutes: 20)),
    messageCount: 7,
    isActive: true,
  ),
];
