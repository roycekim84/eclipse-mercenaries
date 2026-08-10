import 'game_data.dart';
import 'run_growth.dart';
import 'battlefield_events.dart';
import 'battle_rewards.dart';

enum BattleOutcome { victory, retreat, defeat }

enum BattlefieldType { gateDefense, evacuation }

enum BattlefieldCondition { moonlitNight, ashWind }

enum UnitRole { infantry, shield, archer, cavalry, mage, siege, commander }

enum UnitStance { advance, support, retreat }

class BattleControlState {
  const BattleControlState({
    required this.dashCooldown,
    required this.tacticalCooldown,
    required this.tacticalActive,
  });

  const BattleControlState.ready()
    : dashCooldown = 0,
      tacticalCooldown = 0,
      tacticalActive = false;

  final double dashCooldown;
  final double tacticalCooldown;
  final bool tacticalActive;
}

abstract final class BattleControlRules {
  static const dashCooldownSeconds = 2.5;
  static const tacticalCooldownSeconds = 14.0;
  static const tacticalDurationSeconds = 4.0;

  static double dashDistance(double movementSpeed) =>
      (movementSpeed * .72).clamp(92, 132).toDouble();
}

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
    this.battlefield = BattlefieldType.gateDefense,
    this.condition = BattlefieldCondition.moonlitNight,
    this.durationSeconds = 45,
    this.seed = 19,
    this.unitCount = 500,
    this.contractId = 'gate_defense',
    this.contractName = '성문 방어전',
    this.contractGold = 3000,
    this.contractXp = 1200,
    this.mercenaryPermanentLevel,
    this.weaponPermanentLevel = 1,
    this.weaponGrowthStage = 1,
  });

  final MercenarySpec mercenary;
  final WeaponSpec weapon;
  final BattlefieldType battlefield;
  final BattlefieldCondition condition;
  final int durationSeconds;
  final int seed;
  final int unitCount;
  final String contractId;
  final String contractName;
  final int contractGold;
  final int contractXp;
  final int? mercenaryPermanentLevel;
  final int weaponPermanentLevel;
  final int weaponGrowthStage;
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
    required this.build,
    this.escortTotal = 0,
    this.escortAlive = 0,
    this.escortEscaped = 0,
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
  final List<RunBuildEntry> build;
  final int escortTotal;
  final int escortAlive;
  final int escortEscaped;
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
    required this.contractName,
    this.outcome = BattleOutcome.victory,
    this.alliedKills = 0,
    this.triggeredEventIds = const [],
    this.objectiveHpRatio = 1,
    this.completedBonusIds = const [],
    this.commanderSurvived = true,
    this.enemyCommanderDefeated = false,
    this.battlefield = BattlefieldType.gateDefense,
    this.escortEscaped = 0,
    this.escortTotal = 0,
    this.peakActiveUnits = 0,
    this.frameTimeP95Ms = 0,
    this.performance = const BattlePerformanceMetrics(),
    this.rareDropIds = const [],
    this.eventRecords = const [],
    required this.rewardBreakdown,
    required this.lootDrops,
    required this.award,
    this.ultimateActivations = 0,
  });

  final String time;
  final int kills;
  final int gold;
  final int xp;
  final String contractName;
  final BattleOutcome outcome;
  final int alliedKills;
  final List<String> triggeredEventIds;
  final double objectiveHpRatio;
  final List<String> completedBonusIds;
  final bool commanderSurvived;
  final bool enemyCommanderDefeated;
  final BattlefieldType battlefield;
  final int escortEscaped;
  final int escortTotal;
  final int peakActiveUnits;
  final double frameTimeP95Ms;
  final BattlePerformanceMetrics performance;
  final List<String> rareDropIds;
  final List<BattlefieldEventRecord> eventRecords;
  final RewardBreakdown rewardBreakdown;
  final List<LootDrop> lootDrops;
  final BattleAward award;
  final int ultimateActivations;
}

class BattlePerformanceMetrics {
  const BattlePerformanceMetrics({
    this.sampleCount = 0,
    this.updateP95Ms = 0,
    this.aiP95Ms = 0,
    this.combatP95Ms = 0,
    this.weaponsP95Ms = 0,
    this.renderCpuP95Ms = 0,
    this.spatialBuckets = 0,
    this.peakProjectiles = 0,
    this.peakEffects = 0,
    this.peakDamageNumbers = 0,
  });

  final int sampleCount;
  final double updateP95Ms;
  final double aiP95Ms;
  final double combatP95Ms;
  final double weaponsP95Ms;
  final double renderCpuP95Ms;
  final int spatialBuckets;
  final int peakProjectiles;
  final int peakEffects;
  final int peakDamageNumbers;
}

abstract final class EvacuationRules {
  static const int totalEscorts = 12;
  static const int requiredEscaped = 8;

  static BattleOutcome resolve({
    required int alive,
    required int escaped,
    required int secondsLeft,
  }) {
    if (escaped >= requiredEscaped) return BattleOutcome.victory;
    if (alive + escaped < requiredEscaped || secondsLeft <= 0) {
      return BattleOutcome.defeat;
    }
    return BattleOutcome.retreat;
  }

  static List<String> completedBonuses({
    required int escaped,
    required int total,
    required bool enemyCommanderDefeated,
    required int secondsLeft,
  }) => [
    if (total > 0 && escaped / total >= .9) 'convoy_90',
    if (enemyCommanderDefeated) 'pursuer_commander',
    if (secondsLeft >= 8) 'swift_exit',
  ];
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
  const UpgradeOption({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.iconId,
    required this.currentLevel,
    required this.maxLevel,
  });

  final String id;
  final RunUpgradeKind kind;
  final String title;
  final String description;
  final String iconId;
  final int currentLevel;
  final int maxLevel;
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
