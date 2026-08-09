part of '../survivor_game.dart';

extension GateDefenseSystem on SurvivorGame {
  void _spawnBattleLines() {
    var allyIndex = 0;
    var enemyIndex = 0;
    for (var i = 0; i < config.unitCount; i++) {
      final ally = i % 3 == 0;
      final factionIndex = ally ? allyIndex++ : enemyIndex++;
      final archetype = ally ? null : _enemyForIndex(factionIndex);
      final role = archetype?.role ?? _roleForFactionIndex(factionIndex);
      final elite = archetype?.rank == EnemyRank.elite;
      final objectiveAggro =
          !ally &&
          role != UnitRole.commander &&
          (archetype?.ability == EnemyAbility.breach ||
              archetype?.ability == EnemyAbility.blast ||
              _random.nextDouble() <
                  (config.battlefield == BattlefieldType.evacuation
                      ? .28
                      : .4));
      final maxHp =
          UnitRoleRules.maxHp(role) +
          (archetype?.hpBonus ?? 0) +
          (objectiveAggro ? 4 : 0);
      final defaultPosition = config.battlefield == BattlefieldType.evacuation
          ? Vector2(
              ally
                  ? size.x * .2 + _random.nextDouble() * size.x * .3
                  : size.x * .48 + _random.nextDouble() * size.x * .55,
              24 + _random.nextDouble() * math.max(80, size.y - 48),
            )
          : !ally && role == UnitRole.siege
          ? Vector2(
              size.x * .42 + _random.nextDouble() * size.x * .24,
              40 + _random.nextDouble() * math.max(80, size.y - 80),
            )
          : ally
          ? Vector2(
              _defenseLineX - 80 + _random.nextDouble() * 250,
              30 + _random.nextDouble() * math.max(80, size.y - 60),
            )
          : Vector2(
              size.x * .48 + _random.nextDouble() * size.x * .72,
              20 + _random.nextDouble() * math.max(80, size.y - 40),
            );
      final unit = BattleUnit(
        position: role == UnitRole.commander
            ? Vector2(ally ? _defenseLineX - 55 : size.x - 125, size.y / 2)
            : defaultPosition,
        ally: ally,
        elite: elite,
        hp: maxHp,
        maxHp: maxHp,
        playerAggro:
            !ally &&
            (archetype?.ability == EnemyAbility.charge ||
                archetype?.ability == EnemyAbility.flank ||
                i % 7 == 0),
        objectiveAggro: objectiveAggro,
        role: role,
        stance: role == UnitRole.commander
            ? UnitStance.support
            : UnitStance.advance,
        squadId: factionIndex ~/ 8,
        archetype: archetype,
      );
      _units.add(unit);
      if (role == UnitRole.commander) {
        if (ally) {
          _allyCommander = unit;
        } else {
          _enemyCommander = unit;
        }
      }
    }
    _peakActiveUnits = math.max(_peakActiveUnits, _units.length);
  }

  EnemyArchetypeSpec _enemyForIndex(int index) {
    if (index == 0) {
      return EnemyCatalog.byId(
        config.battlefield == BattlefieldType.evacuation
            ? 'hunt_captain'
            : 'siege_marshal',
      );
    }
    if (index % 83 == 0) {
      return EnemyCatalog.elite[(index ~/ 83) % EnemyCatalog.elite.length];
    }
    return EnemyCatalog.common[(index - 1) % EnemyCatalog.common.length];
  }

  UnitRole _roleForFactionIndex(int index) {
    if (index == 0) return UnitRole.commander;
    const formation = [
      UnitRole.infantry,
      UnitRole.shield,
      UnitRole.archer,
      UnitRole.infantry,
      UnitRole.cavalry,
      UnitRole.mage,
      UnitRole.infantry,
      UnitRole.shield,
      UnitRole.infantry,
      UnitRole.archer,
      UnitRole.infantry,
      UnitRole.cavalry,
      UnitRole.mage,
      UnitRole.infantry,
      UnitRole.shield,
      UnitRole.siege,
    ];
    return formation[(index - 1) % formation.length];
  }

  bool _updateSiegeUnit(BattleUnit unit, double dt) {
    final delta = _gatePosition - unit.position;
    final distance = delta.length;
    final attackRange = UnitRoleRules.attackRange(unit.role);
    if (distance > attackRange) {
      final objectiveSpeed =
          UnitRoleRules.speed(unit.role) *
          (unit.archetype?.speedMultiplier ?? 1) *
          (unit.role == UnitRole.siege ? 1.8 : 1.45);
      unit.position += (delta / math.max(distance, 1)) * objectiveSpeed * dt;
      return true;
    }
    if (unit.attackClock <= 0) {
      unit.attackClock = unit.role == UnitRole.siege ? 1.65 : 1.05;
      _gateHp = math.max(
        0,
        _gateHp -
            UnitRoleRules.damage(unit.role) -
            (unit.archetype?.damageBonus ?? 0) -
            (unit.archetype?.ability == EnemyAbility.blast ? 5 : 0),
      );
      _emitSlash(_gatePosition, .2, CombatStyle.greatsword);
    }
    return true;
  }

  void _updateFrontPressure() {
    if (config.battlefield == BattlefieldType.evacuation) {
      final livingEscorts = _escorts.where(
        (escort) => !escort.dead && !escort.escaped,
      );
      if (livingEscorts.isEmpty) {
        _frontPressure = 0;
        return;
      }
      var threatened = 0;
      for (final escort in livingEscorts) {
        if (_units.any(
          (unit) =>
              !unit.dead &&
              !unit.ally &&
              unit.position.distanceTo(escort.position) < 105,
        )) {
          threatened++;
        }
      }
      _frontPressure = (threatened / livingEscorts.length).clamp(0, 1);
      return;
    }
    final livingEnemies = _units.where((unit) => !unit.dead && !unit.ally);
    final breached = livingEnemies.where(
      (unit) => unit.position.x < _defenseLineX,
    );
    _frontPressure = (breached.length / 55).clamp(0, 1);
  }

