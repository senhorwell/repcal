import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:repcal/widgets/tracking_screen.dart';
import '../models/models.dart';

class CalibrationScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CalibrationScreen({super.key, required this.cameras});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _massController = TextEditingController(text: '80');
  final _heightController = TextEditingController(text: '1.77');
  final _extraLoadController = TextEditingController(text: '0');

  ExerciseType _exercise = ExerciseType.pullUp;

  static const _green = Color(0xFF1D9E75);
  static const _purple = Color(0xFF7F77DD);

  Color get _accentColor => _exercise == ExerciseType.pullUp ? _green : _purple;

  @override
  void dispose() {
    _massController.dispose();
    _heightController.dispose();
    _extraLoadController.dispose();
    super.dispose();
  }

  void _start() {
    if (!_formKey.currentState!.validate()) return;
    final profile = UserProfile(
      massKg: double.parse(_massController.text.replaceAll(',', '.')),
      heightM: double.parse(_heightController.text.replaceAll(',', '.')),
      extraLoadKg: _exercise == ExerciseType.squat
          ? double.parse(_extraLoadController.text.replaceAll(',', '.'))
          : 0,
      exercise: _exercise,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TrackingScreen(camera: widget.cameras.first, profile: profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ── Título ─────────────────────────────────────────────────────
                const Text(
                  'Workout\nCalories',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cinemática + Dinâmica em tempo real',
                  style: TextStyle(color: _accentColor, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // ── Seletor de exercício ───────────────────────────────────────
                _label('Exercício'),
                const SizedBox(height: 10),
                _ExercisePicker(
                  selected: _exercise,
                  onChanged: (e) => setState(() => _exercise = e),
                ),
                const SizedBox(height: 28),

                // ── Peso corporal ──────────────────────────────────────────────
                _label('Peso corporal (kg)'),
                const SizedBox(height: 8),
                _field(
                  controller: _massController,
                  hint: 'ex: 80',
                  accent: _accentColor,
                  validator: (v) {
                    final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                    if (n == null || n < 30 || n > 250) {
                      return 'Digite um peso entre 30 e 250 kg';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── Altura ────────────────────────────────────────────────────
                _label('Altura (m)'),
                const SizedBox(height: 8),
                _field(
                  controller: _heightController,
                  hint: 'ex: 1.77',
                  accent: _accentColor,
                  validator: (v) {
                    final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                    if (n == null || n < 1.0 || n > 2.5) {
                      return 'Digite uma altura entre 1.0 e 2.5 m';
                    }
                    return null;
                  },
                ),

                // ── Carga extra (só agachamento) ───────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _exercise == ExerciseType.squat
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _label('Carga adicional (kg)'),
                            const SizedBox(height: 4),
                            Text(
                              'Peso da barra ou halteres somado ao seu corpo',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _field(
                              controller: _extraLoadController,
                              hint: 'ex: 20  (ou 0 sem carga)',
                              accent: _accentColor,
                              validator: (v) {
                                final n = double.tryParse(
                                  v?.replaceAll(',', '.') ?? '',
                                );
                                if (n == null || n < 0 || n > 500) {
                                  return 'Digite um valor entre 0 e 500 kg';
                                }
                                return null;
                              },
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 32),

                // ── Dica contextual ────────────────────────────────────────────
                _InfoBanner(exercise: _exercise, accentColor: _accentColor),
                const SizedBox(height: 24),

                // ── Botão iniciar ──────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _start,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Iniciar treino',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white70,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required Color accent,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    style: const TextStyle(color: Colors.white, fontSize: 16),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Color(0xFFEF9F27)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    validator: validator,
  );
}

// ─── Seletor de exercício ──────────────────────────────────────────────────────
class _ExercisePicker extends StatelessWidget {
  final ExerciseType selected;
  final ValueChanged<ExerciseType> onChanged;

  const _ExercisePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ExerciseCard(
            label: 'Barra fixa',
            subtitle: 'Pull-up',
            icon: Icons.fitness_center,
            accentColor: const Color(0xFF1D9E75),
            selected: selected == ExerciseType.pullUp,
            onTap: () => onChanged(ExerciseType.pullUp),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ExerciseCard(
            label: 'Agachamento',
            subtitle: 'Squat',
            icon: Icons.accessibility_new_rounded,
            accentColor: const Color(0xFF7F77DD),
            selected: selected == ExerciseType.squat,
            onTap: () => onChanged(ExerciseType.squat),
          ),
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool selected;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withOpacity(0.12)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accentColor : Colors.white12,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? accentColor : Colors.white38,
              size: 22,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: selected ? accentColor : Colors.white30,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Banner de instrução contextual ───────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  final ExerciseType exercise;
  final Color accentColor;

  const _InfoBanner({required this.exercise, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final text = exercise == ExerciseType.pullUp
        ? 'Na próxima tela, fique em pé e parado por 2 segundos para calibrar a câmera. Depois, suba na barra!'
        : 'Na próxima tela, fique em pé e parado por 2 segundos para calibrar. Depois, comece a agachar — a câmera rastreia seu quadril automaticamente.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
