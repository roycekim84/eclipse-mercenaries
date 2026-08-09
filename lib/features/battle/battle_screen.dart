part of '../../app/game_app.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({
    super.key,
    required this.contract,
    required this.mercenary,
    required this.weapon,
    required this.onVictory,
    required this.onExit,
  });
  final BattlefieldContract contract;
  final MercenarySpec mercenary;
  final WeaponSpec weapon;
  final ValueChanged<BattleReport> onVictory;
  final VoidCallback onExit;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late final SurvivorGame game;

  @override
  void initState() {
    super.initState();
    game = SurvivorGame(
      config: BattleConfig(mercenary: widget.mercenary, weapon: widget.weapon),
      onVictory: widget.onVictory,
    );
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
                SmallIconButton(icon: Icons.close, onTap: widget.onExit),
              ],
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
      ],
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
                    '성문 방어선 유지  ${stats.kills} / 120',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.castle_outlined,
                        size: 13,
                        color: Color(0xffd7bd7c),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '북문  ${stats.gateHp.ceil()} / ${stats.gateMaxHp.ceil()}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      Text(
                        '전선 ${(stats.frontPressure * 100).round()}%',
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
                    value: stats.gateHp / stats.gateMaxHp,
                    color: stats.gateHp / stats.gateMaxHp > .35
                        ? const Color(0xff60b875)
                        : const Color(0xffd2554e),
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
              SkillOrb(
                icon: weapon.visual.icon,
                label: 'LV.${stats.weaponLevel}',
              ),
              const SkillOrb(icon: Icons.blur_circular, label: 'LV.1'),
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
