import 'package:flutter/material.dart';

import '../services/auth_store.dart';
import '../theme/app_theme.dart';

/// Pantalla de registro de usuario para FIT_PRO con metas fisicas y biometria.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.authStore,
    required this.biometricAvailable,
  });

  final AuthStore authStore;
  final bool biometricAvailable;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _goalCtrl = TextEditingController(text: '8000');
  final _weightCtrl = TextEditingController(text: '70');
  final _heightCtrl = TextEditingController(text: '170');

  bool _obscure = true;
  bool _enableBiometric = true;
  bool _submitting = false;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final goal = int.tryParse(_goalCtrl.text.trim()) ?? 8000;
    final weight = double.tryParse(_weightCtrl.text.trim()) ?? 70.0;
    final height = double.tryParse(_heightCtrl.text.trim()) ?? 170.0;

    final res = await widget.authStore.register(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
      stepGoal: goal.clamp(1000, 50000),
      weightKg: weight.clamp(30, 250),
      heightCm: height.clamp(100, 240),
      biometricEnabled: _enableBiometric,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res.ok && res.user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: FitPalette.green,
        ),
      );
      Navigator.pop(context, res.user);
    } else {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No se pudo registrar'),
          content: Text(res.message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Revisar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _goalCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta FITPRO')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
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
                        'Datos del atleta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo o apodo',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v ?? '').trim().length < 2
                            ? 'Ingresa tu nombre'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          final txt = (v ?? '').trim();
                          if (txt.isEmpty || !txt.contains('@')) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v ?? '').length < 4
                            ? 'Mínimo 4 caracteres'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscure,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar contraseña',
                          prefixIcon: Icon(Icons.lock_reset_outlined),
                        ),
                        validator: (v) => v != _passCtrl.text
                            ? 'Las contraseñas no coinciden'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Perfil físico y objetivo diario',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Peso (kg)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _heightCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Altura (cm)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _goalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Meta diaria de pasos',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: accent,
                        title: const Text('Activar acceso con huella dactilar'),
                        subtitle: Text(
                          widget.biometricAvailable
                              ? 'Desbloquea FITPRO rápidamente con tu huella.'
                              : 'Se activará cuando registres una huella en el teléfono.',
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: _enableBiometric,
                        onChanged: (v) => setState(() => _enableBiometric = v),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Registrarme y comenzar'),
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
