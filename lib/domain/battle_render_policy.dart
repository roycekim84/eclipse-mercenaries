class BattleRenderPolicy {
  const BattleRenderPolicy({required this.performanceMode});

  final bool performanceMode;

  double get terrainGridStep => performanceMode ? 96 : 48;
  int get terrainStainCount => performanceMode ? 10 : 20;

  double detailRadius(double viewportLongestSide) =>
      viewportLongestSide * (performanceMode ? .34 : .58);

  bool showsDetail({
    required double distance,
    required double viewportLongestSide,
    required bool important,
  }) => important || distance <= detailRadius(viewportLongestSide);

  bool showsShadow({required bool detailed, required bool important}) =>
      !performanceMode || detailed || important;

  bool emitsSlash(int sequence) => !performanceMode || sequence.isEven;

  bool emitsDamageNumber({required int sequence, required bool critical}) =>
      !performanceMode || critical || sequence % 3 == 0;
}
