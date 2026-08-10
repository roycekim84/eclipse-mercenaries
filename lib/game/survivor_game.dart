import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Offset, ValueNotifier;

import '../domain/battle_models.dart';
import '../domain/battle_performance.dart';
import '../domain/battlefield_events.dart';
import '../domain/battle_rewards.dart';
import '../domain/combat_rules.dart';
import '../domain/enemy_catalog.dart';
import '../domain/game_data.dart';
import '../domain/progression.dart';
import '../domain/run_growth.dart';
import '../domain/reusable_spatial_grid.dart';
import '../core/content/game_visuals.dart';
import 'render/player_sprite_component.dart';

part 'systems/ultimate_system.dart';
part 'systems/gate_defense_system.dart';
part 'systems/evacuation_system.dart';
part 'systems/battlefield_event_system.dart';
part 'systems/unit_ai_system.dart';
part 'systems/damage_system.dart';
part 'systems/weapon_system.dart';
part 'systems/pooled_effects_system.dart';
part 'systems/run_growth_system.dart';

double _permanentPlayerMaxHp(BattleConfig config) {
  final level = config.mercenaryPermanentLevel ?? config.mercenary.level;
  return config.mercenary.maxHp *
      ProgressionRules.mercenaryHpMultiplier(config.mercenary.level, level);
}

class SurvivorGame extends FlameGame {
  SurvivorGame({required this.config, required this.onVictory})
    : _random = math.Random(config.seed),
      _upgradeRandom = math.Random(config.seed ^ 0x5f3759df),
      _eventRandom = math.Random(config.seed ^ 0x6c8e9cf5) {
    stats = ValueNotifier(
      BattleStats(
        hp: _permanentPlayerMaxHp(config),
        level: 1,
        xp: 0,
        nextXp: 40,
        kills: 0,
        secondsLeft: config.durationSeconds,
        weaponLevel: 1,
        ultimateCharge: 0,
        ultimateEnabled: config.weapon.id == config.mercenary.signatureWeaponId,
        gateHp: GateDefenseRules.maxGateHp,
        gateMaxHp: GateDefenseRules.maxGateHp,
        frontPressure: 0,
        allyCommanderAlive: true,
        enemyCommanderAlive: true,
        build: [
          RunBuildEntry(
            id: config.weapon.id,
            kind: RunUpgradeKind.weapon,
            level: 1,
            maxLevel: 5,
          ),
        ],
      ),
    );
  }
  final BattleConfig config;
  MercenarySpec get mercenary => config.mercenary;
  WeaponSpec get weapon => config.weapon;
  double get _permanentDamageMultiplier =>
      ProgressionRules.combatDamageMultiplier(
        baseMercenaryLevel: mercenary.level,
        permanentMercenaryLevel:
            config.mercenaryPermanentLevel ?? mercenary.level,
        weaponLevel: config.weaponPermanentLevel,
        weaponStage: config.weaponGrowthStage,
      );
  double get _playerMaxHp => _permanentPlayerMaxHp(config);
  final void Function(BattleReport) onVictory;
  late final ValueNotifier<BattleStats> stats;
  final choice = ValueNotifier<BattleChoice?>(null);
  final event = ValueNotifier<BattleEvent?>(null);
  final eventPrompt = ValueNotifier<BattlefieldEventSpec?>(null);
  final ultimate = ValueNotifier<UltimateSequence?>(null);
  final reducedEffects = ValueNotifier(false);
  final combatPaused = ValueNotifier(false);
  final math.Random _random;
  final math.Random _upgradeRandom;
  final math.Random _eventRandom;
  final _units = <BattleUnit>[];
  final _slashes = List.generate(96, (_) => SlashFx.pooled());
  final _projectiles = List.generate(64, (_) => PooledProjectile());
  final _damageNumbers = List.generate(36, (_) => DamageNumberFx());
  final _runWeapons = <RunWeaponState>[];
  final _passiveLevels = <String, int>{};
  final _rareDrops = <String>[];
  final _triggeredEventIds = <String>{};
  final _eventRecords = <BattlefieldEventRecord>[];
  final _escorts = <EscortUnit>[];
  final _frameSamples = List<double>.filled(512, 0);
  final _spatialGrid = ReusableSpatialGrid();
  final _performanceProfiler = BattlePerformanceProfiler();
  final _updateClock = Stopwatch();
  final _renderClock = Stopwatch();
  Vector2? _moveTarget;
  late Vector2 _player;
  late final PlayerSpriteComponent _playerSprite;
  late final Image _unitAtlas;
  BattleUnit? _allyCommander;
  BattleUnit? _enemyCommander;
  late Vector2 _gatePosition;
  late double _defenseLineX;
  double _elapsed = 0;
  double _eventClock = 0;
  double _nextEventAt = 10;
  double _eventRewardMultiplier = 1;
  double _enemySpeedMultiplier = 1;
  int _eventGoldBonus = 0;
  int _eventXpBonus = 0;
  int _enemyDamageBonus = 0;
  double _xp = 0;
  double _nextXp = 40;
  double _ultimateCharge = 0;
  double _ultimateClock = 0;
  bool _ultimateImpactApplied = false;
  int _ultimateActivation = 0;
  double _gateHp = GateDefenseRules.maxGateHp;
  double _frontPressure = 0;
  late double _speed;
  int _level = 1;
  int _kills = 0;
  int _alliedKills = 0;
  int _traitLevel = 0;
  int _frameSampleCount = 0;
  int _frameSampleIndex = 0;
  int _peakActiveUnits = 0;
  bool _finished = false;
  bool _pausedForChoice = false;
  bool _pausedForEvent = false;
  bool _pausedByUser = false;
  bool _pausedByLifecycle = false;

