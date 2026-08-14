import 'battle_rewards.dart';

class MercenaryProgress {
  const MercenaryProgress({
    required this.level,
    required this.xp,
    required this.ascension,
    this.stars = 1,
  });

  final int level;
  final int xp;
  final int ascension;
  final int stars;

  int get levelCap => ProgressionRules.levelCapForGrade(ascension);
  String get grade => ProgressionRules.gradeName(ascension);

  Map<String, Object> toJson() => {
    'level': level,
    'xp': xp,
    'ascension': ascension,
    'stars': stars,
  };

  factory MercenaryProgress.fromJson(Map<String, Object?> json) =>
      MercenaryProgress(
        level: (json['level'] as num?)?.toInt() ?? 1,
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        ascension: (json['ascension'] as num?)?.toInt() ?? 0,
        stars: ((json['stars'] as num?)?.toInt() ?? 1).clamp(1, 5),
      );
}

class WeaponProgress {
  const WeaponProgress({
    required this.level,
    required this.xp,
    required this.stage,
  });

  final int level;
  final int xp;
  final int stage;

  Map<String, Object> toJson() => {'level': level, 'xp': xp, 'stage': stage};

  factory WeaponProgress.fromJson(Map<String, Object?> json) => WeaponProgress(
    level: (json['level'] as num?)?.toInt() ?? 1,
    xp: (json['xp'] as num?)?.toInt() ?? 0,
    stage: (json['stage'] as num?)?.toInt() ?? 1,
  );
}

class GrowthReceipt {
  const GrowthReceipt({
    required this.mercenaryId,
    required this.mercenaryBefore,
    required this.mercenaryAfter,
    required this.mercenaryXpGained,
    required this.weaponId,
    required this.weaponBefore,
    required this.weaponAfter,
    required this.weaponXpGained,
    required this.inventoryAdded,
  });

  final String mercenaryId;
  final MercenaryProgress mercenaryBefore;
  final MercenaryProgress mercenaryAfter;
  final int mercenaryXpGained;
  final String weaponId;
  final WeaponProgress weaponBefore;
  final WeaponProgress weaponAfter;
  final int weaponXpGained;
  final Map<String, int> inventoryAdded;
}

abstract final class ProgressionRules {
  static const gradeNames = ['F', 'E', 'D', 'C', 'B', 'A', 'S'];
  static const gradeLevelCaps = [10, 15, 20, 25, 30, 35, 40];

  static String gradeName(int grade) => gradeNames[grade.clamp(0, 6)];
  static int levelCapForGrade(int grade) => gradeLevelCaps[grade.clamp(0, 6)];

  static int effectiveMercenaryLevel(MercenaryProgress progress) {
    var completed = 0;
    for (var grade = 0; grade < progress.ascension.clamp(0, 6); grade++) {
      completed += gradeLevelCaps[grade];
    }
    return completed + progress.level;
  }

  static double gradePowerMultiplier(MercenaryProgress progress) =>
      1 + progress.ascension.clamp(0, 6) * .12 + (progress.stars - 1) * .045;
  static int commanderXpToNext(int level) => 800 + level * 200;

  static ({int level, int xp}) addCommanderXp(int level, int xp, int gained) {
    var nextLevel = level;
    var nextXp = xp + gained;
    while (nextLevel < 50) {
      final needed = commanderXpToNext(nextLevel);
      if (nextXp < needed) break;
      nextXp -= needed;
      nextLevel++;
    }
    return (level: nextLevel, xp: nextXp);
  }

  static String commanderRank(int level) => switch (level) {
    >= 30 => 'A',
    >= 20 => 'B',
    >= 10 => 'C',
    >= 5 => 'D',
    _ => 'E',
  };

  static int displayPower({
    required int catalogPower,
    required int catalogLevel,
    required int permanentLevel,
  }) {
    if (permanentLevel >= catalogLevel) return catalogPower;
    final ratio = permanentLevel / catalogLevel.clamp(1, 99);
    return (catalogPower * (.28 + .72 * ratio)).round();
  }

