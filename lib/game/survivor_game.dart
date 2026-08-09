import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Offset, ValueNotifier;

import '../domain/battle_models.dart';
import '../domain/game_data.dart';
import '../core/content/game_visuals.dart';
import 'render/player_sprite_component.dart';

part 'systems/ultimate_system.dart';

class SurvivorGame extends FlameGame {
  SurvivorGame({required this.config, required this.onVictory})
    : _random = math.Random(config.seed) {
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
  final math.Random _random;
  final _units = <BattleUnit>[];
  final _slashes = <SlashFx>[];
  final _spatialGrid = <int, List<int>>{};
  Vector2? _moveTarget;
  late Vector2 _player;
  late final PlayerSpriteComponent _playerSprite;
  double _elapsed = 0;
  double _attackClock = 0;
  double _eventClock = 0;
  double _xp = 0;
  double _nextXp = 40;
  double _ultimateCharge = 0;
  double _ultimateClock = 0;
  bool _ultimateImpactApplied = false;
  int _ultimateActivation = 0;
  late double _speed;
  int _level = 1;
  int _kills = 0;
  int _weaponLevel = 1;
  bool _finished = false;
  bool _pausedForChoice = false;

  @override
  Color backgroundColor() => const Color(0xff35362d);

  @override
  Future<void> onLoad() async {
    _player = size / 2;
    final playerImage = await images.load(mercenary.visual.battleSpriteAsset);
    _playerSprite = PlayerSpriteComponent.fromImage(playerImage)
      ..position = _player.clone();
    await add(_playerSprite);
    _speed = mercenary.speed;
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
    );
    for (var i = 0; i < 330; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final radius =
          120 + _random.nextDouble() * math.max(size.x, size.y) * .72;
      _units.add(
        BattleUnit(
          position:
              _player + Vector2(math.cos(angle), math.sin(angle)) * radius,
          ally: i % 3 == 0,
          elite: i % 83 == 0 && i % 3 != 0,
          hp: i % 83 == 0 ? 8 : 2,
          playerAggro: i % 5 == 0,
        ),
      );
    }
  }

  void setMoveTarget(Offset offset) =>
      _moveTarget = Vector2(offset.dx, offset.dy);
  void clearMoveTarget() => _moveTarget = null;

  bool get _signatureWeaponActive => weapon.id == mercenary.signatureWeaponId;

  void toggleReducedEffects() => reducedEffects.value = !reducedEffects.value;

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

