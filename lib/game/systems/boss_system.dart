part of '../survivor_game.dart';

extension BossSystem on SurvivorGame {
  void _updateBossPatterns(double dt) {
    if (_bossPhaseBannerClock > 0) {
      _bossPhaseBannerClock = math.max(0, _bossPhaseBannerClock - dt);
      if (_bossPhaseBannerClock <= 0 &&
          event.value?.id == 'boss_phase_$_bossPhase') {
        event.value = null;
      }
    }
    final boss = _enemyCommander;
    if (boss == null || boss.dead || boss.archetype?.rank != EnemyRank.boss) {
      if (bossTelegraph.value != null) bossTelegraph.value = null;
      return;
    }
    final hpRatio = boss.hp / boss.maxHp;
    final nextPhase = hpRatio > .66
        ? 1
        : hpRatio > .33
        ? 2
        : 3;
    if (nextPhase != _bossPhase) {
      _bossPhase = nextPhase;
      unawaited(GameAudioFeedback.cue(AudioCue.bossPhase, audioSettings));
      event.value = BattleEvent(
        '${boss.archetype!.name} · PHASE $_bossPhase',
        _bossPhase == 2 ? '전선 압박 강화' : '최후 공세',
        _bossPhase == 2 ? '패턴 간격이 짧아집니다.' : '패턴과 증원 규모가 최대가 됩니다.',
        id: 'boss_phase_$_bossPhase',
      );
      _bossPhaseBannerClock = 2.2;
    }
    if (_activeBossPattern == null) {
      _bossPatternClock -= dt;
      if (_bossPatternClock <= 0) _beginBossPattern(boss);
      return;
    }
    _bossTelegraphClock -= dt;
    _bossUiClock -= dt;
    if (_bossUiClock <= 0) {
      _bossUiClock = .08;
      bossTelegraph.value = BossTelegraph(
        bossName: boss.archetype!.name,
        pattern: _activeBossPattern!,
        phase: _bossPhase,
        secondsLeft: math.max(0, _bossTelegraphClock),
      );
    }
    if (_bossTelegraphClock <= 0) _resolveBossPattern(boss);
  }

  void _beginBossPattern(BattleUnit boss) {
    final patterns = BossPatternCatalog.forBoss(boss.archetype!.id);
    _activeBossPattern = patterns[_bossPatternIndex % patterns.length];
    _bossPatternIndex++;
    _bossTelegraphClock = _activeBossPattern!.telegraphSeconds;
    _bossUiClock = 0;
    _bossPatternTarget = _activeBossPattern!.type == BossPatternType.commandWave
        ? (config.battlefield.usesGate
              ? _gatePosition.clone()
              : _player.clone())
        : _player.clone();
  }

  void _resolveBossPattern(BattleUnit boss) {
    final pattern = _activeBossPattern!;
    final target = _bossPatternTarget ?? _player;
    switch (pattern.type) {
      case BossPatternType.chargeLine:
        final hit = _distanceToSegment(_player, boss.position, target) <= 34;
        if (hit) {
          _damagePlayer(82 + _bossPhase * 18, invulnerabilitySeconds: .5);
        }
        boss.position.setFrom(target);
        _emitSlash(target, .5, CombatStyle.greatsword);
      case BossPatternType.bombardment:
        if (_player.distanceTo(target) <= 76) {
          _damagePlayer(
            72 + _bossPhase * 16,
            invulnerabilitySeconds: .55,
            style: CombatStyle.magic,
          );
        }
        _emitSlash(target, .65, CombatStyle.magic);
      case BossPatternType.commandWave:
        final count = 5 + _bossPhase * 3;
        _spawnEventWave(
          count: count,
          archetypeId: switch (boss.archetype!.id) {
            'hunt_captain' => 'free_skirmisher',
            'forest_warlord' => 'fog_stalker',
            'frost_castellan' => 'frost_mage',
            'dusk_general' => 'cinder_hexer',
            _ => 'siege_ram',
          },
        );
        if (config.battlefield.usesGate) {
          _gateHp = math.max(0, _gateHp - 8 * _bossPhase);
        }
    }
    bossTelegraph.value = null;
    _activeBossPattern = null;
    _bossPatternTarget = null;
    _bossPatternClock = switch (_bossPhase) {
      1 => 5.8,
      2 => 4.6,
      _ => 3.6,
    };
  }

  double _distanceToSegment(Vector2 point, Vector2 start, Vector2 end) {
    final line = end - start;
    if (line.length2 <= .01) return point.distanceTo(start);
    final t = ((point - start).dot(line) / line.length2).clamp(0.0, 1.0);
    return point.distanceTo(start + line * t);
  }

  void _drawBossTelegraph(Canvas canvas) {
    final pattern = _activeBossPattern;
    final boss = _enemyCommander;
    final target = _bossPatternTarget;
    if (pattern == null || boss == null || target == null) return;
    final pulse = .5 + math.sin(_elapsed * 10).abs() * .28;
    final paint = Paint()
      ..color = const Color(0xffef493f).withValues(alpha: pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = reducedEffects.value ? 2.5 : 3.5;
    switch (pattern.type) {
      case BossPatternType.chargeLine:
        canvas.drawLine(
          Offset(boss.position.x, boss.position.y),
          Offset(target.x, target.y),
          Paint()
            ..color = const Color(0xffef493f).withValues(alpha: .16)
            ..strokeWidth = 58
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          Offset(boss.position.x, boss.position.y),
          Offset(target.x, target.y),
          paint,
        );
      case BossPatternType.bombardment:
        canvas.drawCircle(
          Offset(target.x, target.y),
          70,
          Paint()..color = const Color(0xffef493f).withValues(alpha: .14),
        );
        canvas.drawCircle(Offset(target.x, target.y), 70, paint);
        canvas.drawCircle(
          Offset(target.x, target.y),
          18,
          paint..strokeWidth = 2,
        );
      case BossPatternType.commandWave:
        final edgeX = size.x * .78;
        final band = Rect.fromLTRB(
          edgeX - 34,
          _combatTop,
          edgeX + 34,
          _combatBottom,
        );
        canvas.drawRect(
          band,
          Paint()
            ..shader = Gradient.linear(
              band.centerLeft,
              band.centerRight,
              const [Color(0x00ef493f), Color(0x66ef493f)],
            ),
        );
        canvas.drawLine(band.topLeft, band.bottomLeft, paint);
        for (var i = 1; i <= 3; i++) {
          final y = band.top + band.height * i / 4;
          final arrow = Path()
            ..moveTo(edgeX + 18, y - 10)
            ..lineTo(edgeX - 5, y)
            ..lineTo(edgeX + 18, y + 10)
            ..close();
          canvas.drawPath(arrow, Paint()..color = const Color(0xddef6a5f));
        }
    }
  }
}
