part of '../survivor_game.dart';

extension WeaponSystem on SurvivorGame {
  void _attackWithWeapon(RunWeaponState state) {
    final activeWeapon = state.weapon;
    final range = switch (activeWeapon.pattern) {
      WeaponPattern.twinSlash => 235.0,
      WeaponPattern.bloodCleave => 230.0,
      WeaponPattern.chainFlame => 365.0,
      WeaponPattern.swordStrike => 245.0,
      WeaponPattern.longBow => 430.0,
      WeaponPattern.emberBurst => 350.0,
      WeaponPattern.spearLine => 300.0,
      WeaponPattern.shadowPierce => 390.0,
      WeaponPattern.rapidVolley => 440.0,
      WeaponPattern.shieldOrbit => 190.0,
      WeaponPattern.runeMine => 350.0,
      WeaponPattern.featherChain => 380.0,
      WeaponPattern.halberdSweep => 270.0,
      WeaponPattern.crescentWave => 400.0,
      WeaponPattern.frostTotem => 320.0,
      WeaponPattern.spiritFamiliar => 370.0,
    };
    final target = _preferredEnemyFrom(
      _player,
      range,
      preferFarthest: activeWeapon.pattern == WeaponPattern.longBow,
    );
    if (target == null) return;
    _playerSprite.playAttack();
    final baseDamage =
        ((mercenary.baseDamage +
                    activeWeapon.attack ~/ 650 +
                    (state.level ~/ 2)) *
                (1 +
                    _passiveLevel('battle_instinct') * .1 +
                    (mercenary.id == 'kael' ? _traitLevel * .08 : 0)) *
                _permanentDamageMultiplier)
            .round();
    final nocturnal =
        mercenary.id == 'luna' &&
        config.condition == BattlefieldCondition.moonlitNight;
    final criticalChance =
        activeWeapon.crit.toDouble() +
        config.gearBonus.criticalChance +
        _passiveLevel('keen_eye') * 5 +
        (nocturnal ? 15 + _traitLevel * 3 : 0);
    final statusBonus = mercenary.id == 'sera' ? _traitLevel * .06 : 0.0;

    switch (activeWeapon.pattern) {
      case WeaponPattern.twinSlash:
        _damageEnemy(
          target,
          baseDamage,
          criticalChance: criticalChance,
          multiplier: .72,
        );
        if (!target.dead) {
          _damageEnemy(
            target,
            baseDamage,
            criticalChance: criticalChance,
            multiplier: .72,
          );
        }
      case WeaponPattern.bloodCleave:
        final impact = target.position.clone();
        for (final unit in _enemiesNear(impact, 76).take(7)) {
          _damageEnemy(
            unit,
            baseDamage,
            criticalChance: criticalChance,
            status: StatusEffectType.bleed,
            statusChance: .42 + statusBonus,
            showFx: identical(unit, target),
          );
        }
      case WeaponPattern.chainFlame:
        _launchProjectile(
          origin: _playerCombatOrigin,
          target: target,
          pattern: activeWeapon.pattern,
          damage: baseDamage,
          speed: 330,
          criticalChance: criticalChance,
          chainRemaining: 2,
        );
      case WeaponPattern.swordStrike:
        _damageEnemy(
          target,
          baseDamage,
          criticalChance: criticalChance,
          multiplier: 1.3,
        );
      case WeaponPattern.longBow:
        _launchProjectile(
          origin: _playerCombatOrigin,
          target: target,
          pattern: activeWeapon.pattern,
          damage: baseDamage + 1,
          speed: 440,
          criticalChance: criticalChance,
        );
      case WeaponPattern.emberBurst:
        _launchProjectile(
          origin: _playerCombatOrigin,
          target: target,
          pattern: activeWeapon.pattern,
          damage: baseDamage,
          speed: 285,
          criticalChance: criticalChance,
        );
      case WeaponPattern.spearLine:
        _strikeLine(
          target: target,
          length: 310,
          halfWidth: 24,
          limit: 8,
          damage: baseDamage,
          criticalChance: criticalChance,
          multiplier: 1.1,
        );
      case WeaponPattern.shadowPierce:
        _strikeLine(
          target: target,
          length: 390,
          halfWidth: 18,
          limit: 6,
          damage: baseDamage,
          criticalChance: criticalChance,
          status: StatusEffectType.bleed,
          statusChance: .28 + statusBonus,
        );
        _launchProjectile(
          origin: _playerCombatOrigin,
          target: target,
          pattern: activeWeapon.pattern,
          damage: 0,
          speed: 560,
          criticalChance: 0,
          appliesDamage: false,
        );
      case WeaponPattern.rapidVolley:
        for (var i = 0; i < 3; i++) {
          _launchProjectile(
            origin: _playerCombatOrigin,
            target: target,
            pattern: activeWeapon.pattern,
            damage: math.max(1, (baseDamage * .58).round()),
            speed: 500 + i * 35,
            criticalChance: criticalChance,
          );
        }
      case WeaponPattern.shieldOrbit:
        for (final unit in _enemiesNear(_player, 94).take(12)) {
          _damageEnemy(
            unit,
            baseDamage,
            criticalChance: criticalChance,
            multiplier: 1.15,
            showFx: identical(unit, target),
          );
        }
        _emitSlash(_playerCombatOrigin, .42, CombatStyle.greatsword);
      case WeaponPattern.runeMine:
        for (final unit in _enemiesNear(target.position, 92).take(10)) {
          _damageEnemy(
            unit,
            baseDamage,
            kind: DamageKind.magical,
            criticalChance: criticalChance,
            status: StatusEffectType.burn,
            statusChance: .26,
            showFx: identical(unit, target),
          );
        }
      case WeaponPattern.featherChain:
        _launchProjectile(
          origin: _playerCombatOrigin,
          target: target,
          pattern: activeWeapon.pattern,
          damage: baseDamage,
          speed: 470,
          criticalChance: criticalChance,
          chainRemaining: 3,
        );
      case WeaponPattern.halberdSweep:
        for (final unit in _enemiesNear(target.position, 105).take(11)) {
          _damageEnemy(
            unit,
            baseDamage,
            criticalChance: criticalChance,
            multiplier: 1.18,
            showFx: identical(unit, target),
          );
        }
        _emitSlash(target.position, .38, CombatStyle.greatsword);
      case WeaponPattern.crescentWave:
        _strikeLine(
          target: target,
          length: 410,
          halfWidth: 34,
          limit: 9,
          damage: baseDamage,
          criticalChance: criticalChance,
          multiplier: 1.05,
        );
      case WeaponPattern.frostTotem:
        for (final unit in _enemiesNear(target.position, 115).take(12)) {
          _damageEnemy(
            unit,
            math.max(1, (baseDamage * .7).round()),
            kind: DamageKind.magical,
            criticalChance: criticalChance,
            status: StatusEffectType.slow,
            statusChance: .75,
            showFx: identical(unit, target),
          );
        }
      case WeaponPattern.spiritFamiliar:
        _launchProjectile(
          origin: _playerCombatOrigin,
          target: target,
          pattern: activeWeapon.pattern,
          damage: baseDamage + 1,
          speed: 390,
          criticalChance: criticalChance,
        );
    }
    if (_xp >= _nextXp) _requestLevelUp();
  }

