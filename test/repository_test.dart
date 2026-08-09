import 'package:eclipse_mercenaries/core/content/game_content_repository.dart';
import 'package:eclipse_mercenaries/core/content/game_visuals.dart';
import 'package:eclipse_mercenaries/core/persistence/save_repository.dart';
import 'package:eclipse_mercenaries/domain/battle_models.dart';
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
}
