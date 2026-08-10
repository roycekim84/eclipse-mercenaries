import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Offset, ValueNotifier;

import '../domain/battle_models.dart';
import '../domain/battle_performance.dart';
import '../domain/battle_render_policy.dart';
import '../domain/battlefield_events.dart';
import '../domain/battle_rewards.dart';
import '../domain/combat_rules.dart';
import '../domain/enemy_catalog.dart';
import '../domain/game_data.dart';
import '../domain/game_settings.dart';
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
part 'systems/boss_system.dart';
part 'systems/damage_system.dart';
part 'systems/weapon_system.dart';
part 'systems/pooled_effects_system.dart';
part 'systems/run_growth_system.dart';

double _permanentPlayerMaxHp(BattleConfig config) {
  final level = config.mercenaryPermanentLevel ?? config.mercenary.level;
  return config.mercenary.maxHp *
      ProgressionRules.mercenaryHpMultiplier(config.mercenary.level, level) *
      config.gearBonus.hpMultiplier;
}

class SurvivorGame extends FlameGame {
  SurvivorGame({
    required this.config,
    required this.onVictory,
    this.targetPriority = AutoTargetPriority.nearest,
    this.screenShakeEnabled = true,
  }) : _random = math.Random(config.seed),
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
  final AutoTargetPriority targetPriority;
  final bool screenShakeEnabled;
  MercenarySpec get mercenary => config.mercenary;
  WeaponSpec get weapon => config.weapon;
  double get _permanentDamageMultiplier =>
      ProgressionRules.combatDamageMultiplier(
        baseMercenaryLevel: mercenary.level,
        permanentMercenaryLevel:
            config.mercenaryPermanentLevel ?? mercenary.level,
        weaponLevel: config.weaponPermanentLevel,
        weaponStage: config.weaponGrowthStage,
      ) *
      config.gearBonus.damageMultiplier;
  double get _playerMaxHp => _permanentPlayerMaxHp(config);
  final void Function(BattleReport) onVictory;
  late final ValueNotifier<BattleStats> stats;
  final choice = ValueNotifier<BattleChoice?>(null);
  final event = ValueNotifier<BattleEvent?>(null);
  final eventPrompt = ValueNotifier<BattlefieldEventSpec?>(null);
  final ultimate = ValueNotifier<UltimateSequence?>(null);
  final reducedEffects = ValueNotifier(false);
  final performanceMode = ValueNotifier(false);
  final combatPaused = ValueNotifier(false);
  final controls = ValueNotifier(const BattleControlState.ready());
  final bossTelegraph = ValueNotifier<BossTelegraph?>(null);
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
  final _visibleUnits = <BattleUnit>[];
  final _visibleUnitDetails = <bool>[];
  final _unitTransforms = <RSTransform>[];
  final _unitSources = <Rect>[];
  final _unitBatchPaint = Paint()..filterQuality = FilterQuality.none;
  final _unitShadowPaint = Paint()..color = const Color(0x66000000);
  Vector2? _moveTarget;
  Vector2? _moveDirection;
  late Vector2 _player;
  late final PlayerSpriteComponent _playerSprite;
  late final Image _unitAtlas;
  Image? _battlefieldBackground;
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
  double _dashCooldown = 0;
  double _playerInvulnerability = 0;
  double _playerHitFlash = 0;
  double _hitStopClock = 0;
  double _cameraImpulse = 0;
  late double _playerHp;
  double _tacticalCooldown = 0;
  double _tacticalClock = 0;
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
  int _slashEmissionSequence = 0;
  int _damageNumberEmissionSequence = 0;
  double _bossPatternClock = 4.5;
  double _bossTelegraphClock = 0;
  int _bossPatternIndex = 0;
  int _bossPhase = 1;
  double _bossPhaseBannerClock = 0;
  double _bossUiClock = 0;
  Vector2? _bossPatternTarget;
  BossPatternSpec? _activeBossPattern;

