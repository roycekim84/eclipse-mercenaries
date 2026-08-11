part of '../survivor_game.dart';

extension UltimateSystem on SurvivorGame {
  void _advanceUltimate(double realDt) {
    if (_ultimateClock <= 0 || _pausedForUltimate) return;
    _ultimateClock = math.max(0, _ultimateClock - realDt);
  }

  Iterable<BattleUnit> _ultimateTargets({
    required double range,
    required int limit,
    bool farthestFirst = false,
  }) {
    final targets = _units
        .where(
          (unit) =>
              !unit.dead &&
              !unit.ally &&
              unit.position.x >= -40 &&
              unit.position.y >= -40 &&
              unit.position.x <= size.x + 40 &&
              unit.position.y <= size.y + 40 &&
              unit.position.distanceTo(_player) <= range,
        )
        .toList(growable: false);
    targets.sort((a, b) {
      final comparison = a.position
          .distanceTo(_player)
          .compareTo(b.position.distanceTo(_player));
      return farthestFirst ? -comparison : comparison;
    });
    return targets.take(limit);
  }

  void _damageUltimateTargets(
    Iterable<BattleUnit> targets, {
    required int damage,
    int hits = 1,
    DamageKind kind = DamageKind.physical,
    double criticalChance = 0,
    StatusEffectType status = StatusEffectType.none,
    double statusChance = 0,
  }) {
    var visualIndex = 0;
    final visualLimit = _reducedVisualLoad ? 14 : 42;
    for (final target in targets) {
      for (var hit = 0; hit < hits && !target.dead; hit++) {
        _damageEnemy(
          target,
          damage,
          kind: kind,
          criticalChance: criticalChance,
          status: status,
          statusChance: statusChance,
          grantUltimateCharge: false,
          fxLife: .46,
          showFx: hit == hits - 1 && visualIndex < visualLimit,
          showNumber: hit == hits - 1,
        );
      }
      visualIndex++;
    }
  }

  void _applyUltimateImpact() {
    final fullScreen = math.max(size.x, size.y) * 1.15;
    switch (mercenary.ultimatePattern) {
      case UltimatePattern.lunarFlurry:
        _damageUltimateTargets(
          _ultimateTargets(range: 560, limit: 52),
          damage: 5,
          hits: 4,
          criticalChance: 28,
        );
      case UltimatePattern.bloodMoonRampage:
        _damageUltimateTargets(
          _ultimateTargets(range: 430, limit: 38),
          damage: 22,
          status: StatusEffectType.bleed,
          statusChance: 1,
        );
        _playerHp = math.min(_playerMaxHp, _playerHp + _playerMaxHp * .16);
      case UltimatePattern.foxfireIllusion:
        _damageUltimateTargets(
          _ultimateTargets(range: fullScreen, limit: 64),
          damage: 8,
          hits: 2,
          kind: DamageKind.magical,
          status: StatusEffectType.burn,
          statusChance: .85,
        );
      case UltimatePattern.meteorPursuit:
        _damageUltimateTargets(
          _ultimateTargets(range: fullScreen, limit: 44, farthestFirst: true),
          damage: 19,
          criticalChance: 46,
        );
      case UltimatePattern.goldenSanctuary:
        _damageUltimateTargets(
          _ultimateTargets(range: 340, limit: 36),
          damage: 16,
          kind: DamageKind.pure,
        );
        _playerHp = math.min(_playerMaxHp, _playerHp + _playerMaxHp * .28);
        if (config.battlefield == BattlefieldType.gateDefense) {
          _gateHp = math.min(GateDefenseRules.maxGateHp, _gateHp + 180);
        }
      case UltimatePattern.skyTactics:
        _damageUltimateTargets(
          _ultimateTargets(range: fullScreen, limit: 58),
          damage: 11,
          kind: DamageKind.magical,
          status: StatusEffectType.slow,
          statusChance: 1,
        );
        _tacticalClock = math.max(_tacticalClock, 5);
      case UltimatePattern.earthPiercer:
        final enemies = _ultimateTargets(
          range: fullScreen,
          limit: 80,
          farthestFirst: true,
        ).toList(growable: false);
        if (enemies.isEmpty) return;
        final direction = (enemies.first.position - _player).normalized();
        final pierced = enemies.where((target) {
          final offset = target.position - _player;
          final forward = offset.dot(direction);
          final side = (offset.x * direction.y - offset.y * direction.x).abs();
          return forward >= -24 && forward <= 720 && side <= 72;
        });
        _damageUltimateTargets(
          pierced.take(46),
          damage: 28,
          kind: DamageKind.pure,
        );
      case UltimatePattern.twinMoonSigil:
        _damageUltimateTargets(
          _ultimateTargets(range: fullScreen, limit: 60),
          damage: 9,
          hits: 2,
          kind: DamageKind.magical,
          criticalChance: 22,
          status: StatusEffectType.slow,
          statusChance: .65,
        );
    }
    _triggerImpact(hitStop: .08, impulse: 9);
  }

