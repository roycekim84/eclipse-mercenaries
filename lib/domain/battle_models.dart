import 'game_data.dart';

enum BattleOutcome { victory, retreat, defeat }

enum UnitRole { infantry, shield, archer, cavalry, mage, siege, commander }

enum UnitStance { advance, support, retreat }

abstract final class UnitRoleRules {
  static int maxHp(UnitRole role) => switch (role) {
    UnitRole.infantry => 4,
    UnitRole.shield => 9,
    UnitRole.archer => 3,
    UnitRole.cavalry => 7,
    UnitRole.mage => 4,
    UnitRole.siege => 16,
    UnitRole.commander => 24,
  };

  static double speed(UnitRole role) => switch (role) {
    UnitRole.infantry => 28,
    UnitRole.shield => 21,
    UnitRole.archer => 25,
    UnitRole.cavalry => 52,
    UnitRole.mage => 23,
    UnitRole.siege => 18,
    UnitRole.commander => 31,
  };

  static double attackRange(UnitRole role) => switch (role) {
    UnitRole.infantry => 19,
    UnitRole.shield => 18,
    UnitRole.archer => 145,
    UnitRole.cavalry => 28,
    UnitRole.mage => 175,
    UnitRole.siege => 38,
    UnitRole.commander => 34,
  };

  static int damage(UnitRole role) => switch (role) {
    UnitRole.infantry => 1,
    UnitRole.shield => 1,
    UnitRole.archer => 1,
    UnitRole.cavalry => 3,
    UnitRole.mage => 2,
    UnitRole.siege => 18,
    UnitRole.commander => 3,
  };

  static int defense(UnitRole role) => switch (role) {
    UnitRole.infantry => 8,
    UnitRole.shield => 35,
    UnitRole.archer => 4,
    UnitRole.cavalry => 14,
    UnitRole.mage => 7,
    UnitRole.siege => 24,
    UnitRole.commander => 28,
  };
}

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
    required this.gateHp,
    required this.gateMaxHp,
    required this.frontPressure,
    required this.allyCommanderAlive,
    required this.enemyCommanderAlive,
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
  final double gateHp;
  final double gateMaxHp;
  final double frontPressure;
  final bool allyCommanderAlive;
  final bool enemyCommanderAlive;
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
    this.objectiveHpRatio = 1,
    this.completedBonusIds = const [],
    this.commanderSurvived = true,
    this.enemyCommanderDefeated = false,
  });

  final String time;
  final int kills;
  final int gold;
  final int xp;
  final BattleOutcome outcome;
  final int alliedKills;
  final List<String> triggeredEventIds;
  final double objectiveHpRatio;
  final List<String> completedBonusIds;
  final bool commanderSurvived;
  final bool enemyCommanderDefeated;
}

abstract final class GateDefenseRules {
  static const double maxGateHp = 1200;

  static BattleOutcome resolve({
    required double gateHp,
    required int secondsLeft,
  }) {
    if (gateHp <= 0) return BattleOutcome.defeat;
    if (secondsLeft <= 0) return BattleOutcome.victory;
    return BattleOutcome.retreat;
  }

  static List<String> completedBonuses({
    required double gateHpRatio,
    required double frontPressure,
    required bool elitesCleared,
  }) => [
    if (gateHpRatio >= .75) 'gate_75',
    if (frontPressure <= .25) 'line_held',
    if (elitesCleared) 'elite_clear',
  ];
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
