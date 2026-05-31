import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mock AIVA session model — represents a single AI chat session.
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

/// Riverpod state notifier for AIVA sessions.
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
    // Deactivate any existing active session
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

// ── Mock data ─────────────────────────────────────────────────────────────────

final _mockSessions = [
  AIVASession(
    id: '1',
    topic: 'Deep Work Strategy',
    summary: 'Discussed Cal Newport\'s deep work principles and built a personal schedule.',
    startedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
    endedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    messageCount: 18,
    isActive: false,
  ),
  AIVASession(
    id: '2',
    topic: 'Goal Setting for Q2',
    summary: 'Broke down quarterly goals into weekly milestones with SMART criteria.',
    startedAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
    endedAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
    messageCount: 32,
    isActive: false,
  ),
  AIVASession(
    id: '3',
    topic: 'Focus Session — Productivity',
    summary: 'Exploring why mornings are the best time for creative work.',
    startedAt: DateTime.now().subtract(const Duration(minutes: 20)),
    messageCount: 7,
    isActive: true,
  ),
];
