import 'dart:math' as math;

enum RunUpgradeKind { weapon, passive, trait }

class RunUpgradeDefinition {
  const RunUpgradeDefinition({
    required this.id,
    required this.kind,
    required this.maxLevel,
    required this.baseWeight,
  });

  final String id;
  final RunUpgradeKind kind;
  final int maxLevel;
  final int baseWeight;
}

class RunGrowthState {
  const RunGrowthState({
    required this.weaponLevels,
    required this.passiveLevels,
    required this.traitLevel,
    this.maxWeaponSlots = 4,
  });

  final Map<String, int> weaponLevels;
  final Map<String, int> passiveLevels;
  final int traitLevel;
  final int maxWeaponSlots;

  int levelOf(RunUpgradeDefinition definition) => switch (definition.kind) {
    RunUpgradeKind.weapon => weaponLevels[definition.id] ?? 0,
    RunUpgradeKind.passive => passiveLevels[definition.id] ?? 0,
    RunUpgradeKind.trait => traitLevel,
  };

  bool canOffer(RunUpgradeDefinition definition) {
    final level = levelOf(definition);
    if (level >= definition.maxLevel) return false;
    if (definition.kind == RunUpgradeKind.weapon &&
        level == 0 &&
        weaponLevels.length >= maxWeaponSlots) {
      return false;
    }
    return true;
  }
}

abstract final class RunGrowthRules {
  static bool canOfferWeapon({
    required String? ownerId,
    required String mercenaryId,
    required String equippedWeaponId,
    required String weaponId,
  }) {
    return ownerId == null ||
        ownerId == mercenaryId ||
        weaponId == equippedWeaponId;
  }

  static List<RunUpgradeDefinition> generateChoices({
    required List<RunUpgradeDefinition> definitions,
    required RunGrowthState state,
    required math.Random random,
    int count = 3,
  }) {
    final pool = definitions.where(state.canOffer).toList();
    final choices = <RunUpgradeDefinition>[];
    while (choices.length < count && pool.isNotEmpty) {
      final weights = pool
          .map((definition) => _effectiveWeight(definition, state))
          .toList();
      final total = weights.fold<int>(0, (sum, weight) => sum + weight);
      var roll = random.nextInt(total);
      var selectedIndex = 0;
      for (var i = 0; i < weights.length; i++) {
        roll -= weights[i];
        if (roll < 0) {
          selectedIndex = i;
          break;
        }
      }
      choices.add(pool.removeAt(selectedIndex));
    }
    return choices;
  }

  static int _effectiveWeight(
    RunUpgradeDefinition definition,
    RunGrowthState state,
  ) {
    final owned = state.levelOf(definition) > 0;
    return definition.baseWeight + (owned ? 35 : 0);
  }
}

class RunBuildEntry {
  const RunBuildEntry({
    required this.id,
    required this.kind,
    required this.level,
    required this.maxLevel,
  });

  final String id;
  final RunUpgradeKind kind;
  final int level;
  final int maxLevel;
}

const alphaPassiveDefinitions = <RunUpgradeDefinition>[
  RunUpgradeDefinition(
    id: 'battle_instinct',
    kind: RunUpgradeKind.passive,
    maxLevel: 5,
    baseWeight: 72,
  ),
  RunUpgradeDefinition(
    id: 'rapid_drill',
    kind: RunUpgradeKind.passive,
    maxLevel: 5,
    baseWeight: 68,
  ),
  RunUpgradeDefinition(
    id: 'swift_step',
    kind: RunUpgradeKind.passive,
    maxLevel: 5,
    baseWeight: 62,
  ),
  RunUpgradeDefinition(
    id: 'keen_eye',
    kind: RunUpgradeKind.passive,
    maxLevel: 5,
    baseWeight: 66,
  ),
];
