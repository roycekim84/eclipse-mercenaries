part of '../survivor_game.dart';

extension PooledEffectsSystem on SurvivorGame {
  void _emitSlash(Vector2 position, double life, CombatStyle style) {
    if (!_renderPolicy.emitsSlash(_slashEmissionSequence++)) return;
    final fx = _slashes.firstWhere(
      (candidate) => !candidate.active,
      orElse: () => _slashes.reduce((a, b) => a.life < b.life ? a : b),
    );
    fx
      ..active = true
      ..position.setFrom(position)
      ..style = style
      ..life = life
      ..maxLife = life;
  }

  void _emitDamageNumber(Vector2 position, int amount, bool critical) {
    if (!_renderPolicy.emitsDamageNumber(
      sequence: _damageNumberEmissionSequence++,
      critical: critical,
    )) {
      return;
    }
    final fx = _damageNumbers.firstWhere(
      (candidate) => !candidate.active,
      orElse: () => _damageNumbers.reduce((a, b) => a.life < b.life ? a : b),
    );
    fx
      ..active = true
      ..position.setFrom(position)
      ..amount = amount
      ..critical = critical
      ..life = .72
      ..maxLife = .72
      ..paragraph = _buildDamageParagraph(amount, critical);
  }

  Paragraph _buildDamageParagraph(int amount, bool critical) {
    final builder =
        ParagraphBuilder(
          ParagraphStyle(
            textAlign: TextAlign.center,
            fontSize: critical ? 17 : 12,
            fontWeight: critical ? FontWeight.w800 : FontWeight.w600,
          ),
        )..pushStyle(
          TextStyle(
            color: critical ? const Color(0xffffd36e) : const Color(0xfff0e8d7),
          ),
        );
    builder.addText('$amount');
    return builder.build()..layout(const ParagraphConstraints(width: 48));
  }

  void _launchProjectile({
    required Vector2 origin,
    required BattleUnit target,
    required WeaponPattern pattern,
    required int damage,
    required double speed,
    required double criticalChance,
    int chainRemaining = 0,
    bool appliesDamage = true,
  }) {
    final projectile = _projectiles.firstWhere(
      (candidate) => !candidate.active,
      orElse: () => _projectiles.reduce((a, b) => a.life < b.life ? a : b),
    );
    projectile
      ..active = true
      ..position.setFrom(origin)
      ..previousPosition.setFrom(origin)
      ..target = target
      ..pattern = pattern
      ..damage = damage
      ..speed = speed
      ..criticalChance = criticalChance
      ..chainRemaining = chainRemaining
      ..appliesDamage = appliesDamage
      ..life = 2.4;
  }

  void _updateCombatPools(double dt) {
    var activeEffects = 0;
    for (final fx in _slashes) {
      if (!fx.active) continue;
      fx.life -= dt;
      if (fx.life <= 0) fx.active = false;
      if (fx.active) activeEffects++;
    }
    var activeDamageNumbers = 0;
    for (final number in _damageNumbers) {
      if (!number.active) continue;
      number.life -= dt;
      number.position.y -= 18 * dt;
      if (number.life <= 0) number.active = false;
      if (number.active) activeDamageNumbers++;
    }
    var activeProjectiles = 0;
    for (final projectile in _projectiles) {
      if (!projectile.active) continue;
      projectile.life -= dt;
      final target = projectile.target;
      if (target == null || target.dead || projectile.life <= 0) {
        projectile.active = false;
        continue;
      }
      final delta = target.position - projectile.position;
      final travel = projectile.speed * dt;
      projectile.previousPosition.setFrom(projectile.position);
      if (delta.length <= travel + 10) {
        projectile.position.setFrom(target.position);
        projectile.active = false;
        _impactProjectile(projectile, target);
      } else {
        projectile.position += delta.normalized() * travel;
      }
      if (projectile.active) activeProjectiles++;
    }
    _performanceProfiler.peakEffects = math.max(
      _performanceProfiler.peakEffects,
      activeEffects,
    );
    _performanceProfiler.peakDamageNumbers = math.max(
      _performanceProfiler.peakDamageNumbers,
      activeDamageNumbers,
    );
    _performanceProfiler.peakProjectiles = math.max(
      _performanceProfiler.peakProjectiles,
      activeProjectiles,
    );
  }