  void _finishBattle(BattleOutcome outcome) {
    if (_finished) return;
    _finished = true;
    final elapsedSeconds = _elapsed.floor().clamp(0, config.durationSeconds);
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    final evacuation = config.battlefield == BattlefieldType.evacuation;
    final objectiveRatio = evacuation
        ? (_escortEscaped / math.max(1, _escorts.length)).clamp(0.0, 1.0)
        : (_gateHp / GateDefenseRules.maxGateHp).clamp(0.0, 1.0);
    final bonuses = outcome != BattleOutcome.victory
        ? const <String>[]
        : evacuation
        ? EvacuationRules.completedBonuses(
            escaped: _escortEscaped,
            total: _escorts.length,
            enemyCommanderDefeated: _enemyCommander?.dead == true,
            secondsLeft: (config.durationSeconds - _elapsed).ceil(),
          )
        : GateDefenseRules.completedBonuses(
            gateHpRatio: objectiveRatio,
            frontPressure: _frontPressure,
            elitesCleared: !_units.any(
              (unit) => !unit.dead && !unit.ally && unit.elite,
            ),
          );
    final rewardRate = outcome == BattleOutcome.victory ? 1.0 : .35;
    onVictory(
      BattleReport(
        time:
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
        kills: _kills,
        alliedKills: _alliedKills,
        gold:
            (((evacuation ? 4500 : 3240) + _kills * 8 + bonuses.length * 300) *
                    rewardRate)
                .round(),
        xp: (((evacuation ? 1450 : 1200) + _kills * 3) * rewardRate).round(),
        outcome: outcome,
        objectiveHpRatio: objectiveRatio,
        completedBonusIds: bonuses,
        commanderSurvived: _allyCommander?.dead != true,
        enemyCommanderDefeated: _enemyCommander?.dead == true,
        battlefield: config.battlefield,
        escortEscaped: _escortEscaped,
        escortTotal: _escorts.length,
        peakActiveUnits: _peakActiveUnits,
        frameTimeP95Ms: _frameTimeP95Ms,
        rareDropIds: List.unmodifiable(_rareDrops),
      ),
    );
  }

  void _drawBattlefieldObjective(Canvas canvas) {
    if (config.battlefield == BattlefieldType.evacuation) {
      _drawEvacuationObjective(canvas);
      return;
    }
    final defensePaint = Paint()..color = const Color(0x182a6a8d);
    final attackPaint = Paint()..color = const Color(0x126e2f2d);
    canvas.drawRect(Rect.fromLTRB(0, 0, _defenseLineX, size.y), defensePaint);
    canvas.drawRect(
      Rect.fromLTRB(_defenseLineX, 0, size.x, size.y),
      attackPaint,
    );

    final linePaint = Paint()
      ..color = const Color(0x88d1ae64)
      ..strokeWidth = 2;
    for (double y = 0; y < size.y; y += 22) {
      canvas.drawLine(
        Offset(_defenseLineX, y),
        Offset(_defenseLineX, math.min(y + 12, size.y)),
        linePaint,
      );
    }

    final wall = Paint()..color = const Color(0xff5d5b52);
    final darkStone = Paint()..color = const Color(0xff343630);
    final timber = Paint()..color = const Color(0xff49372a);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(_gatePosition.x - 23, _gatePosition.y),
        width: 34,
        height: 196,
      ),
      wall,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(_gatePosition.x + 25, _gatePosition.y),
        width: 44,
        height: 112,
      ),
      timber,
    );
    for (var i = -2; i <= 2; i++) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(_gatePosition.x + 25 + i * 8, _gatePosition.y),
          width: 3,
          height: 108,
        ),
        darkStone,
      );
    }
    final hpRatio = (_gateHp / GateDefenseRules.maxGateHp).clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTWH(_gatePosition.x - 38, _gatePosition.y - 118, 96, 8),
      Paint()..color = const Color(0xaa050608),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        _gatePosition.x - 36,
        _gatePosition.y - 116,
        92 * hpRatio,
        4,
      ),
      Paint()
        ..color = hpRatio > .35
            ? const Color(0xff60b875)
            : const Color(0xffd2554e),
    );
    canvas.drawCircle(
      Offset(_gatePosition.x + 3, _gatePosition.y - 136),
      13 + math.sin(_elapsed * 4) * 2,
      Paint()
        ..color = const Color(0x99e2bc69)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    _drawSpawnMarker(
      canvas,
      Offset(_defenseLineX - 32, 34),
      const Color(0xff6e9ec1),
    );
    _drawSpawnMarker(canvas, Offset(size.x - 42, 34), const Color(0xffad514b));
  }

  void _drawSpawnMarker(Canvas canvas, Offset position, Color color) {
    canvas.drawLine(
      position,
      position.translate(0, 32),
      Paint()
        ..color = const Color(0xff20231f)
        ..strokeWidth = 3,
    );
    final flag = Path()
      ..moveTo(position.dx, position.dy)
      ..lineTo(position.dx + 26, position.dy + 8)
      ..lineTo(position.dx, position.dy + 17)
      ..close();
    canvas.drawPath(flag, Paint()..color = color);
  }
}
