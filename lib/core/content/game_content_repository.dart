import '../../domain/game_data.dart';

abstract interface class GameContentRepository {
  List<MercenarySpec> get mercenaries;
  List<WeaponSpec> get weapons;

  MercenarySpec mercenaryById(String id);
  WeaponSpec weaponById(String id);
}

class StaticGameContentRepository implements GameContentRepository {
  const StaticGameContentRepository();

  @override
  List<MercenarySpec> get mercenaries => alphaMercenaries;

  @override
  List<WeaponSpec> get weapons => alphaWeapons;

  @override
  MercenarySpec mercenaryById(String id) =>
      mercenaries.firstWhere((mercenary) => mercenary.id == id);

  @override
  WeaponSpec weaponById(String id) =>
      weapons.firstWhere((weapon) => weapon.id == id);
}
