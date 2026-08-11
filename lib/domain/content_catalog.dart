import 'battle_rewards.dart';
import 'battlefield_events.dart';
import 'economy.dart';
import 'enemy_catalog.dart';
import 'game_data.dart';
import 'progression.dart';
import 'camp_meta.dart';

const currentContentVersion = 1;

class GameContentCatalog {
  const GameContentCatalog({
    required this.version,
    required this.mercenaries,
    required this.weapons,
    required this.enemies,
    required this.events,
    required this.loot,
    required this.shopProducts,
    required this.gear,
    required this.factions,
    required this.operations,
  });

  final int version;
  final List<MercenarySpec> mercenaries;
  final List<WeaponSpec> weapons;
  final List<EnemyArchetypeSpec> enemies;
  final List<BattlefieldEventSpec> events;
  final List<LootItemSpec> loot;
  final List<ShopProductSpec> shopProducts;
  final List<GearSpec> gear;
  final List<FactionSpec> factions;
  final List<WarOperationSpec> operations;
}

const alphaContentCatalog = GameContentCatalog(
  version: currentContentVersion,
  mercenaries: alphaMercenaries,
  weapons: alphaWeapons,
  enemies: alphaEnemyArchetypes,
  events: alphaBattlefieldEvents,
  loot: alphaLootCatalog,
  shopProducts: alphaShopProducts,
  gear: betaGearCatalog,
  factions: betaFactions,
  operations: betaWarOperations,
);

class ContentValidationIssue {
  const ContentValidationIssue(this.code, this.path, this.message);

  final String code;
  final String path;
  final String message;

  @override
  String toString() => '[$code] $path: $message';
}

abstract final class ContentCatalogValidator {
  static List<ContentValidationIssue> validate(GameContentCatalog catalog) {
    final issues = <ContentValidationIssue>[];
    if (catalog.version <= 0) {
      issues.add(
        const ContentValidationIssue(
          'invalid_version',
          'catalog.version',
          '콘텐츠 버전은 1 이상이어야 합니다.',
        ),
      );
    }

    _validateIds('mercenaries', catalog.mercenaries.map((e) => e.id), issues);
    _validateIds('weapons', catalog.weapons.map((e) => e.id), issues);
    _validateIds('enemies', catalog.enemies.map((e) => e.id), issues);
    _validateIds('events', catalog.events.map((e) => e.id), issues);
    _validateIds('loot', catalog.loot.map((e) => e.id), issues);
    _validateIds('shopProducts', catalog.shopProducts.map((e) => e.id), issues);
    _validateIds('gear', catalog.gear.map((e) => e.id), issues);
    _validateIds('factions', catalog.factions.map((e) => e.id), issues);
    _validateIds('operations', catalog.operations.map((e) => e.id), issues);
    if (catalog.factions.length < 3) {
      issues.add(
        const ContentValidationIssue(
          'insufficient_factions',
          'factions',
          '베타 계약에는 최소 3개 세력이 필요합니다.',
        ),
      );
    }
    final factionIds = catalog.factions.map((faction) => faction.id).toSet();
    for (final operation in catalog.operations) {
      if (!factionIds.contains(operation.factionId)) {
        issues.add(
          ContentValidationIssue(
            'missing_operation_faction',
            'operations.${operation.id}.factionId',
            '${operation.factionId} 세력이 없습니다.',
          ),
        );
      }
      if (operation.stages.length < 3) {
        issues.add(
          ContentValidationIssue(
            'insufficient_operation_stages',
            'operations.${operation.id}.stages',
            '작전은 최소 3단계 계약으로 구성해야 합니다.',
          ),
        );
      }
    }

    for (final slot in GearSlot.values) {
      if (catalog.gear.where((gear) => gear.slot == slot).length < 3) {
        issues.add(
          ContentValidationIssue(
            'insufficient_gear_slot',
            'gear.${slot.name}',
            '각 부가 장비 슬롯에는 최소 3개 선택지가 필요합니다.',
          ),
        );
      }
    }
    for (final gear in catalog.gear) {
      if (gear.hpPercent < -50 ||
          gear.damagePercent < -50 ||
          gear.speedPercent < -50 ||
          gear.dashCooldownPercent < 0 ||
          gear.tacticalCooldownPercent < 0) {
        issues.add(
          ContentValidationIssue(
            'invalid_gear_stat',
            'gear.${gear.id}',
            '장비 능력치와 쿨다운 감소량이 허용 범위를 벗어났습니다.',
          ),
        );
      }
    }

    final mercenaryById = {
      for (final value in catalog.mercenaries) value.id: value,
    };
    final weaponById = {for (final value in catalog.weapons) value.id: value};
    final lootIds = catalog.loot.map((value) => value.id).toSet();

    for (final mercenary in catalog.mercenaries) {
      final signature = weaponById[mercenary.signatureWeaponId];
      if (signature == null) {
        issues.add(
          ContentValidationIssue(
            'missing_signature_weapon',
            'mercenaries.${mercenary.id}.signatureWeaponId',
            '${mercenary.signatureWeaponId} 무기가 없습니다.',
          ),
        );
      } else if (signature.ownerId != mercenary.id) {
        issues.add(
          ContentValidationIssue(
            'signature_owner_mismatch',
            'weapons.${signature.id}.ownerId',
            '${mercenary.id}와 고유무기 소유자가 일치하지 않습니다.',
          ),
        );
      }
      if (mercenary.maxHp <= 0 ||
          mercenary.speed <= 0 ||
          mercenary.attackInterval <= 0 ||
          mercenary.baseDamage <= 0) {
        issues.add(
          ContentValidationIssue(
            'invalid_combat_stat',
            'mercenaries.${mercenary.id}',
            'HP, 이동속도, 공격주기, 피해는 양수여야 합니다.',
          ),
        );
      }
    }

    for (final weapon in catalog.weapons) {
      if (weapon.ownerId case final ownerId?) {
        final owner = mercenaryById[ownerId];
        if (owner == null) {
          issues.add(
            ContentValidationIssue(
              'missing_weapon_owner',
              'weapons.${weapon.id}.ownerId',
              '$ownerId 용병이 없습니다.',
            ),
          );
        } else if (owner.signatureWeaponId != weapon.id) {
          issues.add(
            ContentValidationIssue(
              'owner_signature_mismatch',
              'weapons.${weapon.id}',
              '$ownerId 용병의 고유무기 역참조가 일치하지 않습니다.',
            ),
          );
        }
      }
      if (weapon.attack <= 0 || weapon.crit < 0) {
        issues.add(
          ContentValidationIssue(
            'invalid_weapon_stat',
            'weapons.${weapon.id}',
            '공격력은 양수, 치명타는 0 이상이어야 합니다.',
          ),
        );
      }
    }

    for (final enemy in catalog.enemies) {
      final dropId = enemy.rareDropId;
      if (dropId != null && !lootIds.contains(dropId)) {
        issues.add(
          ContentValidationIssue(
            'missing_enemy_drop',
            'enemies.${enemy.id}.rareDropId',
            '$dropId 전리품이 카탈로그에 없습니다.',
          ),
        );
      }
      if (enemy.speedMultiplier <= 0) {
        issues.add(
          ContentValidationIssue(
            'invalid_enemy_speed',
            'enemies.${enemy.id}.speedMultiplier',
            '속도 배율은 양수여야 합니다.',
          ),
        );
      }
    }

    for (final event in catalog.events) {
      if (event.weight <= 0 || event.minProgress < 0 || event.minProgress > 1) {
        issues.add(
          ContentValidationIssue(
            'invalid_event_rule',
            'events.${event.id}',
            '가중치는 양수, 최소 진행도는 0~1이어야 합니다.',
          ),
        );
      }
      if (event.choices.isEmpty) {
        issues.add(
          ContentValidationIssue(
            'empty_event_choices',
            'events.${event.id}.choices',
            '사건에는 최소 하나의 선택지가 필요합니다.',
          ),
        );
      }
      _validateIds(
        'events.${event.id}.choices',
        event.choices.map((choice) => choice.id),
        issues,
      );
    }

    const inventoryOnlyIds = {
      'contract_ticket',
      'field_medicine',
      'officer_map',
      'war_hero_contract',
      'siege_core',
      'contract_seal',
      'royal_writ',
    };
    for (final product in catalog.shopProducts) {
      if (!lootIds.contains(product.itemId) &&
          !inventoryOnlyIds.contains(product.itemId)) {
        issues.add(
          ContentValidationIssue(
            'unknown_shop_item',
            'shopProducts.${product.id}.itemId',
            '${product.itemId} 아이템이 카탈로그에 없습니다.',
          ),
        );
      }
      if (product.quantity <= 0 ||
          product.price <= 0 ||
          product.purchaseLimit <= 0) {
        issues.add(
          ContentValidationIssue(
            'invalid_shop_rule',
            'shopProducts.${product.id}',
            '수량, 가격, 구매 제한은 양수여야 합니다.',
          ),
        );
      }
    }
    return issues;
  }

