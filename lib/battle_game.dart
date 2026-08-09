import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart'
    show IconData, Icons, Offset, ValueNotifier;

class BattleStats {
  const BattleStats({
    required this.hp,
    required this.level,
    required this.xp,
    required this.nextXp,
    required this.kills,
    required this.secondsLeft,
    required this.weaponLevel,
  });
  final double hp;
  final int level;
  final double xp;
  final double nextXp;
  final int kills;
  final int secondsLeft;
  final int weaponLevel;
}

class BattleReport {
  const BattleReport({
    required this.time,
    required this.kills,
    required this.gold,
    required this.xp,
  });
  final String time;
  final int kills;
  final int gold;
  final int xp;
}

class UpgradeOption {
  const UpgradeOption(this.title, this.description, this.icon);
  final String title;
  final String description;
  final IconData icon;
}

class BattleChoice {
  const BattleChoice(this.options);
  final List<UpgradeOption> options;
}

class BattleEvent {
  const BattleEvent(this.grade, this.title, this.description);
  final String grade;
  final String title;
  final String description;
}

class SurvivorGame extends FlameGame {
  SurvivorGame({required this.onVictory});
  final void Function(BattleReport) onVictory;
  final stats = ValueNotifier(
    const BattleStats(
      hp: 1320,
      level: 1,
      xp: 0,
      nextXp: 40,
      kills: 0,
      secondsLeft: 45,
      weaponLevel: 1,
    ),
  );
  final choice = ValueNotifier<BattleChoice?>(null);
  final event = ValueNotifier<BattleEvent?>(null);
  final _random = math.Random(19);
  final _units = <BattleUnit>[];
  final _slashes = <SlashFx>[];
  final _spatialGrid = <int, List<int>>{};
  Vector2? _moveTarget;
  late Vector2 _player;
  double _elapsed = 0;
  double _attackClock = 0;
  double _eventClock = 0;
  double _xp = 0;
  double _nextXp = 40;
  double _speed = 150;
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
    for (var i = 0; i < 330; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final radius =
          120 + _random.nextDouble() * math.max(size.x, size.y) * .72;
      _units.add(
        BattleUnit(
          position:
              _player + Vector2(math.cos(angle), math.sin(angle)) * radius,
          ally: i % 7 == 0,
          elite: i % 83 == 0,
          hp: i % 83 == 0 ? 8 : 2,
        ),
      );
    }
  }

  void setMoveTarget(Offset offset) =>
      _moveTarget = Vector2(offset.dx, offset.dy);
  void clearMoveTarget() => _moveTarget = null;

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
    super.update(dt);
    if (_finished || _pausedForChoice) {
      return;
    }
    _elapsed += dt;
    _attackClock += dt;
    _eventClock += dt;
    if (_moveTarget != null) {
      final delta = _moveTarget! - _player;
      if (delta.length > 8) {
        _player += delta.normalized() * math.min(_speed * dt, delta.length);
      }
    }
    _rebuildGrid();
    _updateUnits(dt);
    if (_attackClock > math.max(.16, .46 - _weaponLevel * .035)) {
      _attackClock = 0;
      _attackNearest();
    }
    for (final fx in _slashes) {
      fx.life -= dt;
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
    if (_elapsed >= 45 && !_finished) {
      _finished = true;
      onVictory(
        BattleReport(
          time: '00:45',
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
      final delta = _player - unit.position;
      final distance = delta.length;
      if (distance > size.x * .8) continue; // Off-screen AI throttling.
      final targetDirection = unit.ally
          ? Vector2(
              math.sin(_elapsed + unit.position.x),
              math.cos(_elapsed + unit.position.y),
            )
          : (distance > 1 ? delta / distance : Vector2.zero());
      unit.position +=
          targetDirection * (unit.ally ? 18 : (unit.elite ? 31 : 23)) * dt;
      unit.phase += dt * (unit.elite ? 6 : 4);
      if (!unit.ally && distance < 25) unit.position -= targetDirection * 28;
    }
  }

  void _attackNearest() {
    BattleUnit? nearest;
    var best = 230.0;
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
    final damage = 1 + (_weaponLevel ~/ 2);
    nearest.hp -= damage;
    _slashes.add(SlashFx(nearest.position.clone(), .24));
    if (nearest.hp <= 0) {
      nearest.dead = true;
      _kills++;
      _xp += nearest.elite ? 16 : 5;
      if (_xp >= _nextXp) _levelUp();
    }
  }

  void _levelUp() {
    _xp -= _nextXp;
    _nextXp = (_nextXp * 1.32).roundToDouble();
    _level++;
    _pausedForChoice = true;
    pauseEngine();
    choice.value = const BattleChoice([
      UpgradeOption('월광쌍검 강화', '공격 피해와 참격 속도가 증가합니다.', Icons.auto_fix_high),
      UpgradeOption('묘족의 발놀림', '이동속도가 12% 증가합니다.', Icons.directions_run),
      UpgradeOption('야행성', '치명타 확률과 회피가 증가합니다.', Icons.dark_mode),
    ]);
  }

  void _publishStats() {
    final next = BattleStats(
      hp: 1320,
      level: _level,
      xp: _xp,
      nextXp: _nextXp,
      kills: _kills,
      secondsLeft: (45 - _elapsed).ceil(),
      weaponLevel: _weaponLevel,
    );
    final old = stats.value;
    if (old.level != next.level ||
        old.kills != next.kills ||
        old.secondsLeft != next.secondsLeft ||
        (old.xp - next.xp).abs() > 1) {
      stats.value = next;
    }
  }

  @override
  void render(Canvas canvas) {
    _drawTerrain(canvas);
    _drawUnits(canvas);
    _drawPlayer(canvas);
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
      final alpha = (255 * (fx.life / .24)).clamp(0, 255).toInt();
      final paint = Paint()
        ..color = Color.fromARGB(alpha, 210, 205, 255)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(fx.position.x, fx.position.y),
          width: 50,
          height: 32,
        ),
        -.8,
        2.2,
        false,
        paint,
      );
    }
  }

  void _drawPlayer(Canvas canvas) {
    canvas.drawCircle(
      Offset(_player.x, _player.y + 9),
      16,
      Paint()..color = const Color(0x77000000),
    );
    canvas.drawCircle(
      Offset(_player.x, _player.y),
      14,
      Paint()
        ..color = const Color(0x554d9bf1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(_player.x, _player.y),
        width: 12,
        height: 20,
      ),
      Paint()..color = const Color(0xff39284a),
    );
    canvas.drawCircle(
      Offset(_player.x, _player.y - 12),
      6,
      Paint()..color = const Color(0xffdfb8a4),
    );
    final ears = Path()
      ..moveTo(_player.x - 6, _player.y - 15)
      ..lineTo(_player.x - 5, _player.y - 24)
      ..lineTo(_player.x, _player.y - 16)
      ..moveTo(_player.x + 2, _player.y - 16)
      ..lineTo(_player.x + 6, _player.y - 24)
      ..lineTo(_player.x + 8, _player.y - 15);
    canvas.drawPath(
      ears,
      Paint()
        ..color = const Color(0xff18151e)
        ..style = PaintingStyle.fill,
    );
    final blade = Paint()
      ..color = const Color(0xffded9ea)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(_player.x - 5, _player.y + 2),
      Offset(_player.x - 18, _player.y + 15),
      blade,
    );
    canvas.drawLine(
      Offset(_player.x + 5, _player.y + 2),
      Offset(_player.x + 18, _player.y + 15),
      blade,
    );
  }
}

class BattleUnit {
  BattleUnit({
    required this.position,
    required this.ally,
    required this.elite,
    required this.hp,
  });
  Vector2 position;
  bool ally;
  bool elite;
  int hp;
  double phase = 0;
  bool dead = false;
}

class SlashFx {
  SlashFx(this.position, this.life);
  final Vector2 position;
  double life;
}
