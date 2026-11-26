import 'package:flutter/material.dart';

import 'models/user_profile.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_store.dart';
import 'services/biometric_service.dart';
import 'services/meal_store.dart';
import 'services/permissions_service.dart';
import 'services/session_store.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authStore = AuthStore();
  await authStore.init();
  final sessionStore = SessionStore();
  await sessionStore.init();
  final mealStore = MealStore();
  await mealStore.init();

  runApp(
    FitProApp(
      authStore: authStore,
      sessionStore: sessionStore,
      mealStore: mealStore,
    ),
  );
}

class FitProApp extends StatefulWidget {
  const FitProApp({
    super.key,
    required this.authStore,
    required this.sessionStore,
    required this.mealStore,
    this.initialUser,
  });

  final AuthStore authStore;
  final SessionStore sessionStore;
  final MealStore mealStore;
  final UserProfile? initialUser;

  @override
  State<FitProApp> createState() => _FitProAppState();
}

class _FitProAppState extends State<FitProApp> {
  final _biometricService = BiometricService();
  final _permissionsService = PermissionsService();
  UserProfile? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.initialUser;
  }

  void _onAuthenticated(UserProfile user) {
    setState(() => _currentUser = user);
  }

  Future<void> _onLogout() async {
    await widget.authStore.logout();
    if (!mounted) return;
    setState(() => _currentUser = null);
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = _currentUser?.darkMode ?? true;
    final accentIdx = _currentUser?.accentIndex ?? 0;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FITPRO',
      theme: AppTheme.build(darkMode: darkMode, accentIndex: accentIdx),
      home: _currentUser == null
          ? LoginScreen(
              authStore: widget.authStore,
              biometricService: _biometricService,
              onAuthenticated: _onAuthenticated,
            )
          : HomeShell(
              key: ValueKey(_currentUser!.email),
              initialUser: _currentUser!,
              authStore: widget.authStore,
              sessionStore: widget.sessionStore,
              mealStore: widget.mealStore,
              permissionsService: _permissionsService,
              biometricService: _biometricService,
              onUserUpdated: (u) => setState(() => _currentUser = u),
              onLogout: _onLogout,
            ),
    );
  }
}
