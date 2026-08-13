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
        if (config.battlefield.usesGate) {
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
    final center = Offset(_player.x, _player.y);
    final index = mercenary.ultimatePattern.index;
    final column = index % 4;
    final row = index ~/ 4;
    final cellWidth = _ultimateVfxAtlas.width / 4;
    final cellHeight = _ultimateVfxAtlas.height / 2;
    final source = Rect.fromLTWH(
      column * cellWidth + 4,
      row * cellHeight + 4,
      cellWidth - 8,
      cellHeight - 8,
    );
    final baseExtent =
        math.min(size.x, size.y) * (_reducedVisualLoad ? .72 : .92);
    final eased = 1 - math.pow(1 - progress, 3).toDouble();
    final impactScale = .72 + eased * .32;
    final destination = Rect.fromCenter(
      center: center.translate(0, -18),
      width: baseExtent * impactScale,
      height: baseExtent * .72 * impactScale,
    );
    canvas.drawImageRect(
      _ultimateVfxAtlas,
      source,
      destination,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..blendMode = BlendMode.screen
        ..color = Color.fromRGBO(255, 255, 255, .42 + pulse * .58),
    );
    if (!_reducedVisualLoad && progress > .38) {
      final echo = Rect.fromCenter(
        center: center.translate(0, -12),
        width: baseExtent * (1.02 + progress * .26),
        height: baseExtent * .72 * (1.02 + progress * .26),
      );
      canvas.drawImageRect(
        _ultimateVfxAtlas,
        source,
        echo,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..blendMode = BlendMode.screen
          ..color = color.withValues(alpha: (1 - progress) * .24),
      );
    }
  }
}
