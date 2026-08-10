import 'package:eclipse_mercenaries/domain/battle_rewards.dart';
import 'package:eclipse_mercenaries/domain/content_catalog.dart';
import 'package:eclipse_mercenaries/domain/game_data.dart';
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
}
