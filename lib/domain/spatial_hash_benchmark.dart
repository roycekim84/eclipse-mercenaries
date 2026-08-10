import 'dart:math' as math;

class SpatialHashBenchmarkResult {
  const SpatialHashBenchmarkResult({
    required this.unitCount,
    required this.frames,
    required this.p95FrameMs,
    required this.averageFrameMs,
    required this.candidateChecks,
    required this.naiveChecks,
  });

  final int unitCount;
  final int frames;
  final double p95FrameMs;
  final double averageFrameMs;
  final int candidateChecks;
  final int naiveChecks;

  double get candidateRatio => candidateChecks / naiveChecks;
}

/// Deterministic CPU harness mirroring the battlefield's 96 px spatial grid.
///
/// This does not replace browser frame profiling. It isolates movement, grid
/// rebuilds, and 5x5-cell opponent queries so regressions can be compared at
/// the alpha target populations without running a full 45-second contract.
abstract final class SpatialHashBenchmark {
  static const double _cellSize = 96;
  static const double _width = 2048;
  static const double _height = 1152;

  static SpatialHashBenchmarkResult run({
    required int unitCount,
    int frames = 120,
  }) {
    assert(unitCount > 1);
    assert(frames > 0);
    final units = List<_BenchmarkUnit>.generate(unitCount, (index) {
      final column = index % 32;
      final row = index ~/ 32;
      return _BenchmarkUnit(
        x: 24 + column * 61 + (row % 3) * 7,
        y: 24 + (row * 47) % 1080,
        vx: index.isEven ? 0.82 : -0.71,
        vy: index % 3 == 0 ? 0.38 : -0.29,
        faction: index & 1,
      );
    });
    final grid = <int, List<int>>{};
    final frameMicros = <int>[];
    var candidateChecks = 0;

    for (var frame = 0; frame < frames; frame++) {
      final stopwatch = Stopwatch()..start();
      grid.clear();
      for (var index = 0; index < units.length; index++) {
        final unit = units[index];
        unit.move();
        final key = _cellKey(unit.x, unit.y);
        (grid[key] ??= <int>[]).add(index);
      }
      for (final unit in units) {
        final cellX = unit.x ~/ _cellSize;
        final cellY = unit.y ~/ _cellSize;
        var nearestSquared = double.infinity;
        for (var y = cellY - 2; y <= cellY + 2; y++) {
          for (var x = cellX - 2; x <= cellX + 2; x++) {
            final candidates = grid[x * 10000 + y];
            if (candidates == null) continue;
            for (final candidateIndex in candidates) {
              final candidate = units[candidateIndex];
              if (candidate.faction == unit.faction) continue;
              candidateChecks++;
              final dx = candidate.x - unit.x;
              final dy = candidate.y - unit.y;
              nearestSquared = math.min(nearestSquared, dx * dx + dy * dy);
            }
          }
        }
        if (nearestSquared.isNegative) {
          throw StateError('unreachable benchmark guard');
        }
      }
      stopwatch.stop();
      frameMicros.add(stopwatch.elapsedMicroseconds);
    }

    final sorted = [...frameMicros]..sort();
    final p95Index = ((sorted.length - 1) * .95).round();
    final totalMicros = frameMicros.fold<int>(0, (sum, value) => sum + value);
    return SpatialHashBenchmarkResult(
      unitCount: unitCount,
      frames: frames,
      p95FrameMs: sorted[p95Index] / 1000,
      averageFrameMs: totalMicros / frames / 1000,
      candidateChecks: candidateChecks,
      naiveChecks: unitCount * unitCount * frames,
    );
  }

  static int _cellKey(double x, double y) =>
      (x ~/ _cellSize) * 10000 + (y ~/ _cellSize);
}

class _BenchmarkUnit {
  _BenchmarkUnit({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.faction,
  });

  double x;
  double y;
  double vx;
  double vy;
  final int faction;

  void move() {
    x += vx;
    y += vy;
    if (x < 0 || x > SpatialHashBenchmark._width) {
      vx = -vx;
      x = x.clamp(0, SpatialHashBenchmark._width);
    }
    if (y < 0 || y > SpatialHashBenchmark._height) {
      vy = -vy;
      y = y.clamp(0, SpatialHashBenchmark._height);
    }
  }
}
