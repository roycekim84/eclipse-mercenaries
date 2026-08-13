part of '../../app/game_app.dart';

class CampScreen extends StatelessWidget {
  const CampScreen({
    super.key,
    required this.gold,
    required this.crystals,
    required this.commanderLevel,
    required this.lastReport,
    required this.campaignCycle,
    required this.onDeploy,
    required this.onRoster,
    required this.onEquipment,
    required this.onCodex,
    required this.onForge,
    required this.onMissions,
    required this.missionBadge,
    required this.onRecruitment,
    required this.onShop,
    required this.onSettings,
    required this.statusNotice,
    required this.onRetrySave,
  });
  final int gold;
  final int crystals;
  final int commanderLevel;
  final BattleReport? lastReport;
  final int campaignCycle;
  final VoidCallback onDeploy;
  final VoidCallback onRoster;
  final VoidCallback onEquipment;
  final VoidCallback onCodex;
  final VoidCallback onForge;
  final VoidCallback onMissions;
  final int missionBadge;
  final VoidCallback onRecruitment;
  final VoidCallback onShop;
  final VoidCallback onSettings;
  final String? statusNotice;
  final VoidCallback onRetrySave;

  @override
  Widget build(BuildContext context) {
    final worldState = CampWorldState.resolve(
      campaignCycle: campaignCycle,
      outcome: lastReport?.outcome.name,
      contractName: lastReport?.contractName,
      objectiveHpRatio: lastReport?.objectiveHpRatio ?? 1,
    );
    return SceneFrame(
      background: 'assets/images/mercenary_camp.png',
      child: SafeArea(
        child: Column(
          children: [
            TopBar(
              gold: gold,
              crystals: crystals,
              commanderLevel: commanderLevel,
              onSettings: onSettings,
            ),
            if (statusNotice != null)
              StatusBanner(
                message: statusNotice!,
                isError: true,
                actionLabel: '저장 재시도',
                onAction: onRetrySave,
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final compactHeight = constraints.maxHeight < 440;
                  return Stack(
                    children: [
                      Positioned(
                        left: 108,
                        right: 300,
                        top: 58,
                        bottom: 10,
                        child: IgnorePointer(
                          child: _CampLifeLayer(
                            compact: compactHeight,
                            woundedCount: worldState.woundedCount,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: 98,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                10,
                                compactHeight ? 8 : 18,
                                4,
                                compactHeight ? 4 : 16,
                              ),
                              child: Column(
                                children: [
                                  if (!compactHeight) ...[
                                    const Crest(),
                                    const SizedBox(height: 14),
                                  ],
                                  NavButton(
                                    icon: Icons.groups_2_outlined,
                                    label: '용병',
                                    onTap: onRoster,
                                    badge: true,
                                  ),
                                  NavButton(
                                    icon: Icons.auto_awesome_mosaic_outlined,
                                    label: '장비',
                                    onTap: onEquipment,
                                  ),
                                  NavButton(
                                    icon: Icons.storefront_outlined,
                                    label: '상점',
                                    onTap: onShop,
                                  ),
                                  NavButton(
                                    icon: Icons.menu_book_outlined,
                                    label: '임무',
                                    onTap: onMissions,
                                    badge: missionBadge > 0,
                                  ),
                                  NavButton(
                                    icon: Icons.auto_stories_outlined,
                                    label: '도감',
                                    onTap: onCodex,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 280,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                10,
                                24,
                                14,
                                18,
                              ),
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
                                    icon: Icons.group_add_outlined,
                                    onTap: onRecruitment,
                                  ),
                                  const SizedBox(height: 9),
                                  FantasyButton(
                                    label: '대장간',
                                    icon: Icons.handyman_outlined,
                                    onTap: onForge,
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
                      Positioned(
                        left: 110,
                        right: 300,
                        top: compactHeight ? 4 : 14,
                        child: _CampStateBanner(state: worldState),
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

class _CampLifeLayer extends StatefulWidget {
  const _CampLifeLayer({required this.compact, required this.woundedCount});

  final bool compact;
  final int woundedCount;

  @override
  State<_CampLifeLayer> createState() => _CampLifeLayerState();
}

class _CampLifeLayerState extends State<_CampLifeLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, _) {
      final drift = Curves.easeInOut.transform(_controller.value);
      return Stack(
        children: [
          _CampActor(
            asset: 'characters/luna_battle_sheet.png',
            label: '루나 · 야간 경계',
            frame: (drift * 7.999).floor(),
            left: 12 + drift * 16,
            bottom: 4,
            height: widget.compact ? 82 : 116,
          ),
          _CampActor(
            asset: 'characters/kael_battle_sheet.png',
            label: '카일 · 장비 점검',
            frame: (drift * 7.999).floor(),
            right: 18 + (1 - drift) * 14,
            bottom: 0,
            height: widget.compact ? 84 : 120,
          ),
          Positioned(
            left: 0,
            top: 4,
            child: _CampActivityChip(
              icon: Icons.forum_outlined,
              label:
                  '용병 대화 ${widget.woundedCount > 0 ? '· 부상자 보고' : '· 다음 계약 준비'}',
            ),
          ),
        ],
      );
    },
  );
}

class _CampActor extends StatelessWidget {
  const _CampActor({
    required this.asset,
    required this.label,
    required this.frame,
    required this.bottom,
    required this.height,
    this.left,
    this.right,
  });

  final String asset;
  final String label;
  final int frame;
  final double bottom;
  final double height;
  final double? left;
  final double? right;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    right: right,
    bottom: bottom,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          color: const Color(0xbb080a0e),
          child: Text(
            label,
            style: const TextStyle(fontSize: 7, color: Color(0xffe1c889)),
          ),
        ),
        SizedBox(
          height: height,
          width: height,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxWidth: height * 8,
              maxHeight: height * 5,
              child: Transform.translate(
                offset: Offset(-frame * height, 0),
                child: SizedBox(
                  width: height * 8,
                  height: height * 5,
                  child: Image.asset(
                    'assets/images/$asset',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _CampActivityChip extends StatelessWidget {
  const _CampActivityChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xaa0b0d12),
      border: Border.all(color: const Color(0x99765f3b)),
    ),
    child: Row(
      children: [
        PremiumGameIcon(icon, size: 12, color: const Color(0xffd8bd7b)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.white70)),
      ],
    ),
  );
}

class _CampStateBanner extends StatelessWidget {
  const _CampStateBanner({required this.state});

  final CampWorldState state;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xd90b0d12),
      border: Border.all(color: const Color(0xff78613d)),
      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
    ),
    child: Row(
      children: [
        const PremiumGameIcon(
          Icons.local_fire_department,
          size: 17,
          color: Color(0xffe5b45d),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.headline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                state.detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: Colors.white60),
              ),
            ],
          ),
        ),
        Text(
          '${state.period} · ${state.weather}',
          style: const TextStyle(fontSize: 9, color: Color(0xffd6bd82)),
        ),
      ],
    ),
  );
}
