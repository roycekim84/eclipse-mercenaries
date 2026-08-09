import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'battle_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const EclipseMercenariesApp());
}

class EclipseMercenariesApp extends StatelessWidget {
  const EclipseMercenariesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.notoSansKrTextTheme(
      ThemeData.dark().textTheme,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '월식 용병단',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xff090b10),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xffc49a54),
          secondary: Color(0xff6b79a6),
          surface: Color(0xff14151a),
        ),
        textTheme: textTheme,
      ),
      home: const GameShell(),
    );
  }
}

enum AppScene { camp, contracts, roster, detail, battle, result }

class GameShell extends StatefulWidget {
  const GameShell({super.key});

  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> {
  AppScene scene = AppScene.camp;
  BattlefieldContract selected = contracts.first;
  BattleReport? report;
  int gold = 45678;
  int crystals = 3250;

  void go(AppScene next) => setState(() => scene = next);

  void finishBattle(BattleReport value) {
    setState(() {
      report = value;
      gold += value.gold;
      scene = AppScene.result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        child: switch (scene) {
          AppScene.camp => CampScreen(
            key: const ValueKey('camp'),
            gold: gold,
            crystals: crystals,
            onDeploy: () => go(AppScene.contracts),
            onRoster: () => go(AppScene.roster),
          ),
          AppScene.contracts => ContractScreen(
            key: const ValueKey('contracts'),
            selected: selected,
            onSelect: (value) => setState(() => selected = value),
            onBack: () => go(AppScene.camp),
            onDeploy: () => go(AppScene.battle),
          ),
          AppScene.roster => RosterScreen(
            key: const ValueKey('roster'),
            onBack: () => go(AppScene.camp),
            onSelect: () => go(AppScene.detail),
          ),
          AppScene.detail => MercenaryDetailScreen(
            key: const ValueKey('detail'),
            onBack: () => go(AppScene.roster),
          ),
          AppScene.battle => BattleScreen(
            key: ValueKey('battle-${DateTime.now().millisecondsSinceEpoch}'),
            contract: selected,
            onExit: () => go(AppScene.camp),
            onVictory: finishBattle,
          ),
          AppScene.result => ResultScreen(
            key: const ValueKey('result'),
            report: report!,
            onCamp: () => go(AppScene.camp),
            onReplay: () => go(AppScene.battle),
          ),
        },
      ),
    );
  }
}

class BattlefieldContract {
  const BattlefieldContract({
    required this.name,
    required this.subtitle,
    required this.power,
    required this.reward,
    required this.color,
    required this.icon,
  });
  final String name;
  final String subtitle;
  final int power;
  final int reward;
  final Color color;
  final IconData icon;
}

const contracts = [
  BattlefieldContract(
    name: '성문 방어전',
    subtitle: '새벽까지 북문을 사수하라',
    power: 18000,
    reward: 3000,
    color: Color(0xff334d6f),
    icon: Icons.shield_outlined,
  ),
  BattlefieldContract(
    name: '철수전',
    subtitle: '부상병과 보급대를 호위하라',
    power: 22000,
    reward: 4500,
    color: Color(0xff8c6031),
    icon: Icons.directions_run,
  ),
  BattlefieldContract(
    name: '적 지휘관 암살',
    subtitle: '혼란 속에서 지휘관을 제거하라',
    power: 25000,
    reward: 5000,
    color: Color(0xff733b3e),
    icon: Icons.gps_fixed,
  ),
];

class CampScreen extends StatelessWidget {
  const CampScreen({
    super.key,
    required this.gold,
    required this.crystals,
    required this.onDeploy,
    required this.onRoster,
  });
  final int gold;
  final int crystals;
  final VoidCallback onDeploy;
  final VoidCallback onRoster;

