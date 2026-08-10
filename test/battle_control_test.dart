import 'package:eclipse_mercenaries/domain/battle_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('battle controls start ready without an active command', () {
    const state = BattleControlState.ready();
    expect(state.dashCooldown, 0);
    expect(state.tacticalCooldown, 0);
    expect(state.tacticalActive, isFalse);
  });

  test('dash distance scales with speed inside a fixed tactical budget', () {
    expect(BattleControlRules.dashDistance(50), 92);
    expect(BattleControlRules.dashDistance(160), closeTo(115.2, .001));
    expect(BattleControlRules.dashDistance(300), 132);
  });

  test('combat actions expose stable cooldown budgets', () {
    expect(BattleControlRules.dashCooldownSeconds, 2.5);
    expect(BattleControlRules.tacticalCooldownSeconds, 14);
    expect(BattleControlRules.tacticalDurationSeconds, 4);
  });

  test(
    'dash grants a short response window and contact damage scales by rank',
    () {
      expect(BattleControlRules.dashInvulnerabilitySeconds, greaterThan(.3));
      expect(BattleControlRules.dashInvulnerabilitySeconds, lessThan(.5));
      expect(BattleControlRules.contactDamage(UnitRole.infantry), 30);
      expect(
        BattleControlRules.contactDamage(UnitRole.commander, boss: true),
        70,
      );
      expect(
        BattleControlRules.contactDamage(
          UnitRole.cavalry,
          elite: true,
          battlefieldBonus: 3,
        ),
        48,
      );
    },
  );
}
