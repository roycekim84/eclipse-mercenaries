import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Offset, ValueNotifier;

import '../domain/battle_models.dart';
import '../domain/combat_rules.dart';
import '../domain/game_data.dart';
import '../domain/run_growth.dart';
import '../core/content/game_visuals.dart';
import 'render/player_sprite_component.dart';

part 'systems/ultimate_system.dart';
part 'systems/gate_defense_system.dart';
part 'systems/unit_ai_system.dart';
part 'systems/damage_system.dart';
part 'systems/weapon_system.dart';
part 'systems/pooled_effects_system.dart';
part 'systems/run_growth_system.dart';

class SurvivorGame extends FlameGame {
  SurvivorGame({required this.config, required this.onVictory})
    : _random = math.Random(config.seed),
      _upgradeRandom = math.Random(config.seed ^ 0x5f3759df) {
    stats = ValueNotifier(
      BattleStats(
        hp: config.mercenary.maxHp.toDouble(),
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
  final void Function(BattleReport) onVictory;
  late final ValueNotifier<BattleStats> stats;
  final choice = ValueNotifier<BattleChoice?>(null);
  final event = ValueNotifier<BattleEvent?>(null);
  final ultimate = ValueNotifier<UltimateSequence?>(null);
  final reducedEffects = ValueNotifier(false);
  final combatPaused = ValueNotifier(false);
  final math.Random _random;
  final math.Random _upgradeRandom;
  final _units = <BattleUnit>[];
  final _slashes = List.generate(96, (_) => SlashFx.pooled());
  final _projectiles = List.generate(64, (_) => PooledProjectile());
  final _damageNumbers = List.generate(36, (_) => DamageNumberFx());
  final _runWeapons = <RunWeaponState>[];
  final _passiveLevels = <String, int>{};
  final _spatialGrid = <int, List<int>>{};
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
  bool _finished = false;
  bool _pausedForChoice = false;
  bool _pausedByUser = false;
  bool _pausedByLifecycle = false;

  @override
  Color backgroundColor() => const Color(0xff35362d);

  @override
  Future<void> onLoad() async {
    _player = size / 2;
    _gatePosition = Vector2(78, size.y / 2);
    _defenseLineX = math.max(190, size.x * .28);
    _unitAtlas = await images.load('battlefield/unit_role_atlas.png');
    final playerImage = await images.load(mercenary.visual.battleSpriteAsset);
    _playerSprite = PlayerSpriteComponent.fromImage(playerImage)
      ..position = _player.clone();
    await add(_playerSprite);
    _speed = mercenary.speed;
    _runWeapons.add(RunWeaponState(weapon));
    stats.value = BattleStats(
      hp: mercenary.maxHp.toDouble(),
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
    );
    _spawnBattleLines();
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
    if (_finished || _pausedForChoice || _pausedByLifecycle) return;
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
    if (!_pausedByUser && !_pausedForChoice && !_finished) resumeEngine();
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
    final worldDt = _ultimateClock > 1.18 ? dt * .08 : dt;
    super.update(worldDt);
    if (_finished || _pausedForChoice) {
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
    _rebuildGrid();
    _updateUnits(worldDt);
    _updateCombatPools(worldDt);
    _updateRunWeapons(worldDt);
    if (_eventClock > 14 && event.value == null) {
      event.value = const BattleEvent(
        '희귀 전장 사건',
        '적군 증원',
        '북동쪽 능선에서 적 증원부대가 도착했습니다. 전리품 획득량이 증가합니다.',
      );
      Future<void>.delayed(
        const Duration(seconds: 4),
        () => event.value = null,
      );
    }
    _updateFrontPressure();
    final objectiveOutcome = GateDefenseRules.resolve(
      gateHp: _gateHp,
      secondsLeft: (config.durationSeconds - _elapsed).ceil(),
    );
    if (objectiveOutcome != BattleOutcome.retreat) {
      _finishBattle(objectiveOutcome);
    }
    _publishStats();
  }

  void _rebuildGrid() {
    _spatialGrid.clear();
    for (var i = 0; i < _units.length; i++) {
      if (_units[i].dead) continue;
      final cell =
          (_units[i].position.x ~/ 96) * 10000 + (_units[i].position.y ~/ 96);
      (_spatialGrid[cell] ??= []).add(i);
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
    final cx = source.position.x ~/ 96;
    final cy = source.position.y ~/ 96;
    for (var gx = cx - 2; gx <= cx + 2; gx++) {
      for (var gy = cy - 2; gy <= cy + 2; gy++) {
        for (final index in _spatialGrid[gx * 10000 + gy] ?? const <int>[]) {
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
      hp: mercenary.maxHp.toDouble(),
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
    );
    final old = stats.value;
    if (old.level != next.level ||
        old.kills != next.kills ||
        old.secondsLeft != next.secondsLeft ||
        (old.gateHp - next.gateHp).abs() > .5 ||
        (old.frontPressure - next.frontPressure).abs() > .01 ||
        old.allyCommanderAlive != next.allyCommanderAlive ||
        old.enemyCommanderAlive != next.enemyCommanderAlive ||
        !_sameBuild(old.build, next.build) ||
        (old.ultimateCharge - next.ultimateCharge).abs() > .005 ||
        (old.xp - next.xp).abs() > 1) {
      stats.value = next;
    }
  }

  @override
  void render(Canvas canvas) {
    _drawTerrain(canvas);
    _drawBattlefieldObjective(canvas);
    _drawUnits(canvas);
    _drawCombatPools(canvas);
    _drawUltimateEffect(canvas);
    _drawPlayerMarker(canvas);
    super.render(canvas);
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
          width: displaySize.width,
          height: displaySize.height,
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
      if (unit.elite || unit.role == UnitRole.commander) {
        canvas.drawCircle(
          Offset(unit.position.x, unit.position.y),
          unit.role == UnitRole.commander ? 22 : 15,
          Paint()
            ..color = unit.role == UnitRole.commander
                ? const Color(0x99f0c96c)
                : const Color(0x55e3b75d)
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
