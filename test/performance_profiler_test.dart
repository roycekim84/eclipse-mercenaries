import 'package:eclipse_mercenaries/domain/battle_performance.dart';
import 'package:eclipse_mercenaries/domain/reusable_spatial_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('performance profiler keeps only its fixed sample capacity', () {
    final profiler = BattlePerformanceProfiler(capacity: 512);

    for (var sample = 0; sample < 20000; sample++) {
      final value = (sample % 100).toDouble();
      profiler.recordUpdate(
        totalMs: value,
        aiMs: value / 2,
        combatMs: value / 4,
        weaponsMs: value / 8,
      );
      profiler.recordRender(value / 3);
    }
    profiler
      ..peakProjectiles = 64
      ..peakEffects = 96
      ..peakDamageNumbers = 36;

    final metrics = profiler.snapshot(spatialBuckets: 264);
    expect(metrics.sampleCount, 512);
    expect(metrics.updateP95Ms, inInclusiveRange(94, 96));
    expect(metrics.renderCpuP95Ms, greaterThan(30));
    expect(metrics.spatialBuckets, 264);
    expect(metrics.peakProjectiles, 64);
    expect(metrics.peakEffects, 96);
    expect(metrics.peakDamageNumbers, 36);
  });

  test('spatial grid reuses buckets through a long simulation', () {
    final grid = ReusableSpatialGrid();

    for (var frame = 0; frame < 10000; frame++) {
      grid.beginFrame();
      for (var index = 0; index < 1000; index++) {
        grid.add(
          x: ((index % 22) * 96 + frame % 80).toDouble(),
          y: (((index ~/ 22) % 12) * 96 + frame % 80).toDouble(),
          index: index,
        );
      }
    }

    expect(grid.activeCellCount, lessThanOrEqualTo(264));
    expect(grid.allocatedBucketCount, lessThanOrEqualTo(264));
  });
}
