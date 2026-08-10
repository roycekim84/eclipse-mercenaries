// ignore_for_file: avoid_print

import 'dart:io';

import 'package:eclipse_mercenaries/domain/battle_performance.dart';
import 'package:eclipse_mercenaries/domain/reusable_spatial_grid.dart';

void main() {
  const unitCount = 1000;
  const frames = 18000;
  const warmupFrames = 1200;
  final grid = ReusableSpatialGrid();
  final profiler = BattlePerformanceProfiler();
  final x = List<double>.generate(unitCount, (i) => (i % 22) * 96 + 8);
  final y = List<double>.generate(unitCount, (i) => ((i ~/ 22) % 12) * 96 + 8);
  final initialRss = ProcessInfo.currentRss;
  var warmupRss = initialRss;
  var warmupBuckets = 0;
  final clock = Stopwatch()..start();

  for (var frame = 0; frame < frames; frame++) {
    grid.beginFrame();
    for (var index = 0; index < unitCount; index++) {
      x[index] += index.isEven ? .82 : -.71;
      y[index] += index % 3 == 0 ? .38 : -.29;
      if (x[index] < 0) x[index] += 2112;
      if (x[index] >= 2112) x[index] -= 2112;
      if (y[index] < 0) y[index] += 1152;
      if (y[index] >= 1152) y[index] -= 1152;
      grid.add(x: x[index], y: y[index], index: index);
    }
    final syntheticMs = 4 + (frame % 40) / 100;
    profiler.recordUpdate(
      totalMs: syntheticMs,
      aiMs: syntheticMs * .48,
      combatMs: syntheticMs * .24,
      weaponsMs: syntheticMs * .12,
    );
    profiler.recordRender(syntheticMs * .4);
    if (frame == warmupFrames) {
      warmupRss = ProcessInfo.currentRss;
      warmupBuckets = grid.allocatedBucketCount;
    }
  }
  clock.stop();

  final finalRss = ProcessInfo.currentRss;
  final metrics = profiler.snapshot(spatialBuckets: grid.allocatedBucketCount);
  final deltaMb = (finalRss - warmupRss) / (1024 * 1024);
  print('Long-run allocation harness · 5 simulated minutes at 60 Hz');
  print(
    'units=$unitCount frames=$frames elapsed=${clock.elapsedMilliseconds}ms',
  );
  print(
    'rss initial=${_mb(initialRss)}MB warm=${_mb(warmupRss)}MB '
    'final=${_mb(finalRss)}MB delta=${deltaMb.toStringAsFixed(2)}MB',
  );
  print(
    'buckets warm=$warmupBuckets final=${grid.allocatedBucketCount} '
    'samples=${metrics.sampleCount}',
  );

  if (grid.allocatedBucketCount > 264 ||
      grid.allocatedBucketCount > warmupBuckets) {
    stderr.writeln('Reusable spatial buckets grew after warm-up.');
    exitCode = 1;
  }
}

String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(2);