  Color get _ultimateColor => switch (mercenary.ultimatePattern) {
    UltimatePattern.lunarFlurry => const Color(0xffb58af0),
    UltimatePattern.bloodMoonRampage => const Color(0xffe24d4d),
    UltimatePattern.foxfireIllusion => const Color(0xff65d9ef),
    UltimatePattern.meteorPursuit => const Color(0xffe9d17d),
    UltimatePattern.goldenSanctuary => const Color(0xffffd36e),
    UltimatePattern.skyTactics => const Color(0xffd18bff),
    UltimatePattern.earthPiercer => const Color(0xff64c39a),
    UltimatePattern.twinMoonSigil => const Color(0xffa98cff),
  };

  void _drawUltimateEffect(Canvas canvas) {
    if (_ultimateClock <= 0 || _pausedForUltimate) return;
    final progress = (1 - _ultimateClock / 1.2).clamp(0.0, 1.0);
    final color = _ultimateColor;
    final pulse = math.sin(progress * math.pi).clamp(0.0, 1.0);
    canvas.drawRect(
      Offset.zero & Size(size.x, size.y),
      Paint()..color = color.withValues(alpha: .05 + pulse * .11),
    );
    final paint = Paint()
      ..color = color.withValues(alpha: .3 + pulse * .62)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3 + pulse * 5;
    final center = Offset(_player.x, _player.y);

    switch (mercenary.ultimatePattern) {
      case UltimatePattern.lunarFlurry:
        final count = _reducedVisualLoad ? 7 : 18;
        for (var i = 0; i < count; i++) {
          final phase = i / count;
          final x = size.x * phase + math.sin(progress * 18 + i) * 95;
          final y = size.y * (.12 + phase * .7);
          canvas.drawLine(
            Offset(x - 115, y + 58),
            Offset(x + 115, y - 58),
            paint,
          );
        }
      case UltimatePattern.bloodMoonRampage:
        for (var i = 0; i < 3; i++) {
          canvas.drawArc(
            Rect.fromCircle(
              center: center,
              radius: 90 + i * 74 + progress * 80,
            ),
            -.9 + i * .65,
            2.2,
            false,
            paint..strokeWidth = 12 - i * 2,
          );
        }
      case UltimatePattern.foxfireIllusion:
        final count = _reducedVisualLoad ? 5 : 9;
        for (var i = 0; i < count; i++) {
          final angle = math.pi * 2 * i / count + progress * 3.2;
          final radius = 70 + progress * 180;
          final flame = Offset(
            center.dx + math.cos(angle) * radius,
            center.dy + math.sin(angle) * radius,
          );
          canvas.drawCircle(flame, 13 + pulse * 18, paint);
          canvas.drawLine(center, flame, paint..strokeWidth = 2);
        }
      case UltimatePattern.meteorPursuit:
        final count = _reducedVisualLoad ? 6 : 14;
        for (var i = 0; i < count; i++) {
          final impact = Offset(
            size.x * ((i * .137 + .08) % .86 + .07),
            size.y * ((i * .223 + .16) % .68 + .14),
          );
          canvas.drawLine(
            impact.translate(-130 - progress * 80, -180),
            impact,
            paint..strokeWidth = 4 + (i % 3) * 2,
          );
          canvas.drawCircle(impact, 7 + pulse * 10, paint);
        }
      case UltimatePattern.goldenSanctuary:
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final angle = -math.pi / 2 + math.pi * 2 * i / 6;
          final point =
              center +
              Offset(math.cos(angle), math.sin(angle)) * (95 + progress * 120);
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint..strokeWidth = 9);
        canvas.drawCircle(center, 58 + progress * 130, paint..strokeWidth = 3);
      case UltimatePattern.skyTactics:
        final spacing = _reducedVisualLoad ? 100.0 : 64.0;
        for (double x = -size.y; x < size.x + size.y; x += spacing) {
          canvas.drawLine(
            Offset(x + progress * spacing, 0),
            Offset(x - size.y + progress * spacing, size.y),
            paint..strokeWidth = 2.5,
          );
        }
        canvas.drawCircle(center, 70 + progress * 250, paint..strokeWidth = 5);
      case UltimatePattern.earthPiercer:
        final end = Offset(
          size.x + 80,
          center.dy - 180 * math.sin(progress * math.pi),
        );
        canvas.drawLine(center.translate(-40, 0), end, paint..strokeWidth = 24);
        canvas.drawLine(
          center.translate(-40, 0),
          end,
          Paint()
            ..color = const Color(0xffe7fff2)
            ..strokeWidth = 4,
        );
      case UltimatePattern.twinMoonSigil:
        final radius = 105 + progress * 165;
        canvas.drawArc(
          Rect.fromCircle(center: center.translate(-55, 0), radius: radius),
          -.9,
          1.8,
          false,
          paint..strokeWidth = 9,
        );
        canvas.drawArc(
          Rect.fromCircle(center: center.translate(55, 0), radius: radius),
          math.pi - .9,
          1.8,
          false,
          paint,
        );
        canvas.drawCircle(center, 32 + pulse * 34, paint..strokeWidth = 4);
    }
  }
}
