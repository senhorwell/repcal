import 'package:flutter/material.dart';
import '../models/models.dart';

class HudOverlay extends StatelessWidget {
  final WorkoutState state;
  final UserProfile profile;
  final VoidCallback onReset;
  final VoidCallback onBack;

  const HudOverlay({
    super.key,
    required this.state,
    required this.profile,
    required this.onReset,
    required this.onBack,
  });

  static const _green = Color(0xFF1D9E75);
  static const _purple = Color(0xFF7F77DD);
  static const _amber = Color(0xFFEF9F27);

  Color get _accent =>
      profile.exercise == ExerciseType.pullUp ? _green : _purple;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(),
          if (state.status == CalibrationStatus.calibrating)
            _buildCalibrationBanner(),
          const Spacer(),
          if (state.status == CalibrationStatus.tracking) _buildMetricsPanel(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _glassButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const Spacer(),
          _statusPill(),
          const Spacer(),
          _glassButton(icon: Icons.refresh_rounded, onTap: onReset),
        ],
      ),
    );
  }

  Widget _glassButton({required IconData icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );

  Widget _statusPill() {
    final (label, color) = switch (state.status) {
      CalibrationStatus.idle => ('Aguardando', Colors.white38),
      CalibrationStatus.calibrating => ('Calibrando...', _amber),
      CalibrationStatus.ready => ('Pronto', _accent),
      CalibrationStatus.tracking => ('Rastreando', _accent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _amber.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            const Text(
              'Fique em pé e parado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Calibrando proporção px → metro...',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: state.calibrationProgress,
                backgroundColor: Colors.white12,
                color: _amber,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(state.calibrationProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: _amber, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            // ── kcal principal ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    state.totalKcal.toStringAsFixed(3),
                    style: TextStyle(
                      color: _accent,
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8, left: 6),
                    child: Text(
                      'kcal',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            // ── Métricas secundárias (contextuais) ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: profile.exercise == ExerciseType.pullUp
                  ? _pullUpMetrics()
                  : _squatMetrics(),
            ),
          ],
        ),
      ),
    );
  }

  // Barra fixa: repetições | Força (N) | px/m
  Widget _pullUpMetrics() => Row(
    children: [
      _metricCell(
        value: state.repCount.toString(),
        label: 'repetições',
        color: Colors.white,
      ),
      _vertDivider(),
      _metricCell(
        value: state.currentForceN.toStringAsFixed(0),
        label: 'Força (N)',
        color: _amber,
      ),
      _vertDivider(),
      _metricCell(
        value: state.pixelsPerMeter.toStringAsFixed(0),
        label: 'px/m',
        color: Colors.white38,
      ),
    ],
  );

  // Agachamento: repetições | Deslocamento (m) | Peso total (kg)
  Widget _squatMetrics() => Row(
    children: [
      _metricCell(
        value: state.repCount.toString(),
        label: 'repetições',
        color: Colors.white,
      ),
      _vertDivider(),
      _metricCell(
        value: state.lastRepDisplacementM > 0
            ? state.lastRepDisplacementM.toStringAsFixed(2)
            : '—',
        label: 'h últ. rep (m)',
        color: _amber,
      ),
      _vertDivider(),
      _metricCell(
        value: profile.totalMassKg.toStringAsFixed(0),
        label: 'Peso total (kg)',
        color: Colors.white38,
      ),
    ],
  );

  Widget _metricCell({
    required String value,
    required String label,
    required Color color,
  }) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    ),
  );

  Widget _vertDivider() =>
      Container(width: 1, height: 36, color: Colors.white.withOpacity(0.08));
}
