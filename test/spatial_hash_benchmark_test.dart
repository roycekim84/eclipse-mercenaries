import 'package:eclipse_mercenaries/domain/spatial_hash_benchmark.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spatial grid benchmark covers all alpha stress populations', () {
    for (final unitCount in const [330, 500, 750, 1000]) {
      final result = SpatialHashBenchmark.run(unitCount: unitCount, frames: 8);

      expect(result.unitCount, unitCount);
      expect(result.frames, 8);
      expect(result.candidateChecks, greaterThan(0));
      expect(result.candidateRatio, lessThan(.35));
      expect(result.p95FrameMs, greaterThanOrEqualTo(0));
      expect(result.allocatedBuckets, lessThanOrEqualTo(300));
    }
  });
}
