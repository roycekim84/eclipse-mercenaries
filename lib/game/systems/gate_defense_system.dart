part of '../survivor_game.dart';

extension GateDefenseSystem on SurvivorGame {
  void _spawnBattleLines() {
    // A battle should form a front, not dump the full simulation budget on the
    // first frame. The remaining budget is introduced by staged reinforcements.
    final initialDeployment = math.min(
      config.unitCount,
      config.balance.initialDeployment,
    );
    var allyIndex = 0;
    var enemyIndex = 0;
    var initialEnemySiege = 0;
    for (var i = 0; i < initialDeployment; i++) {
      // 첫 55초는 루나 혼자 약한 선발대를 상대한다. 일반 계약의
      // 전선 배치는 유지하고 인트로만 증원 연출 전까지 아군을 비운다.
      final ally = config.isIntroBattle ? false : i % 5 < 2;
      final factionIndex = ally ? allyIndex++ : enemyIndex++;
      final archetype = ally
          ? null
          : config.isIntroBattle && factionIndex == 0
          ? EnemyCatalog.byId('vargar_conscript')
          : _enemyForIndex(factionIndex);
      var role = archetype?.role ?? _roleForFactionIndex(factionIndex);
      if (!ally && role == UnitRole.siege) {
        if (initialEnemySiege >= 4) {
          role = UnitRole.infantry;
        } else {
          initialEnemySiege++;
        }
      }
      final elite = archetype?.rank == EnemyRank.elite;
      final objectiveAggro =
          !ally &&
          (config.battlefield.usesGate || config.battlefield.isConvoy) &&
          role != UnitRole.commander &&
          (archetype?.ability == EnemyAbility.breach ||
              archetype?.ability == EnemyAbility.blast ||
              _random.nextDouble() < (config.battlefield.isConvoy ? .28 : .4));
      final rawMaxHp =
          UnitRoleRules.maxHp(role) +
          (archetype?.hpBonus ?? 0) +
          (objectiveAggro ? 4 : 0);
      final maxHp = ally
          ? rawMaxHp
          : math.max(1, (rawMaxHp * config.balance.enemyHpMultiplier).round());
      final lane = factionIndex % 5;
      final rank = (factionIndex ~/ 5) % 8;
      final usableHeight = _combatBottom - _combatTop;
      final laneY = _safeCombatY(
        _combatTop +
            usableHeight * ((lane + 1) / 6) +
            (_random.nextDouble() - .5) * 18,
      );
      final frontX = size.x * .50;
      final defaultPosition = config.battlefield.isConvoy
          ? Vector2(
              ally
                  ? size.x * .24 + rank * 14 + _random.nextDouble() * 10
                  : size.x * .68 + rank * 14 + _random.nextDouble() * 10,
              laneY,
            )
          : !ally && role == UnitRole.siege
          ? Vector2(frontX + 112 + rank * 12 + _random.nextDouble() * 8, laneY)
          : ally
          ? Vector2(frontX - 78 - rank * 12 - _random.nextDouble() * 8, laneY)
          : Vector2(frontX + 78 + rank * 12 + _random.nextDouble() * 8, laneY);
      final unit = BattleUnit(
        position: role == UnitRole.commander
            ? Vector2(ally ? frontX - 128 : frontX + 128, size.y / 2)
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
        squadId: factionIndex,
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

  void _maintainBattlePopulation(double dt) {
    _reinforcementClock -= dt;
    if (_reinforcementClock > 0 || _finished) return;
    _reinforcementClock = config.balance.reinforcementInterval;
    final secondsLeft = config.durationSeconds - _elapsed;
    if (secondsLeft <= 7) return;
    final livingEnemies = _units
        .where((unit) => !unit.dead && !unit.ally)
        .length;
    final livingAllies = _units.where((unit) => !unit.dead && unit.ally).length;
    final progress = (_elapsed / config.durationSeconds).clamp(0.0, 1.0);
    final initialDeployment = math.min(
      config.unitCount,
      config.balance.initialDeployment,
    );
    final activePopulationTarget = math.min(
      config.unitCount,
      config.balance.activePopulationTarget,
    );
    final stagedPopulation =
        initialDeployment +
        ((activePopulationTarget - initialDeployment) * progress).round();
    final enemyFloor = config.isIntroBattle
        ? math.max(10, (stagedPopulation * .58).round())
        : math.max(34, (stagedPopulation * .60).round());
    final allyFloor = config.isIntroBattle && !_introAlliesArrived
        ? 0
        : math.max(22, (stagedPopulation * .40).round());
    if (livingEnemies < enemyFloor) {
      final archetype = EnemyCatalog
          .common[(_elapsed ~/ 5).toInt() % EnemyCatalog.common.length];
      _spawnEventWave(
        count: math.min(24, enemyFloor - livingEnemies + 5),
        archetypeId: archetype.id,
      );
    }
    if (livingAllies < allyFloor) {
      _spawnEventWave(
        count: math.min(14, allyFloor - livingAllies + 3),
        ally: true,
      );
    }
  }

  EnemyArchetypeSpec _enemyForIndex(int index) {
    if (index == 0) {
      return EnemyCatalog.byId(switch (config.condition) {
        BattlefieldCondition.ashWind => 'hunt_captain',
        BattlefieldCondition.blackForest => 'forest_warlord',
        BattlefieldCondition.whiteNight => 'frost_castellan',
        BattlefieldCondition.twilightSiege => 'dusk_general',
        BattlefieldCondition.moonlitNight => 'siege_marshal',
      });
    }
    if (index % config.balance.eliteStride == 0) {
      return EnemyCatalog.elite[(index ~/ config.balance.eliteStride) %
          EnemyCatalog.elite.length];
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
            _enemyDamageBonus -
            (unit.archetype?.ability == EnemyAbility.blast ? 5 : 0),
      );
      _emitSlash(_gatePosition, .2, CombatStyle.greatsword);
    }
    return true;
  }

  void _updateFrontPressure() {
    if (config.battlefield.isConvoy) {
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
    final evacuation = config.battlefield.isConvoy;
    final objectiveRatio = switch (config.objective) {
      ContractObjective.evacuation || ContractObjective.supplyEscort =>
        (_escortEscaped / math.max(1, _escorts.length)).clamp(0.0, 1.0),
      ContractObjective.assassination =>
        _enemyCommander?.dead == true ? 1.0 : 0.0,
      ContractObjective.ambush => (_kills / 120).clamp(0.0, 1.0),
      ContractObjective.fortressRetake =>
        math
            .min(_kills / 80, _enemyCommander?.dead == true ? 1.0 : .5)
            .clamp(0.0, 1.0),
      ContractObjective.defense => (_gateHp / GateDefenseRules.maxGateHp).clamp(
        0.0,
        1.0,
      ),
    };
    final bonuses = outcome != BattleOutcome.victory
        ? const <String>[]
        : evacuation
        ? EvacuationRules.completedBonuses(
            escaped: _escortEscaped,
            total: _escorts.length,
            enemyCommanderDefeated: _enemyCommander?.dead == true,
            secondsLeft: (config.durationSeconds - _elapsed).ceil(),
          )
        : config.battlefield.usesGate
        ? GateDefenseRules.completedBonuses(
            gateHpRatio: objectiveRatio,
            frontPressure: _frontPressure,
            elitesCleared: !_units.any(
              (unit) => !unit.dead && !unit.ally && unit.elite,
            ),
          )
        : <String>[
            if (_enemyCommander?.dead == true) 'commander_eliminated',
            if (_kills >= 80) 'field_dominance',
            if (!_units.any((unit) => !unit.dead && !unit.ally && unit.elite))
              'elite_clear',
          ];
    final rewardRate = BattleRewardRules.preservationRate(outcome.name);
    final reward = BattleRewardRules.calculate(
      contractGold: config.contractGold,
      contractXp: config.contractXp,
      kills: _kills,
      completedObjectives: bonuses.length,
      eventGold: _eventGoldBonus,
      eventXp: _eventXpBonus,
      eventMultiplier: _eventRewardMultiplier,
      preservationRate: rewardRate,
    );
    final award = BattleRewardRules.award(
      kills: _kills,
      alliedKills: _alliedKills,
      objectiveRatio: objectiveRatio,
      evacuation: evacuation,
      commanderSurvived: _allyCommander?.dead != true,
      enemyCommanderDefeated: _enemyCommander?.dead == true,
      ultimateActivations: _ultimateActivation,
      completedObjectives: bonuses.length,
      eventCount: _eventRecords.length,
    );
    final lootDrops = BattleLootRules.resolve(
      seed: config.seed,
      completedObjectives: bonuses.length,
      eventCount: _eventRecords.length,
      rareDropIds: _rareDrops,
      eventChoiceIds: _eventRecords.map((record) => record.choiceId).toList(),
      preservationRate: rewardRate,
    );
    onVictory(
      BattleReport(
        time:
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
        kills: _kills,
        alliedKills: _alliedKills,
        gold: reward.keptGold,
        xp: reward.keptXp,
        contractName: config.contractName,
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
        performance: _performanceProfiler.snapshot(
          spatialBuckets: _spatialGrid.allocatedBucketCount,
        ),
        rareDropIds: List.unmodifiable(_rareDrops),
        triggeredEventIds: List.unmodifiable(_triggeredEventIds),
        eventRecords: List.unmodifiable(_eventRecords),
        rewardBreakdown: reward,
        lootDrops: List.unmodifiable(lootDrops),
        award: award,
        ultimateActivations: _ultimateActivation,
        isIntroBattle: config.isIntroBattle,
        funMetrics: config.isIntroBattle
            ? FunPrototypeMetrics(
                firstLevelUpSeconds: _firstLevelUpAt,
                firstUltimateReadySeconds: _firstUltimateReadyAt,
                firstUltimateUsedSeconds: _firstUltimateUsedAt,
                deathSeconds: outcome == BattleOutcome.defeat ? _elapsed : null,
                bossDefeatedSeconds: _bossDefeatedAt,
                completionSeconds: _elapsed,
                selectedGrowthIds: List.unmodifiable(_funGrowthChoices),
              )
            : null,
      ),
    );
  }

  void _drawBattlefieldObjective(Canvas canvas) {
    if (config.battlefield.isConvoy) {
      _drawEvacuationObjective(canvas);
      return;
    }
    if (config.battlefield.isOpenField) {
      final target =
          _enemyCommander?.position ?? Vector2(size.x * .74, size.y / 2);
      final atlasCellWidth = _vfxAtlas.width / 4;
      final atlasCellHeight = _vfxAtlas.height / 4;
      final index = switch (config.objective) {
        ContractObjective.assassination => 7,
        ContractObjective.ambush => 14,
        ContractObjective.fortressRetake => 15,
        _ => 10,
      };
      canvas.drawImageRect(
        _vfxAtlas,
        Rect.fromLTWH(
          (index % 4) * atlasCellWidth,
          (index ~/ 4) * atlasCellHeight,
          atlasCellWidth,
          atlasCellHeight,
        ),
        Rect.fromCenter(
          center: Offset(target.x, target.y + 18),
          width: config.objective == ContractObjective.fortressRetake ? 96 : 68,
          height: config.objective == ContractObjective.fortressRetake
              ? 96
              : 68,
        ),
        Paint()
          ..filterQuality = FilterQuality.none
          ..color = const Color(0x99ffffff)
          ..blendMode = BlendMode.screen,
      );
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

    final damageStage = GateDefenseRules.damageStage(_gateHp);
    canvas.drawCircle(
      Offset(_gatePosition.x + 3, _gatePosition.y - 136),
      13 + math.sin(_elapsed * 4) * 2,
      Paint()
        ..color = const Color(0x99e2bc69)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    if (damageStage != ObjectiveDamageStage.secure) {
      final crackPaint = Paint()
        ..color = damageStage == ObjectiveDamageStage.critical
            ? const Color(0xfff28a62)
            : const Color(0xffa88b70)
        ..strokeWidth = damageStage == ObjectiveDamageStage.critical ? 3 : 2
        ..style = PaintingStyle.stroke;
      final crack = Path()
        ..moveTo(_gatePosition.x - 8, _gatePosition.y - 90)
        ..lineTo(_gatePosition.x + 4, _gatePosition.y - 62)
        ..lineTo(_gatePosition.x - 3, _gatePosition.y - 34)
        ..lineTo(_gatePosition.x + 13, _gatePosition.y - 8);
      canvas.drawPath(crack, crackPaint);
      if (damageStage == ObjectiveDamageStage.critical) {
        for (var i = 0; i < (_reducedVisualLoad ? 2 : 5); i++) {
          final phase = _elapsed * (1.1 + i * .13) + i * 1.7;
          final smoke = Offset(
            _gatePosition.x - 12 + math.sin(phase) * (7 + i * 2),
            _gatePosition.y - 62 - (phase * 13) % 72,
          );
          canvas.drawCircle(
            smoke,
            7 + i * 1.4,
            Paint()..color = const Color(0x665a4b48),
          );
        }
      }
    }

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
