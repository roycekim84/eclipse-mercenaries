// ignore_for_file: avoid_print

import 'package:eclipse_mercenaries/domain/battle_render_policy.dart';

void main() {
  const visibleUnits = 500;
  const viewportLongestSide = 1280.0;
  for (final performanceMode in const [false, true]) {
    final policy = BattleRenderPolicy(performanceMode: performanceMode);
    var detailedUnits = 0;
    var shadows = 0;
    var emittedSlashes = 0;
    var emittedDamageNumbers = 0;
    for (var index = 0; index < visibleUnits; index++) {
      final important = index % 25 == 0;
      final distance = (index % 100) * 9.0;
      final detailed = policy.showsDetail(
        distance: distance,
        viewportLongestSide: viewportLongestSide,
        important: important,
      );
      if (detailed) detailedUnits++;
      if (policy.showsShadow(detailed: detailed, important: important)) {
        shadows++;
      }
      if (policy.emitsSlash(index)) emittedSlashes++;
      if (policy.emitsDamageNumber(sequence: index, critical: important)) {
        emittedDamageNumbers++;
      }
    }
    print(
      '${performanceMode ? 'performance' : 'standard'}: '
      'sprite submissions=1, detail=$detailedUnits, shadows=$shadows, '
      'slash emissions=$emittedSlashes, damage numbers=$emittedDamageNumbers',
    );
  }
  print('legacy sprite submissions=$visibleUnits');
}
