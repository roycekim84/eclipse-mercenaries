import 'package:eclipse_mercenaries/core/content/game_content_repository.dart';
import 'package:eclipse_mercenaries/core/content/game_visuals.dart';
import 'package:eclipse_mercenaries/core/persistence/save_repository.dart';
import 'package:eclipse_mercenaries/domain/battle_models.dart';
import 'package:eclipse_mercenaries/domain/combat_rules.dart';
import 'package:eclipse_mercenaries/domain/game_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const content = StaticGameContentRepository();

  test('alpha content IDs resolve through the repository', () {
    expect(content.mercenaries, hasLength(3));
    expect(content.weapons, hasLength(8));
    expect(content.mercenaryById('kael').race, '늑대족');
    expect(content.weaponById('glass_flame').ownerId, 'sera');
  });

  test('every alpha content entry has presentation metadata', () {
    for (final mercenary in content.mercenaries) {
      expect(mercenary.visual.portraitAsset, startsWith('assets/images/'));
      expect(mercenary.visual.battleSpriteAsset, endsWith('_battle_sheet.png'));
    }
    for (final weapon in content.weapons) {
      expect(weapon.visual.icon.codePoint, isPositive);
    }
  });

  test('save repository preserves loadout and reward state', () {
    final repository = InMemorySaveRepository();
    final initial = repository.load();
    final updated = initial.copyWith(
      gold: initial.gold + 500,
      selectedMercenaryId: 'kael',
      equippedWeaponByMercenary: {
        ...initial.equippedWeaponByMercenary,
        'kael': 'iron_sword',
      },
    );

    repository.save(updated);

    expect(repository.load().gold, 46178);
    expect(repository.load().selectedMercenaryId, 'kael');
    expect(repository.load().equippedWeaponByMercenary['kael'], 'iron_sword');
  });

  test('battle config is an immutable session boundary', () {
    final config = BattleConfig(
      mercenary: content.mercenaryById('sera'),
      weapon: content.weaponById('glass_flame'),
      durationSeconds: 300,
      seed: 20260809,
    );

    expect(config.mercenary.style.name, 'magic');
    expect(config.weapon.name, '유리불꽃 지팡이');
    expect(config.durationSeconds, 300);
    expect(config.seed, 20260809);
  });

  test('every mercenary has one resolvable signature ultimate pairing', () {
    final ultimateNames = <String>{};
    for (final mercenary in content.mercenaries) {
      final signature = content.weaponById(mercenary.signatureWeaponId);
      expect(signature.ownerId, mercenary.id);
      expect(mercenary.ultimate, isNotEmpty);
      ultimateNames.add(mercenary.ultimate);
    }

    expect(ultimateNames, hasLength(content.mercenaries.length));
  });

  test('gate defense outcome is resolved from time and gate durability', () {
    expect(
      GateDefenseRules.resolve(gateHp: 0, secondsLeft: 12),
      BattleOutcome.defeat,
    );
    expect(
      GateDefenseRules.resolve(gateHp: 1, secondsLeft: 0),
      BattleOutcome.victory,
    );
    expect(
      GateDefenseRules.resolve(gateHp: 800, secondsLeft: 20),
      BattleOutcome.retreat,
    );
  });

  test('gate defense bonuses use durability pressure and elite conditions', () {
    expect(
      GateDefenseRules.completedBonuses(
        gateHpRatio: .8,
        frontPressure: .2,
        elitesCleared: true,
      ),
      ['gate_75', 'line_held', 'elite_clear'],
    );
    expect(
      GateDefenseRules.completedBonuses(
        gateHpRatio: .5,
        frontPressure: .7,
        elitesCleared: false,
      ),
      isEmpty,
    );
  });

  test('every battlefield role has valid combat rules', () {
    for (final role in UnitRole.values) {
      expect(UnitRoleRules.maxHp(role), isPositive);
      expect(UnitRoleRules.speed(role), isPositive);
      expect(UnitRoleRules.attackRange(role), isPositive);
      expect(UnitRoleRules.damage(role), isPositive);
      expect(UnitRoleRules.defense(role), isPositive);
    }
  });

  test('battlefield roles preserve their tactical strengths', () {
    expect(
      UnitRoleRules.speed(UnitRole.cavalry),
      greaterThan(UnitRoleRules.speed(UnitRole.infantry)),
    );
    expect(
      UnitRoleRules.maxHp(UnitRole.shield),
      greaterThan(UnitRoleRules.maxHp(UnitRole.infantry)),
    );
    expect(
      UnitRoleRules.attackRange(UnitRole.archer),
      greaterThan(UnitRoleRules.attackRange(UnitRole.infantry)),
    );
    expect(
      UnitRoleRules.damage(UnitRole.siege),
      greaterThan(UnitRoleRules.damage(UnitRole.cavalry)),
    );
    expect(
      UnitRoleRules.maxHp(UnitRole.commander),
      greaterThan(UnitRoleRules.maxHp(UnitRole.siege)),
    );
  });

  test('damage resolver applies defense critical and pure damage rules', () {
    final defended = DamageResolver.resolve(
      const DamageRequest(
        baseDamage: 100,
        defense: 100,
        criticalChance: 0,
        criticalRoll: .5,
      ),
    );
    final critical = DamageResolver.resolve(
      const DamageRequest(
        baseDamage: 100,
        defense: 100,
        criticalChance: 25,
        criticalRoll: .1,
      ),
    );
    final pure = DamageResolver.resolve(
      const DamageRequest(
        baseDamage: 100,
        defense: 999,
        criticalChance: 0,
        criticalRoll: .5,
        kind: DamageKind.pure,
      ),
    );

    expect(defended.amount, 50);
    expect(critical.amount, 75);
    expect(critical.isCritical, isTrue);
    expect(pure.amount, 100);
  });

  test('damage resolver applies status only when its roll succeeds', () {
    final applied = DamageResolver.resolve(
      const DamageRequest(
        baseDamage: 10,
        defense: 0,
        criticalChance: 0,
        criticalRoll: 1,
        status: StatusEffectType.bleed,
        statusChance: .4,
        statusRoll: .2,
      ),
    );
    final resisted = DamageResolver.resolve(
      const DamageRequest(
        baseDamage: 10,
        defense: 0,
        criticalChance: 0,
        criticalRoll: 1,
        status: StatusEffectType.burn,
        statusChance: .4,
        statusRoll: .8,
      ),
    );

    expect(applied.appliedStatus, StatusEffectType.bleed);
    expect(resisted.appliedStatus, StatusEffectType.none);
  });

  test('all eight alpha weapons expose distinct attack patterns', () {
    expect(content.weapons, hasLength(WeaponPattern.values.length));
    expect(
      content.weapons.map((weapon) => weapon.pattern).toSet(),
      hasLength(WeaponPattern.values.length),
    );
  });
}
