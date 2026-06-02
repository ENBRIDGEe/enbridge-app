import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enbridge/core/supabase/supabase_client.dart';

class FocusTimerState {
  final int totalSeconds;
  final int remaining;
  final bool running;
  final bool sessionCompleted;

  const FocusTimerState({
    this.totalSeconds = 25 * 60,
    this.remaining = 25 * 60,
    this.running = false,
    this.sessionCompleted = false,
  });

  double get progress => remaining / totalSeconds;

  String get timeString {
    final m = (remaining ~/ 60).toString().padLeft(2, '0');
    final s = (remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  FocusTimerState copyWith({
    int? totalSeconds,
    int? remaining,
    bool? running,
    bool? sessionCompleted,
  }) =>
      FocusTimerState(
        totalSeconds: totalSeconds ?? this.totalSeconds,
        remaining: remaining ?? this.remaining,
        running: running ?? this.running,
        sessionCompleted: sessionCompleted ?? this.sessionCompleted,
      );
}

class FocusTimerNotifier extends Notifier<FocusTimerState> {
  Timer? _timer;

  @override
  FocusTimerState build() => const FocusTimerState();

  void start() {
    if (state.running) return;
    state = state.copyWith(running: true, sessionCompleted: false);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remaining > 0) {
        state = state.copyWith(remaining: state.remaining - 1);
      } else {
        _timer?.cancel();
        state = state.copyWith(running: false, sessionCompleted: true);
        _saveSession();
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(running: false);
  }

  void reset() {
    _timer?.cancel();
    state = state.copyWith(
      remaining: state.totalSeconds,
      running: false,
      sessionCompleted: false,
    );
  }

  void setDuration(int minutes) {
    _timer?.cancel();
    final secs = minutes * 60;
    state = FocusTimerState(totalSeconds: secs, remaining: secs);
  }

  void clearCompleted() {
    state = state.copyWith(sessionCompleted: false);
  }

  Future<void> _saveSession() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      await supabase.from('focus_sessions').insert({
        'user_id': userId,
        'session_duration_minutes': state.totalSeconds ~/ 60,
        'completed_at': DateTime.now().toIso8601String(),
        'date': DateTime.now().toIso8601String().split('T').first,
      });
    } catch (_) {}
  }
}

final focusTimerProvider =
    NotifierProvider<FocusTimerNotifier, FocusTimerState>(FocusTimerNotifier.new);
