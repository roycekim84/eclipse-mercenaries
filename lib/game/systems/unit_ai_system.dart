part of '../survivor_game.dart';

extension UnitAiSystem on SurvivorGame {
  void _updateRoleUnit(BattleUnit unit, double dt) {
    if (unit.ally && _tacticalClock > 0) {
      unit.attackClock -= dt * .45;
      dt *= 1.18;
    }
    if (unit.hp <= unit.maxHp * .25 &&
        unit.role != UnitRole.commander &&
        unit.role != UnitRole.siege) {
      unit.stance = UnitStance.retreat;
    }
    if (unit.stance == UnitStance.retreat) {
      _moveRetreatingUnit(unit, dt);
      return;
    }
    if (!unit.ally && unit.objectiveAggro) {
      if (config.battlefield == BattlefieldType.evacuation) {
        _updatePursuer(unit, dt);
      } else {
        _updateSiegeUnit(unit, dt);
      }
      return;
    }

    if (!unit.ally && unit.playerAggro) {
      final playerDistance = unit.position.distanceTo(_player);
      if (playerDistance <= 38) {
        unit.stance = UnitStance.advance;
        if (unit.attackClock <= 0) _attackPlayer(unit);
        return;
      }
    }

    final attackRange = UnitRoleRules.attackRange(unit.role);
    final searchRange = math.max(150.0, attackRange + 55);
    final opponent = _nearestOpponent(unit, searchRange);
    if (opponent == null) {
      if (!unit.ally && unit.playerAggro) {
        _moveToward(unit, _player, dt, stopDistance: 42);
      } else {
        _moveInFormation(unit, dt);
      }
      return;
    }

    unit.stance = UnitStance.advance;
    final delta = opponent.position - unit.position;
    final distance = delta.length;
    final isRanged = unit.role == UnitRole.archer || unit.role == UnitRole.mage;
    if (isRanged && distance < attackRange * .48) {
      _moveAlong(unit, -delta, dt);
    } else if (distance > attackRange) {
      _moveAlong(unit, delta, dt);
    }
    if (distance <= attackRange && unit.attackClock <= 0) {
      _roleAttack(unit, opponent);
    }
  }

  void _roleAttack(BattleUnit attacker, BattleUnit target) {
    final commander = attacker.ally ? _allyCommander : _enemyCommander;
    final commandBuff =
        commander != null &&
        !commander.dead &&
        commander.position.distanceTo(attacker.position) <= 180;
    final interval = switch (attacker.role) {
      UnitRole.archer => 1.25,
      UnitRole.mage => 1.55,
      UnitRole.cavalry => 1.05,
      UnitRole.commander => .82,
      UnitRole.shield => 1.22,
      UnitRole.siege => 1.7,
      UnitRole.infantry => 1.0,
    };
    final ability = attacker.archetype?.ability ?? EnemyAbility.none;
    attacker.abilityCounter++;
    final abilityInterval = switch (ability) {
      EnemyAbility.riposte => .68,
      EnemyAbility.bloodNova => .86,
      _ => 1.0,
    };
    attacker.attackClock = interval * (commandBuff ? .82 : 1) * abilityInterval;
    var damage =
        UnitRoleRules.damage(attacker.role) +
        (attacker.archetype?.damageBonus ?? 0) +
        (attacker.ally ? 0 : _enemyDamageBonus) +
        (attacker.elite ? 1 : 0) +
        (commandBuff && attacker.role != UnitRole.commander ? 1 : 0);
    if (ability == EnemyAbility.charge && attacker.abilityCounter == 1) {
      damage += 3;
    }
    if (ability == EnemyAbility.volley && attacker.abilityCounter % 3 == 0) {
      damage += 2;
    }
    _damageBattleUnit(attacker, target, damage);
    if (ability == EnemyAbility.hex && !target.dead) {
      target.status = StatusEffectType.slow;
      target.statusClock = 1.8;
    }
    if (attacker.role == UnitRole.mage || ability == EnemyAbility.bloodNova) {
      var splashes = 0;
      for (final candidate in _units) {
        if (candidate.dead ||
            candidate.ally != target.ally ||
            identical(candidate, target) ||
            candidate.position.distanceTo(target.position) > 34) {
          continue;
        }
        _damageBattleUnit(
          attacker,
          candidate,
          ability == EnemyAbility.bloodNova ? 2 : 1,
          showFx: false,
        );
        if (++splashes >= (ability == EnemyAbility.bloodNova ? 4 : 2)) break;
      }
    }
  }

