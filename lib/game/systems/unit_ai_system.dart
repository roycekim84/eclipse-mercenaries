part of '../survivor_game.dart';

extension UnitAiSystem on SurvivorGame {
  void _updateRoleUnit(BattleUnit unit, double dt) {
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
      _updateSiegeUnit(unit, dt);
      return;
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
    attacker.attackClock = interval * (commandBuff ? .82 : 1);
    final damage =
        UnitRoleRules.damage(attacker.role) +
        (attacker.elite ? 1 : 0) +
        (commandBuff && attacker.role != UnitRole.commander ? 1 : 0);
    _damageBattleUnit(attacker, target, damage);
    if (attacker.role == UnitRole.mage) {
      var splashes = 0;
      for (final candidate in _units) {
        if (candidate.dead ||
            candidate.ally != target.ally ||
            identical(candidate, target) ||
            candidate.position.distanceTo(target.position) > 34) {
          continue;
        }
        _damageBattleUnit(attacker, candidate, 1, showFx: false);
        if (++splashes >= 2) break;
      }
    }
  }

  void _moveRetreatingUnit(BattleUnit unit, double dt) {
    final destination = unit.ally
        ? Vector2(_gatePosition.x + 45, _gatePosition.y)
        : Vector2(size.x + 55, unit.position.y);
    _moveToward(unit, destination, dt, speedMultiplier: 1.22);
  }

  void _moveInFormation(BattleUnit unit, double dt) {
    final commander = unit.ally ? _allyCommander : _enemyCommander;
    if (unit.role == UnitRole.commander) {
      unit.stance = UnitStance.support;
      final anchor = Vector2(
        unit.ally ? _defenseLineX - 48 : _defenseLineX + 190,
        size.y / 2,
      );
      _moveToward(unit, anchor, dt, stopDistance: 18);
      return;
    }
    if (commander != null && !commander.dead) {
      final column = unit.squadId % 4;
      final row = (unit.squadId ~/ 4) % 5;
      final target =
          commander.position +
          Vector2(
            unit.ally ? 45 + column * 24 : -45 - column * 24,
            (row - 2) * 38,
          );
      unit.stance = unit.position.distanceTo(target) > 95
          ? UnitStance.support
          : UnitStance.advance;
      _moveToward(unit, target, dt, stopDistance: 20);
      return;
    }
    final fallback = Vector2(
      unit.ally ? _defenseLineX - 10 : _defenseLineX + 90,
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
    unit.position +=
        delta.normalized() *
        UnitRoleRules.speed(unit.role) *
        speedMultiplier *
        commandSpeed *
        statusSpeed *
        dt;
  }
}