  void _strikeLine({
    required BattleUnit target,
    required double length,
    required double halfWidth,
    required int limit,
    required int damage,
    required double criticalChance,
    double multiplier = 1,
    StatusEffectType status = StatusEffectType.none,
    double statusChance = 0,
  }) {
    final direction = (target.position - _player).normalized();
    var hits = 0;
    for (final unit in _units) {
      if (unit.dead || unit.ally) continue;
      final delta = unit.position - _player;
      final forward = direction.dot(delta);
      final sideways = (direction.x * delta.y - direction.y * delta.x).abs();
      if (forward < 0 || forward > length || sideways > halfWidth) continue;
      _damageEnemy(
        unit,
        damage,
        criticalChance: criticalChance,
        multiplier: multiplier,
        status: status,
        statusChance: statusChance,
        showFx: hits == 0,
      );
      if (++hits >= limit) break;
    }
    _emitSlash(target.position, .34, CombatStyle.blades);
  }

  Iterable<BattleUnit> _enemiesNear(Vector2 center, double range) =>
      _units
          .where(
            (unit) =>
                !unit.dead &&
                !unit.ally &&
                unit.position.distanceTo(center) <= range,
          )
          .toList()
        ..sort(
          (a, b) => a.position
              .distanceTo(center)
              .compareTo(b.position.distanceTo(center)),
        );

  BattleUnit? _nearestEnemyFrom(
    Vector2 center,
    double range, {
    BattleUnit? excluded,
  }) {
    BattleUnit? nearest;
    var best = range;
    for (final unit in _units) {
      if (unit.dead || unit.ally || identical(unit, excluded)) continue;
      final distance = unit.position.distanceTo(center);
      if (distance < best) {
        best = distance;
        nearest = unit;
      }
    }
    return nearest;
  }

  BattleUnit? _preferredEnemyFrom(
    Vector2 center,
    double range, {
    bool preferFarthest = false,
  }) {
    if (targetPriority == AutoTargetPriority.nearest) {
      return preferFarthest
          ? _farthestEnemyFrom(center, range)
          : _nearestEnemyFrom(center, range);
    }
    BattleUnit? preferred;
    var preferredDistance = double.infinity;
    for (final unit in _units) {
      if (unit.dead || unit.ally) continue;
      final distance = unit.position.distanceTo(center);
      if (distance > range) continue;
      final matches = switch (targetPriority) {
        AutoTargetPriority.nearest => true,
        AutoTargetPriority.elite =>
          unit.elite || unit.role == UnitRole.commander,
        AutoTargetPriority.objectiveThreat => unit.objectiveAggro,
      };
      if (matches && distance < preferredDistance) {
        preferred = unit;
        preferredDistance = distance;
      }
    }
    return preferred ?? _nearestEnemyFrom(center, range);
  }

  BattleUnit? _farthestEnemyFrom(Vector2 center, double range) {
    BattleUnit? farthest;
    var best = 0.0;
    for (final unit in _units) {
      if (unit.dead || unit.ally) continue;
      final distance = unit.position.distanceTo(center);
      if (distance <= range && distance > best) {
        best = distance;
        farthest = unit;
      }
    }
    return farthest;
  }
}