  static void _validateIds(
    String path,
    Iterable<String> ids,
    List<ContentValidationIssue> issues,
  ) {
    final seen = <String>{};
    for (final id in ids) {
      if (id.trim().isEmpty) {
        issues.add(ContentValidationIssue('empty_id', path, '비어 있는 ID가 있습니다.'));
      } else if (!seen.add(id)) {
        issues.add(
          ContentValidationIssue('duplicate_id', '$path.$id', 'ID가 중복됩니다.'),
        );
      }
    }
  }
}

class AlphaBalanceSnapshot {
  const AlphaBalanceSnapshot({
    required this.mercenaryDamagePerSecond,
    required this.weaponPowerIndex,
    required this.sampleRewardGoldPerMinute,
    required this.sampleRewardXpPerMinute,
    required this.weaponLevelOneToTwentyXp,
  });

  final Map<String, double> mercenaryDamagePerSecond;
  final Map<String, double> weaponPowerIndex;
  final double sampleRewardGoldPerMinute;
  final double sampleRewardXpPerMinute;
  final int weaponLevelOneToTwentyXp;

  factory AlphaBalanceSnapshot.calculate(GameContentCatalog catalog) {
    const sampleDurationSeconds = 45;
    final reward = BattleRewardRules.calculate(
      contractGold: 3000,
      contractXp: 1200,
      kills: 100,
      completedObjectives: 3,
      eventGold: 0,
      eventXp: 0,
      eventMultiplier: 1,
      preservationRate: 1,
    );
    return AlphaBalanceSnapshot(
      mercenaryDamagePerSecond: {
        for (final mercenary in catalog.mercenaries)
          mercenary.id: mercenary.baseDamage / mercenary.attackInterval,
      },
      weaponPowerIndex: {
        for (final weapon in catalog.weapons)
          weapon.id:
              weapon.attack *
              (1 + weapon.crit * .005) *
              (1 + weapon.speed / 100),
      },
      sampleRewardGoldPerMinute: reward.keptGold * 60 / sampleDurationSeconds,
      sampleRewardXpPerMinute: reward.keptXp * 60 / sampleDurationSeconds,
      weaponLevelOneToTwentyXp: [
        for (var level = 1; level < 20; level++)
          ProgressionRules.weaponXpToNext(level),
      ].fold(0, (sum, value) => sum + value),
    );
  }
}
