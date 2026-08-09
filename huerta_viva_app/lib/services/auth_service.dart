import '../models/user.dart';

abstract class AuthService {
  Future<AppUser?> signInWithGoogle();
  Future<AppUser?> signInWithEmail(String email, String password);
  Future<AppUser?> registerWithEmail(String email, String password, String displayName);
  Future<void> signOut();
  Future<AppUser?> getCurrentUser();
  Stream<AppUser?> authStateChanges();
}

class MockAuthService implements AuthService {
  AppUser? _currentUser;

  @override
  Future<AppUser?> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _currentUser = const AppUser(
      uid: 'mock-uid-001',
      email: 'usuario@huertaviva.cl',
      displayName: 'María González',
      photoUrl: null,
      mode: AppMode.basic,
    );
    return _currentUser;
  }

  @override
  Future<AppUser?> signInWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = AppUser(
      uid: 'mock-${email.hashCode}',
      email: email,
      displayName: email.split('@').first,
      mode: AppMode.basic,
    );
    return _currentUser;
  }

  @override
  Future<AppUser?> registerWithEmail(String email, String password, String displayName) async {
    await Future.delayed(const Duration(milliseconds: 700));
    _currentUser = AppUser(
      uid: 'mock-${email.hashCode}',
      email: email,
      displayName: displayName.isNotEmpty ? displayName : email.split('@').first,
      mode: AppMode.basic,
    );
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return Stream.value(_currentUser);
  }
}
