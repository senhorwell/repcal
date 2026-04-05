/// Engine de física que implementa toda a cadeia de cálculo do vídeo:
///   px → metros → v(t) → a(t) → F(t) → Trabalho (J) → kcal
///
/// Deve ser instanciada uma vez por sessão de treino.
/// Chame [reset] para reiniciar sem recriar o objeto.
class PhysicsEngine {
  // ── Constantes físicas ───────────────────────────────────────────────────
  static const double _g = 9.81; // m/s²
  static const double _efficiency = 0.25; // eficiência muscular média (25 %)
  static const double _joulesPerKcal = 4184.0;

  // ── Parâmetros do usuário ─────────────────────────────────────────────────
  final double massKg;
  final double pixelsPerMeter; // Fator de calibração: px / m

  // ── Estado interno ────────────────────────────────────────────────────────
  double _prevYMeters = 0;
  double _prevVelocity = 0;
  double _totalKcal = 0;
  int _repCount = 0;

  // Detecção de repetição por threshold de posição
  double _repStartY = 0;
  bool _isGoingUp = false;
  static const double _repMinDisplacementM = 0.15; // mín. 15 cm para contar rep

  PhysicsEngine({required this.massKg, required this.pixelsPerMeter});

  // ── API pública ───────────────────────────────────────────────────────────

  double get totalKcal => _totalKcal;
  int get repCount => _repCount;

  /// Processa um frame com a posição Y do mid_hip em pixels.
  /// [yPx]  posição Y em pixels (eixo Y cresce para baixo na tela).
  /// [dt]   intervalo de tempo desde o último frame (segundos).
  /// Retorna a força média aplicada neste frame (N).
  double processFrame(double yPx, double dt) {
    if (dt <= 0) return 0;

    final yMeters = yPx / pixelsPerMeter;
    final dy = yMeters - _prevYMeters; // + = descendo, - = subindo

    // ── Cinemática ──────────────────────────────────────────────────────────
    final velocity = dy / dt; // m/s
    final acceleration = (velocity - _prevVelocity) / dt; // m/s²

    // ── Dinâmica (apenas na fase de subida, dy < 0) ─────────────────────────
    double forceN = 0;
    if (dy < 0) {
      // Força resultante: vence a gravidade e gera aceleração
      forceN = massKg * (acceleration.abs() + _g);

      // Trabalho mecânico neste frame (Joules)
      final workJoules = forceN * dy.abs();

      // Energia metabólica total (considerando eficiência de 25 %)
      final energyJoules = workJoules / _efficiency;

      // Conversão para kcal
      _totalKcal += energyJoules / _joulesPerKcal;

      // ── Detecção de repetição ──────────────────────────────────────────────
      if (!_isGoingUp) {
        _isGoingUp = true;
        _repStartY = yMeters;
      }
    } else {
      if (_isGoingUp) {
        // Usuário começou a descer: verifica se o deslocamento foi suficiente
        final displacement = (_repStartY - _prevYMeters).abs();
        if (displacement >= _repMinDisplacementM) {
          _repCount++;
        }
        _isGoingUp = false;
      }
    }

    _prevYMeters = yMeters;
    _prevVelocity = velocity;
    return forceN;
  }

  void reset() {
    _prevYMeters = 0;
    _prevVelocity = 0;
    _totalKcal = 0;
    _repCount = 0;
    _repStartY = 0;
    _isGoingUp = false;
  }
}

// ─── Squat Engine ─────────────────────────────────────────────────────────────
/// Calcula calorias para agachamento usando a fórmula direta:
///   W = P × g × h × n
///   C = W / (4184 × η)
///
/// O deslocamento h é medido diretamente via MediaPipe (sem derivadas),
/// tornando o cálculo mais estável do que o método cinemático da barra.
class SquatEngine {
  static const double _g = 9.81;
  static const double _efficiency = 0.25;
  static const double _joulesPerKcal = 4184.0;
  static const double _repMinDisplacementM = 0.12; // mín. 12 cm para contar rep

  final double totalMassKg; // peso corporal + carga adicional
  final double pixelsPerMeter;

  double _totalKcal = 0;
  int _repCount = 0;
  double _lastRepDisplacementM = 0;

  // Rastreamento de posição para detectar rep
  double _prevYMeters = 0;
  double _topYMeters = 0; // posição mais alta do quadril na rep atual
  double _bottomYMeters = 0; // posição mais baixa (fundo do agachamento)
  bool _isGoingDown = false;

  SquatEngine({required this.totalMassKg, required this.pixelsPerMeter});

  double get totalKcal => _totalKcal;
  int get repCount => _repCount;
  double get lastRepDisplacementM => _lastRepDisplacementM;

  /// Processa um frame.
  /// No agachamento, dy > 0 = descendo, dy < 0 = subindo (voltando ao topo).
  /// A caloria é computada no momento em que a rep é concluída (subida completa).
  void processFrame(double yPx) {
    final yMeters = yPx / pixelsPerMeter;
    final dy = yMeters - _prevYMeters;

    if (dy > 0.005) {
      // ── Descendo ──────────────────────────────────────────────────────────
      if (!_isGoingDown) {
        _isGoingDown = true;
        _topYMeters = _prevYMeters; // registra ponto de partida (em pé)
      }
      _bottomYMeters = yMeters; // atualiza fundo da descida
    } else if (dy < -0.005 && _isGoingDown) {
      // ── Subindo de volta ───────────────────────────────────────────────────
      final displacement = (_bottomYMeters - _topYMeters).abs();
      if (displacement >= _repMinDisplacementM) {
        // Rep concluída — calcula energia desta repetição
        // W = P × g × h  (uma rep = uma subida)
        final workJoules = totalMassKg * _g * displacement;
        final energyJoules = workJoules / _efficiency;
        _totalKcal += energyJoules / _joulesPerKcal;
        _lastRepDisplacementM = displacement;
        _repCount++;
      }
      _isGoingDown = false;
    }

    _prevYMeters = yMeters;
  }

  void reset() {
    _totalKcal = 0;
    _repCount = 0;
    _lastRepDisplacementM = 0;
    _prevYMeters = 0;
    _topYMeters = 0;
    _bottomYMeters = 0;
    _isGoingDown = false;
  }
}

// ─── Calibration Helper ───────────────────────────────────────────────────────
/// Acumula amostras de ombro-tornozelo durante a fase de calibração e
/// devolve o [pixelsPerMeter] assim que [minSamples] forem coletadas.
class CalibrationHelper {
  final double heightM; // altura real do usuário em metros
  final int minSamples; // quantas amostras antes de concluir
  final double
  shoulderRatio; // fração da altura representada por ombro-tornozelo

  final List<double> _samples = [];

  CalibrationHelper({
    required this.heightM,
    this.minSamples = 60, // ~2 segundos a 30 fps
    this.shoulderRatio = 0.82, // ombro-tornozelo ≈ 82% da altura total
  });

  double get progress => (_samples.length / minSamples).clamp(0.0, 1.0);
  bool get isDone => _samples.length >= minSamples;

  /// Adiciona uma amostra (em pixels). Retorna null se ainda não concluiu.
  double? addSample(double shoulderAnklePx) {
    _samples.add(shoulderAnklePx);
    if (!isDone) return null;

    // Mediana para descartar outliers
    final sorted = List<double>.from(_samples)..sort();
    final medianPx = sorted[sorted.length ~/ 2];

    // Distância real correspondente
    final realDistM = heightM * shoulderRatio;

    return medianPx / realDistM; // px / m
  }

  void reset() => _samples.clear();
}