  @override
  Widget build(BuildContext context) {
    return SceneFrame(
      background: 'assets/images/mercenary_camp.png',
      child: SafeArea(
        child: Column(
          children: [
            TopBar(gold: gold, crystals: crystals),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 98,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 18, 4, 16),
                      child: Column(
                        children: [
                          const Crest(),
                          const SizedBox(height: 14),
                          NavButton(
                            icon: Icons.groups_2_outlined,
                            label: '용병',
                            onTap: onRoster,
                            badge: true,
                          ),
                          NavButton(
                            icon: Icons.auto_awesome_mosaic_outlined,
                            label: '장비',
                            onTap: () {},
                          ),
                          NavButton(
                            icon: Icons.storefront_outlined,
                            label: '상점',
                            onTap: () {},
                          ),
                          NavButton(
                            icon: Icons.menu_book_outlined,
                            label: '임무',
                            onTap: () {},
                          ),
                          NavButton(
                            icon: Icons.local_fire_department_outlined,
                            label: '도감',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 280,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 24, 14, 18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FantasyButton(
                            label: '전쟁터 출전',
                            icon: Icons.gavel,
                            prominent: true,
                            onTap: onDeploy,
                          ),
                          const SizedBox(height: 9),
                          FantasyButton(
                            label: '용병 모집',
                            icon: Icons.description_outlined,
                            onTap: () {},
                          ),
                          const SizedBox(height: 9),
                          FantasyButton(
                            label: '대장간',
                            icon: Icons.handyman_outlined,
                            onTap: () {},
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '오늘의 전쟁 보상  0 / 3',
                            style: TextStyle(
                              color: Color(0xffd1b980),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContractScreen extends StatelessWidget {
  const ContractScreen({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onBack,
    required this.onDeploy,
  });
  final BattlefieldContract selected;
  final ValueChanged<BattlefieldContract> onSelect;
  final VoidCallback onBack;
  final VoidCallback onDeploy;

  @override
  Widget build(BuildContext context) {
    return DarkBackdrop(
      child: SafeArea(
        child: Column(
          children: [
            TitleBar(
              title: '전쟁 계약',
              subtitle: '참여할 전쟁을 선택하십시오',
              onBack: onBack,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: MapPainter()),
                      ),
                      ...List.generate(contracts.length, (index) {
                        final item = contracts[index];
                        final x =
                            constraints.maxWidth * [0.22, 0.5, 0.78][index];
                        final y =
                            constraints.maxHeight * [0.38, 0.25, 0.43][index];
                        return Positioned(
                          left: x - 95,
                          top: y - 74,
                          child: ContractMarker(
                            contract: item,
                            selected: selected == item,
                            onTap: () => onSelect(item),
                          ),
                        );
                      }),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Row(
                          children: [
                            Expanded(
                              child: ContractSummary(contract: selected),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 210,
                              child: FantasyButton(
                                label: '계약 수락 · 출전',
                                icon: Icons.gavel,
                                prominent: true,
                                onTap: onDeploy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BattleScreen extends StatefulWidget {
  const BattleScreen({
    super.key,
    required this.contract,
    required this.onVictory,
    required this.onExit,
  });
  final BattlefieldContract contract;
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
    game = SurvivorGame(onVictory: widget.onVictory);
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
            builder: (context, value, _) => IgnorePointer(
              child: BattleHud(contract: widget.contract, stats: value),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: SafeArea(
            child: SmallIconButton(icon: Icons.close, onTap: widget.onExit),
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
      ],
    );
  }
}

class BattleHud extends StatelessWidget {
  const BattleHud({super.key, required this.contract, required this.stats});
  final BattlefieldContract contract;
  final BattleStats stats;

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
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xff33233f),
                        child: Icon(
                          Icons.pets,
                          color: Color(0xffd2b5e8),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LV.${stats.level}  루나 벨하르트',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Meter(
                              value: stats.hp / 1320,
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
              SkillOrb(icon: Icons.flash_on, label: 'LV.${stats.weaponLevel}'),
              const SkillOrb(icon: Icons.blur_circular, label: 'LV.1'),
              const SkillOrb(icon: Icons.auto_awesome, label: 'ULT'),
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
                                    option.icon,
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

class RosterScreen extends StatelessWidget {
  const RosterScreen({super.key, required this.onBack, required this.onSelect});
  final VoidCallback onBack;
  final VoidCallback onSelect;
  @override
  Widget build(BuildContext context) => DarkBackdrop(
    child: SafeArea(
      child: Column(
        children: [
          TitleBar(title: '용병 명부', subtitle: '보유 용병  8 / 100', onBack: onBack),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const ChipLabel('전체'),
                const ChipLabel('종족'),
                const ChipLabel('직업'),
                const Spacer(),
                SmallIconButton(icon: Icons.tune, onTap: () {}),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190,
                childAspectRatio: .78,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 8,
              itemBuilder: (_, index) => MercenaryCard(
                index: index,
                onTap: index == 0 ? onSelect : () {},
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class MercenaryDetailScreen extends StatelessWidget {
  const MercenaryDetailScreen({super.key, required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => DarkBackdrop(
    child: SafeArea(
      child: Column(
        children: [
          TitleBar(title: '용병 상세', subtitle: '월영의 암살자', onBack: onBack),
          Expanded(
            child: LayoutBuilder(
              builder: (_, c) => c.maxWidth < 700
                  ? ListView(
                      padding: const EdgeInsets.all(14),
                      children: const [
                        LunaPortrait(),
                        SizedBox(height: 12),
                        LunaStats(),
                      ],
                    )
                  : const Padding(
                      padding: EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Expanded(flex: 5, child: LunaPortrait()),
                          SizedBox(width: 14),
                          Expanded(flex: 4, child: LunaStats()),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

class LunaPortrait extends StatelessWidget {
  const LunaPortrait({super.key});
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 3 / 4,
    child: GoldPanel(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/luna_belhardt.png', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xee080a10)],
                stops: [.56, 1],
              ),
            ),
          ),
          const Positioned(
            left: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LUNA BELHARDT',
                  style: TextStyle(
                    color: Color(0xffd8bd7d),
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  '루나 벨하르트',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  '★★★★★  묘족 / 암살자',
                  style: TextStyle(color: Color(0xffffcf67)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class LunaStats extends StatelessWidget {
  const LunaStats({super.key});
  @override
  Widget build(BuildContext context) => GoldPanel(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('Lv.45 / 60', style: TextStyle(color: Color(0xff87b9d5))),
              Spacer(),
              Text(
                '전투력  28,450',
                style: TextStyle(
                  color: Color(0xffffcf67),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Meter(value: .62, color: Color(0xff4f97bd)),
          const SizedBox(height: 18),
          ...const [
            ('HP', '12,350'),
            ('공격력', '2,145'),
            ('방어력', '1,095'),
            ('치명타', '32.5%'),
            ('회피', '24.1%'),
            ('공격속도', '1.48'),
          ].map((e) => StatRow(e.$1, e.$2)),
          const Divider(color: Color(0xff5e5038)),
          const Text(
            '고유 특성 · 야행성',
            style: TextStyle(
              color: Color(0xffffd27c),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '밤 전장에서 공격속도 20% 증가, 치명타 확률 15% 증가',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xff17121d),
              border: Border.all(color: const Color(0xff725684)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_fix_high, color: Color(0xffbda2d4)),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '월광쌍검',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '고유 장비 · 궁극기 활성화',
                        style: TextStyle(
                          color: Color(0xffc9a9df),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.report,
    required this.onCamp,
    required this.onReplay,
  });
  final BattleReport report;
  final VoidCallback onCamp;
  final VoidCallback onReplay;
  @override
  Widget build(BuildContext context) => DarkBackdrop(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: GoldPanel(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'VICTORY',
                    style: TextStyle(
                      fontFamily: 'serif',
                      color: Color(0xffffd27c),
                      fontSize: 42,
                      letterSpacing: 7,
                    ),
                  ),
                  const Text(
                    '계약 완수 · 성문 방어선 사수',
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ResultStat('전투 시간', report.time),
                      ResultStat('처치 수', '${report.kills}'),
                      ResultStat('획득 골드', '${report.gold}'),
                      ResultStat('경험치', '${report.xp}'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: Color(0xff665536)),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '획득 전리품',
                      style: TextStyle(color: Color(0xffd6bd81)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Loot(icon: Icons.monetization_on, amount: '3,240'),
                      Loot(icon: Icons.diamond, amount: '12'),
                      Loot(icon: Icons.auto_fix_high, amount: '1'),
                      Loot(icon: Icons.science, amount: '4'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FantasyButton(
                          label: '캠프로 귀환',
                          icon: Icons.home_outlined,
                          onTap: onCamp,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FantasyButton(
                          label: '다시 출전',
                          icon: Icons.gavel,
                          prominent: true,
                          onTap: onReplay,
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
    ),
  );
}

// Shared premium fantasy UI components.
class SceneFrame extends StatelessWidget {
  const SceneFrame({super.key, required this.background, required this.child});
  final String background;
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(background, fit: BoxFit.cover),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xcc05070b), Colors.transparent, Color(0xb307090d)],
            stops: [0, .52, 1],
          ),
        ),
      ),
      child,
    ],
  );
}

class DarkBackdrop extends StatelessWidget {
  const DarkBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(.2, -.3),
        radius: 1.4,
        colors: [Color(0xff242736), Color(0xff0b0d13), Color(0xff050609)],
      ),
    ),
    child: child,
  );
}

class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.gold, required this.crystals});
  final int gold;
  final int crystals;
  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      color: Color(0xdd0b0d12),
      border: Border(bottom: BorderSide(color: Color(0xff665535))),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 19,
          backgroundColor: Color(0xff4f3821),
          child: Icon(Icons.pets, color: Color(0xffddb870)),
        ),
        const SizedBox(width: 9),
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '월영 Lv.15',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              '단장 랭크 B',
              style: TextStyle(fontSize: 10, color: Colors.white54),
            ),
          ],
        ),
        const Spacer(),
        Currency(
          icon: Icons.monetization_on,
          value: '$gold',
          color: Color(0xffffc95d),
        ),
        const SizedBox(width: 8),
        Currency(
          icon: Icons.diamond,
          value: '$crystals',
          color: Color(0xff6baee8),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.mail_outline, size: 19),
        const SizedBox(width: 10),
        const Icon(Icons.settings_outlined, size: 19),
      ],
    ),
  );
}

class TitleBar extends StatelessWidget {
  const TitleBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      color: Color(0xee0c0e14),
      border: Border(bottom: BorderSide(color: Color(0xff6e5a37))),
    ),
    child: Row(
      children: [
        SmallIconButton(icon: Icons.arrow_back_ios_new, onTap: onBack),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xffbfa875)),
            ),
          ],
        ),
      ],
    ),
  );
}

class GoldPanel extends StatelessWidget {
  const GoldPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xf522242b), Color(0xf50b0d12)],
      ),
      border: Border.all(color: const Color(0xff76613c)),
      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
    ),
    child: child,
  );
}

class HudPanel extends StatelessWidget {
  const HudPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: const Color(0xb8090b10),
      border: Border.all(color: const Color(0x9969583b)),
    ),
    child: child,
  );
}

class FantasyButton extends StatelessWidget {
  const FantasyButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.prominent = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool prominent;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: prominent
                ? const [Color(0xff263f5e), Color(0xff15253b)]
                : const [Color(0xff372a20), Color(0xff191512)],
          ),
          border: Border.all(
            color: prominent
                ? const Color(0xff7691ad)
                : const Color(0xff8b7045),
          ),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 7)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xffd8bd7b), size: 20),
            const SizedBox(width: 9),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class NavButton extends StatelessWidget {
  const NavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool badge;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xcc11141a),
            border: Border.all(color: const Color(0xff57482f)),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: const Color(0xffd0b375)),
                    Text(label, style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              if (badge)
                const Positioned(
                  right: 4,
                  top: 3,
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: Color(0xffc34d3f),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class Crest extends StatelessWidget {
  const Crest({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        colors: [Color(0xff69512d), Color(0xff181719)],
      ),
      border: Border.all(color: const Color(0xffb28a48), width: 2),
    ),
    child: const Icon(Icons.dark_mode, color: Color(0xffffd47b), size: 28),
  );
}

class Currency extends StatelessWidget {
  const Currency({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xaa050609),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

class SmallIconButton extends StatelessWidget {
  const SmallIconButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xaa11141a),
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: Color(0xff6d5937)),
      borderRadius: BorderRadius.circular(2),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 18),
      ),
    ),
  );
}

class Meter extends StatelessWidget {
  const Meter({super.key, required this.value, required this.color});
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(1),
      child: SizedBox(
        height: 5,
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          color: color,
          backgroundColor: Colors.black54,
        ),
      ),
    ),
  );
}

class ContractMarker extends StatelessWidget {
  const ContractMarker({
    super.key,
    required this.contract,
    required this.selected,
    required this.onTap,
  });
  final BattlefieldContract contract;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedScale(
      scale: selected ? 1.08 : 1,
      duration: const Duration(milliseconds: 180),
      child: SizedBox(
        width: 190,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: contract.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xffffd36e)
                      : const Color(0xff8d7952),
                  width: selected ? 3 : 1,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black87, blurRadius: 12),
                ],
              ),
              child: Icon(contract.icon, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: const Color(0xdd0a0c11),
              child: Text(
                contract.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ContractSummary extends StatelessWidget {
  const ContractSummary({super.key, required this.contract});
  final BattlefieldContract contract;
  @override
  Widget build(BuildContext context) => GoldPanel(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Icon(contract.icon, color: const Color(0xffd4b56f)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  contract.subtitle,
                  style: const TextStyle(fontSize: 10, color: Colors.white54),
                ),
              ],
            ),
          ),
          Text(
            '권장 ${contract.power}\n보상 ${contract.reward} G',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, color: Color(0xffd6bd82)),
          ),
        ],
      ),
    ),
  );
}

