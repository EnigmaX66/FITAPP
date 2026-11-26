import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/user_profile.dart';
import '../services/biometric_service.dart';
import '../services/permissions_service.dart';
import '../theme/app_theme.dart';

/// Pestana "Yo": perfil, metas, tema, gestion de permisos en tiempo de ejecucion y cierre de sesion.
class YoTab extends StatelessWidget {
  const YoTab({
    super.key,
    required this.user,
    required this.permissionsService,
    required this.biometricService,
    required this.onUpdateUser,
    required this.onLogout,
  });

  final UserProfile user;
  final PermissionsService permissionsService;
  final BiometricService biometricService;
  final ValueChanged<UserProfile> onUpdateUser;
  final VoidCallback onLogout;

  void _editGoalDialog(BuildContext context) {
    final ctrl = TextEditingController(text: '${user.stepGoal}');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Objetivo diario de pasos'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Meta de pasos',
            hintText: 'Ej. 8000 o 10000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final nextGoal =
                  (int.tryParse(ctrl.text.trim()) ?? user.stepGoal)
                      .clamp(1000, 50000);
              onUpdateUser(user.copyWith(stepGoal: nextGoal));
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personalizar tema FITPRO',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Modo oscuro deportivo'),
              value: user.darkMode,
              onChanged: (v) {
                onUpdateUser(user.copyWith(darkMode: v));
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 10),
            const Text(
              'Color de acento',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: List.generate(FitPalette.accentOptions.length, (i) {
                final color = FitPalette.accentOptions[i];
                final selected = user.accentIndex == i;
                return ChoiceChip(
                  label: Text(FitPalette.accentNames[i]),
                  selected: selected,
                  avatar: CircleAvatar(backgroundColor: color, radius: 8),
                  onSelected: (_) {
                    onUpdateUser(user.copyWith(accentIndex: i));
                    Navigator.pop(ctx);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountSettings(BuildContext context) {
    final nameCtrl = TextEditingController(text: user.name);
    final weightCtrl = TextEditingController(text: user.weightKg.toStringAsFixed(0));
    bool bioEnabled = user.biometricEnabled;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ajustes de perfil y seguridad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: weightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Peso (kg)'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Inicio con huella dactilar'),
                value: bioEnabled,
                onChanged: (v) => setSheetState(() => bioEnabled = v),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () {
                  final nextName = nameCtrl.text.trim().isEmpty
                      ? user.name
                      : nameCtrl.text.trim();
                  final nextWeight =
                      double.tryParse(weightCtrl.text.trim()) ?? user.weightKg;
                  onUpdateUser(
                    user.copyWith(
                      name: nextName,
                      weightKg: nextWeight.clamp(30, 250),
                      biometricEnabled: bioEnabled,
                    ),
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Guardar cambios'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  onLogout();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: FitPalette.heartRed,
                  side: const BorderSide(color: FitPalette.heartRed),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPermissionsSheet(BuildContext context) async {
    final overview = await permissionsService.getOverview();
    final bio = await biometricService.checkAvailability();
    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Configuración de permisos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _PermissionRow(
              label: 'Ubicación GPS',
              granted: overview.locationStatus.isGranted,
              statusText: overview.locationStatus.isGranted
                  ? (overview.gpsServiceEnabled ? 'Concedido y GPS activo' : 'Permiso ok, GPS apagado')
                  : 'Pendiente',
            ),
            _PermissionRow(
              label: 'Actividad física (Podómetro)',
              granted: overview.activityStatus.isGranted,
              statusText: overview.activityStatus.isGranted ? 'Concedido' : 'Pendiente',
            ),
            _PermissionRow(
              label: 'Biometría (Huella dactilar)',
              granted: bio.available,
              statusText: bio.available ? 'Configurada' : 'Revisar en Ajustes',
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await permissionsService.requestWorkoutPermissions(context);
              },
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('Solicitar permisos ahora'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text('Abrir ajustes del sistema'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? FitPalette.surfaceDark : Colors.white;
    final border = isDark ? FitPalette.borderDark : FitPalette.borderLight;
    final accent = Theme.of(context).colorScheme.primary;
    final initials = user.name.trim().isNotEmpty
        ? user.name.trim()[0].toUpperCase()
        : 'F';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        // Avatar centrado y nombre (identico a la captura 3)
        Center(
          child: Container(
            width: 102,
            height: 102,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: FitPalette.surfaceElevatedDark,
              border: Border.all(color: FitPalette.textMuted, width: 2.5),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          user.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          user.email,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: FitPalette.textMuted),
        ),
        const SizedBox(height: 18),

        // Tarjeta de 4 acciones rapidas
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuickActionItem(
                icon: Icons.flag_rounded,
                color: FitPalette.blue,
                label: 'Objetivo',
                onTap: () => _editGoalDialog(context),
              ),
              _QuickActionItem(
                icon: Icons.help_outline_rounded,
                color: FitPalette.pink,
                label: 'Ayuda',
                onTap: () => _showInfoDialog(
                  context,
                  'Ayuda de FITPRO',
                  '1. En "Estado" visualizas pasos, calorías, distancia, acelerómetro, giroscopio y acceso a comidas.\n'
                      '2. En "Deporte" activas tu GPS, ves tu ubicación en vivo y guardas rutas.\n'
                      '3. En "Dispositivo" revisas el estado físico de cada sensor.',
                ),
              ),
              _QuickActionItem(
                icon: Icons.chat_bubble_rounded,
                color: FitPalette.yellow,
                label: 'FAQ',
                onTap: () => _showInfoDialog(
                  context,
                  'Preguntas frecuentes',
                  '• ¿Por qué no marca pasos en emulador? Algunos emuladores no simulan el chip podómetro; pruébalo en un Android físico.\n'
                      '• ¿Dónde se guardan mis rutas y comidas? Localmente con Hive en tu dispositivo.',
                ),
              ),
              _QuickActionItem(
                icon: Icons.lock_rounded,
                color: FitPalette.teal,
                label: 'Soporte',
                onTap: () => _showInfoDialog(
                  context,
                  'FITPRO · UPFIM',
                  'Proyecto Integrador — Desarrollo de Aplicaciones Móviles.\n'
                      'Ingeniería en Tecnologías de la Información e Innovación Digital (4TIG1).',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Tarjeta Cambia tema
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: _YoTile(
            icon: Icons.palette_rounded,
            color: FitPalette.purple,
            title: 'Cambia tema',
            onTap: () => _showThemePicker(context),
          ),
        ),
        const SizedBox(height: 12),

        // Grupo Ajustes / Permisos / Comentarios / Sobre
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              _YoTile(
                icon: Icons.settings_rounded,
                color: FitPalette.purple,
                title: 'Ajustes',
                onTap: () => _showAccountSettings(context),
              ),
              Divider(height: 1, indent: 60, color: border),
              _YoTile(
                icon: Icons.lock_person_rounded,
                color: FitPalette.teal,
                title: 'Configuración de permisos',
                onTap: () => _showPermissionsSheet(context),
              ),
              Divider(height: 1, indent: 60, color: border),
              _YoTile(
                icon: Icons.feedback_rounded,
                color: FitPalette.yellow,
                title: 'Comentarios',
                onTap: () => _showInfoDialog(
                  context,
                  'Comentarios FITPRO',
                  'Tu experiencia nos ayuda a mejorar. Todas tus métricas y rutas permanecen privadas en este teléfono.',
                ),
              ),
              Divider(height: 1, indent: 60, color: border),
              _YoTile(
                icon: Icons.info_rounded,
                color: FitPalette.orange,
                title: 'Sobre',
                onTap: () => _showInfoDialog(
                  context,
                  'Acerca de FITPRO',
                  'FITPRO v1.0.0\n'
                      '• Autenticación local + Biometría (RF-01)\n'
                      '• Podómetro, Acelerómetro y Giroscopio (RF-02..04)\n'
                      '• Mapa interactivo OpenStreetMap + GPS (RF-05)\n'
                      '• Persistencia local con Hive (RF-06)',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YoTile extends StatelessWidget {
  const _YoTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      leading: CircleAvatar(
        radius: 17,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: FitPalette.textMuted),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.granted,
    required this.statusText,
  });

  final String label;
  final bool granted;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: granted ? FitPalette.green : FitPalette.yellow,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: granted ? FitPalette.green : FitPalette.yellow,
            ),
          ),
        ],
      ),
    );
  }
}