  static const _standardRenderPolicy = BattleRenderPolicy(
    performanceMode: false,
  );
  static const _performanceRenderPolicy = BattleRenderPolicy(
    performanceMode: true,
  );
  static const _alliedUnitSources = <Rect>[
    Rect.fromLTWH(0, 0, 88, 124),
    Rect.fromLTWH(88, 0, 88, 124),
    Rect.fromLTWH(176, 0, 88, 124),
    Rect.fromLTWH(264, 0, 136, 148),
    Rect.fromLTWH(400, 0, 88, 124),
    Rect.fromLTWH(488, 0, 148, 132),
    Rect.fromLTWH(636, 0, 108, 144),
  ];
  static const _enemyUnitSources = <Rect>[
    Rect.fromLTWH(0, 148, 88, 124),
    Rect.fromLTWH(88, 148, 88, 124),
    Rect.fromLTWH(176, 148, 88, 124),
    Rect.fromLTWH(264, 148, 136, 148),
    Rect.fromLTWH(400, 148, 88, 124),
    Rect.fromLTWH(488, 148, 148, 132),
    Rect.fromLTWH(636, 148, 108, 144),
  ];

  BattleRenderPolicy get _renderPolicy =>
      performanceMode.value ? _performanceRenderPolicy : _standardRenderPolicy;
  bool get _reducedVisualLoad => reducedEffects.value || performanceMode.value;

  @override
  Color backgroundColor() => const Color(0xff35362d);

