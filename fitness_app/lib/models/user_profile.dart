/// Perfil del usuario autenticado y preferencias persistidas en Hive.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.stepGoal = 8000,
    this.weightKg = 70.0,
    this.heightCm = 170.0,
    this.biometricEnabled = true,
    this.useImperialUnits = false,
    this.accentIndex = 0,
    this.darkMode = true,
    this.sedentaryReminder = true,
    this.notificationsEnabled = true,
    this.wristWakeEnabled = false,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final int stepGoal;
  final double weightKg;
  final double heightCm;
  final bool biometricEnabled;
  final bool useImperialUnits;
  final int accentIndex;
  final bool darkMode;
  final bool sedentaryReminder;
  final bool notificationsEnabled;
  final bool wristWakeEnabled;
  final DateTime createdAt;

  UserProfile copyWith({
    String? name,
    String? email,
    String? passwordHash,
    int? stepGoal,
    double? weightKg,
    double? heightCm,
    bool? biometricEnabled,
    bool? useImperialUnits,
    int? accentIndex,
    bool? darkMode,
    bool? sedentaryReminder,
    bool? notificationsEnabled,
    bool? wristWakeEnabled,
  }) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
        stepGoal: stepGoal ?? this.stepGoal,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        useImperialUnits: useImperialUnits ?? this.useImperialUnits,
        accentIndex: accentIndex ?? this.accentIndex,
        darkMode: darkMode ?? this.darkMode,
        sedentaryReminder: sedentaryReminder ?? this.sedentaryReminder,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        wristWakeEnabled: wristWakeEnabled ?? this.wristWakeEnabled,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'stepGoal': stepGoal,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'biometricEnabled': biometricEnabled,
        'useImperialUnits': useImperialUnits,
        'accentIndex': accentIndex,
        'darkMode': darkMode,
        'sedentaryReminder': sedentaryReminder,
        'notificationsEnabled': notificationsEnabled,
        'wristWakeEnabled': wristWakeEnabled,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) => UserProfile(
        id: (map['id'] as String?) ?? '',
        name: (map['name'] as String?) ?? 'Atleta FITPRO',
        email: (map['email'] as String?) ?? '',
        passwordHash: (map['passwordHash'] as String?) ?? '',
        stepGoal: (map['stepGoal'] as num?)?.toInt() ?? 8000,
        weightKg: (map['weightKg'] as num?)?.toDouble() ?? 70.0,
        heightCm: (map['heightCm'] as num?)?.toDouble() ?? 170.0,
        biometricEnabled: (map['biometricEnabled'] as bool?) ?? true,
        useImperialUnits: (map['useImperialUnits'] as bool?) ?? false,
        accentIndex: (map['accentIndex'] as num?)?.toInt() ?? 0,
        darkMode: (map['darkMode'] as bool?) ?? true,
        sedentaryReminder: (map['sedentaryReminder'] as bool?) ?? true,
        notificationsEnabled: (map['notificationsEnabled'] as bool?) ?? true,
        wristWakeEnabled: (map['wristWakeEnabled'] as bool?) ?? false,
        createdAt: DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
            DateTime.now(),
      );
}