  @override
  Color backgroundColor() => const Color(0xff35362d);

  @override
  Future<void> onLoad() async {
    _player = config.battlefield == BattlefieldType.evacuation
        ? Vector2(size.x * .34, size.y / 2)
        : size / 2;
    _gatePosition = Vector2(78, size.y / 2);
    _defenseLineX = math.max(190, size.x * .28);
    _unitAtlas = await images.load('battlefield/unit_role_atlas.png');
    final playerImage = await images.load(mercenary.visual.battleSpriteAsset);
    _playerSprite = PlayerSpriteComponent.fromImage(playerImage)
      ..position = _player.clone();
    await add(_playerSprite);
    _speed =
        mercenary.speed *
        ProgressionRules.mercenarySpeedMultiplier(
          mercenary.level,
          config.mercenaryPermanentLevel ?? mercenary.level,
        ) *
        (config.condition == BattlefieldCondition.ashWind ? .94 : 1);
    _runWeapons.add(RunWeaponState(weapon));
    stats.value = BattleStats(
      hp: _playerMaxHp,
      level: 1,
      xp: 0,
      nextXp: 40,
      kills: 0,
      secondsLeft: config.durationSeconds,
      weaponLevel: 1,
      ultimateCharge: 0,
      ultimateEnabled: _signatureWeaponActive,
      gateHp: _gateHp,
      gateMaxHp: GateDefenseRules.maxGateHp,
      frontPressure: 0,
      allyCommanderAlive: true,
      enemyCommanderAlive: true,
      build: _currentBuildEntries,
      escortTotal: config.battlefield == BattlefieldType.evacuation
          ? EvacuationRules.totalEscorts
          : 0,
      escortAlive: config.battlefield == BattlefieldType.evacuation
          ? EvacuationRules.totalEscorts
          : 0,
    );
    _spawnBattleLines();
    if (config.battlefield == BattlefieldType.evacuation) {
      _spawnEvacuationConvoy();
    }
  }

  void setMoveTarget(Offset offset) =>
      _moveTarget = Vector2(offset.dx, offset.dy);
  void clearMoveTarget() => _moveTarget = null;

  bool get _signatureWeaponActive => _runWeapons.isEmpty
      ? weapon.id == mercenary.signatureWeaponId
      : _runWeapons.any(
          (state) => state.weapon.id == mercenary.signatureWeaponId,
        );

  void toggleReducedEffects() => reducedEffects.value = !reducedEffects.value;

  void toggleCombatPause() {
    if (_finished ||
        _pausedForChoice ||
        _pausedForEvent ||
        _pausedByLifecycle) {
      return;
    }
    _pausedByUser = !_pausedByUser;
    combatPaused.value = _pausedByUser;
    if (_pausedByUser) {
      pauseEngine();
    } else {
      resumeEngine();
    }
  }

