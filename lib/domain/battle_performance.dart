import 'battle_models.dart';

class BattlePerformanceProfiler {
  BattlePerformanceProfiler({this.capacity = 512})
    : _update = _FixedSampleWindow(capacity),
      _ai = _FixedSampleWindow(capacity),
      _combat = _FixedSampleWindow(capacity),
      _weapons = _FixedSampleWindow(capacity),
      _render = _FixedSampleWindow(capacity);

  final int capacity;
  final _FixedSampleWindow _update;
  final _FixedSampleWindow _ai;
  final _FixedSampleWindow _combat;
  final _FixedSampleWindow _weapons;
  final _FixedSampleWindow _render;

  int peakProjectiles = 0;
  int peakEffects = 0;
  int peakDamageNumbers = 0;

  void recordUpdate({
    required double totalMs,
    required double aiMs,
    required double combatMs,
    required double weaponsMs,
  }) {
    _update.add(totalMs);
    _ai.add(aiMs);
    _combat.add(combatMs);
    _weapons.add(weaponsMs);
  }

  void recordRender(double milliseconds) => _render.add(milliseconds);

  BattlePerformanceMetrics snapshot({required int spatialBuckets}) =>
      BattlePerformanceMetrics(
        sampleCount: _update.count,
        updateP95Ms: _update.p95,
        aiP95Ms: _ai.p95,
        combatP95Ms: _combat.p95,
        weaponsP95Ms: _weapons.p95,
        renderCpuP95Ms: _render.p95,
        spatialBuckets: spatialBuckets,
        peakProjectiles: peakProjectiles,
        peakEffects: peakEffects,
        peakDamageNumbers: peakDamageNumbers,
      );
}

class _FixedSampleWindow {
  _FixedSampleWindow(int capacity) : _samples = List.filled(capacity, 0);

  final List<double> _samples;
  int _index = 0;
  int count = 0;

  void add(double value) {
    if (!value.isFinite || value < 0) return;
    _samples[_index] = value;
    _index = (_index + 1) % _samples.length;
    if (count < _samples.length) count++;
  }

  double get p95 {
    if (count == 0) return 0;
    final sorted = _samples.take(count).toList()..sort();
    return sorted[((sorted.length - 1) * .95).round()];
  }
}
