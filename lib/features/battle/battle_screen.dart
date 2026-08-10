part of '../../app/game_app.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({
    super.key,
    required this.contract,
    required this.mercenary,
    required this.weapon,
    required this.mercenaryProgress,
    required this.weaponProgress,
    required this.reducedEffects,
    required this.performanceMode,
    required this.screenShakeEnabled,
    required this.inputMode,
    required this.targetPriority,
    required this.gearBonus,
    required this.onVictory,
    required this.onExit,
  });
  final BattlefieldContract contract;
  final MercenarySpec mercenary;
  final WeaponSpec weapon;
  final MercenaryProgress mercenaryProgress;
  final WeaponProgress weaponProgress;
  final bool reducedEffects;
  final bool performanceMode;
  final bool screenShakeEnabled;
  final BattleInputMode inputMode;
  final AutoTargetPriority targetPriority;
  final GearCombatBonus gearBonus;
  final ValueChanged<BattleReport> onVictory;
  final VoidCallback onExit;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>
    with WidgetsBindingObserver {
  late final SurvivorGame game;

  @override
  void initState() {
    super.initState();
    game = SurvivorGame(
      config: BattleConfig(
        mercenary: widget.mercenary,
        weapon: widget.weapon,
        battlefield: widget.contract.battlefield,
        condition: widget.contract.condition,
        objective: widget.contract.objective,
        contractId: widget.contract.id,
        contractName: widget.contract.name,
        contractGold: widget.contract.reward,
        contractXp: widget.contract.xp,
        mercenaryPermanentLevel: widget.mercenaryProgress.level,
        weaponPermanentLevel: widget.weaponProgress.level,
        weaponGrowthStage: widget.weaponProgress.stage,
        gearBonus: widget.gearBonus,
      ),
      onVictory: widget.onVictory,
      targetPriority: widget.targetPriority,
      screenShakeEnabled: widget.screenShakeEnabled,
    );
    game.reducedEffects.value = widget.reducedEffects;
    game.performanceMode.value = widget.performanceMode;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      game.resumeFromLifecycle();
    } else {
      game.pauseForLifecycle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: GameWidget(game: game)),
        if (widget.inputMode != BattleInputMode.virtualStick)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (d) => game.setMoveTarget(d.localPosition),
              onPanUpdate: (d) => game.setMoveTarget(d.localPosition),
              onPanEnd: (_) => game.clearMoveTarget(),
              onTapDown: (d) => game.setMoveTarget(d.localPosition),
              onTapUp: (_) => game.clearMoveTarget(),
            ),
          ),
        SafeArea(
          child: ValueListenableBuilder<BattleStats>(
            valueListenable: game.stats,
            builder: (context, value, _) => ValueListenableBuilder(
              valueListenable: game.controls,
              builder: (context, controls, _) => BattleHud(
                contract: widget.contract,
                mercenary: widget.mercenary,
                weapon: widget.weapon,
                stats: value,
                controls: controls,
                onUltimate: game.triggerUltimate,
                onDash: game.triggerDash,
                onTactical: game.triggerTacticalAction,
                onMove: game.setMoveDirection,
                onMoveEnd: game.clearMoveDirection,
                showJoystick: widget.inputMode != BattleInputMode.touch,
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: SafeArea(
            child: Row(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: game.reducedEffects,
                  builder: (context, reduced, _) => SmallIconButton(
                    icon: reduced ? Icons.blur_off : Icons.blur_on,
                    onTap: game.toggleReducedEffects,
                  ),
                ),
                const SizedBox(width: 6),
                ValueListenableBuilder<bool>(
                  valueListenable: game.combatPaused,
                  builder: (context, paused, _) => SmallIconButton(
                    icon: paused ? Icons.play_arrow : Icons.pause,
                    onTap: game.toggleCombatPause,
                  ),
                ),
                const SizedBox(width: 6),
                SmallIconButton(icon: Icons.close, onTap: widget.onExit),
              ],
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 66,
          child: SafeArea(
            child: ValueListenableBuilder<BattleStats>(
              valueListenable: game.stats,
              builder: (context, stats, _) =>
                  BattleMiniMap(contract: widget.contract, stats: stats),
            ),
          ),
        ),
        ValueListenableBuilder<BattleChoice?>(
          valueListenable: game.choice,
          builder: (context, choice, _) => choice == null
              ? const SizedBox.shrink()
              : LevelUpOverlay(choice: choice, onPick: game.selectUpgrade),
        ),
        ValueListenableBuilder<BattleEvent?>(
          valueListenable: game.event,
          builder: (context, event, _) => event == null
              ? const SizedBox.shrink()
              : EventBanner(event: event),
        ),
        ValueListenableBuilder<BossTelegraph?>(
          valueListenable: game.bossTelegraph,
          builder: (context, warning, _) => warning == null
              ? const SizedBox.shrink()
              : BossWarningBanner(warning: warning),
        ),
        ValueListenableBuilder<BattlefieldEventSpec?>(
          valueListenable: game.eventPrompt,
          builder: (context, prompt, _) => prompt == null
              ? const SizedBox.shrink()
              : BattlefieldEventChoiceOverlay(
                  event: prompt,
                  onPick: game.selectBattlefieldEventChoice,
                ),
        ),
        ValueListenableBuilder<UltimateSequence?>(
          valueListenable: game.ultimate,
          builder: (context, sequence, _) => sequence == null
              ? const SizedBox.shrink()
              : UltimateCutIn(
                  key: ValueKey(sequence.activation),
                  sequence: sequence,
                  mercenary: widget.mercenary,
                ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: game.combatPaused,
          builder: (context, paused, _) => paused
              ? BattlePauseOverlay(onResume: game.toggleCombatPause)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class BossWarningBanner extends StatelessWidget {
  const BossWarningBanner({super.key, required this.warning});

  final BossTelegraph warning;

  @override
  Widget build(BuildContext context) {
    final dense = MediaQuery.sizeOf(context).height < 500;
    return Positioned(
      top: dense ? 34 : 42,
      left: 0,
      right: 0,
      child: SafeArea(
        child: IgnorePointer(
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: dense ? 320 : 390),
              padding: EdgeInsets.symmetric(
                horizontal: dense ? 11 : 18,
                vertical: dense ? 5 : 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xe6190c12),
                border: Border.all(color: const Color(0xffdc594c), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x88000000), blurRadius: 12),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xffff7a66),
                    size: dense ? 18 : 22,
                  ),
                  SizedBox(width: dense ? 6 : 9),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${warning.bossName} · PHASE ${warning.phase} · ${warning.pattern.name}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xffffd0bd),
                            fontSize: dense ? 9 : 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${warning.pattern.warning}  ${warning.secondsLeft.toStringAsFixed(1)}초',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: dense ? 8 : 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BattlePauseOverlay extends StatelessWidget {
  const BattlePauseOverlay({super.key, required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xaa080a0f),
        child: Center(
          child: GoldPanel(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.hourglass_top,
                    size: 30,
                    color: Color(0xffd6bd81),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '전투 일시정지',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 22,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '전장 시간과 모든 전투 처리가 멈췄습니다.',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 190,
                    child: FantasyButton(
                      label: '전투 계속',
                      icon: Icons.play_arrow,
                      prominent: true,
                      onTap: onResume,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BattleHud extends StatelessWidget {
  const BattleHud({
    super.key,
    required this.contract,
    required this.mercenary,
    required this.weapon,
    required this.stats,
    required this.controls,
    required this.onUltimate,
    required this.onDash,
    required this.onTactical,
    required this.onMove,
    required this.onMoveEnd,
    required this.showJoystick,
  });
  final BattlefieldContract contract;
  final MercenarySpec mercenary;
  final WeaponSpec weapon;
  final BattleStats stats;
  final BattleControlState controls;
  final VoidCallback onUltimate;
  final VoidCallback onDash;
  final VoidCallback onTactical;
  final ValueChanged<Offset> onMove;
  final VoidCallback onMoveEnd;
  final bool showJoystick;

  @override
  Widget build(BuildContext context) {
    final seconds = stats.secondsLeft.clamp(0, 999);
    final screenSize = MediaQuery.sizeOf(context);
    final dense = screenSize.height < 500;
    final compact = screenSize.width < 1100 || dense;
    return Stack(
      children: [
        Positioned(
          left: dense ? 8 : 12,
          top: dense ? 5 : 8,
          child: SizedBox(
            width: dense ? 205 : 230,
            child: HudPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: dense ? 15 : 18,
                        backgroundColor: mercenary.visual.color,
                        child: Icon(
                          mercenary.visual.icon,
                          color: mercenary.visual.accent,
                          size: dense ? 17 : 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LV.${stats.level}  ${mercenary.name}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: dense ? 10 : 12,
                              ),
                            ),
                            Meter(
                              value: stats.hp / mercenary.maxHp,
                              color: const Color(0xff55b16d),
                            ),
                            Meter(
                              value: stats.xp / stats.nextXp,
                              color: const Color(0xff5da6d8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: dense ? 4 : 8),
                  Text(
                    '임무  ${contract.name}',
                    style: TextStyle(
                      color: Color(0xffd5bc83),
                      fontSize: dense ? 9 : 11,
                    ),
                  ),
                  Text(switch (contract.objective) {
                    ContractObjective.evacuation =>
                      '부상병 ${EvacuationRules.requiredEscaped}명 탈출',
                    ContractObjective.supplyEscort =>
                      '보급대 ${EvacuationRules.requiredEscaped}명 호위',
                    ContractObjective.assassination => '적 지휘관 제거',
                    ContractObjective.ambush => '적 병력 120명 격파',
                    ContractObjective.fortressRetake => '지휘관 격파 · 80명 소탕',
                    ContractObjective.defense => '성문 방어선 유지',
                  }, style: TextStyle(fontSize: dense ? 9 : 11)),
                  SizedBox(height: dense ? 2 : 5),
                  Row(
                    children: [
                      Icon(
                        contract.battlefield == BattlefieldType.evacuation
                            ? Icons.local_shipping_outlined
                            : Icons.castle_outlined,
                        size: 13,
                        color: const Color(0xffd7bd7c),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          contract.battlefield == BattlefieldType.evacuation
                              ? '탈출 ${stats.escortEscaped} / ${stats.escortTotal}'
                              : '북문 ${switch (GateDefenseRules.damageStage(stats.gateHp)) {
                                  ObjectiveDamageStage.secure => '안정',
                                  ObjectiveDamageStage.damaged => '파손',
                                  ObjectiveDamageStage.critical => '붕괴 위험',
                                }}  ${stats.gateHp.ceil()} / ${stats.gateMaxHp.ceil()}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      Text(
                        contract.battlefield == BattlefieldType.evacuation
                            ? '생존 ${stats.escortAlive}'
                            : '전선 ${(stats.frontPressure * 100).round()}%',
                        style: TextStyle(
                          fontSize: 9,
                          color: stats.frontPressure > .6
                              ? const Color(0xffff756b)
                              : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  Meter(
                    value: contract.battlefield == BattlefieldType.evacuation
                        ? stats.escortEscaped / EvacuationRules.requiredEscaped
                        : stats.gateHp / stats.gateMaxHp,
                    color:
                        (contract.battlefield == BattlefieldType.evacuation
                            ? stats.escortAlive + stats.escortEscaped >=
                                  EvacuationRules.requiredEscaped
                            : stats.gateHp / stats.gateMaxHp > .35)
                        ? const Color(0xff60b875)
                        : const Color(0xffd2554e),
                  ),
                  if (!dense) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        CommanderStatus(
                          ally: true,
                          alive: stats.allyCommanderAlive,
                        ),
                        const SizedBox(width: 8),
                        CommanderStatus(
                          ally: false,
                          alive: stats.enemyCommanderAlive,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: dense ? 4 : 10,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '00:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: dense ? 19 : 22,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(blurRadius: 8, color: Colors.black)],
              ),
            ),
          ),
        ),
        if (showJoystick)
          Positioned(
            left: 12,
            bottom: 12,
            child: BattleJoystick(onMove: onMove, onEnd: onMoveEnd),
          ),
        Positioned(
          right: 14,
          bottom: 10,
          child: Row(
            children: [
              BattleActionOrb(
                icon: Icons.double_arrow,
                label: '대시',
                cooldown: controls.dashCooldown,
                maxCooldown: BattleControlRules.dashCooldownSeconds,
                color: const Color(0xff507aa1),
                onTap: onDash,
              ),
              BattleActionOrb(
                icon: contract.battlefield == BattlefieldType.evacuation
                    ? Icons.directions_run
                    : Icons.flag,
                label: contract.battlefield == BattlefieldType.evacuation
                    ? '강행군'
                    : '집결',
                cooldown: controls.tacticalCooldown,
                maxCooldown: BattleControlRules.tacticalCooldownSeconds,
                active: controls.tacticalActive,
                color: const Color(0xffb58a42),
                onTap: onTactical,
              ),
              for (final entry in stats.build.take(compact ? 2 : 6))
                SkillOrb(
                  icon: entry.kind == RunUpgradeKind.weapon
                      ? gameContent.weaponById(entry.id).visual.icon
                      : gameIcon(entry.id),
                  label: entry.level >= entry.maxLevel
                      ? 'MAX'
                      : 'LV.${entry.level}',
                ),
              UltimateOrb(
                charge: stats.ultimateCharge,
                enabled: stats.ultimateEnabled,
                color: mercenary.visual.accent,
                onTap: onUltimate,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BattleJoystick extends StatefulWidget {
  const BattleJoystick({super.key, required this.onMove, required this.onEnd});

  final ValueChanged<Offset> onMove;
  final VoidCallback onEnd;

  @override
  State<BattleJoystick> createState() => _BattleJoystickState();
}

class _BattleJoystickState extends State<BattleJoystick> {
  static const _size = 76.0;
  static const _travel = 24.0;
  Offset _knob = Offset.zero;

  void _update(Offset localPosition) {
    final delta = localPosition - const Offset(_size / 2, _size / 2);
    final distance = delta.distance;
    final clamped = distance > _travel ? delta / distance * _travel : delta;
    setState(() => _knob = clamped);
    widget.onMove(clamped / _travel);
  }

  void _end() {
    setState(() => _knob = Offset.zero);
    widget.onEnd();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: '이동 조이스틱',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) => _update(details.localPosition),
      onPanUpdate: (details) => _update(details.localPosition),
      onPanEnd: (_) => _end(),
      onPanCancel: _end,
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x9910141b),
          border: Border.all(color: const Color(0xaac7a460), width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
        ),
        child: Center(
          child: Transform.translate(
            offset: _knob,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xff8095aa), Color(0xff263543)],
                ),
                border: Border.all(color: const Color(0xffd7c28e)),
              ),
              child: const Icon(
                Icons.control_camera,
                size: 17,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class BattleActionOrb extends StatelessWidget {
  const BattleActionOrb({
    super.key,
    required this.icon,
    required this.label,
    required this.cooldown,
    required this.maxCooldown,
    required this.color,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final double cooldown;
  final double maxCooldown;
  final Color color;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ready = cooldown <= 0;
    final progress = 1 - (cooldown / maxCooldown).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Semantics(
        button: true,
        enabled: ready,
        label: ready ? '$label 사용' : '$label ${cooldown.ceil()}초 후 사용',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: ready ? onTap : null,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: ready ? .9 : .35),
                    const Color(0xff11131a),
                  ],
                ),
                border: Border.all(
                  color: active ? const Color(0xffffdf86) : color,
                  width: active ? 2.5 : 1.2,
                ),
                boxShadow: active
                    ? [BoxShadow(color: color, blurRadius: 14)]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.square(
                    dimension: 48,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2.5,
                      color: const Color(0xffffdd80),
                      backgroundColor: Colors.white10,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 18, color: Colors.white),
                      Text(
                        ready ? label : '${cooldown.ceil()}s',
                        style: const TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BattleMiniMap extends StatelessWidget {
  const BattleMiniMap({super.key, required this.contract, required this.stats});

  final BattlefieldContract contract;
  final BattleStats stats;

  @override
  Widget build(BuildContext context) {
    final dense = MediaQuery.sizeOf(context).height < 500;
    final conditionLabel = switch (contract.condition) {
      BattlefieldCondition.ashWind => '잿바람 · 이동 -6%',
      BattlefieldCondition.blackForest => '검은숲 · 시야 제한',
      BattlefieldCondition.whiteNight => '백야 · 빙결 지대',
      BattlefieldCondition.twilightSiege => '황혼 · 공성 포격',
      BattlefieldCondition.moonlitNight => '월광 야전 · 야행성',
    };
    return Container(
      width: dense ? 122 : 150,
      height: dense ? 70 : 86,
      decoration: BoxDecoration(
        color: const Color(0xcc0b0e13),
        border: Border.all(color: const Color(0xff6b5b3d)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BattleMiniMapPainter(
                battlefield: contract.battlefield,
                pressure: stats.frontPressure,
                escortProgress:
                    stats.escortEscaped /
                    (stats.escortTotal == 0 ? 1 : stats.escortTotal),
              ),
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 4,
            child: Text(
              conditionLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 8,
                color: Color(0xffd7bd7c),
                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BattleMiniMapPainter extends CustomPainter {
  const BattleMiniMapPainter({
    required this.battlefield,
    required this.pressure,
    required this.escortProgress,
  });

  final BattlefieldType battlefield;
  final double pressure;
  final double escortProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final field = Rect.fromLTWH(6, 6, size.width - 12, size.height - 24);
    canvas.drawRect(field, Paint()..color = const Color(0xff272922));
    if (battlefield == BattlefieldType.gateDefense) {
      final lineX = field.left + field.width * .28;
      canvas.drawRect(
        Rect.fromLTWH(field.left, field.top, field.width * .28, field.height),
        Paint()..color = const Color(0x553f7895),
      );
      canvas.drawLine(
        Offset(lineX, field.top),
        Offset(lineX, field.bottom),
        Paint()
          ..color = const Color(0xffd6b968)
          ..strokeWidth = 2,
      );
      canvas.drawCircle(
        Offset(field.left + 8, field.center.dy),
        5,
        Paint()..color = const Color(0xff68a9c8),
      );
      canvas.drawCircle(
        Offset(field.right - field.width * pressure, field.center.dy),
        4,
        Paint()..color = const Color(0xffd15f57),
      );
    } else {
      canvas.drawLine(
        Offset(field.left + 7, field.center.dy),
        Offset(field.right - 7, field.center.dy),
        Paint()
          ..color = const Color(0xff8d7650)
          ..strokeWidth = 9,
      );
      final convoyX = field.left + 7 + (field.width - 14) * escortProgress;
      canvas.drawCircle(
        Offset(convoyX, field.center.dy),
        5,
        Paint()..color = const Color(0xff71adc8),
      );
      canvas.drawRect(
        Rect.fromLTWH(field.right - 9, field.top, 9, field.height),
        Paint()..color = const Color(0x8866a7b8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BattleMiniMapPainter oldDelegate) =>
      oldDelegate.battlefield != battlefield ||
      oldDelegate.pressure != pressure ||
      oldDelegate.escortProgress != escortProgress;
}

class CommanderStatus extends StatelessWidget {
  const CommanderStatus({super.key, required this.ally, required this.alive});

  final bool ally;
  final bool alive;

  @override
  Widget build(BuildContext context) {
    final activeColor = ally
        ? const Color(0xff75abd0)
        : const Color(0xffd67268);
    return Expanded(
      child: Row(
        children: [
          Icon(
            alive ? Icons.shield_outlined : Icons.close,
            size: 11,
            color: alive ? activeColor : Colors.white30,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              ally
                  ? (alive ? '아군 지휘 유지' : '아군 지휘 붕괴')
                  : (alive ? '적 지휘관 활동' : '적 지휘관 격퇴'),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                color: alive ? Colors.white60 : const Color(0xffffd27c),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LevelUpOverlay extends StatelessWidget {
  const LevelUpOverlay({super.key, required this.choice, required this.onPick});
  final BattleChoice choice;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xcc05070d),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'LEVEL UP',
                  style: TextStyle(
                    color: Color(0xffffd889),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
                const Text(
                  '전장의 흐름을 바꿀 힘을 선택하십시오',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 18),
                Row(
                  children: List.generate(choice.options.length, (i) {
                    final option = choice.options[i];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: InkWell(
                          onTap: () => onPick(i),
                          child: GoldPanel(
                            child: SizedBox(
                              height: 150,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    gameIcon(option.iconId),
                                    size: 34,
                                    color: const Color(0xffc8a461),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    option.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: option.currentLevel == 0
                                          ? const Color(0x554d8fb8)
                                          : const Color(0x553f2852),
                                      border: Border.all(
                                        color: option.currentLevel == 0
                                            ? const Color(0xff6eafd0)
                                            : const Color(0xff8c6aa0),
                                      ),
                                    ),
                                    child: Text(
                                      option.currentLevel == 0
                                          ? 'NEW'
                                          : option.currentLevel + 1 >=
                                                option.maxLevel
                                          ? 'LV.${option.currentLevel} → MAX'
                                          : 'LV.${option.currentLevel} → ${option.currentLevel + 1}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Color(0xffffd889),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    option.description,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BattlefieldEventChoiceOverlay extends StatelessWidget {
  const BattlefieldEventChoiceOverlay({
    super.key,
    required this.event,
    required this.onPick,
  });

  final BattlefieldEventSpec event;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final rarityColor = switch (event.rarity) {
      BattlefieldEventRarity.common => const Color(0xffaab4bf),
      BattlefieldEventRarity.special => const Color(0xff66b9da),
      BattlefieldEventRarity.rare => const Color(0xffc28adc),
      BattlefieldEventRarity.legendary => const Color(0xffffbd5d),
    };
    final rarityLabel = switch (event.rarity) {
      BattlefieldEventRarity.common => 'COMMON',
      BattlefieldEventRarity.special => 'SPECIAL',
      BattlefieldEventRarity.rare => 'RARE',
      BattlefieldEventRarity.legendary => 'LEGENDARY',
    };
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xdd05070c),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: GoldPanel(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rarityLabel,
                      style: TextStyle(
                        color: rarityColor,
                        fontSize: 10,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      event.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(event.choices.length, (index) {
                        final choice = event.choices[index];
                        final danger =
                            choice.retreat ||
                            choice.id == 'fight_company' ||
                            choice.id == 'challenge_royal_guard';
                        return Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 310),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: InkWell(
                                onTap: () => onPick(index),
                                child: Container(
                                  height: 118,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: danger
                                        ? const Color(0x663b1719)
                                        : const Color(0x66203549),
                                    border: Border.all(
                                      color: danger
                                          ? const Color(0xff9e554e)
                                          : const Color(0xff668cac),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        choice.retreat
                                            ? Icons.directions_run
                                            : danger
                                            ? Icons.gavel
                                            : Icons.shield_outlined,
                                        color: danger
                                            ? const Color(0xffe28a78)
                                            : const Color(0xff8fc4dd),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        choice.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        choice.description,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EventBanner extends StatelessWidget {
  const EventBanner({super.key, required this.event});
  final BattleEvent event;
  @override
  Widget build(BuildContext context) => Positioned(
    top: 100,
    left: MediaQuery.sizeOf(context).width * .23,
    right: MediaQuery.sizeOf(context).width * .23,
    child: IgnorePointer(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xdd281313),
              border: Border.all(color: const Color(0xff9e5349)),
            ),
            child: Column(
              children: [
                Text(
                  event.grade,
                  style: const TextStyle(
                    color: Color(0xffffc46d),
                    letterSpacing: 4,
                    fontSize: 10,
                  ),
                ),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  event.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
