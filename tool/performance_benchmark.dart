// ignore_for_file: avoid_print

import 'package:eclipse_mercenaries/domain/spatial_hash_benchmark.dart';

void main() {
  const populations = [330, 500, 750, 1000];
  SpatialHashBenchmark.run(unitCount: 500, frames: 30);
  print('Spatial hash CPU benchmark · 120 simulated frames');
  print('units | avg ms | p95 ms | candidate / naive');
  for (final unitCount in populations) {
    final result = SpatialHashBenchmark.run(unitCount: unitCount);
    final percent = result.candidateRatio * 100;
    print(
      '${result.unitCount.toString().padLeft(5)} | '
      '${result.averageFrameMs.toStringAsFixed(3).padLeft(6)} | '
      '${result.p95FrameMs.toStringAsFixed(3).padLeft(6)} | '
      '${percent.toStringAsFixed(2).padLeft(6)}%',
    );
  }
}