  void _attackPlayer(BattleUnit attacker) {
    final interval = switch (attacker.role) {
      UnitRole.cavalry => 1.15,
      UnitRole.commander => .95,
      UnitRole.mage || UnitRole.archer => 1.35,
      _ => 1.05,
    };
    attacker.attackClock = interval;
    if (_playerInvulnerability > 0) return;
    final damage = BattleControlRules.contactDamage(
      attacker.role,
      elite: attacker.archetype?.rank == EnemyRank.elite,
      boss: attacker.archetype?.rank == EnemyRank.boss,
      battlefieldBonus: _enemyDamageBonus,
    );
    _damagePlayer(
      damage,
      invulnerabilitySeconds: BattleControlRules.contactRecoverySeconds,
    );
  }

  void _moveRetreatingUnit(BattleUnit unit, double dt) {
    final destination = unit.ally
        ? config.battlefield == BattlefieldType.evacuation
              ? Vector2(size.x - 45, unit.position.y)
              : Vector2(_gatePosition.x + 45, _gatePosition.y)
        : Vector2(size.x + 55, unit.position.y);
    _moveToward(unit, destination, dt, speedMultiplier: 1.22);
  }

  void _moveInFormation(BattleUnit unit, double dt) {
    final commander = unit.ally ? _allyCommander : _enemyCommander;
    if (unit.role == UnitRole.commander) {
      unit.stance = UnitStance.support;
      final anchor = Vector2(
        config.battlefield == BattlefieldType.evacuation
            ? (unit.ally ? size.x * .42 : size.x * .7)
            : (unit.ally ? _defenseLineX - 48 : _defenseLineX + 190),
        size.y / 2,
      );
      _moveToward(unit, anchor, dt, stopDistance: 18);
      return;
    }
    if (commander != null && !commander.dead) {
      final lane = unit.squadId % 11;
      final rank = (unit.squadId ~/ 11) % 9;
      final target =
          commander.position +
          Vector2(
            unit.ally ? 42 + rank * 18 : -42 - rank * 18,
            (lane - 5) * 27 + (rank.isOdd ? 7 : -7),
          );
      unit.stance = unit.position.distanceTo(target) > 95
          ? UnitStance.support
          : UnitStance.advance;
      _moveToward(unit, target, dt, stopDistance: 20);
      return;
    }
    final fallback = Vector2(
      config.battlefield == BattlefieldType.evacuation
          ? (unit.ally ? size.x * .48 : size.x * .68)
          : (unit.ally ? _defenseLineX - 10 : _defenseLineX + 90),
      unit.position.y,
    );
    _moveToward(unit, fallback, dt, stopDistance: 24);
  }

  void _moveToward(
    BattleUnit unit,
    Vector2 target,
    double dt, {
    double stopDistance = 0,
    double speedMultiplier = 1,
  }) {
    final delta = target - unit.position;
    if (delta.length <= stopDistance) return;
    _moveAlong(unit, delta, dt, speedMultiplier: speedMultiplier);
  }

  void _moveAlong(
    BattleUnit unit,
    Vector2 delta,
    double dt, {
    double speedMultiplier = 1,
  }) {
    if (delta.length <= .1) return;
    final commander = unit.ally ? _allyCommander : _enemyCommander;
    final commandSpeed =
        commander != null &&
            !commander.dead &&
            commander.position.distanceTo(unit.position) <= 180
        ? 1.12
        : 1.0;
    final statusSpeed = unit.status == StatusEffectType.slow ? .62 : 1.0;
    final archetypeSpeed = unit.archetype?.speedMultiplier ?? 1.0;
    final bossCommandSpeed =
        commander?.archetype?.ability == EnemyAbility.commandSiege &&
            unit.role == UnitRole.siege
        ? 1.18
        : commander?.archetype?.ability == EnemyAbility.huntMark &&
              unit.objectiveAggro
        ? 1.15
        : 1.0;
    unit.position +=
        delta.normalized() *
        UnitRoleRules.speed(unit.role) *
        speedMultiplier *
        archetypeSpeed *
        _enemySpeedMultiplierFor(unit) *
        bossCommandSpeed *
        commandSpeed *
        statusSpeed *
        dt;
  }

  double _enemySpeedMultiplierFor(BattleUnit unit) =>
      unit.ally ? 1 : _enemySpeedMultiplier;
}