  void _impactProjectile(PooledProjectile projectile, BattleUnit target) {
    if (!projectile.appliesDamage) return;
    switch (projectile.pattern) {
      case WeaponPattern.chainFlame || WeaponPattern.featherChain:
        final isFlame = projectile.pattern == WeaponPattern.chainFlame;
        _damageEnemy(
          target,
          projectile.damage,
          kind: isFlame ? DamageKind.magical : DamageKind.physical,
          criticalChance: projectile.criticalChance,
          status: isFlame ? StatusEffectType.burn : StatusEffectType.bleed,
          statusChance: isFlame
              ? .32 + (mercenary.id == 'sera' ? _traitLevel * .06 : 0)
              : .18,
        );
        if (projectile.chainRemaining > 0) {
          final next = _nearestEnemyFrom(
            target.position,
            135,
            excluded: target,
          );
          if (next != null) {
            _launchProjectile(
              origin: target.position,
              target: next,
              pattern: projectile.pattern,
              damage: math.max(1, projectile.damage - 1),
              speed: projectile.speed,
              criticalChance: projectile.criticalChance,
              chainRemaining: projectile.chainRemaining - 1,
            );
          }
        }
      case WeaponPattern.emberBurst:
        for (final unit in _enemiesNear(target.position, 68).take(8)) {
          _damageEnemy(
            unit,
            projectile.damage,
            kind: DamageKind.magical,
            criticalChance: projectile.criticalChance,
            status: StatusEffectType.burn,
            statusChance: .24,
            showFx: identical(unit, target),
          );
        }
      default:
        _damageEnemy(
          target,
          projectile.damage,
          criticalChance: projectile.criticalChance,
          status: projectile.pattern == WeaponPattern.longBow
              ? StatusEffectType.slow
              : StatusEffectType.none,
          statusChance: .18,
        );
    }
    if (_xp >= _nextXp) _requestLevelUp();
  }

  void _drawCombatPools(Canvas canvas) {
    for (final fx in _slashes) {
      if (!fx.active) continue;
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
    for (final projectile in _projectiles) {
      if (!projectile.active) continue;
      final color = switch (projectile.pattern) {
        WeaponPattern.chainFlame => const Color(0xff72d8ee),
        WeaponPattern.emberBurst => const Color(0xffff8a43),
        WeaponPattern.shadowPierce => const Color(0xffa782e8),
        _ => const Color(0xffe6c57a),
      };
      final head = Offset(projectile.position.x, projectile.position.y);
      var trail = Offset(
        projectile.previousPosition.x,
        projectile.previousPosition.y,
      );
      final delta = head - trail;
      if (delta.distance < 12 && delta.distance > 0) {
        trail = head - delta / delta.distance * 20;
      }
      final glow = Paint()
        ..color = color.withValues(alpha: .22)
        ..strokeWidth = projectile.pattern == WeaponPattern.emberBurst ? 12 : 7
        ..strokeCap = StrokeCap.round;
      final core = Paint()
        ..color = color
        ..strokeWidth = projectile.pattern == WeaponPattern.longBow ? 2.2 : 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(trail, head, glow);
      canvas.drawLine(trail, head, core);
      switch (projectile.pattern) {
        case WeaponPattern.emberBurst || WeaponPattern.chainFlame:
          canvas.drawCircle(
            head,
            7,
            Paint()..color = color.withValues(alpha: .25),
          );
          canvas.drawCircle(
            head,
            3.5,
            Paint()..color = const Color(0xfffff0b0),
          );
        case WeaponPattern.shadowPierce:
          final path = Path()
            ..moveTo(head.dx, head.dy - 6)
            ..lineTo(head.dx + 5, head.dy)
            ..lineTo(head.dx, head.dy + 6)
            ..lineTo(head.dx - 5, head.dy)
            ..close();
          canvas.drawPath(path, Paint()..color = color);
        case WeaponPattern.featherChain:
          canvas.drawOval(
            Rect.fromCenter(center: head, width: 11, height: 5),
            Paint()..color = color,
          );
        case WeaponPattern.spiritFamiliar:
          canvas.drawCircle(
            head,
            8,
            Paint()..color = color.withValues(alpha: .2),
          );
          canvas.drawCircle(head, 3, Paint()..color = const Color(0xffffffff));
        default:
          final direction = delta.distance > 0
              ? delta / delta.distance
              : const Offset(1, 0);
          final normal = Offset(-direction.dy, direction.dx);
          final arrow = Path()
            ..moveTo(head.dx, head.dy)
            ..lineTo(
              head.dx - direction.dx * 10 + normal.dx * 3,
              head.dy - direction.dy * 10 + normal.dy * 3,
            )
            ..lineTo(
              head.dx - direction.dx * 10 - normal.dx * 3,
              head.dy - direction.dy * 10 - normal.dy * 3,
            )
            ..close();
          canvas.drawPath(arrow, Paint()..color = color);
      }
    }
    for (final number in _damageNumbers) {
      if (!number.active) continue;
      final paragraph = number.paragraph;
      if (paragraph == null) continue;
      canvas.drawParagraph(
        paragraph,
        Offset(number.position.x - 24, number.position.y - 38),
      );
    }
  }
}
