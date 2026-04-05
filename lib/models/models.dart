// ─── models/user_profile.dart ───────────────────────────────────────────────

enum ExerciseType { pullUp, squat }

class UserProfile {
  final double massKg; // Peso corporal em kg
  final double heightM; // Altura em metros
  final double extraLoadKg; // Carga adicional (barra/halteres) — só agachamento
  final ExerciseType exercise;

  const UserProfile({
    required this.massKg,
    required this.heightM,
    this.extraLoadKg = 0,
    this.exercise = ExerciseType.pullUp,
  });

  /// Peso total usado nos cálculos de agachamento (corpo + carga)
  double get totalMassKg => massKg + extraLoadKg;
}

// ─── models/workout_state.dart ───────────────────────────────────────────────

enum CalibrationStatus { idle, calibrating, ready, tracking }

class WorkoutState {
  final CalibrationStatus status;
  final double totalKcal;
  final int repCount;
  final double currentForceN;
  final double? hipYMeters;
  final double pixelsPerMeter;
  final double calibrationProgress;
  final double lastRepDisplacementM; // deslocamento da última rep (agachamento)

  const WorkoutState({
    this.status = CalibrationStatus.idle,
    this.totalKcal = 0,
    this.repCount = 0,
    this.currentForceN = 0,
    this.hipYMeters,
    this.pixelsPerMeter = 1,
    this.calibrationProgress = 0,
    this.lastRepDisplacementM = 0,
  });

  WorkoutState copyWith({
    CalibrationStatus? status,
    double? totalKcal,
    int? repCount,
    double? currentForceN,
    double? hipYMeters,
    double? pixelsPerMeter,
    double? calibrationProgress,
    double? lastRepDisplacementM,
  }) {
    return WorkoutState(
      status: status ?? this.status,
      totalKcal: totalKcal ?? this.totalKcal,
      repCount: repCount ?? this.repCount,
      currentForceN: currentForceN ?? this.currentForceN,
      hipYMeters: hipYMeters ?? this.hipYMeters,
      pixelsPerMeter: pixelsPerMeter ?? this.pixelsPerMeter,
      calibrationProgress: calibrationProgress ?? this.calibrationProgress,
      lastRepDisplacementM: lastRepDisplacementM ?? this.lastRepDisplacementM,
    );
  }
}
