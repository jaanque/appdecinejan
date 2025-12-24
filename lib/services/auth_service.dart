import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream of auth state changes
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  // Current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Sign Up with Email and Password
  /// Returns null if successful but email verification is required.
  /// Returns Session if successful and auto-confirmed.
  /// Throws AuthException on failure.
  Future<Session?> signUp({
    required String email,
    required String password,
    String? emailRedirectTo,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: emailRedirectTo,
      );

      // If auto-confirm is enabled, session might be available immediately
      if (response.session != null) {
        return response.session;
      }

      // If session is null, it usually means email verification is required
      return null;
    } catch (e) {
      // Re-throw to be handled by the UI
      rethrow;
    }
  }

  /// Sign In with Email and Password
  Future<Session> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.session == null) {
       throw const AuthException('Error signing in: Could not obtain session.');
    }

    return response.session!;
  }

  /// Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Send Password Reset Email
  Future<void> resetPasswordForEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}
