import 'dart:math' as math;

import 'package:eclipse_mercenaries/core/content/game_content_repository.dart';
import 'package:eclipse_mercenaries/core/content/game_visuals.dart';
import 'package:eclipse_mercenaries/core/persistence/save_repository.dart';
import 'package:eclipse_mercenaries/domain/battle_models.dart';
import 'package:eclipse_mercenaries/domain/combat_rules.dart';
import 'package:eclipse_mercenaries/domain/enemy_catalog.dart';
import 'package:eclipse_mercenaries/domain/game_data.dart';
import 'package:eclipse_mercenaries/domain/run_growth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const content = StaticGameContentRepository();

  test('alpha content IDs resolve through the repository', () {
    expect(content.mercenaries, hasLength(3));
    expect(content.weapons, hasLength(8));
    expect(content.enemies, hasLength(12));
    expect(content.mercenaryById('kael').race, '늑대족');
    expect(content.weaponById('glass_flame').ownerId, 'sera');
  });

  test('enemy catalog satisfies alpha content counts', () {
    expect(EnemyCatalog.common, hasLength(8));
    expect(EnemyCatalog.elite, hasLength(2));
    expect(EnemyCatalog.boss, hasLength(2));
    expect(
      alphaEnemyArchetypes.map((enemy) => enemy.id).toSet(),
      hasLength(alphaEnemyArchetypes.length),
    );
  });

  test('common enemies expose eight distinct battlefield abilities', () {
    expect(
      EnemyCatalog.common.map((enemy) => enemy.ability).toSet(),
      hasLength(8),
    );
    for (final enemy in EnemyCatalog.common) {
      expect(enemy.abilityDescription, isNotEmpty);
      expect(enemy.lore, isNotEmpty);
      expect(enemy.visual.color.a, greaterThan(0));
    }
  });

  test('elite and boss enemies always expose rare drops', () {
    for (final enemy in [...EnemyCatalog.elite, ...EnemyCatalog.boss]) {
      expect(enemy.rareDropId, isNotNull);
      expect(enemy.hpBonus, isPositive);
    }
  });

  test('battlefields use tactically different boss archetypes', () {
    final siegeMarshal = EnemyCatalog.byId('siege_marshal');
    final huntCaptain = EnemyCatalog.byId('hunt_captain');

    expect(siegeMarshal.ability, EnemyAbility.commandSiege);
    expect(huntCaptain.ability, EnemyAbility.huntMark);
    expect(siegeMarshal.role, UnitRole.commander);
    expect(huntCaptain.role, UnitRole.commander);
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
      battlefield: BattlefieldType.evacuation,
      condition: BattlefieldCondition.ashWind,
      durationSeconds: 300,
      seed: 20260809,
      unitCount: 500,
    );

    expect(config.mercenary.style.name, 'magic');
    expect(config.weapon.name, '유리불꽃 지팡이');
    expect(config.durationSeconds, 300);
    expect(config.seed, 20260809);
    expect(config.battlefield, BattlefieldType.evacuation);
    expect(config.condition, BattlefieldCondition.ashWind);
    expect(config.unitCount, 500);
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

  test('evacuation requires eight escorts to escape', () {
    expect(
      EvacuationRules.resolve(alive: 4, escaped: 8, secondsLeft: 12),
      BattleOutcome.victory,
    );
    expect(
      EvacuationRules.resolve(alive: 7, escaped: 0, secondsLeft: 20),
      BattleOutcome.defeat,
    );
    expect(
      EvacuationRules.resolve(alive: 10, escaped: 2, secondsLeft: 20),
      BattleOutcome.retreat,
    );
    expect(
      EvacuationRules.resolve(alive: 10, escaped: 2, secondsLeft: 0),
      BattleOutcome.defeat,
    );
  });

  test('evacuation bonuses reward survival commander and speed', () {
    expect(
      EvacuationRules.completedBonuses(
        escaped: 11,
        total: 12,
        enemyCommanderDefeated: true,
        secondsLeft: 9,
      ),
      ['convoy_90', 'pursuer_commander', 'swift_exit'],
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

  test('run upgrade choices are reproducible for the same seed', () {
    const definitions = [
      RunUpgradeDefinition(
        id: 'weapon_a',
        kind: RunUpgradeKind.weapon,
        maxLevel: 5,
        baseWeight: 70,
      ),
      RunUpgradeDefinition(
        id: 'weapon_b',
        kind: RunUpgradeKind.weapon,
        maxLevel: 5,
        baseWeight: 60,
      ),
      ...alphaPassiveDefinitions,
      RunUpgradeDefinition(
        id: 'trait',
        kind: RunUpgradeKind.trait,
        maxLevel: 3,
        baseWeight: 55,
      ),
    ];
    const state = RunGrowthState(
      weaponLevels: {'weapon_a': 1},
      passiveLevels: {},
      traitLevel: 0,
    );

    final first = RunGrowthRules.generateChoices(
      definitions: definitions,
      state: state,
      random: math.Random(20260810),
    );
    final second = RunGrowthRules.generateChoices(
      definitions: definitions,
      state: state,
      random: math.Random(20260810),
    );

    expect(first.map((choice) => choice.id), second.map((choice) => choice.id));
    expect(first.map((choice) => choice.id).toSet(), hasLength(first.length));
  });

  test('run growth excludes maxed upgrades and blocked weapon slots', () {
    const definitions = [
      RunUpgradeDefinition(
        id: 'owned',
        kind: RunUpgradeKind.weapon,
        maxLevel: 5,
        baseWeight: 70,
      ),
      RunUpgradeDefinition(
        id: 'new_weapon',
        kind: RunUpgradeKind.weapon,
        maxLevel: 5,
        baseWeight: 70,
      ),
      RunUpgradeDefinition(
        id: 'passive',
        kind: RunUpgradeKind.passive,
        maxLevel: 5,
        baseWeight: 70,
      ),
      RunUpgradeDefinition(
        id: 'trait',
        kind: RunUpgradeKind.trait,
        maxLevel: 3,
        baseWeight: 70,
      ),
    ];
    const state = RunGrowthState(
      weaponLevels: {'owned': 5},
      passiveLevels: {'passive': 5},
      traitLevel: 3,
      maxWeaponSlots: 1,
    );

    final choices = RunGrowthRules.generateChoices(
      definitions: definitions,
      state: state,
      random: math.Random(1),
    );

    expect(choices, isEmpty);
  });

  test('owned weapons remain upgradeable when weapon slots are full', () {
    const definition = RunUpgradeDefinition(
      id: 'owned',
      kind: RunUpgradeKind.weapon,
      maxLevel: 5,
      baseWeight: 70,
    );
    const state = RunGrowthState(
      weaponLevels: {'owned': 2},
      passiveLevels: {},
      traitLevel: 0,
      maxWeaponSlots: 1,
    );

    expect(state.canOffer(definition), isTrue);
  });
}
