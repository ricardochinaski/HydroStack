/// Modelo de hardware de la huerta (tier de equipamiento).
/// - basic: sin sensores, solo bomba circuladora.
/// - eco: sensores básicos (pH, temperatura, nivel), sin dosificación.
/// - pro: todos los sensores + dosificación automática de nutrientes.
enum AppMode { basic, eco, pro }

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final AppMode mode;
  final bool esp32Connected;
  final String? esp32Id;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.photoUrl,
    this.mode = AppMode.basic,
    this.esp32Connected = false,
    this.esp32Id,
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    AppMode? mode,
    bool? esp32Connected,
    String? esp32Id,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      mode: mode ?? this.mode,
      esp32Connected: esp32Connected ?? this.esp32Connected,
      esp32Id: esp32Id ?? this.esp32Id,
    );
  }
}
