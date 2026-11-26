import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/meal_entry.dart';
import '../models/user_profile.dart';
import '../services/meal_analyzer_service.dart';
import '../services/meal_store.dart';
import '../theme/app_theme.dart';

/// Modulo de Nutricion / Comidas con conteo de calorias por foto y ajuste manual.
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({
    super.key,
    required this.user,
    required this.mealStore,
    required this.analyzerService,
    required this.burnedCaloriesToday,
    required this.onMealsChanged,
  });

  final UserProfile user;
  final MealStore mealStore;
  final MealAnalyzerService analyzerService;
  final double burnedCaloriesToday;
  final VoidCallback onMealsChanged;

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final _picker = ImagePicker();

  final _nameCtrl = TextEditingController();
  final _portionCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  String? _selectedImagePath;
  bool _analyzing = false;
  bool _hasDraft = false;
  double _confidence = 0.9;
  double _portionMultiplier = 1.0;

  double _baseKcal = 0;
  double _baseProtein = 0;
  double _baseCarbs = 0;
  double _baseFat = 0;

  List<MealEntry> _todayMeals = const [];
  DailyNutritionTotals _totals = const DailyNutritionTotals(
    calories: 0,
    proteinGrams: 0,
    carbsGrams: 0,
    fatGrams: 0,
    mealsCount: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    final meals = await widget.mealStore.loadTodayMeals(userEmail: widget.user.email);
    final totals = await widget.mealStore.getTodayTotals(userEmail: widget.user.email);
    if (!mounted) return;
    setState(() {
      _todayMeals = meals;
      _totals = totals;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (file == null) return;
      await _runAnalysis(file.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir la cámara o galería en este dispositivo. '
            'Puedes probar con la estimación de ejemplo.',
          ),
        ),
      );
    }
  }

  Future<void> _runSamplePhotoAnalysis() async {
    await _runAnalysis('sample://bowl_pollo_fit_${DateTime.now().second}.jpg');
  }

  Future<void> _runAnalysis(String path) async {
    setState(() {
      _selectedImagePath = path;
      _analyzing = true;
      _hasDraft = true;
      _portionMultiplier = 1.0;
    });

    final result = await widget.analyzerService.analyzePhoto(path);
    if (!mounted) return;

    _baseKcal = result.calories;
    _baseProtein = result.proteinGrams;
    _baseCarbs = result.carbsGrams;
    _baseFat = result.fatGrams;

    setState(() {
      _analyzing = false;
      _confidence = result.confidence;
      _nameCtrl.text = result.name;
      _portionCtrl.text = result.portionLabel;
      _applyMultiplier(1.0);
    });
  }

  void _applyMultiplier(double multiplier) {
    _portionMultiplier = multiplier;
    _kcalCtrl.text = (_baseKcal * multiplier).toStringAsFixed(0);
    _proteinCtrl.text = (_baseProtein * multiplier).toStringAsFixed(0);
    _carbsCtrl.text = (_baseCarbs * multiplier).toStringAsFixed(0);
    _fatCtrl.text = (_baseFat * multiplier).toStringAsFixed(0);
    setState(() {});
  }

  Future<void> _saveMeal({required bool addToDaily}) async {
    final name = _nameCtrl.text.trim().isEmpty
        ? 'Comida personalizada'
        : _nameCtrl.text.trim();
    final portion = _portionCtrl.text.trim().isEmpty
        ? '1 porción'
        : _portionCtrl.text.trim();
    final kcal = (double.tryParse(_kcalCtrl.text.trim()) ?? 0).clamp(0.0, 5000.0);
    final protein =
        (double.tryParse(_proteinCtrl.text.trim()) ?? 0).clamp(0.0, 500.0);
    final carbs = (double.tryParse(_carbsCtrl.text.trim()) ?? 0).clamp(0.0, 500.0);
    final fat = (double.tryParse(_fatCtrl.text.trim()) ?? 0).clamp(0.0, 500.0);

    final entry = MealEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      userEmail: widget.user.email,
      name: name,
      portionLabel: portion,
      calories: kcal,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
      loggedAt: DateTime.now(),
      imagePath: _selectedImagePath,
      confidence: _confidence,
      addedToDailyTotal: addToDaily,
    );

    await widget.mealStore.saveMeal(entry);
    await _loadMeals();
    widget.onMealsChanged();

    if (!mounted) return;
    setState(() {
      _hasDraft = false;
      _selectedImagePath = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          addToDaily
              ? 'Comida sumada al contador diario (+${kcal.toStringAsFixed(0)} kcal).'
              : 'Comida guardada en tu historial de hoy.',
        ),
        backgroundColor: FitPalette.green,
      ),
    );
  }

  Future<void> _toggleMealCounted(MealEntry meal) async {
    final updated = meal.copyWith(addedToDailyTotal: !meal.addedToDailyTotal);
    await widget.mealStore.saveMeal(updated);
    await _loadMeals();
    widget.onMealsChanged();
  }

  Future<void> _deleteMeal(MealEntry meal) async {
    await widget.mealStore.deleteMeal(meal.id);
    await _loadMeals();
    widget.onMealsChanged();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _portionCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? FitPalette.surfaceDark : Colors.white;
    final border = isDark ? FitPalette.borderDark : FitPalette.borderLight;
    final accent = Theme.of(context).colorScheme.primary;
    final netKcal = _totals.calories - widget.burnedCaloriesToday;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nutrición y Comidas',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Resumen del balance calorico diario
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF161D2B), Color(0xFF111926)]
                    : const [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
              ),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Balance calórico de hoy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${_totals.mealsCount} comidas',
                      style: TextStyle(
                        fontSize: 12,
                        color: FitPalette.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _KcalSummaryStat(
                      label: 'Consumidas',
                      value: '+${_totals.calories.toStringAsFixed(0)}',
                      color: FitPalette.orange,
                    ),
                    _KcalSummaryStat(
                      label: 'Quemadas',
                      value: '-${widget.burnedCaloriesToday.toStringAsFixed(0)}',
                      color: FitPalette.green,
                    ),
                    _KcalSummaryStat(
                      label: 'Neto hoy',
                      value: '${netKcal.toStringAsFixed(0)} kcal',
                      color: const Color(0xFF3B9EFF),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MacroMiniBar(
                        label: 'Prot',
                        grams: _totals.proteinGrams,
                        color: const Color(0xFF3B9EFF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MacroMiniBar(
                        label: 'Carb',
                        grams: _totals.carbsGrams,
                        color: FitPalette.yellow,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MacroMiniBar(
                        label: 'Grasas',
                        grams: _totals.fatGrams,
                        color: FitPalette.pink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Botones de camara / galeria
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Registrar comida con foto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toma una foto o elige una imagen para estimar calorías y macros.',
                  style: TextStyle(fontSize: 12.5, color: FitPalette.textMuted),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded, size: 19),
                        label: const Text('Cámara'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.gallery),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: BorderSide(color: border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.photo_library_rounded, size: 19),
                        label: const Text('Galería'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: _runSamplePhotoAnalysis,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('Probar análisis con platillo de ejemplo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Vista previa y editor de estimacion
          if (_hasDraft) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: 0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _MealThumb(imagePath: _selectedImagePath, size: 74),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (_analyzing
                                        ? const Color(0xFF3B9EFF)
                                        : FitPalette.green)
                                    .withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _analyzing
                                    ? 'Analizando imagen...'
                                    : 'Estimación lista · ${(_confidence * 100).round()}% confianza',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _analyzing
                                      ? const Color(0xFF3B9EFF)
                                      : FitPalette.green,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _analyzing
                                  ? 'Identificando ingredientes y porción...'
                                  : 'Puedes ajustar el nombre, la porción o las calorías antes de sumar.',
                              style: TextStyle(
                                fontSize: 12,
                                color: FitPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_analyzing) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ] else ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Platillo estimado',
                        prefixIcon: Icon(Icons.fastfood_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _portionCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Porción',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _kcalCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Calorías (kcal)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [0.5, 1.0, 1.5, 2.0].map((mult) {
                        final selected = _portionMultiplier == mult;
                        return ChoiceChip(
                          label: Text('${mult}x'),
                          selected: selected,
                          onSelected: (_) => _applyMultiplier(mult),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _proteinCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Prot (g)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _carbsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Carb (g)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _fatCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Grasa (g)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => _saveMeal(addToDaily: true),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Sumar al contador diario'),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => _saveMeal(addToDaily: false),
                      child: const Text('Guardar solo en historial sin sumar aún'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Historial de comidas registradas en el dia
          Row(
            children: [
              const Text(
                'Comidas registradas hoy',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${_todayMeals.length} registros',
                style: TextStyle(fontSize: 12, color: FitPalette.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_todayMeals.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Text(
                'Aún no registras comidas hoy. Toma una foto o elige una imagen arriba para calcular tus calorías.',
                style: TextStyle(color: FitPalette.textMuted, fontSize: 13),
              ),
            )
          else
            ..._todayMeals.map((m) {
              final hh = m.loggedAt.hour.toString().padLeft(2, '0');
              final mm = m.loggedAt.minute.toString().padLeft(2, '0');
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    _MealThumb(imagePath: m.imagePath, size: 58),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$hh:$mm · ${m.portionLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: FitPalette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${m.calories.toStringAsFixed(0)} kcal · P ${m.proteinGrams.toStringAsFixed(0)}g · C ${m.carbsGrams.toStringAsFixed(0)}g · G ${m.fatGrams.toStringAsFixed(0)}g',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () => _toggleMealCounted(m),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (m.addedToDailyTotal
                                      ? FitPalette.green
                                      : accent)
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              m.addedToDailyTotal ? 'Sumada' : '+ Sumar',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: m.addedToDailyTotal
                                    ? FitPalette.green
                                    : accent,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: FitPalette.textMuted,
                          ),
                          onPressed: () => _deleteMeal(m),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MealThumb extends StatelessWidget {
  const _MealThumb({required this.imagePath, required this.size});

  final String? imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasLocalFile = imagePath != null &&
        !imagePath!.startsWith('sample://') &&
        File(imagePath!).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFF1D2432),
        child: hasLocalFile
            ? Image.file(File(imagePath!), fit: BoxFit.cover)
            : const Icon(
                Icons.lunch_dining_rounded,
                color: Color(0xFFFF6B1A),
                size: 30,
              ),
      ),
    );
  }
}

class _KcalSummaryStat extends StatelessWidget {
  const _KcalSummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.5, color: FitPalette.textMuted),
        ),
      ],
    );
  }
}

class _MacroMiniBar extends StatelessWidget {
  const _MacroMiniBar({
    required this.label,
    required this.grams,
    required this.color,
  });

  final String label;
  final double grams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: FitPalette.textMuted),
          ),
          Text(
            '${grams.toStringAsFixed(0)}g',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
