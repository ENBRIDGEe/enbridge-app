import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';

enum AuthStatus { loading, authenticated, unauthenticated, passwordRecovery }

final authStatusProvider = StreamProvider<AuthStatus>((ref) {
  return supabase.auth.onAuthStateChange.map((event) {
    // When user clicks password reset link → route to reset screen
    if (event.event == AuthChangeEvent.passwordRecovery) {
      return AuthStatus.passwordRecovery;
    }
    if (event.session != null) {
      return AuthStatus.authenticated;
    }
    return AuthStatus.unauthenticated;
  });
});

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    return supabase.auth.currentUser;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = AsyncData(response.user);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncLoading();
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      state = AsyncData(response.user);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await supabase.auth.signOut();
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);