import '../../domain/game_data.dart';
import '../../domain/enemy_catalog.dart';

abstract interface class GameContentRepository {
  List<MercenarySpec> get mercenaries;
  List<WeaponSpec> get weapons;
  List<EnemyArchetypeSpec> get enemies;

  MercenarySpec mercenaryById(String id);
  WeaponSpec weaponById(String id);
  EnemyArchetypeSpec enemyById(String id);
}

class StaticGameContentRepository implements GameContentRepository {
  const StaticGameContentRepository();

  @override
  List<MercenarySpec> get mercenaries => alphaMercenaries;

  @override
  List<WeaponSpec> get weapons => alphaWeapons;

  @override
  List<EnemyArchetypeSpec> get enemies => alphaEnemyArchetypes;

  @override
  MercenarySpec mercenaryById(String id) =>
      mercenaries.firstWhere((mercenary) => mercenary.id == id);

  @override
  WeaponSpec weaponById(String id) =>
      weapons.firstWhere((weapon) => weapon.id == id);

  @override
  EnemyArchetypeSpec enemyById(String id) =>
      enemies.firstWhere((enemy) => enemy.id == id);
}