  void selectUpgrade(int index) {
    if (index == 0) _weaponLevel++;
    if (index == 1) _speed += 18;
    choice.value = null;
    _pausedForChoice = false;
    resumeEngine();
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
    _attackClock += worldDt;
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
    final attackInterval =
        mercenary.attackInterval *
        (100 / (100 + weapon.speed)) *
        math.max(.55, 1 - _weaponLevel * .045);
    if (_attackClock > attackInterval) {
      _attackClock = 0;
      _attackNearest();
    }
    for (final fx in _slashes) {
      fx.life -= worldDt;
    }
    _slashes.removeWhere((fx) => fx.life <= 0);
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
    if (_elapsed >= config.durationSeconds && !_finished) {
      _finished = true;
      final minutes = config.durationSeconds ~/ 60;
      final seconds = config.durationSeconds % 60;
      onVictory(
        BattleReport(
          time:
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          kills: _kills,
          gold: 3240 + _kills * 8,
          xp: 1200 + _kills * 3,
        ),
      );
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
      if (unit.dead) continue;
      unit.attackClock -= dt;
      final playerDistance = _player.distanceTo(unit.position);
      if (playerDistance > size.x * .8) continue; // Off-screen AI throttling.
      final opponent = _nearestOpponent(unit, 150);
      Vector2 direction;
      double targetDistance;
      if (opponent != null) {
        final delta = opponent.position - unit.position;
        targetDistance = delta.length;
        direction = targetDistance > 1
            ? delta / targetDistance
            : Vector2.zero();
        if (targetDistance < (unit.elite ? 24 : 18) && unit.attackClock <= 0) {
          unit.attackClock = unit.elite ? .72 : 1.05;
          opponent.hp -= unit.elite ? 2 : 1;
          _slashes.add(
            SlashFx(
              opponent.position.clone(),
              .15,
              unit.ally ? CombatStyle.blades : CombatStyle.greatsword,
            ),
          );
          if (opponent.hp <= 0) opponent.dead = true;
        }
      } else if (!unit.ally && unit.playerAggro) {
        final delta = _player - unit.position;
        targetDistance = delta.length;
        direction = targetDistance > 1
            ? delta / targetDistance
            : Vector2.zero();
      } else {
        targetDistance = 999;
        direction = Vector2(
          math.sin(_elapsed * .4 + unit.position.x),
          math.cos(_elapsed * .4 + unit.position.y),
        );
      }
      if (targetDistance > 15) {
        unit.position +=
            direction * (unit.ally ? 26 : (unit.elite ? 34 : 25)) * dt;
      }
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

  void _attackNearest() {
    BattleUnit? nearest;
    var best = mercenary.style == CombatStyle.magic ? 330.0 : 230.0;
    final cx = _player.x ~/ 96;
    final cy = _player.y ~/ 96;
    for (var gx = cx - 3; gx <= cx + 3; gx++) {
      for (var gy = cy - 3; gy <= cy + 3; gy++) {
        for (final index in _spatialGrid[gx * 10000 + gy] ?? const <int>[]) {
          final unit = _units[index];
          if (unit.ally || unit.dead) continue;
          final d = unit.position.distanceTo(_player);
          if (d < best) {
            best = d;
            nearest = unit;
          }
        }
      }
    }
    if (nearest == null) return;
    _playerSprite.playAttack();
    final impact = nearest.position.clone();
    final damage =
        mercenary.baseDamage + weapon.attack ~/ 650 + (_weaponLevel ~/ 2);
    final Iterable<BattleUnit> targets =
        mercenary.style == CombatStyle.greatsword
        ? _units
              .where(
                (unit) =>
                    !unit.dead &&
                    !unit.ally &&
                    unit.position.distanceTo(impact) < 55,
              )
              .take(5)
        : <BattleUnit>[nearest];
    for (final target in targets) {
      _damageEnemy(target, damage);
    }
    if (_xp >= _nextXp) {
      _levelUp();
    }
  }

  void _damageEnemy(
    BattleUnit target,
    int damage, {
    bool grantUltimateCharge = true,
    double fxLife = .24,
    bool showFx = true,
  }) {
    target.hp -= damage;
    if (showFx) {
      _slashes.add(SlashFx(target.position.clone(), fxLife, mercenary.style));
    }
    if (target.hp > 0 || target.dead) return;
    target.dead = true;
    _kills++;
    _xp += target.elite ? 16 : 5;
    if (grantUltimateCharge && _signatureWeaponActive) {
      _ultimateCharge = math.min(
        1,
        _ultimateCharge + (target.elite ? .22 : .07),
      );
    }
  }

  void _levelUp() {
    _xp -= _nextXp;
    _nextXp = (_nextXp * 1.32).roundToDouble();
    _level++;
    _pausedForChoice = true;
    pauseEngine();
    choice.value = BattleChoice([
      UpgradeOption('${weapon.name} 강화', '공격 피해와 공격 속도가 증가합니다.', weapon.id),
      UpgradeOption('${mercenary.race}의 발놀림', '이동속도가 12% 증가합니다.', 'movement'),
      UpgradeOption(mercenary.trait, mercenary.traitDescription, mercenary.id),
    ]);
  }

  void _publishStats() {
    final next = BattleStats(
      hp: mercenary.maxHp.toDouble(),
      level: _level,
      xp: _xp,
      nextXp: _nextXp,
      kills: _kills,
      secondsLeft: (config.durationSeconds - _elapsed).ceil(),
      weaponLevel: _weaponLevel,
      ultimateCharge: _ultimateCharge,
      ultimateEnabled: _signatureWeaponActive,
    );
    final old = stats.value;
    if (old.level != next.level ||
        old.kills != next.kills ||
        old.secondsLeft != next.secondsLeft ||
        (old.ultimateCharge - next.ultimateCharge).abs() > .005 ||
        (old.xp - next.xp).abs() > 1) {
      stats.value = next;
    }
  }

  @override
  void render(Canvas canvas) {
    _drawTerrain(canvas);
    _drawUnits(canvas);
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
      final bob = math.sin(unit.phase) * 1.5;
      final color = unit.ally
          ? const Color(0xff6484a9)
          : (unit.elite ? const Color(0xffd19b49) : const Color(0xff8f3f3b));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(unit.position.x, unit.position.y + 7),
          width: unit.elite ? 18 : 12,
          height: 6,
        ),
        Paint()..color = const Color(0x66000000),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(unit.position.x, unit.position.y + bob),
          width: unit.elite ? 11 : 8,
          height: unit.elite ? 16 : 12,
        ),
        Paint()..color = color,
      );
      canvas.drawCircle(
        Offset(unit.position.x, unit.position.y - 7 + bob),
        unit.elite ? 5 : 3.5,
        Paint()..color = const Color(0xffd0ad8d),
      );
      if (unit.elite) {
        canvas.drawCircle(
          Offset(unit.position.x, unit.position.y),
          13,
          Paint()
            ..color = const Color(0x55e3b75d)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
    for (final fx in _slashes) {
      final progress = 1 - fx.life / fx.maxLife;
      final alpha = (255 * (fx.life / fx.maxLife)).clamp(0, 255).toInt();
      final fxColor = switch (fx.style) {
        CombatStyle.blades => mercenary.visual.accent,
        CombatStyle.greatsword => const Color(0xffd2675b),
        CombatStyle.magic => const Color(0xff71d4e7),
      };
      final paint = Paint()
        ..color = fxColor.withAlpha(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = fx.style == CombatStyle.greatsword ? 7 : 4;
      if (fx.style == CombatStyle.magic) {
        canvas.drawCircle(
          Offset(fx.position.x, fx.position.y),
          18 + progress * 18,
          paint,
        );
      } else {
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(fx.position.x, fx.position.y),
            width: fx.style == CombatStyle.greatsword ? 72 : 50,
            height: fx.style == CombatStyle.greatsword ? 48 : 32,
          ),
          -.8,
          2.2,
          false,
          paint,
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
  });
  Vector2 position;
  bool ally;
  bool elite;
  int hp;
  bool playerAggro;
  double phase = 0;
  double attackClock = 0;
  bool dead = false;
}

class SlashFx {
  SlashFx(this.position, this.life, this.style) : maxLife = life;
  final Vector2 position;
  final CombatStyle style;
  final double maxLife;
  double life;
}
