part of '../survivor_game.dart';

extension DamageSystem on SurvivorGame {
  DamageResult _resolveAgainstUnit(
    BattleUnit target,
    int baseDamage, {
    DamageKind kind = DamageKind.physical,
    double criticalChance = 0,
    double multiplier = 1,
    StatusEffectType status = StatusEffectType.none,
    double statusChance = 0,
  }) => DamageResolver.resolve(
    DamageRequest(
      baseDamage: baseDamage,
      defense: UnitRoleRules.defense(target.role),
      criticalChance: criticalChance,
      criticalRoll: _random.nextDouble(),
      kind: kind,
      damageMultiplier: multiplier,
      status: status,
      statusChance: statusChance,
      statusRoll: _random.nextDouble(),
    ),
  );

  void _damageEnemy(
    BattleUnit target,
    int damage, {
    bool grantUltimateCharge = true,
    double fxLife = .24,
    bool showFx = true,
    bool showNumber = true,
    DamageKind kind = DamageKind.physical,
    double criticalChance = 0,
    double multiplier = 1,
    StatusEffectType status = StatusEffectType.none,
    double statusChance = 0,
  }) {
    if (target.dead) return;
    final result = _resolveAgainstUnit(
      target,
      damage,
      kind: kind,
      criticalChance: criticalChance,
      multiplier: multiplier,
      status: status,
      statusChance: statusChance,
    );
    target.hp -= result.amount;
    target.hitFlash = .12;
    if (result.appliedStatus != StatusEffectType.none) {
      _applyStatus(target, result.appliedStatus);
    }
    if (showFx) _emitSlash(target.position, fxLife, mercenary.style);
    if (showNumber) {
      _emitDamageNumber(target.position, result.amount, result.isCritical);
    }
    if (target.hp > 0) return;
    target.dead = true;
    _kills++;
    _xp += target.elite ? 16 : 5;
    if (grantUltimateCharge && _signatureWeaponActive) {
      _ultimateCharge = math.min(
        1,
        _ultimateCharge + (target.elite ? .22 : .07),
      );
    }
  }

  void _damageBattleUnit(
    BattleUnit attacker,
    BattleUnit target,
    int damage, {
    bool showFx = true,
  }) {
    if (target.dead) return;
    final kind = attacker.role == UnitRole.mage
        ? DamageKind.magical
        : DamageKind.physical;
    final result = _resolveAgainstUnit(
      target,
      damage,
      kind: kind,
      criticalChance: attacker.role == UnitRole.commander ? 8 : 0,
    );
    target.hp -= result.amount;
    target.hitFlash = .09;
    if (showFx) {
      final style = switch (attacker.role) {
        UnitRole.mage => CombatStyle.magic,
        UnitRole.cavalry ||
        UnitRole.siege ||
        UnitRole.commander => CombatStyle.greatsword,
        _ => CombatStyle.blades,
      };
      _emitSlash(target.position, .18, style);
    }
    if (target.hp > 0) return;
    target.dead = true;
    if (attacker.ally) _alliedKills++;
  }

  void _applyStatus(BattleUnit target, StatusEffectType status) {
    target.status = status;
    target.statusClock = switch (status) {
      StatusEffectType.bleed => 4.0,
      StatusEffectType.burn => 3.2,
      StatusEffectType.slow => 3.0,
      StatusEffectType.none => 0,
    };
    target.statusTickClock = .7;
  }

  void _updateUnitStatus(BattleUnit unit, double dt) {
    unit.hitFlash = math.max(0, unit.hitFlash - dt);
    if (unit.status == StatusEffectType.none) return;
    unit.statusClock -= dt;
    unit.statusTickClock -= dt;
    if (unit.status != StatusEffectType.slow && unit.statusTickClock <= 0) {
      unit.statusTickClock = .7;
      _damageEnemy(
        unit,
        unit.status == StatusEffectType.bleed ? 2 : 1,
        kind: DamageKind.pure,
        criticalChance: 0,
        showFx: false,
        showNumber: true,
      );
    }
    if (unit.statusClock <= 0) {
      unit.status = StatusEffectType.none;
      unit.statusClock = 0;
    }
  }
}
