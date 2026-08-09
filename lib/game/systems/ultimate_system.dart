part of '../survivor_game.dart';

extension UltimateSystem on SurvivorGame {
  void _advanceUltimate(double realDt) {
    if (_ultimateClock <= 0) return;
    _ultimateClock -= realDt;
    if (!_ultimateImpactApplied && _ultimateClock <= 1.18) {
      _ultimateImpactApplied = true;
      _applyUltimateImpact();
    }
    if (_ultimateClock <= 0) {
      _ultimateClock = 0;
      ultimate.value = null;
    }
  }

  void _applyUltimateImpact() {
    final candidates = _units.where(
      (unit) =>
          !unit.dead &&
          !unit.ally &&
          unit.position.x >= -40 &&
          unit.position.y >= -40 &&
          unit.position.x <= size.x + 40 &&
          unit.position.y <= size.y + 40,
    );
    final targetLimit = switch (mercenary.style) {
      CombatStyle.blades => 48,
      CombatStyle.greatsword => 36,
      CombatStyle.magic => 64,
    };
    final visualLimit = switch (mercenary.style) {
      CombatStyle.blades => reducedEffects.value ? 18 : 48,
      CombatStyle.greatsword => reducedEffects.value ? 14 : 36,
      CombatStyle.magic => reducedEffects.value ? 20 : 64,
    };
    final range = switch (mercenary.style) {
      CombatStyle.blades => 520.0,
      CombatStyle.greatsword => 360.0,
      CombatStyle.magic => math.max(size.x, size.y),
    };
    final damage = switch (mercenary.style) {
      CombatStyle.blades => 10,
      CombatStyle.greatsword => 14,
      CombatStyle.magic => 11,
    };
    var index = 0;
    for (final target
        in candidates
            .where((unit) => unit.position.distanceTo(_player) <= range)
            .take(targetLimit)) {
      _damageEnemy(
        target,
        damage,
        grantUltimateCharge: false,
        fxLife: .7,
        showFx: index < visualLimit,
      );
      index++;
    }
  }

  void _drawUltimateEffect(Canvas canvas) {
    if (_ultimateClock <= 0) return;
    final progress = (1 - _ultimateClock / 2.4).clamp(0.0, 1.0);
    final color = switch (mercenary.style) {
      CombatStyle.blades => const Color(0xffb58af0),
      CombatStyle.greatsword => const Color(0xffd64b45),
      CombatStyle.magic => const Color(0xff65d9ef),
    };
    canvas.drawRect(
      Offset.zero & Size(size.x, size.y),
      Paint()..color = color.withValues(alpha: progress < .5 ? .12 : .06),
    );
    if (!_ultimateImpactApplied) return;
    final paint = Paint()
      ..color = color.withValues(alpha: .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = mercenary.style == CombatStyle.greatsword ? 12 : 5;
    if (mercenary.style == CombatStyle.greatsword) {
      canvas.drawCircle(
        Offset(_player.x, _player.y),
        80 + progress * 310,
        paint,
      );
      return;
    }
    if (mercenary.style == CombatStyle.magic) {
      final count = reducedEffects.value ? 3 : 9;
      for (var i = 0; i < count; i++) {
        final angle = math.pi * 2 * i / count + progress * 2;
        final center = Offset(
          _player.x + math.cos(angle) * (70 + progress * 120),
          _player.y + math.sin(angle) * (70 + progress * 120),
        );
        canvas.drawCircle(center, 22 + progress * 26, paint);
      }
      return;
    }
    final count = reducedEffects.value ? 6 : 16;
    for (var i = 0; i < count; i++) {
      final phase = i / count;
      final x = size.x * phase + math.sin(progress * 14 + i) * 80;
      canvas.drawLine(
        Offset(x - 90, size.y * (.15 + phase * .65)),
        Offset(x + 90, size.y * (.05 + phase * .65)),
        paint,
      );
    }
  }
}
