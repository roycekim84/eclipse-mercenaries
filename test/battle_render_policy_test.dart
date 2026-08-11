import 'package:eclipse_mercenaries/domain/battle_render_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('standard render policy preserves readable sampled feedback', () {
    const policy = BattleRenderPolicy(performanceMode: false);

    expect(policy.terrainGridStep, 48);
    expect(policy.terrainStainCount, 20);
    expect(policy.showsShadow(detailed: false, important: false), isTrue);
    expect(policy.emitsSlash(0), isTrue);
    expect(policy.emitsSlash(1), isFalse);
    expect(policy.emitsSlash(2), isFalse);
    expect(policy.emitsSlash(4), isFalse);
    expect(policy.emitsSlash(6), isTrue);
    expect(policy.emitsDamageNumber(sequence: 0, critical: false), isTrue);
    expect(policy.emitsDamageNumber(sequence: 1, critical: false), isFalse);
    expect(policy.emitsDamageNumber(sequence: 1, critical: true), isTrue);
  });

  test('performance policy reduces distant decoration and cosmetic VFX', () {
    const policy = BattleRenderPolicy(performanceMode: true);

    expect(policy.terrainGridStep, 96);
    expect(policy.terrainStainCount, 10);
    expect(
      policy.showsDetail(
        distance: 400,
        viewportLongestSide: 1000,
        important: false,
      ),
      isFalse,
    );
    expect(
      policy.showsDetail(
        distance: 900,
        viewportLongestSide: 1000,
        important: true,
      ),
      isTrue,
    );
    expect(policy.showsShadow(detailed: false, important: false), isFalse);
    expect(policy.emitsSlash(0), isTrue);
    expect(policy.emitsSlash(1), isFalse);
    expect(policy.emitsSlash(2), isFalse);
    expect(policy.emitsSlash(4), isFalse);
    expect(policy.emitsSlash(8), isFalse);
    expect(policy.emitsSlash(12), isTrue);
    expect(policy.emitsDamageNumber(sequence: 1, critical: false), isFalse);
    expect(policy.emitsDamageNumber(sequence: 1, critical: true), isTrue);
  });
}
