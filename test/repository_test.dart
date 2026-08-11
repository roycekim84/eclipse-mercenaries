import 'dart:convert';
import 'dart:math' as math;

import 'package:eclipse_mercenaries/app/game_app.dart';
import 'package:eclipse_mercenaries/core/content/game_content_repository.dart';
import 'package:eclipse_mercenaries/core/content/game_visuals.dart';
import 'package:eclipse_mercenaries/core/persistence/save_repository.dart';
import 'package:eclipse_mercenaries/domain/battle_models.dart';
import 'package:eclipse_mercenaries/domain/battle_diagnostics.dart';
import 'package:eclipse_mercenaries/domain/battlefield_events.dart';
import 'package:eclipse_mercenaries/domain/battle_rewards.dart';
import 'package:eclipse_mercenaries/domain/balance_manifest.dart';
import 'package:eclipse_mercenaries/domain/camp_meta.dart';
import 'package:eclipse_mercenaries/domain/combat_rules.dart';
import 'package:eclipse_mercenaries/domain/enemy_catalog.dart';
import 'package:eclipse_mercenaries/domain/economy.dart';
import 'package:eclipse_mercenaries/domain/game_data.dart';
import 'package:eclipse_mercenaries/domain/game_settings.dart';
import 'package:eclipse_mercenaries/domain/progression.dart';
import 'package:eclipse_mercenaries/domain/run_growth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const content = StaticGameContentRepository();

  test('beta content IDs resolve through the repository', () {
    expect(content.mercenaries, hasLength(8));
    expect(content.weapons, hasLength(16));
    expect(content.enemies, hasLength(27));
    expect(content.mercenaryById('kael').race, '늑대족');
    expect(content.weaponById('glass_flame').ownerId, 'sera');
  });

  test('enemy catalog satisfies beta content counts', () {
    expect(EnemyCatalog.common, hasLength(16));
    expect(EnemyCatalog.elite, hasLength(6));
    expect(EnemyCatalog.boss, hasLength(5));
    expect(
      alphaEnemyArchetypes.map((enemy) => enemy.id).toSet(),
      hasLength(alphaEnemyArchetypes.length),
    );
  });

  test('common enemies expose nine distinct battlefield abilities', () {
    expect(
      EnemyCatalog.common.map((enemy) => enemy.ability).toSet(),
      hasLength(9),
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

  test('every beta vertical-slice boss exposes three readable patterns', () {
    for (final boss in EnemyCatalog.boss) {
      final patterns = BossPatternCatalog.forBoss(boss.id);
      expect(patterns, hasLength(3), reason: boss.id);
      expect(patterns.map((pattern) => pattern.type).toSet(), hasLength(3));
      expect(
        patterns.every(
          (pattern) =>
              pattern.name.isNotEmpty &&
              pattern.warning.isNotEmpty &&
              pattern.telegraphSeconds >= 1.2,
        ),
        isTrue,
        reason: boss.id,
      );
    }
  });

  test('battlefield event catalog contains 24 complete unique events', () {
    expect(alphaBattlefieldEvents, hasLength(24));
    expect(
      alphaBattlefieldEvents.map((event) => event.id).toSet(),
      hasLength(24),
    );
    expect(
      alphaBattlefieldEvents.where(
        (event) => event.rarity == BattlefieldEventRarity.common,
      ),
      hasLength(10),
    );
    expect(
      alphaBattlefieldEvents.where(
        (event) => event.rarity == BattlefieldEventRarity.special,
      ),
      hasLength(7),
    );
    expect(
      alphaBattlefieldEvents.where(
        (event) => event.rarity == BattlefieldEventRarity.rare,
      ),
      hasLength(5),
    );
    expect(
      alphaBattlefieldEvents.where(
        (event) => event.rarity == BattlefieldEventRarity.legendary,
      ),
      hasLength(2),
    );
    expect(
      alphaBattlefieldEvents.map((event) => event.effect).toSet(),
      hasLength(BattlefieldEventEffect.values.length),
    );
    for (final event in alphaBattlefieldEvents) {
      expect(event.title, isNotEmpty);
      expect(event.description, isNotEmpty);
      expect(event.weight, isPositive);
      expect(event.choices, isNotEmpty);
      expect(
        event.choices.map((choice) => choice.id).toSet(),
        hasLength(event.choices.length),
      );
      for (final choice in event.choices) {
        expect(choice.label, isNotEmpty);
        expect(choice.description, isNotEmpty);
        expect(choice.resultText, isNotEmpty);
      }
    }
  });

  test('battlefield event selection is reproducible for the same seed', () {
    BattlefieldEventSpec? pick(int seed) => BattlefieldEventRules.pickNext(
      definitions: alphaBattlefieldEvents,
      triggeredIds: const {},
      progress: 1,
      random: math.Random(seed),
    );

    expect(pick(20260810)?.id, pick(20260810)?.id);
  });

  test('battlefield events respect progress and never repeat', () {
    final early = BattlefieldEventRules.pickNext(
      definitions: alphaBattlefieldEvents,
      triggeredIds: const {},
      progress: .1,
      random: math.Random(1),
    );
    expect(early, isNull);

    final triggered = <String>{};
    for (var i = 0; i < alphaBattlefieldEvents.length; i++) {
      final event = BattlefieldEventRules.pickNext(
        definitions: alphaBattlefieldEvents,
        triggeredIds: triggered,
        progress: 1,
        random: math.Random(i + 7),
      );
      expect(event, isNotNull);
      expect(triggered.add(event!.id), isTrue);
    }
    expect(
      BattlefieldEventRules.pickNext(
        definitions: alphaBattlefieldEvents,
        triggeredIds: triggered,
        progress: 1,
        random: math.Random(99),
      ),
      isNull,
    );
  });

  test('retreat is an explicit option only for escalation events', () {
    final retreatChoices = alphaBattlefieldEvents
        .expand((event) => event.choices)
        .where((choice) => choice.retreat)
        .map((choice) => choice.id)
        .toSet();

    expect(retreatChoices, {'tactical_retreat', 'royal_retreat'});
  });

  test('reward breakdown separates sources before preservation', () {
    final reward = BattleRewardRules.calculate(
      contractGold: 3000,
      contractXp: 1200,
      kills: 100,
      completedObjectives: 3,
      eventGold: 500,
      eventXp: 200,
      eventMultiplier: 1.25,
      preservationRate: .5,
    );

    expect(reward.contractGold, 3000);
    expect(reward.objectiveGold, 900);
    expect(reward.combatGold, 800);
    expect(reward.eventGold, 500);
    expect(reward.grossGold, 6500);
    expect(reward.keptGold, 3250);
    expect(reward.grossXp, 2500);
    expect(reward.keptXp, 1250);
  });

  test('outcomes preserve rewards at 100 50 and 20 percent', () {
    expect(BattleRewardRules.preservationRate('victory'), 1);
    expect(BattleRewardRules.preservationRate('retreat'), .5);
    expect(BattleRewardRules.preservationRate('defeat'), .2);
  });

  test('loot table is deterministic and prioritizes rare preserved loot', () {
    List<LootDrop> roll(double preservationRate) => BattleLootRules.resolve(
      seed: 20260810,
      completedObjectives: 3,
      eventCount: 2,
      rareDropIds: const ['marshal_seal'],
      eventChoiceIds: const ['embrace_red_moon'],
      preservationRate: preservationRate,
    );

    final first = roll(1);
    final second = roll(1);
    final retreat = roll(.5);

    expect(
      first.map((drop) => (drop.id, drop.quantity)),
      second.map((drop) => (drop.id, drop.quantity)),
    );
    expect(first.any((drop) => drop.id == 'red_moon_shard'), isTrue);
    expect(first.any((drop) => drop.id == 'marshal_seal'), isTrue);
    expect(retreat.length, lessThan(first.length));
    expect(
      retreat.map((drop) => drop.rarity.index),
      orderedEquals(
        retreat.map((drop) => drop.rarity.index).toList()
          ..sort((a, b) => b.compareTo(a)),
      ),
    );
  });

  test('battle award records MVP and major feats', () {
    final award = BattleRewardRules.award(
      kills: 130,
      alliedKills: 80,
      objectiveRatio: 1,
      evacuation: false,
      commanderSurvived: true,
      enemyCommanderDefeated: true,
      ultimateActivations: 1,
      completedObjectives: 3,
      eventCount: 2,
    );

    expect(award.title, '지휘관 사냥꾼');
    expect(award.honors, containsAll(['백인참', '적 지휘관 격퇴', '전술 목표 완수']));
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

  test('every mercenary owns a distinct battle animation sheet', () {
    final spriteAssets = content.mercenaries
        .map((mercenary) => mercenary.visual.battleSpriteAsset)
        .toList(growable: false);

    expect(spriteAssets.toSet(), hasLength(content.mercenaries.length));
  });

  test('new account starts with a focused onboarding economy', () {
    final account = AccountSave.initial();

    expect(account.commanderLevel, 1);
    expect(account.commanderXp, 0);
    expect(account.gold, 5000);
    expect(account.crystals, 600);
    expect(account.warSeals, 0);
    expect(account.honor, 0);
    expect(account.mercenaryProgress.keys, ['luna']);
    expect(account.mercenaryProgress['luna']?.level, 1);
    expect(
      account.weaponProgress.keys,
      containsAll(['moon_blades', 'iron_sword']),
    );
    expect(account.weaponProgress, hasLength(2));
    expect(account.inventory['contract_ticket'], 1);
    expect(AccountSave.betaTest().mercenaryProgress, hasLength(8));
  });

  test('contract tiers and commander progression pace early unlocks', () {
    expect(contracts.map((contract) => contract.requiredCommanderLevel), [
      1,
      3,
      5,
      8,
      12,
      16,
    ]);
    final gained = ProgressionRules.addCommanderXp(1, 0, 1200);
    expect(gained.level, 2);
    expect(gained.xp, 200);
    expect(ProgressionRules.commanderRank(1), 'E');
    expect(ProgressionRules.commanderRank(15), 'C');
  });

  test('onboarding missions unlock in order', () {
    expect(CampMetaRules.missionUnlocked('camp_arrival', const {}), isTrue);
    expect(CampMetaRules.missionUnlocked('field_scavenger', const {}), isFalse);
    expect(
      CampMetaRules.missionUnlocked('field_scavenger', const {'camp_arrival'}),
      isTrue,
    );
  });

  test('save repository preserves loadout and reward state', () async {
    final repository = InMemorySaveRepository();
    final initial = await repository.load();
    final updated = initial.copyWith(
      gold: initial.gold + 500,
      selectedMercenaryId: 'kael',
      equippedWeaponByMercenary: {
        ...initial.equippedWeaponByMercenary,
        'kael': 'iron_sword',
      },
    );

    await repository.save(updated);

    final restored = await repository.load();
    expect(restored.gold, 46178);
    expect(restored.selectedMercenaryId, 'kael');
    expect(restored.equippedWeaponByMercenary['kael'], 'iron_sword');
  });

  test(
    'version one save migrates progression, inventory, and missions',
    () async {
      final store = MemoryKeyValueStore({
        JsonSaveRepository.primaryKey: jsonEncode({
          'schemaVersion': 1,
          'gold': 12345,
          'crystals': 600,
          'selectedMercenaryId': 'kael',
          'equippedWeaponByMercenary': {'kael': 'iron_sword'},
        }),
      });
      final repository = JsonSaveRepository(store);

      final migrated = await repository.load();

      expect(migrated.schemaVersion, 12);
      expect(migrated.commanderLevel, 15);
      expect(migrated.battleDiagnostics, isEmpty);
      expect(migrated.equippedGearByMercenary['luna:armor'], isNotNull);
      expect(migrated.gold, 12345);
      expect(migrated.mercenaryProgress['kael']?.level, 42);
      expect(migrated.weaponProgress['iron_sword']?.stage, 1);
      expect(migrated.inventory, isEmpty);
      expect(migrated.claimedMissionIds, isEmpty);
      expect(migrated.mercenaryCopies['luna'], 1);
      expect(migrated.warSeals, 120);
      expect(migrated.settings.tutorialCompleted, isFalse);
      expect(migrated.settings.performanceMode, isFalse);
    },
  );

  test('corrupt primary save recovers from the last valid backup', () async {
    final backup = AccountSave.initial().copyWith(
      gold: 77777,
      inventory: {'officer_map': 2},
    );
    final store = MemoryKeyValueStore({
      JsonSaveRepository.primaryKey: '{broken json',
      JsonSaveRepository.backupKey: jsonEncode(backup.toJson()),
    });
    final repository = JsonSaveRepository(store);

    final recovered = await repository.load();

    expect(repository.lastLoadSource, SaveLoadSource.backup);
    expect(recovered.gold, 77777);
    expect(recovered.inventory['officer_map'], 2);
    expect(store.values[JsonSaveRepository.primaryKey], isNot('{broken json'));
  });

  test('schema eleven beta ownership is preserved by onboarding migration', () {
    final raw = AccountSave.betaTest().toJson()
      ..['schemaVersion'] = 11
      ..remove('commanderLevel')
      ..remove('commanderXp');

    final migrated = AccountSave.fromJson(raw);

    expect(migrated.schemaVersion, 12);
    expect(migrated.commanderLevel, 15);
    expect(migrated.mercenaryProgress, hasLength(8));
    expect(migrated.weaponProgress, hasLength(16));
    expect(migrated.gold, 45678);
  });

  test('version five settings migrate performance mode safely', () async {
    final settings =
        const GameSettings.defaults().copyWith(reducedFlash: true).toJson()
          ..remove('performanceMode');
    final raw = AccountSave.initial().toJson()
      ..['schemaVersion'] = 5
      ..['settings'] = settings;
    final repository = JsonSaveRepository(
      MemoryKeyValueStore({JsonSaveRepository.primaryKey: jsonEncode(raw)}),
    );

    final migrated = await repository.load();

    expect(migrated.schemaVersion, 12);
    expect(migrated.settings.reducedFlash, isTrue);
    expect(migrated.settings.performanceMode, isFalse);
    expect(migrated.settings.battleInputMode, BattleInputMode.hybrid);
    expect(migrated.settings.autoTargetPriority, AutoTargetPriority.nearest);
  });

  test('mercenary and weapon permanent growth crosses level thresholds', () {
    final mercenary = ProgressionRules.addMercenaryXp(
      const MercenaryProgress(level: 1, xp: 0, ascension: 0),
      1000,
    );
    final weapon = ProgressionRules.addWeaponXp(
      const WeaponProgress(level: 1, xp: 0, stage: 1),
      1000,
    );

    expect(mercenary.level, 2);
    expect(mercenary.xp, 520);
    expect(weapon.level, 3);
    expect(weapon.xp, 200);
    expect(weapon.stage, 1);
  });

  test(
    'ascension expands the mercenary level cap when sigils are available',
    () {
      const capped = MercenaryProgress(level: 50, xp: 0, ascension: 0);

      expect(ProgressionRules.canAscend(capped, 1), isFalse);
      expect(ProgressionRules.canAscend(capped, 2), isTrue);
      final ascended = ProgressionRules.ascend(capped, availableSigils: 2);
      expect(ascended.ascension, 1);
      expect(ascended.levelCap, 55);
    },
  );

  test('permanent levels increase the next battle combat multipliers', () {
    expect(
      ProgressionRules.mercenaryHpMultiplier(45, 46),
      closeTo(1.012, .001),
    );
    expect(
      ProgressionRules.mercenarySpeedMultiplier(45, 46),
      closeTo(1.003, .001),
    );
    expect(
      ProgressionRules.combatDamageMultiplier(
        baseMercenaryLevel: 45,
        permanentMercenaryLevel: 46,
        weaponLevel: 6,
        weaponStage: 2,
      ),
      closeTo(1.205, .001),
    );
  });

  test('save round trip preserves growth and loot inventory', () async {
    final repository = InMemorySaveRepository();
    final initial = await repository.load();
    final updated = initial.copyWith(
      mercenaryProgress: {
        ...initial.mercenaryProgress,
        'luna': const MercenaryProgress(level: 46, xp: 125, ascension: 1),
      },
      weaponProgress: {
        ...initial.weaponProgress,
        'moon_blades': const WeaponProgress(level: 6, xp: 80, stage: 2),
      },
      inventory: {'red_moon_shard': 1, 'war_scrap': 4},
      claimedMissionIds: {'camp_arrival'},
      recruitmentCount: 11,
      mercenaryCopies: {'luna': 4, 'kael': 5, 'sera': 5},
      shopPurchaseCounts: {'ration_pack': 2},
      settings: const GameSettings.defaults().copyWith(
        tutorialCompleted: true,
        reducedFlash: true,
        performanceMode: true,
        largeText: true,
      ),
    );

    await repository.save(updated);
    final restored = await repository.load();

    expect(restored.mercenaryProgress['luna']?.level, 46);
    expect(restored.mercenaryProgress['luna']?.ascension, 1);
    expect(restored.weaponProgress['moon_blades']?.stage, 2);
    expect(restored.inventory['war_scrap'], 4);
    expect(restored.claimedMissionIds, contains('camp_arrival'));
    expect(restored.recruitmentCount, 11);
    expect(restored.mercenaryCopies['kael'], 5);
    expect(restored.shopPurchaseCounts['ration_pack'], 2);
    expect(restored.settings.tutorialCompleted, isTrue);
    expect(restored.settings.reducedFlash, isTrue);
    expect(restored.settings.performanceMode, isTrue);
    expect(restored.settings.largeText, isTrue);
  });

  test('battle diagnostics round trip and retain only the latest twenty', () {
    final report = BattleReport(
      time: '03:21',
      kills: 77,
      gold: 10,
      xp: 20,
      contractName: '성문 방어전',
      peakActiveUnits: 512,
      frameTimeP95Ms: 15.7,
      rewardBreakdown: const RewardBreakdown(
        contractGold: 10,
        objectiveGold: 0,
        combatGold: 0,
        eventGold: 0,
        contractXp: 20,
        objectiveXp: 0,
        combatXp: 0,
        eventXp: 0,
        rewardMultiplier: 1,
        preservationRate: 1,
        keptGold: 10,
        keptXp: 20,
      ),
      lootDrops: const [],
      award: const BattleAward(title: '루나', detail: 'MVP', honors: []),
    );
    var records = <BattleDiagnosticRecord>[];
    for (var seed = 0; seed < 24; seed++) {
      records = BattleDiagnosticRules.append(
        records,
        BattleDiagnosticRecord.fromReport(
          report: report,
          contentVersion: 1,
          seed: seed,
          contractId: 'gate_defense',
          mercenaryId: 'luna',
          weaponId: 'moon_blades',
          recordedAt: DateTime.utc(2026, 8, 10),
        ),
      );
    }

    final restored = AccountSave.fromJson(
      AccountSave.initial().copyWith(battleDiagnostics: records).toJson(),
    );

    expect(restored.battleDiagnostics, hasLength(20));
    expect(restored.battleDiagnostics.first.seed, 4);
    expect(restored.battleDiagnostics.last.seed, 23);
    expect(
      restored.battleDiagnostics.last.terminationReason,
      'objective_completed',
    );
    expect(restored.battleDiagnostics.last.frameTimeP95Ms, 15.7);
  });

  test(
    'balance manifest rejects invalid remote data and uses safe fallback',
    () {
      final valid = jsonEncode({
        'version': 'beta-2',
        'enemyHpMultiplier': 1.1,
        'rewardMultiplier': .9,
        'spawnMultiplier': 1.2,
        'signature': BalanceManifest.signatureFor('beta-2|1.1|0.9|1.2'),
      });
      final tampered = jsonEncode({
        'version': 'beta-3',
        'enemyHpMultiplier': 99,
        'rewardMultiplier': 99,
        'spawnMultiplier': 99,
        'signature': 'invalid',
      });

      expect(BalanceManifestRules.resolve(remoteJson: valid).source, 'remote');
      final fallback = BalanceManifestRules.resolve(
        remoteJson: tampered,
        lastKnownGoodJson: valid,
      );
      expect(fallback.source, 'last_known_good');
      expect(fallback.manifest.version, 'beta-2');
      expect(
        BalanceManifestRules.resolve(remoteJson: tampered).source,
        'bundled',
      );
    },
  );

  test('game settings deserialize missing fields with accessible defaults', () {
    final settings = GameSettings.fromJson({
      'tutorialCompleted': true,
      'soundEnabled': false,
    });

    expect(settings.tutorialCompleted, isTrue);
    expect(settings.soundEnabled, isFalse);
    expect(settings.hapticsEnabled, isTrue);
    expect(settings.screenShakeEnabled, isTrue);
    expect(settings.reducedFlash, isFalse);
    expect(settings.performanceMode, isFalse);
    expect(settings.battleInputMode, BattleInputMode.hybrid);
    expect(settings.autoTargetPriority, AutoTargetPriority.nearest);
  });

  test('recruitment rolls are deterministic and respect currency gates', () {
    expect(RecruitmentRules.roll(startIndex: 0, count: 3), [
      'sera',
      'kael',
      'luna',
    ]);
    expect(
      RecruitmentRules.canRecruit(count: 1, crystals: 0, tickets: 1),
      isTrue,
    );
    expect(
      RecruitmentRules.canRecruit(count: 10, crystals: 2699, tickets: 10),
      isFalse,
    );
    expect(
      RecruitmentRules.canRecruit(count: 10, crystals: 2700, tickets: 0),
      isTrue,
    );
    expect(
      RecruitmentRules.roll(startIndex: 39, count: 1),
      ['luna'],
      reason: '40번째 계약은 픽업 용병을 보증해야 한다.',
    );
    expect(RecruitmentRules.guaranteeRemaining(0), 40);
    expect(RecruitmentRules.guaranteeRemaining(39), 1);
  });

  test('shop rules enforce balance and per-refresh purchase limits', () {
    final product = alphaShopProducts.first;
    expect(
      ShopRules.canPurchase(product: product, balance: 800, purchased: 0),
      isTrue,
    );
    expect(
      ShopRules.canPurchase(product: product, balance: 799, purchased: 0),
      isFalse,
    );
    expect(
      ShopRules.canPurchase(
        product: product,
        balance: 9999,
        purchased: product.purchaseLimit,
      ),
      isFalse,
    );
  });

  test('seven day beta economy neither blocks nor inflates resources', () {
    final simulation = BetaEconomySimulator.simulateSevenDays();
    expect(simulation.days, hasLength(7));
    expect(simulation.hasProgressBlock, isFalse);
    expect(simulation.finalState.gold, inInclusiveRange(8000, 25000));
    expect(simulation.finalState.crystals, greaterThanOrEqualTo(2000));
    expect(simulation.finalState.warSeals, lessThan(100));
    expect(simulation.finalState.honor, lessThan(100));
  });

  test('camp mission rules connect inventory and weapon growth', () {
    expect(
      CampMetaRules.missionComplete(
        'camp_arrival',
        inventory: const {},
        weaponProgress: const {},
      ),
      isTrue,
    );
    expect(
      CampMetaRules.missionComplete(
        'field_scavenger',
        inventory: const {'war_scrap': 2, 'field_ration': 1},
        weaponProgress: const {},
      ),
      isTrue,
    );
    expect(
      CampMetaRules.missionComplete(
        'tempered_edge',
        inventory: const {},
        weaponProgress: const {
          'moon_blades': WeaponProgress(level: 2, xp: 0, stage: 1),
        },
      ),
      isTrue,
    );
    expect(CampMetaRules.missionInventoryReward('tempered_edge'), {
      'contract_seal': 2,
    });
  });

  test('camp costs reject incomplete resource sets', () {
    const mercenary = MercenaryProgress(level: 45, xp: 0, ascension: 0);
    expect(
      CampMetaRules.canTrain(gold: 1000, rations: 1, progress: mercenary),
      isTrue,
    );
    expect(
      CampMetaRules.canTrain(gold: 999, rations: 1, progress: mercenary),
      isFalse,
    );
    expect(CampMetaRules.canForge(gold: 700, scrap: 2), isTrue);
    expect(CampMetaRules.canForge(gold: 700, scrap: 1), isFalse);
  });

  test('beta gear catalog fills every slot and produces bounded bonuses', () {
    for (final slot in GearSlot.values) {
      expect(
        betaGearCatalog.where((gear) => gear.slot == slot).length,
        greaterThanOrEqualTo(3),
      );
    }
    final bonus = GearRules.combatBonus([
      'veteran_plate',
      'nightfang_charm',
      'moonstep_hook',
    ]);
    expect(bonus.hpMultiplier, 1.22);
    expect(bonus.damageMultiplier, 1.10);
    expect(bonus.criticalChance, 7);
    expect(bonus.dashCooldownMultiplier, .8);
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
      mercenaryPermanentLevel: 44,
      weaponPermanentLevel: 6,
      weaponGrowthStage: 2,
    );

    expect(config.mercenary.style.name, 'magic');
    expect(config.weapon.name, '유리불꽃 지팡이');
    expect(config.durationSeconds, 300);
    expect(config.seed, 20260809);
    expect(config.battlefield, BattlefieldType.evacuation);
    expect(config.condition, BattlefieldCondition.ashWind);
    expect(config.unitCount, 500);
    expect(config.mercenaryPermanentLevel, 44);
    expect(config.weaponPermanentLevel, 6);
    expect(config.weaponGrowthStage, 2);
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

  test('all sixteen beta weapons expose distinct attack patterns', () {
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
