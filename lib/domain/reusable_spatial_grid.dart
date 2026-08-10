class ReusableSpatialGrid {
  ReusableSpatialGrid({this.cellSize = 96});

  final double cellSize;
  final Map<int, List<int>> _buckets = <int, List<int>>{};
  final List<int> _activeKeys = <int>[];

  int get allocatedBucketCount => _buckets.length;
  int get activeCellCount => _activeKeys.length;

  void beginFrame() {
    for (final key in _activeKeys) {
      _buckets[key]!.clear();
    }
    _activeKeys.clear();
  }

  void add({required double x, required double y, required int index}) {
    final key = cellKey(x, y);
    final bucket = _buckets[key] ??= <int>[];
    if (bucket.isEmpty) _activeKeys.add(key);
    bucket.add(index);
  }

  List<int> bucketAt(int x, int y) => _buckets[x * 10000 + y] ?? const <int>[];

  int cellX(double x) => x ~/ cellSize;
  int cellY(double y) => y ~/ cellSize;
  int cellKey(double x, double y) => cellX(x) * 10000 + cellY(y);
}