class SkillOrb extends StatelessWidget {
  const SkillOrb({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xff68408b), Color(0xff161225)],
        ),
        border: Border.all(color: const Color(0xffba94cb), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          Text(label, style: const TextStyle(fontSize: 8)),
        ],
      ),
    ),
  );
}

class ChipLabel extends StatelessWidget {
  const ChipLabel(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 7),
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xff20222b),
      border: Border.all(color: const Color(0xff635438)),
    ),
    child: Text(label, style: const TextStyle(fontSize: 11)),
  );
}

class MercenaryCard extends StatelessWidget {
  const MercenaryCard({super.key, required this.index, required this.onTap});
  final int index;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    const names = ['루나', '카일', '세라', '미엘', '라비', '노아', '아린', '로웬'];
    const colors = [
      Color(0xff49335c),
      Color(0xff51433b),
      Color(0xff374b61),
      Color(0xff694a37),
      Color(0xff604041),
      Color(0xff3f5547),
      Color(0xff49465f),
      Color(0xff654e3b),
    ];
    return GestureDetector(
      onTap: onTap,
      child: GoldPanel(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors[index], const Color(0xff0a0b0e)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Icon(
                index == 0
                    ? Icons.pets
                    : [
                        Icons.shield,
                        Icons.auto_awesome,
                        Icons.bolt,
                        Icons.health_and_safety,
                        Icons.architecture,
                        Icons.local_fire_department,
                        Icons.air,
                      ][index - 1],
                color: Colors.white12,
                size: 88,
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    names[index],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Lv.${45 - index * 3}',
                    style: const TextStyle(fontSize: 11, color: Colors.white60),
                  ),
                  Text(
                    index < 3 ? '★★★★★' : '★★★★',
                    style: const TextStyle(
                      color: Color(0xffffc95d),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 7,
              top: 7,
              child: Icon(
                index == 0 ? Icons.dark_mode : Icons.change_history,
                size: 16,
                color: const Color(0xffdfc180),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  const StatRow(this.label, this.value, {super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    ),
  );
}

class ResultStat extends StatelessWidget {
  const ResultStat(this.label, this.value, {super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      const SizedBox(height: 5),
      Text(
        value,
        style: const TextStyle(
          color: Color(0xffffd27c),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    ],
  );
}

class Loot extends StatelessWidget {
  const Loot({super.key, required this.icon, required this.amount});
  final IconData icon;
  final String amount;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xff11141a),
        border: Border.all(color: const Color(0xff54472f)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xffb9a5db)),
          const SizedBox(height: 4),
          Text(amount, style: const TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
}

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xff25241f);
    canvas.drawRect(Offset.zero & size, bg);
    final road = Paint()
      ..color = const Color(0xff8a754e)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * .08, size.height * .62)
      ..quadraticBezierTo(
        size.width * .35,
        size.height * .05,
        size.width * .55,
        size.height * .35,
      )
      ..quadraticBezierTo(
        size.width * .72,
        size.height * .65,
        size.width * .94,
        size.height * .2,
      );
    canvas.drawPath(path, road);
    final contour = Paint()
      ..color = const Color(0x225e7a63)
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 10; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            size.width * (.1 + i * .09),
            size.height * (.25 + (i % 3) * .15),
          ),
          width: 190 + i * 13,
          height: 70 + i * 4,
        ),
        contour,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
