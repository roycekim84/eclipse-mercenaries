part of '../survivor_game.dart';

extension DamageSystem on SurvivorGame {
  void _damagePlayer(
    int damage, {
    double invulnerabilitySeconds = .32,
    CombatStyle style = CombatStyle.greatsword,
  }) {
    if (_playerInvulnerability > 0 || _finished) return;
    final appliedDamage = config.introProfile == null
        ? damage
        : math.max(
            1,
            (damage * config.introProfile!.enemyDamageMultiplier).round(),
          );
    _playerHp = math.max(0, _playerHp - appliedDamage);
    _playerHitFlash = .16;
    _playerInvulnerability = invulnerabilitySeconds;
    _emitSlash(_player, .2, style);
    _triggerImpact(hitStop: .04, impulse: 5.5);
    unawaited(
      GameAudioFeedback.combat(
        CombatAudioCue.playerHurt,
        style: style,
        enabled: soundEnabled,
        haptics: true,
      ),
    );
  }

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
      defense:
          UnitRoleRules.defense(target.role) +
          (target.archetype?.defenseBonus ?? 0),
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
    if (showFx) {
      final bossHit = target.archetype?.rank == EnemyRank.boss;
      _triggerImpact(
        hitStop: result.isCritical
            ? .035
            : bossHit
            ? .026
            : .012,
        impulse: result.isCritical
            ? 3.2
            : bossHit
            ? 2.2
            : .8,
      );
      unawaited(
        GameAudioFeedback.combat(
          result.isCritical
              ? CombatAudioCue.critical
              : bossHit
              ? CombatAudioCue.bossImpact
              : CombatAudioCue.slash,
          style: mercenary.style,
          enabled: soundEnabled,
          haptics: result.isCritical,
        ),
      );
    }
    if (showNumber) {
      _emitDamageNumber(target.position, result.amount, result.isCritical);
    }
    if (target.hp > 0) return;
    target.dead = true;
    _kills++;
    final rank = target.archetype?.rank ?? EnemyRank.common;
    final gainedXp = switch (rank) {
      EnemyRank.common => 5,
      EnemyRank.elite => 20,
      EnemyRank.boss => 45,
    };
    _xp += gainedXp * (config.introProfile?.xpMultiplier ?? 1);
    _collectRareDrop(target);
    if (rank != EnemyRank.common) {
      unawaited(
        GameAudioFeedback.combat(
          CombatAudioCue.enemyDefeat,
          enabled: soundEnabled,
        ),
      );
    }
    if (grantUltimateCharge && _signatureWeaponActive) {
      _ultimateCharge = math.min(
        1,
        _ultimateCharge +
            switch (rank) {
                  EnemyRank.common => .07,
                  EnemyRank.elite => .22,
                  EnemyRank.boss => .35,
                } *
                (config.introProfile?.ultimateChargeMultiplier ?? 1),
      );
      if (_ultimateCharge >= 1) _firstUltimateReadyAt ??= _elapsed;
    }
    if (target == _enemyCommander && rank == EnemyRank.boss) {
      _bossDefeatedAt ??= _elapsed;
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
    final renderArmyImpact =
        showFx &&
        (_battleUnitFxSequence++ % (_reducedVisualLoad ? 9 : 5) == 0 ||
            attacker.role == UnitRole.commander ||
            attacker.elite);
    if (renderArmyImpact) {
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
    if (attacker.ally) {
      _alliedKills++;
      _collectRareDrop(target);
    }
  }

  void _collectRareDrop(BattleUnit target) {
    final rareDrop = target.archetype?.rareDropId;
    if (rareDrop != null && !_rareDrops.contains(rareDrop)) {
      _rareDrops.add(rareDrop);
      unawaited(GameAudioFeedback.cue(AudioCue.lootRare, audioSettings));
    }
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