  @override
  Future<void> onLoad() async {
    _player = config.battlefield == BattlefieldType.evacuation
        ? Vector2(size.x * .34, size.y / 2)
        : size / 2;
    _gatePosition = Vector2(78, size.y / 2);
    _defenseLineX = math.max(190, size.x * .28);
    _unitAtlas = await images.load('battlefield/unit_role_batch.png');
    _battlefieldBackground = await images.load(switch (config.condition) {
      BattlefieldCondition.moonlitNight =>
        'battlefield/north_gate_battlefield.png',
      BattlefieldCondition.ashWind => 'battlefield/ashwind_road_v2.png',
      BattlefieldCondition.blackForest => 'battlefield/black_forest_route.png',
      BattlefieldCondition.whiteNight => 'battlefield/white_night_fortress.png',
      BattlefieldCondition.twilightSiege =>
        'battlefield/twilight_siege_plain.png',
    });
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
        config.gearBonus.speedMultiplier *
        (config.condition == BattlefieldCondition.ashWind ? .94 : 1);
    _playerHp = _playerMaxHp;
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
  void setMoveDirection(Offset direction) {
    final next = Vector2(direction.dx, direction.dy);
    _moveDirection = next.length2 > .01 ? next.normalized() : null;
    _moveTarget = null;
  }

  void clearMoveDirection() => _moveDirection = null;

  void triggerDash() {
    if (_dashCooldown > 0 ||
        _finished ||
        _pausedForChoice ||
        _pausedForEvent ||
        _pausedByUser ||
        _pausedByLifecycle) {
      return;
    }
    var direction = _moveDirection;
    if (direction == null && _moveTarget != null) {
      final delta = _moveTarget! - _player;
      if (delta.length2 > 1) direction = delta.normalized();
    }
    direction ??= Vector2(1, 0);
    final distance = BattleControlRules.dashDistance(_speed);
    _player.add(direction * distance);
    _player
      ..x = _player.x.clamp(24, size.x - 24)
      ..y = _player.y.clamp(24, size.y - 24);
    _playerSprite.position = _player;
    _emitSlash(_player, .32, mercenary.style);
    _dashCooldown =
        BattleControlRules.dashCooldownSeconds *
        config.gearBonus.dashCooldownMultiplier;
    _playerInvulnerability = BattleControlRules.dashInvulnerabilitySeconds;
    _publishControls();
  }

  void triggerTacticalAction() {
    if (_tacticalCooldown > 0 ||
        _finished ||
        _pausedForChoice ||
        _pausedForEvent ||
        _pausedByUser ||
        _pausedByLifecycle) {
      return;
    }
    _tacticalClock = BattleControlRules.tacticalDurationSeconds;
    _tacticalCooldown =
        BattleControlRules.tacticalCooldownSeconds *
        config.gearBonus.tacticalCooldownMultiplier;
    _emitSlash(_player, .5, CombatStyle.magic);
    event.value = BattleEvent(
      '전술 명령',
      config.battlefield == BattlefieldType.evacuation ? '강행군' : '전선 집결',
      config.battlefield == BattlefieldType.evacuation
          ? '호위대가 4초간 이동속도 35% 증가'
          : '아군이 4초간 공격·이동 주기 가속',
      id: 'tactical_action',
    );
    _publishControls();
  }

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
      clearMoveDirection();
      clearMoveTarget();
      pauseEngine();
    } else {
      resumeEngine();
    }
  }

  void pauseForLifecycle() {
    if (_finished) return;
    clearMoveDirection();
    clearMoveTarget();
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
    clearMoveDirection();
    _publishStats();
  }

  @override
  void update(double dt) {
    _recordPerformance(dt);
    _updateClock
      ..reset()
      ..start();
    final hitStopActive = _hitStopClock > 0;
    _hitStopClock = math.max(0, _hitStopClock - dt);
    _cameraImpulse = math.max(0, _cameraImpulse - dt * 18);
    final combatTimeScale = hitStopActive ? .08 : 1.0;
    final worldDt = (_ultimateClock > 1.18 ? dt * .08 : dt) * combatTimeScale;
    super.update(worldDt);
    if (_finished || _pausedForChoice || _pausedForEvent) {
      _updateClock.stop();
      return;
    }
    _advanceUltimate(dt);
    _dashCooldown = math.max(0, _dashCooldown - worldDt);
    _playerInvulnerability = math.max(0, _playerInvulnerability - worldDt);
    _playerHitFlash = math.max(0, _playerHitFlash - worldDt);
    _tacticalCooldown = math.max(0, _tacticalCooldown - worldDt);
    final tacticalWasActive = _tacticalClock > 0;
    _tacticalClock = math.max(0, _tacticalClock - worldDt);
    if (tacticalWasActive &&
        _tacticalClock <= 0 &&
        event.value?.id == 'tactical_action') {
      event.value = null;
    }
    _elapsed += worldDt;
    _eventClock += worldDt;
    var isMoving = false;
    if (_moveDirection != null) {
      _player += _moveDirection! * _speed * worldDt;
      _player
        ..x = _player.x.clamp(24, size.x - 24)
        ..y = _player.y.clamp(24, size.y - 24);
      isMoving = true;
    } else if (_moveTarget != null) {
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
    _updateBossPatterns(worldDt);
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
    if (_playerHp <= 0) {
      _finishBattle(BattleOutcome.defeat);
      _publishStats();
      _publishControls();
      return;
    }
    final objectiveOutcome = switch (config.objective) {
      ContractObjective.evacuation ||
      ContractObjective.supplyEscort => EvacuationRules.resolve(
        alive: _escortAlive,
        escaped: _escortEscaped,
        secondsLeft: secondsLeft,
      ),
      ContractObjective.assassination =>
        _enemyCommander?.dead == true
            ? BattleOutcome.victory
            : (_gateHp <= 0 || secondsLeft <= 0
                  ? BattleOutcome.defeat
                  : BattleOutcome.retreat),
      ContractObjective.ambush =>
        _kills >= 120
            ? BattleOutcome.victory
            : (_gateHp <= 0 || secondsLeft <= 0
                  ? BattleOutcome.defeat
                  : BattleOutcome.retreat),
      ContractObjective.fortressRetake =>
        _enemyCommander?.dead == true && _kills >= 80
            ? BattleOutcome.victory
            : (_gateHp <= 0 || secondsLeft <= 0
                  ? BattleOutcome.defeat
                  : BattleOutcome.retreat),
      ContractObjective.defense => GateDefenseRules.resolve(
        gateHp: _gateHp,
        secondsLeft: secondsLeft,
      ),
    };
    if (objectiveOutcome != BattleOutcome.retreat) {
      _finishBattle(objectiveOutcome);
    }
    _publishStats();
    _publishControls();
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
      _applyLocalSeparation(unit, dt);
      unit.phase += dt * (unit.elite ? 6 : 4);
    }
  }

  void _applyLocalSeparation(BattleUnit unit, double dt) {
    final cx = _spatialGrid.cellX(unit.position.x);
    final cy = _spatialGrid.cellY(unit.position.y);
    final push = Vector2.zero();
    var neighbours = 0;
    for (var gx = cx - 1; gx <= cx + 1 && neighbours < 10; gx++) {
      for (var gy = cy - 1; gy <= cy + 1 && neighbours < 10; gy++) {
        for (final index in _spatialGrid.bucketAt(gx, gy)) {
          final other = _units[index];
          if (identical(other, unit) || other.dead || other.ally != unit.ally) {
            continue;
          }
          final delta = unit.position - other.position;
          final distance = delta.length;
          final spacing =
              unit.role == UnitRole.siege || other.role == UnitRole.siege
              ? 34.0
              : 21.0;
          if (distance >= spacing) continue;
          if (distance > .1) {
            push.add(delta.normalized() * (1 - distance / spacing));
          } else {
            push.add(Vector2(math.cos(unit.phase), math.sin(unit.phase)));
          }
          neighbours++;
          if (neighbours >= 10) break;
        }
      }
    }
    final playerDelta = unit.position - _player;
    final playerDistance = playerDelta.length;
    final playerSpacing = !unit.ally && unit.playerAggro ? 26.0 : 42.0;
    if (playerDistance < playerSpacing && playerDistance > .1) {
      push.add(playerDelta.normalized() * (1 - playerDistance / playerSpacing));
    }
    if (push.length2 <= .001) return;
    unit.position.add(push.normalized() * 22 * dt);
    unit.position
      ..x = unit.position.x.clamp(12, size.x - 12)
      ..y = unit.position.y.clamp(12, size.y - 12);
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
      hp: _playerHp,
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
        (old.hp - next.hp).abs() > .5 ||
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

  void _publishControls() {
    final next = BattleControlState(
      dashCooldown: _dashCooldown,
      tacticalCooldown: _tacticalCooldown,
      tacticalActive: _tacticalClock > 0,
    );
    final old = controls.value;
    if ((old.dashCooldown - next.dashCooldown).abs() > .08 ||
        (old.tacticalCooldown - next.tacticalCooldown).abs() > .08 ||
        old.tacticalActive != next.tacticalActive) {
      controls.value = next;
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
    final allowShake = screenShakeEnabled && !_reducedVisualLoad;
    final shakeX = allowShake ? math.sin(_elapsed * 117) * _cameraImpulse : 0.0;
    final shakeY = allowShake ? math.cos(_elapsed * 93) * _cameraImpulse : 0.0;
    canvas.save();
    canvas.translate(shakeX, shakeY);
    _drawTerrain(canvas);
    _drawBattlefieldObjective(canvas);
    _drawUnits(canvas);
    _drawCombatPools(canvas);
    _drawBossTelegraph(canvas);
    _drawUltimateEffect(canvas);
    _drawPlayerMarker(canvas);
    super.render(canvas);
    canvas.restore();
    _renderClock.stop();
    if (_elapsed >= 2) {
      _performanceProfiler.recordRender(
        _renderClock.elapsedMicroseconds / 1000,
      );
    }
  }

  void _triggerImpact({required double hitStop, required double impulse}) {
    if (reducedEffects.value || performanceMode.value) return;
    _hitStopClock = math.max(_hitStopClock, hitStop);
    if (screenShakeEnabled) {
      _cameraImpulse = math.max(_cameraImpulse, impulse);
    }
  }

  void _drawTerrain(Canvas canvas) {
    final background = _battlefieldBackground;
    if (background != null) {
      canvas.drawImageRect(
        background,
        Rect.fromLTWH(
          0,
          0,
          background.width.toDouble(),
          background.height.toDouble(),
        ),
        Offset.zero & Size(size.x, size.y),
        Paint()..filterQuality = FilterQuality.none,
      );
      return;
    }
    final policy = _renderPolicy;
    canvas.drawRect(
      Offset.zero & Size(size.x, size.y),
      Paint()..color = const Color(0xff3b3b31),
    );
    final grid = Paint()
      ..color = const Color(0x1822251f)
      ..strokeWidth = 1;
    for (double x = 0; x < size.x; x += policy.terrainGridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), grid);
    }
    for (double y = 0; y < size.y; y += policy.terrainGridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), grid);
    }
    final stain = Paint()..color = const Color(0x335a3028);
    for (var i = 0; i < policy.terrainStainCount; i++) {
      canvas.drawCircle(
        Offset((i * 137) % size.x, (i * 79) % size.y),
        12 + i % 4 * 5,
        stain,
      );
    }
  }

  void _drawUnits(Canvas canvas) {
    final policy = _renderPolicy;
    final viewportLongestSide = math.max(size.x, size.y);
    _visibleUnits.clear();
    _visibleUnitDetails.clear();
    _unitTransforms.clear();
    _unitSources.clear();
    for (final unit in _units) {
      if (unit.dead) continue;
      if (unit.position.x < -20 ||
          unit.position.y < -20 ||
          unit.position.x > size.x + 20 ||
          unit.position.y > size.y + 20) {
        continue;
      }
      _visibleUnits.add(unit);
      final distance = _player.distanceTo(unit.position);
      final important = _isImportantRenderUnit(unit);
      final detailed = policy.showsDetail(
        distance: distance,
        viewportLongestSide: viewportLongestSide,
        important: important,
      );
      _visibleUnitDetails.add(detailed);
      final bob = detailed ? math.sin(unit.phase) * 1.2 : 0.0;
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
      if (policy.showsShadow(detailed: detailed, important: important)) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(unit.position.x, unit.position.y + 7),
            width: displaySize.width * .56,
            height: 8,
          ),
          _unitShadowPaint,
        );
      }
      final source = _unitBatchSource(unit);
      _unitSources.add(source);
      _unitTransforms.add(
        RSTransform.fromComponents(
          scale: .5 * rankScale,
          anchorX: source.width / 2,
          anchorY: source.height / 2,
          rotation: 0,
          translateX: unit.position.x,
          translateY: unit.position.y - 14 + bob,
        ),
      );
    }
    if (_unitSources.isNotEmpty) {
      canvas.drawAtlas(
        _unitAtlas,
        _unitTransforms,
        _unitSources,
        null,
        BlendMode.srcOver,
        null,
        _unitBatchPaint,
      );
    }
    for (var index = 0; index < _visibleUnits.length; index++) {
      final unit = _visibleUnits[index];
      if (!_visibleUnitDetails[index]) continue;
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

  bool _isImportantRenderUnit(BattleUnit unit) =>
      unit.elite ||
      unit.role == UnitRole.commander ||
      unit.archetype?.rank == EnemyRank.boss ||
      unit.status != StatusEffectType.none ||
      unit.stance == UnitStance.retreat;

  Rect _unitBatchSource(BattleUnit unit) {
    final sources = unit.ally ? _alliedUnitSources : _enemyUnitSources;
    return sources[unit.role.index];
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
    final pulse = .72 + math.sin(_elapsed * 5).abs() * .18;
    canvas.drawCircle(
      Offset(_player.x, _player.y + 9),
      16,
      Paint()..color = const Color(0x77000000),
    );
    canvas.drawCircle(
      Offset(_player.x, _player.y),
      18,
      Paint()
        ..color = const Color(0xffffdf86).withValues(alpha: pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(_player.x, _player.y),
      14,
      Paint()
        ..color = _playerHitFlash > 0
            ? const Color(0xffffe8df)
            : mercenary.visual.accent.withValues(
                alpha: _playerInvulnerability > 0 ? .9 : .45,
              )
        ..style = PaintingStyle.stroke
        ..strokeWidth = _playerInvulnerability > 0 ? 4 : 3,
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