  void pauseForLifecycle() {
    if (_finished) return;
    _pausedByLifecycle = true;
    combatPaused.value = true;
    pauseEngine();
  }

  void resumeFromLifecycle() {
    if (!_pausedByLifecycle) return;
    _pausedByLifecycle = false;
    combatPaused.value = _pausedByUser;
    if (!_pausedByUser && !_pausedForChoice && !_pausedForEvent && !_finished) {
      resumeEngine();
    }
  }

  void triggerUltimate() {
    if (!_signatureWeaponActive ||
        _ultimateCharge < 1 ||
        _ultimateClock > 0 ||
        _finished ||
        _pausedForChoice) {
      return;
    }
    _ultimateCharge = 0;
    _ultimateClock = 2.4;
    _ultimateImpactApplied = false;
    _ultimateActivation++;
    ultimate.value = UltimateSequence(
      mercenaryId: mercenary.id,
      title: mercenary.ultimate,
      activation: _ultimateActivation,
    );
    clearMoveTarget();
    _publishStats();
  }

  @override
  void update(double dt) {
    _recordPerformance(dt);
    _updateClock
      ..reset()
      ..start();
    final worldDt = _ultimateClock > 1.18 ? dt * .08 : dt;
    super.update(worldDt);
    if (_finished || _pausedForChoice || _pausedForEvent) {
      _updateClock.stop();
      return;
    }
    _advanceUltimate(dt);
    _elapsed += worldDt;
    _eventClock += worldDt;
    var isMoving = false;
    if (_moveTarget != null) {
      final delta = _moveTarget! - _player;
      if (delta.length > 8) {
        _player +=
            delta.normalized() * math.min(_speed * worldDt, delta.length);
        isMoving = true;
      }
    }
    _playerSprite
      ..position = _player
      ..setMoving(isMoving);
    if (config.battlefield == BattlefieldType.evacuation) {
      _updateEvacuation(worldDt);
    }
    final aiStartMicros = _updateClock.elapsedMicroseconds;
    _rebuildGrid();
    _updateUnits(worldDt);
    final aiMs = (_updateClock.elapsedMicroseconds - aiStartMicros) / 1000;
    final combatStartMicros = _updateClock.elapsedMicroseconds;
    _updateCombatPools(worldDt);
    final combatMs =
        (_updateClock.elapsedMicroseconds - combatStartMicros) / 1000;
    final weaponsStartMicros = _updateClock.elapsedMicroseconds;
    _updateRunWeapons(worldDt);
    final weaponsMs =
        (_updateClock.elapsedMicroseconds - weaponsStartMicros) / 1000;
    if (_pausedForChoice) {
      _updateClock.stop();
      return;
    }
    _updateBattlefieldEvents();
    _updateFrontPressure();
    _updateClock.stop();
    if (_elapsed >= 2) {
      _performanceProfiler.recordUpdate(
        totalMs: _updateClock.elapsedMicroseconds / 1000,
        aiMs: aiMs,
        combatMs: combatMs,
        weaponsMs: weaponsMs,
      );
    }
    final secondsLeft = (config.durationSeconds - _elapsed).ceil();
    final objectiveOutcome = config.battlefield == BattlefieldType.evacuation
        ? EvacuationRules.resolve(
            alive: _escortAlive,
            escaped: _escortEscaped,
            secondsLeft: secondsLeft,
          )
        : GateDefenseRules.resolve(gateHp: _gateHp, secondsLeft: secondsLeft);
    if (objectiveOutcome != BattleOutcome.retreat) {
      _finishBattle(objectiveOutcome);
    }
    _publishStats();
  }

  void _rebuildGrid() {
    _spatialGrid.beginFrame();
    for (var i = 0; i < _units.length; i++) {
      if (_units[i].dead) continue;
      _spatialGrid.add(
        x: _units[i].position.x,
        y: _units[i].position.y,
        index: i,
      );
    }
  }

