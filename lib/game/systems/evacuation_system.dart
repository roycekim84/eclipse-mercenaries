part of '../survivor_game.dart';

extension EvacuationSystem on SurvivorGame {
  int get _escortAlive =>
      _escorts.where((escort) => !escort.dead && !escort.escaped).length;

  int get _escortEscaped => _escorts.where((escort) => escort.escaped).length;

  void _spawnEvacuationConvoy() {
    for (var i = 0; i < EvacuationRules.totalEscorts; i++) {
      final supplyCart = i % 4 == 0;
      _escorts.add(
        EscortUnit(
          position: Vector2(
            95 - (i % 4) * 24,
            size.y * .28 + (i ~/ 4) * 78 + (i % 2) * 20,
          ),
          lane: i % 3,
          maxHp: supplyCart ? 42 : 30,
          speed: supplyCart ? 31 : 36 + (i % 3),
          supplyCart: supplyCart,
        ),
      );
    }
    _peakActiveUnits = _units.length + _escorts.length;
  }

  void _updateEvacuation(double dt) {
    final exitX = size.x - 76;
    for (final escort in _escorts) {
      if (escort.dead || escort.escaped) continue;
      escort.hitFlash = math.max(0, escort.hitFlash - dt);
      final progress = (escort.position.x / size.x).clamp(0.0, 1.0);
      final laneOffset = (escort.lane - 1) * size.y * .08;
      final targetY = size.y * (.78 - progress * .56) + laneOffset;
      final direction = Vector2(
        1,
        ((targetY + math.sin(_elapsed * .8 + escort.lane) * 18) -
                escort.position.y) /
            120,
      ).normalized();
      final windSpeed = config.condition == BattlefieldCondition.ashWind
          ? .94
          : 1.0;
      final tacticalSpeed = _tacticalClock > 0 ? 1.35 : 1.0;
      escort.position.add(
        direction * escort.speed * windSpeed * tacticalSpeed * dt,
      );
      if (escort.position.x >= exitX) escort.escaped = true;
    }
  }

  bool _updatePursuer(BattleUnit unit, double dt) {
    EscortUnit? target;
    var best = double.infinity;
    for (final escort in _escorts) {
      if (escort.dead || escort.escaped) continue;
      final distance = unit.position.distanceTo(escort.position);
      if (distance < best) {
        best = distance;
        target = escort;
      }
    }
    if (target == null) return false;
    final attackRange = UnitRoleRules.attackRange(unit.role).clamp(22, 110);
    if (best > attackRange) {
      _moveToward(
        unit,
        target.position,
        dt,
        speedMultiplier: unit.role == UnitRole.cavalry ? 1.08 : .92,
      );
      return true;
    }
    if (unit.attackClock <= 0) {
      unit.attackClock = unit.role == UnitRole.siege ? 1.8 : 1.15;
      final damage =
          (UnitRoleRules.damage(unit.role) +
                  (unit.archetype?.damageBonus ?? 0) +
                  _enemyDamageBonus +
                  (unit.archetype?.ability == EnemyAbility.blast ? 3 : 0))
              .clamp(1, 6);
      target.hp -= damage;
      target.hitFlash = .14;
      _emitSlash(target.position, .18, CombatStyle.greatsword);
      if (target.hp <= 0) target.dead = true;
    }
    return true;
  }

  void _drawEvacuationObjective(Canvas canvas) {
    final road = Path()
      ..moveTo(0, size.y * .78)
      ..cubicTo(
        size.x * .3,
        size.y * .68,
        size.x * .67,
        size.y * .32,
        size.x,
        size.y * .22,
      );
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0x18554735)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 78,
    );
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0x886f624a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final exitRect = Rect.fromLTWH(size.x - 112, 22, 88, size.y - 44);
    canvas.drawRect(exitRect, Paint()..color = const Color(0x183f87a1));
    canvas.drawLine(
      Offset(size.x - 112, 22),
      Offset(size.x - 112, size.y - 22),
      Paint()
        ..color = const Color(0xaad8bd75)
        ..strokeWidth = 2,
    );
    _drawSpawnMarker(canvas, Offset(size.x - 104, 34), const Color(0xff72a8c5));

    for (final escort in _escorts) {
      if (escort.dead || escort.escaped) continue;
      final position = Offset(escort.position.x, escort.position.y);
      final flash = escort.hitFlash > 0;
      canvas.drawOval(
        Rect.fromCenter(center: position.translate(0, 9), width: 32, height: 8),
        Paint()..color = const Color(0x66000000),
      );
      if (escort.supplyCart) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: position, width: 28, height: 15),
            const Radius.circular(4),
          ),
          Paint()
            ..color = flash ? const Color(0xffd9ba8b) : const Color(0xff69472f),
        );
        canvas.drawLine(
          position.translate(-12, -5),
          position.translate(16, -5),
          Paint()
            ..color = const Color(0xffa77d4f)
            ..strokeWidth = 2,
        );
        canvas.drawCircle(
          position.translate(-7, -5),
          4,
          Paint()..color = const Color(0xff8f7150),
        );
        canvas.drawCircle(
          position.translate(3, -5),
          4,
          Paint()..color = const Color(0xff806243),
        );
        canvas.drawCircle(
          position.translate(-10, 12),
          5,
          Paint()..color = const Color(0xff27231e),
        );
        canvas.drawCircle(
          position.translate(10, 12),
          5,
          Paint()..color = const Color(0xff27231e),
        );
      } else {
        canvas.drawCircle(
          position.translate(0, -9),
          4,
          Paint()
            ..color = flash ? const Color(0xffffd7ad) : const Color(0xffb78d6d),
        );
        final cloak = Path()
          ..moveTo(position.dx, position.dy - 5)
          ..lineTo(position.dx - 7, position.dy + 12)
          ..lineTo(position.dx + 7, position.dy + 12)
          ..close();
        canvas.drawPath(
          cloak,
          Paint()
            ..color = flash ? const Color(0xffa9c3cf) : const Color(0xff425e71),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: position.translate(-5, 2),
            width: 8,
            height: 13,
          ),
          Paint()
            ..color = const Color(0xff263b49)
            ..style = PaintingStyle.fill,
        );
        canvas.drawLine(
          position.translate(2, -4),
          position.translate(8, 10),
          Paint()
            ..color = const Color(0xffb7aa8d)
            ..strokeWidth = 1.5,
        );
      }
      final ratio = (escort.hp / escort.maxHp).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(position.dx - 15, position.dy - 24, 30, 3),
        Paint()..color = const Color(0xaa090b0c),
      );
      canvas.drawRect(
        Rect.fromLTWH(position.dx - 15, position.dy - 24, 30 * ratio, 3),
        Paint()
          ..color = ratio > .35
              ? const Color(0xff67b887)
              : const Color(0xffd05b54),
      );
    }
  }
}

class EscortUnit {
  EscortUnit({
    required this.position,
    required this.lane,
    required this.maxHp,
    required this.speed,
    required this.supplyCart,
  }) : hp = maxHp.toDouble();

  final Vector2 position;
  final int lane;
  final int maxHp;
  final double speed;
  final bool supplyCart;
  double hp;
  double hitFlash = 0;
  bool dead = false;
  bool escaped = false;
}
