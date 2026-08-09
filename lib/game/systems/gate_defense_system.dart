part of '../survivor_game.dart';

extension GateDefenseSystem on SurvivorGame {
  void _spawnBattleLines() {
    for (var i = 0; i < 330; i++) {
      final ally = i % 3 == 0;
      final elite = !ally && i % 83 == 0;
      final objectiveAggro = !ally && _random.nextDouble() < .6;
      final position = ally
          ? Vector2(
              _defenseLineX - 80 + _random.nextDouble() * 250,
              30 + _random.nextDouble() * math.max(80, size.y - 60),
            )
          : Vector2(
              size.x * .48 + _random.nextDouble() * size.x * .72,
              20 + _random.nextDouble() * math.max(80, size.y - 40),
            );
      _units.add(
        BattleUnit(
          position: position,
          ally: ally,
          elite: elite,
          hp: elite ? 14 : (objectiveAggro ? 8 : 2),
          playerAggro: !ally && i % 5 == 0,
          objectiveAggro: objectiveAggro,
        ),
      );
    }
  }

  bool _updateSiegeUnit(BattleUnit unit, double dt) {
    final delta = _gatePosition - unit.position;
    final distance = delta.length;
    if (distance > 34) {
      unit.position +=
          (delta / math.max(distance, 1)) * (unit.elite ? 48 : 42) * dt;
      return true;
    }
    if (unit.attackClock <= 0) {
      unit.attackClock = unit.elite ? .72 : 1.05;
      _gateHp = math.max(0, _gateHp - (unit.elite ? 12 : 4));
      _slashes.add(SlashFx(_gatePosition.clone(), .2, CombatStyle.greatsword));
    }
    return true;
  }

  void _updateFrontPressure() {
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
    final gateRatio = (_gateHp / GateDefenseRules.maxGateHp).clamp(0.0, 1.0);
    final bonuses = outcome == BattleOutcome.victory
        ? GateDefenseRules.completedBonuses(
            gateHpRatio: gateRatio,
            frontPressure: _frontPressure,
            elitesCleared: !_units.any(
              (unit) => !unit.dead && !unit.ally && unit.elite,
            ),
          )
        : const <String>[];
    final rewardRate = outcome == BattleOutcome.victory ? 1.0 : .35;
    onVictory(
      BattleReport(
        time:
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
        kills: _kills,
        alliedKills: _alliedKills,
        gold: ((3240 + _kills * 8 + bonuses.length * 300) * rewardRate).round(),
        xp: ((1200 + _kills * 3) * rewardRate).round(),
        outcome: outcome,
        objectiveHpRatio: gateRatio,
        completedBonusIds: bonuses,
      ),
    );
  }

  void _drawBattlefieldObjective(Canvas canvas) {
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
