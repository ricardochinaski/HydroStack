import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_init.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return firebaseReady ? FirebaseAuthService() : MockAuthService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.data(null));

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithEmail(email, password);
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> registerWithEmail(String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.registerWithEmail(email, password, displayName);
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> checkSession() async {
    final user = await _authService.getCurrentUser();
    state = AsyncValue.data(user);
  }
}
