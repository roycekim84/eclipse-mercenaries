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
    required this.onVictory,
    required this.onExit,
  });
  final BattlefieldContract contract;
  final MercenarySpec mercenary;
  final WeaponSpec weapon;
  final MercenaryProgress mercenaryProgress;
  final WeaponProgress weaponProgress;
  final bool reducedEffects;
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
        contractId: widget.contract.id,
        contractName: widget.contract.name,
        contractGold: widget.contract.reward,
        contractXp: widget.contract.xp,
        mercenaryPermanentLevel: widget.mercenaryProgress.level,
        weaponPermanentLevel: widget.weaponProgress.level,
        weaponGrowthStage: widget.weaponProgress.stage,
      ),
      onVictory: widget.onVictory,
    );
    game.reducedEffects.value = widget.reducedEffects;
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
            builder: (context, value, _) => BattleHud(
              contract: widget.contract,
              mercenary: widget.mercenary,
              weapon: widget.weapon,
              stats: value,
              onUltimate: game.triggerUltimate,
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
                      fontFamily: 'serif',
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
    required this.onUltimate,
  });
  final BattlefieldContract contract;
  final MercenarySpec mercenary;
  final WeaponSpec weapon;
  final BattleStats stats;
  final VoidCallback onUltimate;

  @override
  Widget build(BuildContext context) {
    final seconds = stats.secondsLeft.clamp(0, 999);
    return Stack(
      children: [
        Positioned(
          left: 12,
          top: 8,
          child: SizedBox(
            width: 230,
            child: HudPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: mercenary.visual.color,
                        child: Icon(
                          mercenary.visual.icon,
                          color: mercenary.visual.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LV.${stats.level}  ${mercenary.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
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
                  const SizedBox(height: 8),
                  Text(
                    '임무  ${contract.name}',
                    style: const TextStyle(
                      color: Color(0xffd5bc83),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    contract.battlefield == BattlefieldType.evacuation
                        ? '호위 대상 ${EvacuationRules.requiredEscaped}명 탈출'
                        : '성문 방어선 유지  ${stats.kills} / 120',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 5),
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
                              : '북문  ${stats.gateHp.ceil()} / ${stats.gateMaxHp.ceil()}',
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
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '00:${seconds.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(blurRadius: 8, color: Colors.black)],
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 12,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x88c7a460)),
              color: const Color(0x6610141b),
            ),
            child: const Icon(Icons.control_camera, color: Colors.white54),
          ),
        ),
        Positioned(
          right: 14,
          bottom: 10,
          child: Row(
            children: [
              for (final entry in stats.build.take(6))
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

class BattleMiniMap extends StatelessWidget {
  const BattleMiniMap({super.key, required this.contract, required this.stats});

  final BattlefieldContract contract;
  final BattleStats stats;

  @override
  Widget build(BuildContext context) {
    final conditionLabel = contract.condition == BattlefieldCondition.ashWind
        ? '잿바람 · 이동 -6%'
        : '월광 야전 · 야행성';
    return Container(
      width: 150,
      height: 86,
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
                        fontFamily: 'serif',
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
