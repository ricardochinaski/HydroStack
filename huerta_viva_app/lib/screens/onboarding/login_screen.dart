import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registrando = false;
  bool _verPassword = false;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(authProvider.notifier);
    if (_registrando) {
      await notifier.registerWithEmail(_email.text, _password.text, _nombre.text.trim());
    } else {
      await notifier.signInWithEmail(_email.text, _password.text);
    }
    _irSiAutenticado();
  }

  Future<void> _google() async {
    await ref.read(authProvider.notifier).signInWithGoogle();
    _irSiAutenticado();
  }

  void _irSiAutenticado() {
    final state = ref.read(authProvider);
    if (state.valueOrNull != null && mounted) context.go('/elegir-modo');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final cargando = authState.isLoading;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).scaffoldBackgroundColor, AppColors.profundoBg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 92, height: 92,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: AppColors.profundo.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(padding: const EdgeInsets.all(12), child: Image.asset('assets/images/app_icon.png')),
                  ),
                ),
                const SizedBox(height: 20),
                Text('HidroSmart', style: TextStyle(
                  fontFamily: 'Montserrat', fontSize: 30, fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5,
                )),
                const SizedBox(height: 6),
                Text('INTELIGENCIA LÍQUIDA', style: AppTypography.techLabel.copyWith(color: AppColors.circuit, letterSpacing: 2)),
                const SizedBox(height: 28),

                // Tabs Iniciar sesión / Crear cuenta
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      _tab('Iniciar sesión', !_registrando, () => setState(() => _registrando = false)),
                      _tab('Crear cuenta', _registrando, () => setState(() => _registrando = true)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_registrando) ...[
                        TextFormField(
                          controller: _nombre,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.mail_outline)),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: !_verPassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_verPassword ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setState(() => _verPassword = !_verPassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cargando ? null : _continuar,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: cargando
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_registrando ? 'Crear cuenta' : 'Entrar'),
                  ),
                ),

                if (authState.hasError) ...[
                  const SizedBox(height: 12),
                  Text(_mensajeError(authState.error), textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: AppColors.danger)),
                ],

                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('o', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))),
                  Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                ]),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: cargando ? null : _google,
                    icon: const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.profundo)),
                    label: const Text('Continuar con Google'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Tu huerta vertical hidropónica, siempre bajo control.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.profundo : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(
            fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600,
            color: active ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
          )),
        ),
      ),
    );
  }

  String _mensajeError(Object? e) {
    final s = e.toString();
    if (s.contains('wrong-password') || s.contains('invalid-credential')) return 'Correo o contraseña incorrectos.';
    if (s.contains('email-already-in-use')) return 'Ese correo ya está registrado.';
    if (s.contains('user-not-found')) return 'No existe una cuenta con ese correo.';
    if (s.contains('weak-password')) return 'La contraseña es muy débil.';
    if (s.contains('network')) return 'Sin conexión. Revisa tu internet.';
    return 'No se pudo completar. Intenta de nuevo.';
  }
}
