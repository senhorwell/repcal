import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Wrapper do PoseDetector do ML Kit.
/// Extrai o ponto mid_hip (média de leftHip e rightHip) em coordenadas de pixel.
class PoseService {
  PoseService._();
  static final PoseService instance = PoseService._();

  late final PoseDetector _detector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    ),
  );

  bool _isProcessing = false;

  /// Processa um [CameraImage] e retorna a posição Y do mid_hip em pixels.
  /// Retorna null se nenhuma pose for detectada ou se já houver um frame em
  /// processamento (descarta frame para manter 30 fps sem acumular fila).
  Future<HipResult?> processFrame({
    required CameraImage image,
    required InputImageRotation rotation,
    required CameraLensDirection lensDirection,
  }) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      final inputImage = _toInputImage(image, rotation, lensDirection);
      final poses = await _detector.processImage(inputImage);

      if (poses.isEmpty) return null;

      final pose = poses.first;
      final left = pose.landmarks[PoseLandmarkType.leftHip];
      final right = pose.landmarks[PoseLandmarkType.rightHip];
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

      if (left == null || right == null) return null;

      final midHipX = (left.x + right.x) / 2;
      final midHipY = (left.y + right.y) / 2;

      // Distância ombro-tornozelo em pixels (usada para calibração)
      double? shoulderAnklePx;
      if (leftShoulder != null && leftAnkle != null) {
        shoulderAnklePx = (leftAnkle.y - leftShoulder.y).abs();
      }

      return HipResult(
        midHipX: midHipX,
        midHipY: midHipY,
        shoulderAnklePx: shoulderAnklePx,
        allLandmarks: pose.landmarks,
      );
    } catch (e) {
      debugPrint('[PoseService] Erro ao processar frame: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  InputImage _toInputImage(
    CameraImage image,
    InputImageRotation rotation,
    CameraLensDirection lensDirection,
  ) {
    // Combina os planos YUV em um único Uint8List
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.yuv_420_888,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  void dispose() => _detector.close();
}

/// Resultado de detecção de pose para um único frame.
class HipResult {
  final double midHipX;
  final double midHipY;
  final double? shoulderAnklePx; // null se ombro ou tornozelo não detectados
  final Map<PoseLandmarkType, PoseLandmark> allLandmarks;

  const HipResult({
    required this.midHipX,
    required this.midHipY,
    this.shoulderAnklePx,
    required this.allLandmarks,
  });
}