  void _updateUnits(double dt) {
    for (final unit in _units) {
      if (_finished) break;
      if (unit.dead) continue;
      _updateUnitStatus(unit, dt);
      if (unit.dead) continue;
      unit.attackClock -= dt;
      final playerDistance = _player.distanceTo(unit.position);
      if (playerDistance > size.x * .8) continue; // Off-screen AI throttling.
      _updateRoleUnit(unit, dt);
      unit.phase += dt * (unit.elite ? 6 : 4);
    }
  }

  BattleUnit? _nearestOpponent(BattleUnit source, double range) {
    BattleUnit? nearest;
    var best = range;
    final cx = _spatialGrid.cellX(source.position.x);
    final cy = _spatialGrid.cellY(source.position.y);
    for (var gx = cx - 2; gx <= cx + 2; gx++) {
      for (var gy = cy - 2; gy <= cy + 2; gy++) {
        for (final index in _spatialGrid.bucketAt(gx, gy)) {
          final candidate = _units[index];
          if (candidate.dead || candidate.ally == source.ally) continue;
          final distance = candidate.position.distanceTo(source.position);
          if (distance < best) {
            best = distance;
            nearest = candidate;
          }
        }
      }
    }
    return nearest;
  }

  void _publishStats() {
    final next = BattleStats(
      hp: _playerMaxHp,
      level: _level,
      xp: _xp,
      nextXp: _nextXp,
      kills: _kills,
      secondsLeft: (config.durationSeconds - _elapsed).ceil(),
      weaponLevel: _runWeapons.first.level,
      ultimateCharge: _ultimateCharge,
      ultimateEnabled: _signatureWeaponActive,
      gateHp: _gateHp,
      gateMaxHp: GateDefenseRules.maxGateHp,
      frontPressure: _frontPressure,
      allyCommanderAlive: _allyCommander?.dead != true,
      enemyCommanderAlive: _enemyCommander?.dead != true,
      build: _currentBuildEntries,
      escortTotal: _escorts.length,
      escortAlive: _escortAlive,
      escortEscaped: _escortEscaped,
    );
    final old = stats.value;
    if (old.level != next.level ||
        old.kills != next.kills ||
        old.secondsLeft != next.secondsLeft ||
        (old.gateHp - next.gateHp).abs() > .5 ||
        (old.frontPressure - next.frontPressure).abs() > .01 ||
        old.allyCommanderAlive != next.allyCommanderAlive ||
        old.enemyCommanderAlive != next.enemyCommanderAlive ||
        old.escortAlive != next.escortAlive ||
        old.escortEscaped != next.escortEscaped ||
        !_sameBuild(old.build, next.build) ||
        (old.ultimateCharge - next.ultimateCharge).abs() > .005 ||
        (old.xp - next.xp).abs() > 1) {
      stats.value = next;
    }
  }

  void _recordPerformance(double dt) {
    if (_elapsed < 2 || dt <= 0 || dt > .25) return;
    _frameSamples[_frameSampleIndex] = dt * 1000;
    _frameSampleIndex = (_frameSampleIndex + 1) % _frameSamples.length;
    _frameSampleCount = math.min(_frameSampleCount + 1, _frameSamples.length);
    final active = _units.where((unit) => !unit.dead).length + _escortAlive;
    _peakActiveUnits = math.max(_peakActiveUnits, active);
  }

  double get _frameTimeP95Ms {
    if (_frameSampleCount == 0) return 0;
    final values = _frameSamples.take(_frameSampleCount).toList()..sort();
    return values[((values.length - 1) * .95).round()];
  }

  @override
  void render(Canvas canvas) {
    _renderClock
      ..reset()
      ..start();
    _drawTerrain(canvas);
    _drawBattlefieldObjective(canvas);
    _drawUnits(canvas);
    _drawCombatPools(canvas);
    _drawUltimateEffect(canvas);
    _drawPlayerMarker(canvas);
    super.render(canvas);
    _renderClock.stop();
    if (_elapsed >= 2) {
      _performanceProfiler.recordRender(
        _renderClock.elapsedMicroseconds / 1000,
      );
    }
  }

