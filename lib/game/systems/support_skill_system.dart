part of '../survivor_game.dart';

extension SupportSkillSystem on SurvivorGame {
  void _updateSupportSkill(double dt) {
    final support = config.supportMercenary;
    if (support == null) return;
    _supportVisualClock = math.max(0, _supportVisualClock - dt);
    _supportSkillClock -= dt;
    if (_supportSkillClock > 0 || _finished || _pausedForUltimate) return;
    final level = config.supportSkillLevel.clamp(1, 5);
    _supportSkillClock = math.max(10, 19 - level * 1.4);
    _supportVisualClock = 1.35;
    final skillName = switch (support.id) {
      'mira' => '응급 전선',
      'garr' => '노병의 방벽',
      'elka' => '공성 해체',
      'soren' => '무흔 표식',
      _ => support.trait,
    };
    event.value = BattleEvent(
      '${support.name} 지원 호출',
      skillName,
      '지원 스킬 Lv.$level 발동',
      id: 'support_call',
    );
    switch (support.id) {
      case 'mira':
        _playerHp = math.min(
          _playerMaxHp,
          _playerHp + _playerMaxHp * (.06 + level * .025),
        );
        if (config.battlefield.usesGate) {
          _gateHp = math.min(
            GateDefenseRules.maxGateHp,
            _gateHp + 24 + level * 18,
          );
        }
      case 'garr':
        _playerInvulnerability = math.max(
          _playerInvulnerability,
          .65 + level * .18,
        );
        _playerHp = math.min(
          _playerMaxHp,
          _playerHp + _playerMaxHp * (.02 + level * .012),
        );
      case 'elka':
        final targets =
            _units
                .where((unit) => !unit.dead && !unit.ally)
                .toList(growable: false)
              ..sort((a, b) {
                final aPriority =
                    a.role == UnitRole.siege || a.role == UnitRole.commander
                    ? 0
                    : 1;
                final bPriority =
                    b.role == UnitRole.siege || b.role == UnitRole.commander
                    ? 0
                    : 1;
                return aPriority.compareTo(bPriority);
              });
        for (final target in targets.take(5 + level * 2)) {
          _damageEnemy(
            target,
            5 + level * 3,
            kind: DamageKind.pure,
            grantUltimateCharge: false,
            showNumber: true,
          );
        }
      case 'soren':
        final targets =
            _units
                .where((unit) => !unit.dead && !unit.ally)
                .toList(growable: false)
              ..sort(
                (a, b) => b.position
                    .distanceTo(_player)
                    .compareTo(a.position.distanceTo(_player)),
              );
        for (final target in targets.take(4 + level * 2)) {
          _damageEnemy(
            target,
            3 + level * 2,
            criticalChance: 12 + level * 5,
            status: StatusEffectType.slow,
            statusChance: 1,
            grantUltimateCharge: false,
          );
        }
    }
    _emitSlash(_player + Vector2(14, -22), .9, CombatStyle.magic);
    _publishStats();
  }

  void _drawSupportSkillEffect(Canvas canvas) {
    final support = config.supportMercenary;
    final image = _supportSpriteImage;
    if (support == null || image == null || _supportVisualClock <= 0) return;
    final progress = 1 - _supportVisualClock / 1.35;
    final alpha = math.sin(progress * math.pi).clamp(0.0, 1.0);
    final center = Offset(_player.x + 66, _player.y - 42);
    canvas.drawCircle(
      center,
      37 + progress * 13,
      Paint()
        ..color = const Color(0xff73d8c4).withValues(alpha: alpha * .22)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      31 + progress * 8,
      Paint()
        ..color = const Color(0xffffd477).withValues(alpha: alpha * .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final columns = support.visual.battleColumns;
    final cellWidth = image.width / columns;
    final cellHeight = image.height / 5;
    final frame = support.visual.battleFrameIndices.first.first;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(frame * cellWidth, 0, cellWidth, cellHeight),
      Rect.fromCenter(center: center.translate(0, -9), width: 58, height: 72),
      Paint()
        ..filterQuality = FilterQuality.none
        ..color = Color.fromRGBO(255, 255, 255, alpha),
    );
  }
}
