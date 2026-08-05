import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/google_auth_service.dart';

// Provider for the auth service instance
final authServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

// ──────────────────────────────────────────────
// Stream from Firebase Auth → converts to AppUser?
// This is the single source of truth for auth state.
// It reacts instantly when the user signs in or out.
// ──────────────────────────────────────────────
final authStreamProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.userStream;
});

// Convenience bool provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStreamProvider);
  return authState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

// ──────────────────────────────────────────────
// Keep the old StateNotifier for backward compatibility
// so existing sign-in/sign-out calls still work.
// ──────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final GoogleAuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    // Listen to Firebase Auth stream so UI always reflects current user
    _authService.userStream.listen(
      (user) => state = AsyncValue.data(user),
      onError: (e, st) => state = AsyncValue.error(e, st),
    );
  }

  Future<void> signIn() async {
    state = const AsyncValue.loading();
    try {
      final account = await _authService.signIn();
      state = AsyncValue.data(account);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
