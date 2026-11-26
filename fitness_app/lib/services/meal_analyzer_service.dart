import 'dart:async';

/// Resultado de estimacion nutricional a partir de una fotografia de comida.
class MealAnalysisResult {
  const MealAnalysisResult({
    required this.name,
    required this.portionLabel,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.confidence,
  });

  final String name;
  final String portionLabel;
  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double confidence;
}

/// Interfaz modular para conectar facilmente un modelo o API real de vision nutricional.
abstract class MealAnalyzerService {
  Future<MealAnalysisResult> analyzePhoto(String imagePath);
}

/// Implementacion local realista lista para demostracion offline y reemplazo por API real.
class SimulatedVisionMealAnalyzer implements MealAnalyzerService {
  static const List<MealAnalysisResult> _presets = [
    MealAnalysisResult(
      name: 'Bowl de pollo a la plancha con arroz y aguacate',
      portionLabel: '1 plato mediano (350 g)',
      calories: 520,
      proteinGrams: 38,
      carbsGrams: 52,
      fatGrams: 16,
      confidence: 0.93,
    ),
    MealAnalysisResult(
      name: 'Avena proteica con plátano y frutos rojos',
      portionLabel: '1 tazón (280 g)',
      calories: 385,
      proteinGrams: 22,
      carbsGrams: 54,
      fatGrams: 9,
      confidence: 0.91,
    ),
    MealAnalysisResult(
      name: 'Tacos de pechuga asada con pico de gallo',
      portionLabel: '3 piezas (260 g)',
      calories: 430,
      proteinGrams: 32,
      carbsGrams: 44,
      fatGrams: 12,
      confidence: 0.89,
    ),
    MealAnalysisResult(
      name: 'Salmón a la plancha con vegetales al vapor',
      portionLabel: '1 filete + guarnición (320 g)',
      calories: 490,
      proteinGrams: 39,
      carbsGrams: 18,
      fatGrams: 27,
      confidence: 0.94,
    ),
    MealAnalysisResult(
      name: 'Ensalada César con pollo y crutones integrales',
      portionLabel: '1 porción (300 g)',
      calories: 410,
      proteinGrams: 31,
      carbsGrams: 24,
      fatGrams: 19,
      confidence: 0.88,
    ),
    MealAnalysisResult(
      name: 'Huevos revueltos con espinaca y pan integral',
      portionLabel: '2 piezas + 2 rebanadas (240 g)',
      calories: 360,
      proteinGrams: 24,
      carbsGrams: 30,
      fatGrams: 15,
      confidence: 0.90,
    ),
  ];

  @override
  Future<MealAnalysisResult> analyzePhoto(String imagePath) async {
    // Simula latencia realista de inferencia visual antes de devolver la estimacion.
    await Future<void>.delayed(const Duration(milliseconds: 750));
    final lower = imagePath.toLowerCase();

    if (lower.contains('avena') || lower.contains('breakfast')) {
      return _presets[1];
    }
    if (lower.contains('taco')) return _presets[2];
    if (lower.contains('salmon') || lower.contains('fish')) return _presets[3];
    if (lower.contains('salad') || lower.contains('ensalada')) return _presets[4];

    final hash = imagePath.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return _presets[hash % _presets.length];
  }
}