  static int displayPowerForProgress({
    required int catalogPower,
    required int catalogLevel,
    required MercenaryProgress progress,
  }) =>
      (displayPower(
                catalogPower: catalogPower,
                catalogLevel: catalogLevel,
                permanentLevel: effectiveMercenaryLevel(progress),
              ) *
              gradePowerMultiplier(progress))
          .round();

  static int mercenaryXpToNext(int level, {int grade = 0}) =>
      260 + level * 70 + grade * 180;
  static int weaponXpToNext(int level) => 250 + level * 100;
  static int ascensionCost(int ascension) => 2 + ascension * 2;
  static int legacyGradeForLevel(int level) => switch (level) {
    >= 40 => 6,
    >= 35 => 5,
    >= 30 => 4,
    >= 25 => 3,
    >= 20 => 2,
    >= 10 => 1,
    _ => 0,
  };

  static double mercenaryHpMultiplier(int baseLevel, int permanentLevel) =>
      permanentLevel < baseLevel
      ? .65 + .35 * permanentLevel / baseLevel
      : 1 + (permanentLevel - baseLevel).clamp(0, 60) * .012;

  static double mercenarySpeedMultiplier(int baseLevel, int permanentLevel) =>
      permanentLevel < baseLevel
      ? .88 + .12 * permanentLevel / baseLevel
      : 1 + (permanentLevel - baseLevel).clamp(0, 60) * .003;

  static double combatDamageMultiplier({
    required int baseMercenaryLevel,
    required int permanentMercenaryLevel,
    required int weaponLevel,
    required int weaponStage,
  }) {
    final levelFactor = permanentMercenaryLevel < baseMercenaryLevel
        ? .45 + .55 * permanentMercenaryLevel / baseMercenaryLevel
        : 1 + (permanentMercenaryLevel - baseMercenaryLevel).clamp(0, 60) * .03;
    return levelFactor +
        (weaponLevel - 1).clamp(0, 19) * .025 +
        (weaponStage - 1).clamp(0, 3) * .05;
  }

  static bool canAscend(MercenaryProgress current, int availableSigils) =>
      current.ascension < 6 &&
      current.level >= current.levelCap &&
      availableSigils >= ascensionCost(current.ascension);

  static MercenaryProgress ascend(
    MercenaryProgress current, {
    required int availableSigils,
  }) {
    if (!canAscend(current, availableSigils)) return current;
    return MercenaryProgress(
      level: 1,
      xp: 0,
      ascension: current.ascension + 1,
      stars: current.stars,
    );
  }

  static int limitBreakTokenCost(int stars) => 20 + (stars - 1) * 15;

  static bool canLimitBreak(MercenaryProgress current, int tokens) =>
      current.stars < 5 && tokens >= limitBreakTokenCost(current.stars);

  static MercenaryProgress limitBreak(MercenaryProgress current) =>
      MercenaryProgress(
        level: current.level,
        xp: current.xp,
        ascension: current.ascension,
        stars: (current.stars + 1).clamp(1, 5),
      );

  static MercenaryProgress addMercenaryXp(
    MercenaryProgress current,
    int gained,
  ) {
    var level = current.level;
    var xp = current.xp + gained;
    while (level < current.levelCap) {
      final needed = mercenaryXpToNext(level, grade: current.ascension);
      if (xp < needed) break;
      xp -= needed;
      level++;
    }
    if (level >= current.levelCap) xp = 0;
    return MercenaryProgress(
      level: level,
      xp: xp,
      ascension: current.ascension,
      stars: current.stars,
    );
  }

  static WeaponProgress addWeaponXp(WeaponProgress current, int gained) {
    var level = current.level;
    var xp = current.xp + gained;
    while (level < 20) {
      final needed = weaponXpToNext(level);
      if (xp < needed) break;
      xp -= needed;
      level++;
    }
    if (level >= 20) xp = 0;
    return WeaponProgress(level: level, xp: xp, stage: 1 + (level - 1) ~/ 5);
  }

  static Map<String, int> lootQuantities(List<LootDrop> drops) => {
    for (final drop in drops) drop.id: drop.quantity,
  };
}
