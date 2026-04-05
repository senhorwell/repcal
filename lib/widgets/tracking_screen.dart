import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/models.dart';
import '../services/pose_service.dart';
import '../services/physics_engine.dart';
import '../widgets/skeleton_painter.dart';
import '../widgets/hud_overlay.dart';

class TrackingScreen extends StatefulWidget {
  final CameraDescription camera;
  final UserProfile profile;

  const TrackingScreen({
    super.key,
    required this.camera,
    required this.profile,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with WidgetsBindingObserver {
  // ── Câmera ────────────────────────────────────────────────────────────────
  late CameraController _cameraController;
  bool _cameraReady = false;

  // ── Serviços ──────────────────────────────────────────────────────────────
  final _poseService = PoseService.instance;
  late CalibrationHelper _calibrationHelper;
  PhysicsEngine? _pullUpEngine;
  SquatEngine? _squatEngine;

  bool get _isPullUp => widget.profile.exercise == ExerciseType.pullUp;

  // ── Estado do treino ──────────────────────────────────────────────────────
  WorkoutState _state = const WorkoutState();
  Map<PoseLandmarkType, PoseLandmark> _landmarks = {};
  Size _imageSize = Size.zero;

  // ── Controle de tempo entre frames ───────────────────────────────────────
  DateTime? _lastFrameTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _calibrationHelper = CalibrationHelper(heightM: widget.profile.heightM);
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _cameraController.initialize();
    if (!mounted) return;

    setState(() {
      _cameraReady = true;
      _state = _state.copyWith(status: CalibrationStatus.calibrating);
    });

    _cameraController.startImageStream(_onFrame);
  }

  void _onFrame(CameraImage image) async {
    final rotation = _rotationForDevice();
    final result = await _poseService.processFrame(
      image: image,
      rotation: rotation,
      lensDirection: widget.camera.lensDirection,
    );

    if (result == null) return;
    if (!mounted) return;

    _imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final now = DateTime.now();
    final dt = _lastFrameTime != null
        ? now.difference(_lastFrameTime!).inMicroseconds / 1_000_000.0
        : 1 / 30.0;
    _lastFrameTime = now;

    // ── Fase de calibração ────────────────────────────────────────────────────
    if (_state.status == CalibrationStatus.calibrating) {
      if (result.shoulderAnklePx != null) {
        final pxPerMeter = _calibrationHelper.addSample(
          result.shoulderAnklePx!,
        );

        if (pxPerMeter != null) {
          // Calibração concluída — instancia a engine correta
          if (_isPullUp) {
            _pullUpEngine = PhysicsEngine(
              massKg: widget.profile.massKg,
              pixelsPerMeter: pxPerMeter,
            );
          } else {
            _squatEngine = SquatEngine(
              totalMassKg: widget.profile.totalMassKg,
              pixelsPerMeter: pxPerMeter,
            );
          }
          setState(() {
            _state = _state.copyWith(
              status: CalibrationStatus.tracking,
              pixelsPerMeter: pxPerMeter,
            );
            _landmarks = result.allLandmarks;
          });
        } else {
          setState(() {
            _state = _state.copyWith(
              calibrationProgress: _calibrationHelper.progress,
            );
            _landmarks = result.allLandmarks;
          });
        }
      }
      return;
    }

    // ── Fase de tracking ──────────────────────────────────────────────────────
    if (_state.status == CalibrationStatus.tracking) {
      if (_isPullUp && _pullUpEngine != null) {
        final forceN = _pullUpEngine!.processFrame(result.midHipY, dt);
        setState(() {
          _state = _state.copyWith(
            totalKcal: _pullUpEngine!.totalKcal,
            repCount: _pullUpEngine!.repCount,
            currentForceN: forceN,
            hipYMeters: result.midHipY / _state.pixelsPerMeter,
          );
          _landmarks = result.allLandmarks;
        });
      } else if (!_isPullUp && _squatEngine != null) {
        _squatEngine!.processFrame(result.midHipY);
        setState(() {
          _state = _state.copyWith(
            totalKcal: _squatEngine!.totalKcal,
            repCount: _squatEngine!.repCount,
            lastRepDisplacementM: _squatEngine!.lastRepDisplacementM,
            hipYMeters: result.midHipY / _state.pixelsPerMeter,
          );
          _landmarks = result.allLandmarks;
        });
      }
    }
  }

  InputImageRotation _rotationForDevice() {
    final sensorOrientation = widget.camera.sensorOrientation;
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  void _resetWorkout() {
    _pullUpEngine?.reset();
    _squatEngine?.reset();
    _calibrationHelper.reset();
    _lastFrameTime = null;
    setState(() {
      _state = const WorkoutState(status: CalibrationStatus.calibrating);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraController.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      _cameraController.startImageStream(_onFrame);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.stopImageStream();
    _cameraController.dispose();
    _poseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _cameraReady ? _buildBody() : _buildLoading(),
    );
  }

  Widget _buildLoading() =>
      const Center(child: CircularProgressIndicator(color: Color(0xFF1D9E75)));

  Widget _buildBody() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Preview da câmera ─────────────────────────────────────────────
        _buildCameraPreview(),

        // ── Overlay do esqueleto (CustomPainter) ──────────────────────────
        if (_landmarks.isNotEmpty && _imageSize != Size.zero)
          SkeletonPainterOverlay(
            landmarks: _landmarks,
            imageSize: _imageSize,
            screenSize: MediaQuery.of(context).size,
            state: _state,
          ),

        // ── HUD com métricas ──────────────────────────────────────────────
        HudOverlay(
          state: _state,
          profile: widget.profile,
          onReset: _resetWorkout,
          onBack: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController;
    final screenSize = MediaQuery.of(context).size;
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return const SizedBox.shrink();

    // previewSize vem em landscape (largura > altura) independente da orientação
    // Para portrait, invertemos
    final previewW = previewSize.height; // lado menor = largura em portrait
    final previewH = previewSize.width; // lado maior = altura em portrait

    final screenRatio = screenSize.width / screenSize.height;
    final previewRatio = previewW / previewH;

    // Escala mínima para cobrir a tela sem distorcer (cover)
    final scale = screenRatio > previewRatio
        ? screenSize.width / previewW
        : screenSize.height / previewH;

    return ClipRect(
      child: OverflowBox(
        maxWidth: previewW * scale,
        maxHeight: previewH * scale,
        child: SizedBox(
          width: previewW * scale,
          height: previewH * scale,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}
