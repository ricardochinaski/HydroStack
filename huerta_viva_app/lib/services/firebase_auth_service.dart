import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import 'auth_service.dart';

/// Implementación real de autenticación con Firebase Auth.
/// Soporta correo/contraseña y Google. Crea/lee el perfil del usuario en
/// la colección `usuarios/{uid}` de Cloud Firestore.
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppMode _modeFromString(String? s) {
    switch (s) {
      case 'eco':
        return AppMode.eco;
      case 'pro':
        return AppMode.pro;
      default:
        return AppMode.basic;
    }
  }

  /// Convierte un usuario de Firebase en AppUser, leyendo el modo guardado.
  Future<AppUser> _toAppUser(User user) async {
    final doc = await _db.collection('usuarios').doc(user.uid).get();
    final data = doc.data();
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? data?['displayName'] ?? (user.email?.split('@').first ?? 'Usuario'),
      photoUrl: user.photoURL,
      mode: _modeFromString(data?['mode'] as String?),
    );
  }

  /// Crea el documento de perfil si no existe (al registrarse o primer login).
  Future<void> _ensureProfile(User user, {String? displayName}) async {
    final ref = _db.collection('usuarios').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName ?? user.displayName ?? (user.email?.split('@').first ?? 'Usuario'),
        'mode': 'basic',
        'creadoEn': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // cancelado por el usuario
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    await _ensureProfile(result.user!);
    return _toAppUser(result.user!);
  }

  @override
  Future<AppUser?> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    await _ensureProfile(result.user!);
    return _toAppUser(result.user!);
  }

  @override
  Future<AppUser?> registerWithEmail(String email, String password, String displayName) async {
    final result = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    if (displayName.isNotEmpty) {
      await result.user!.updateDisplayName(displayName);
    }
    await _ensureProfile(result.user!, displayName: displayName);
    return _toAppUser(result.user!);
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _toAppUser(user);
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _toAppUser(user);
    });
  }
}
