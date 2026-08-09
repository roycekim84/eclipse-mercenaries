import 'game_data.dart';

enum BattleOutcome { victory, retreat, defeat }

class BattleConfig {
  const BattleConfig({
    required this.mercenary,
    required this.weapon,
    this.durationSeconds = 45,
    this.seed = 19,
  });

  final MercenarySpec mercenary;
  final WeaponSpec weapon;
  final int durationSeconds;
  final int seed;
}

class BattleStats {
  const BattleStats({
    required this.hp,
    required this.level,
    required this.xp,
    required this.nextXp,
    required this.kills,
    required this.secondsLeft,
    required this.weaponLevel,
    required this.ultimateCharge,
    required this.ultimateEnabled,
  });

  final double hp;
  final int level;
  final double xp;
  final double nextXp;
  final int kills;
  final int secondsLeft;
  final int weaponLevel;
  final double ultimateCharge;
  final bool ultimateEnabled;
}

class UltimateSequence {
  const UltimateSequence({
    required this.mercenaryId,
    required this.title,
    required this.activation,
  });

  final String mercenaryId;
  final String title;
  final int activation;
}

class BattleReport {
  const BattleReport({
    required this.time,
    required this.kills,
    required this.gold,
    required this.xp,
    this.outcome = BattleOutcome.victory,
    this.alliedKills = 0,
    this.triggeredEventIds = const [],
  });

  final String time;
  final int kills;
  final int gold;
  final int xp;
  final BattleOutcome outcome;
  final int alliedKills;
  final List<String> triggeredEventIds;
}

class UpgradeOption {
  const UpgradeOption(this.title, this.description, this.iconId);

  final String title;
  final String description;
  final String iconId;
}

class BattleChoice {
  const BattleChoice(this.options);

  final List<UpgradeOption> options;
}

class BattleEvent {
  const BattleEvent(this.grade, this.title, this.description, {this.id = ''});

  final String id;
  final String grade;
  final String title;
  final String description;
}