  void _drawTerrain(Canvas canvas) {
    canvas.drawRect(
      Offset.zero & Size(size.x, size.y),
      Paint()..color = const Color(0xff3b3b31),
    );
    final grid = Paint()
      ..color = const Color(0x1822251f)
      ..strokeWidth = 1;
    for (double x = 0; x < size.x; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), grid);
    }
    for (double y = 0; y < size.y; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), grid);
    }
    final stain = Paint()..color = const Color(0x335a3028);
    for (var i = 0; i < 20; i++) {
      canvas.drawCircle(
        Offset((i * 137) % size.x, (i * 79) % size.y),
        12 + i % 4 * 5,
        stain,
      );
    }
  }

  void _drawUnits(Canvas canvas) {
    for (final unit in _units) {
      if (unit.dead) continue;
      if (unit.position.x < -20 ||
          unit.position.y < -20 ||
          unit.position.x > size.x + 20 ||
          unit.position.y > size.y + 20) {
        continue;
      }
      final bob = math.sin(unit.phase) * 1.2;
      final displaySize = switch (unit.role) {
        UnitRole.cavalry => const Size(68, 74),
        UnitRole.siege => const Size(74, 66),
        UnitRole.commander => const Size(54, 72),
        _ => const Size(44, 62),
      };
      final rankScale = switch (unit.archetype?.rank) {
        EnemyRank.elite => 1.18,
        EnemyRank.boss => 1.34,
        _ => 1.0,
      };
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(unit.position.x, unit.position.y + 7),
          width: displaySize.width * .56,
          height: 8,
        ),
        Paint()..color = const Color(0x66000000),
      );
      final cellWidth = _unitAtlas.width / UnitRole.values.length;
      final cellHeight = _unitAtlas.height / 2;
      final unitPaint = Paint()..filterQuality = FilterQuality.none;
      if (unit.hitFlash > 0) {
        unitPaint.colorFilter = const ColorFilter.mode(
          Color(0xccffffff),
          BlendMode.modulate,
        );
      } else if (unit.archetype != null) {
        unitPaint.colorFilter = ColorFilter.mode(
          unit.archetype!.factionColor,
          BlendMode.modulate,
        );
      }
      canvas.drawImageRect(
        _unitAtlas,
        Rect.fromLTWH(
          unit.role.index * cellWidth,
          unit.ally ? 0 : cellHeight,
          cellWidth,
          cellHeight,
        ),
        Rect.fromCenter(
          center: Offset(unit.position.x, unit.position.y - 14 + bob),
          width: displaySize.width * rankScale,
          height: displaySize.height * rankScale,
        ),
        unitPaint,
      );
      if (unit.status != StatusEffectType.none) {
        final statusColor = switch (unit.status) {
          StatusEffectType.bleed => const Color(0xffd94f58),
          StatusEffectType.burn => const Color(0xffff8a43),
          StatusEffectType.slow => const Color(0xff62c9e8),
          StatusEffectType.none => const Color(0x00000000),
        };
        canvas.drawCircle(
          Offset(unit.position.x, unit.position.y + 2),
          11,
          Paint()
            ..color = statusColor.withValues(alpha: .7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      if (unit.archetype?.rank != null &&
          unit.archetype!.rank != EnemyRank.common) {
        _drawEnemyArchetypeMark(canvas, unit);
      }
      if (unit.elite || unit.role == UnitRole.commander) {
        canvas.drawCircle(
          Offset(unit.position.x, unit.position.y),
          unit.role == UnitRole.commander ? 28 : 19,
          Paint()
            ..color = unit.archetype?.rank == EnemyRank.boss
                ? const Color(0xccf0c96c)
                : const Color(0x99ce8be0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      if (unit.stance == UnitStance.retreat) {
        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(unit.position.x, unit.position.y),
            radius: 18,
          ),
          0,
          math.pi * 1.4,
          false,
          Paint()
            ..color = const Color(0xffe1b75e)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  void _drawEnemyArchetypeMark(Canvas canvas, BattleUnit unit) {
    final archetype = unit.archetype!;
    final center = Offset(unit.position.x, unit.position.y - 47);
    final paint = Paint()
      ..color = archetype.factionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = archetype.rank == EnemyRank.common ? 1.5 : 2.2;
    switch (archetype.ability) {
      case EnemyAbility.none:
        canvas.drawCircle(center, 3, paint..style = PaintingStyle.fill);
      case EnemyAbility.brace:
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 9, height: 11),
          paint,
        );
      case EnemyAbility.volley:
        canvas.drawLine(
          center.translate(-6, 4),
          center.translate(6, -4),
          paint,
        );
        canvas.drawLine(
          center.translate(2, -5),
          center.translate(6, -4),
          paint,
        );
      case EnemyAbility.charge:
        final path = Path()
          ..moveTo(center.dx, center.dy - 6)
          ..lineTo(center.dx + 6, center.dy + 5)
          ..lineTo(center.dx - 6, center.dy + 5)
          ..close();
        canvas.drawPath(path, paint);
      case EnemyAbility.hex || EnemyAbility.bloodNova:
        canvas.drawCircle(center, 6, paint);
        canvas.drawCircle(center, 2, paint..style = PaintingStyle.fill);
      case EnemyAbility.breach || EnemyAbility.blast:
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 10, height: 10),
          paint,
        );
        canvas.drawLine(
          center.translate(-5, -5),
          center.translate(5, 5),
          paint,
        );
      case EnemyAbility.flank || EnemyAbility.huntMark:
        canvas.drawLine(center.translate(-6, -4), center, paint);
        canvas.drawLine(center, center.translate(-6, 4), paint);
        canvas.drawLine(center, center.translate(6, 0), paint);
      case EnemyAbility.riposte:
        canvas.drawLine(
          center.translate(-5, 5),
          center.translate(5, -5),
          paint,
        );
        canvas.drawLine(
          center.translate(-2, -5),
          center.translate(5, -5),
          paint,
        );
      case EnemyAbility.commandSiege:
        canvas.drawLine(
          center.translate(-5, 6),
          center.translate(-5, -7),
          paint,
        );
        final flag = Path()
          ..moveTo(center.dx - 5, center.dy - 7)
          ..lineTo(center.dx + 7, center.dy - 3)
          ..lineTo(center.dx - 5, center.dy + 1)
          ..close();
        canvas.drawPath(flag, paint..style = PaintingStyle.fill);
    }
  }

  void _drawPlayerMarker(Canvas canvas) {
    canvas.drawCircle(
      Offset(_player.x, _player.y + 9),
      16,
      Paint()..color = const Color(0x77000000),
    );
    canvas.drawCircle(
      Offset(_player.x, _player.y),
      14,
      Paint()
        ..color = mercenary.visual.accent.withValues(alpha: .45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}

class BattleUnit {
  BattleUnit({
    required this.position,
    required this.ally,
    required this.elite,
    required this.hp,
    required this.playerAggro,
    required this.objectiveAggro,
    required this.role,
    required this.stance,
    required this.squadId,
    required this.maxHp,
    this.archetype,
  });
  Vector2 position;
  bool ally;
  bool elite;
  int hp;
  bool playerAggro;
  bool objectiveAggro;
  UnitRole role;
  UnitStance stance;
  int squadId;
  int maxHp;
  EnemyArchetypeSpec? archetype;
  int abilityCounter = 0;
  double phase = 0;
  double attackClock = 0;
  double hitFlash = 0;
  StatusEffectType status = StatusEffectType.none;
  double statusClock = 0;
  double statusTickClock = 0;
  bool dead = false;
}

class SlashFx {
  SlashFx.pooled();
  Vector2 position = Vector2.zero();
  CombatStyle style = CombatStyle.blades;
  double maxLife = 0;
  double life = 0;
  bool active = false;
}

class PooledProjectile {
  bool active = false;
  Vector2 position = Vector2.zero();
  BattleUnit? target;
  WeaponPattern pattern = WeaponPattern.longBow;
  int damage = 0;
  double speed = 0;
  double criticalChance = 0;
  int chainRemaining = 0;
  bool appliesDamage = true;
  double life = 0;
}

class DamageNumberFx {
  bool active = false;
  Vector2 position = Vector2.zero();
  int amount = 0;
  bool critical = false;
  double life = 0;
  double maxLife = 0;
  Paragraph? paragraph;
}

class RunWeaponState {
  RunWeaponState(this.weapon);

  final WeaponSpec weapon;
  int level = 1;
  double attackClock = 0;
}
