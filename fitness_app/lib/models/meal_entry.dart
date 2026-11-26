/// Registro de comida analizada por fotografia y conectada al contador diario.
class MealEntry {
  const MealEntry({
    required this.id,
    required this.userEmail,
    required this.name,
    required this.portionLabel,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.loggedAt,
    this.imagePath,
    this.confidence = 0.9,
    this.addedToDailyTotal = true,
  });

  final String id;
  final String userEmail;
  final String name;
  final String portionLabel;
  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final DateTime loggedAt;
  final String? imagePath;
  final double confidence;
  final bool addedToDailyTotal;

  MealEntry copyWith({
    String? name,
    String? portionLabel,
    double? calories,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
    String? imagePath,
    double? confidence,
    bool? addedToDailyTotal,
  }) =>
      MealEntry(
        id: id,
        userEmail: userEmail,
        name: name ?? this.name,
        portionLabel: portionLabel ?? this.portionLabel,
        calories: calories ?? this.calories,
        proteinGrams: proteinGrams ?? this.proteinGrams,
        carbsGrams: carbsGrams ?? this.carbsGrams,
        fatGrams: fatGrams ?? this.fatGrams,
        loggedAt: loggedAt,
        imagePath: imagePath ?? this.imagePath,
        confidence: confidence ?? this.confidence,
        addedToDailyTotal: addedToDailyTotal ?? this.addedToDailyTotal,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userEmail': userEmail,
        'name': name,
        'portionLabel': portionLabel,
        'calories': calories,
        'proteinGrams': proteinGrams,
        'carbsGrams': carbsGrams,
        'fatGrams': fatGrams,
        'loggedAt': loggedAt.toIso8601String(),
        'imagePath': imagePath,
        'confidence': confidence,
        'addedToDailyTotal': addedToDailyTotal,
      };

  factory MealEntry.fromMap(Map<dynamic, dynamic> map) => MealEntry(
        id: (map['id'] as String?) ?? '',
        userEmail: (map['userEmail'] as String?) ?? 'local',
        name: (map['name'] as String?) ?? 'Comida registrada',
        portionLabel: (map['portionLabel'] as String?) ?? '1 porción',
        calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
        proteinGrams: (map['proteinGrams'] as num?)?.toDouble() ?? 0.0,
        carbsGrams: (map['carbsGrams'] as num?)?.toDouble() ?? 0.0,
        fatGrams: (map['fatGrams'] as num?)?.toDouble() ?? 0.0,
        loggedAt: DateTime.tryParse((map['loggedAt'] as String?) ?? '') ??
            DateTime.now(),
        imagePath: map['imagePath'] as String?,
        confidence: (map['confidence'] as num?)?.toDouble() ?? 0.88,
        addedToDailyTotal: (map['addedToDailyTotal'] as bool?) ?? true,
      );
}
