import 'package:eclipse_mercenaries/domain/battle_rewards.dart';
import 'package:eclipse_mercenaries/domain/content_catalog.dart';
import 'package:eclipse_mercenaries/domain/game_data.dart';
import 'package:eclipse_mercenaries/domain/camp_meta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('alpha catalog has no broken content references', () {
    expect(ContentCatalogValidator.validate(alphaContentCatalog), isEmpty);
  });

  test('validator reports duplicate IDs and broken signature references', () {
    final broken = GameContentCatalog(
      version: 1,
      mercenaries: [alphaMercenaries.first, alphaMercenaries.first],
      weapons: const [],
      enemies: const [],
      events: const [],
      loot: const [],
      shopProducts: const [],
      gear: alphaContentCatalog.gear,
      factions: alphaContentCatalog.factions,
    );

    final codes = ContentCatalogValidator.validate(
      broken,
    ).map((issue) => issue.code);
    expect(codes, contains('duplicate_id'));
    expect(codes, contains('missing_signature_weapon'));
  });

  test('every elite and boss rare drop is a discoverable loot item', () {
    final lootIds = alphaLootCatalog.map((loot) => loot.id).toSet();
    for (final enemy in alphaContentCatalog.enemies) {
      if (enemy.rareDropId case final dropId?) {
        expect(lootIds, contains(dropId), reason: enemy.id);
      }
    }
  });

  test('balance snapshot is deterministic and covers all combat content', () {
    final first = AlphaBalanceSnapshot.calculate(alphaContentCatalog);
    final second = AlphaBalanceSnapshot.calculate(alphaContentCatalog);

    expect(first.mercenaryDamagePerSecond, second.mercenaryDamagePerSecond);
    expect(first.weaponPowerIndex, second.weaponPowerIndex);
    expect(first.mercenaryDamagePerSecond, hasLength(alphaMercenaries.length));
    expect(first.weaponPowerIndex, hasLength(alphaWeapons.length));
    expect(first.weaponLevelOneToTwentyXp, greaterThan(0));
  });

  test('faction reputation has deterministic ranks and battle gains', () {
    expect(alphaContentCatalog.factions, hasLength(3));
    expect(FactionRules.reputationGain('victory'), 12);
    expect(FactionRules.reputationGain('retreat'), 5);
    expect(FactionRules.reputationGain('defeat'), 2);
    expect(FactionRules.rankName(24), '낯선 칼날');
    expect(FactionRules.rankName(25), '정식 계약자');
    expect(FactionRules.rankName(60), '신뢰받는 전우');
    expect(FactionRules.rankName(120), '맹약 용병단');
  });
}
