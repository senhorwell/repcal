import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../models/models.dart';

/// Widget que posiciona um [CustomPainter] sobre o preview da câmera
/// e desenha o esqueleto + destaque do mid_hip.
class SkeletonPainterOverlay extends StatelessWidget {
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final Size imageSize;
  final Size screenSize;
  final WorkoutState state;

  const SkeletonPainterOverlay({
    super.key,
    required this.landmarks,
    required this.imageSize,
    required this.screenSize,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SkeletonPainter(
        landmarks: landmarks,
        imageSize: imageSize,
        screenSize: screenSize,
        state: state,
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final Size imageSize;
  final Size screenSize;
  final WorkoutState state;

  _SkeletonPainter({
    required this.landmarks,
    required this.imageSize,
    required this.screenSize,
    required this.state,
  });

  // ── Pares de conexões do esqueleto ─────────────────────────────────────────
  static const _connections = [
    // Torso
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    // Braço esquerdo
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    // Braço direito
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    // Perna esquerda
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    // Perna direita
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
  ];

  static final _bonePaint = Paint()
    ..color = Colors.white.withOpacity(0.7)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;

  static final _jointPaint = Paint()
    ..color = const Color(0xFF1D9E75)
    ..style = PaintingStyle.fill;

  static final _hipPaint = Paint()
    ..color = const Color(0xFFEF9F27)
    ..style = PaintingStyle.fill;

  static final _hipRingPaint = Paint()
    ..color = const Color(0xFFEF9F27).withOpacity(0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    // ── Conexões (ossos) ────────────────────────────────────────────────────
    for (final pair in _connections) {
      final a = landmarks[pair[0]];
      final b = landmarks[pair[1]];
      if (a == null || b == null) continue;
      if (a.likelihood < 0.5 || b.likelihood < 0.5) continue;

      canvas.drawLine(
        _toScreen(a.x, a.y, size),
        _toScreen(b.x, b.y, size),
        _bonePaint,
      );
    }

    // ── Articulações (joints) ───────────────────────────────────────────────
    for (final entry in landmarks.entries) {
      if (entry.value.likelihood < 0.5) continue;
      final pt = _toScreen(entry.value.x, entry.value.y, size);
      canvas.drawCircle(pt, 4, _jointPaint);
    }

    // ── Destaque do mid_hip ─────────────────────────────────────────────────
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    if (leftHip != null && rightHip != null) {
      final midX = (leftHip.x + rightHip.x) / 2;
      final midY = (leftHip.y + rightHip.y) / 2;
      final midPt = _toScreen(midX, midY, size);

      // Anel externo (pulsa durante tracking)
      if (state.status == CalibrationStatus.tracking) {
        canvas.drawCircle(midPt, 16, _hipRingPaint);
      }
      // Ponto central amarelo
      canvas.drawCircle(midPt, 7, _hipPaint);

      // Label "mid_hip"
      final tp = TextPainter(
        text: const TextSpan(
          text: 'mid_hip',
          style: TextStyle(
            color: Color(0xFFEF9F27),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, midPt.translate(12, -8));
    }
  }

  /// Converte coordenadas de pixel do frame da câmera para coordenadas de tela.
  Offset _toScreen(double x, double y, Size canvasSize) {
    final scaleX = canvasSize.width / imageSize.width;
    final scaleY = canvasSize.height / imageSize.height;
    return Offset(x * scaleX, y * scaleY);
  }

  @override
  bool shouldRepaint(_SkeletonPainter old) =>
      old.landmarks != landmarks || old.state != state;
}
