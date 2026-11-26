import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_store.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';

/// Pantalla de inicio de sesion de FITPRO con credenciales y huella dactilar (RF-01).
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authStore,
    required this.biometricService,
    required this.onAuthenticated,
  });

  final AuthStore authStore;
  final BiometricService biometricService;
  final ValueChanged<UserProfile> onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String _biometricStatus = 'Verifica tu identidad con huella o correo.';
  bool _biometricAvailable = true;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward();
    _prefillAndCheckBiometrics();
  }

  Future<void> _prefillAndCheckBiometrics() async {
    final lastEmail = await widget.authStore.getLastEmail();
    final bio = await widget.biometricService.checkAvailability();
    if (!mounted) return;
    setState(() {
      if (lastEmail != null && lastEmail.isNotEmpty) {
        _emailCtrl.text = lastEmail;
      }
      _biometricAvailable = bio.available;
      _biometricStatus = bio.statusText;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _showResultAlert({
    required bool success,
    required String title,
    required String message,
    VoidCallback? onContinue,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: FitPalette.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              success ? Icons.verified_user_rounded : Icons.error_outline_rounded,
              color: success ? FitPalette.green : FitPalette.heartRed,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onContinue?.call();
            },
            child: Text(success ? 'Entrar a FITPRO' : 'Intentar de nuevo'),
          ),
        ],
      ),
    );
  }

  Future<void> _loginWithCredentials() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final res = await widget.authStore.loginWithCredentials(
      _emailCtrl.text,
      _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.ok && res.user != null) {
      widget.onAuthenticated(res.user!);
    } else {
      await _showResultAlert(
        success: false,
        title: 'Acceso denegado',
        message: res.message,
      );
    }
  }

  Future<void> _loginWithBiometrics() async {
    setState(() => _loading = true);
    final result = await widget.biometricService.authenticate(
      reason: 'Escanea tu huella dactilar para ingresar a FITPRO',
    );
    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _loading = false;
        _biometricStatus = result.message;
      });
      await _showResultAlert(
        success: false,
        title: 'Fallo de autenticación biométrica',
        message: result.message,
      );
      return;
    }

    var user = await widget.authStore.getLastBiometricUser();
    if (user == null) {
      final created = await widget.authStore.register(
        name: 'Atleta FITPRO',
        email: 'atleta@fitpro.local',
        password: 'fitpro_bio_user',
        biometricEnabled: true,
      );
      user = created.user;
    } else {
      await widget.authStore.activateBiometricSession(user);
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (user != null) {
      final verifiedUser = user;
      await _showResultAlert(
        success: true,
        title: 'Autenticación exitosa',
        message: 'Huella dactilar verificada. Bienvenido a FITPRO, ${verifiedUser.name}.',
        onContinue: () => widget.onAuthenticated(verifiedUser),
      );
    }
  }

  Future<void> _openRegister() async {
    final createdUser = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterScreen(
          authStore: widget.authStore,
          biometricAvailable: _biometricAvailable,
        ),
      ),
    );
    if (createdUser != null && mounted) {
      widget.onAuthenticated(createdUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo FITPRO (Estilo azul neón / cian inspirado en la segunda foto)
                      Center(
                        child: ScaleTransition(
                          scale: _scaleAnim,
                          child: Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF00E5FF),
                                  Color(0xFF1976D2),
                                  Color(0xFF0D47A1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                                  blurRadius: 26,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/icon/icono2.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.directions_run_rounded,
                                  size: 44,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'FITPRO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Entrenamiento inteligente con sensores y GPS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: FitPalette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Tarjeta de formulario
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: FitPalette.surfaceDark,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: FitPalette.borderDark),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Correo electrónico',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (v) {
                                  final text = (v ?? '').trim();
                                  if (text.isEmpty || !text.contains('@')) {
                                    return 'Ingresa un correo válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if ((v ?? '').length < 4) {
                                    return 'Mínimo 4 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed:
                                    _loading ? null : _loginWithCredentials,
                                child: _loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Ingresar'),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      'o acceso rápido',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: FitPalette.textMuted,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed:
                                    _loading ? null : _loginWithBiometrics,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  side: BorderSide(color: accent),
                                  foregroundColor: accent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.fingerprint_rounded,
                                  size: 24,
                                ),
                                label: const Text(
                                  'Ingresar con huella dactilar',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _biometricStatus,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: _biometricAvailable
                                      ? FitPalette.textMuted
                                      : FitPalette.yellow,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '¿No tienes cuenta?',
                            style: TextStyle(color: FitPalette.textMuted),
                          ),
                          TextButton(
                            onPressed: _openRegister,
                            child: Text(
                              'Regístrate aquí',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
