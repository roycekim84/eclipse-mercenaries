part of '../../app/game_app.dart';

class CampScreen extends StatelessWidget {
  const CampScreen({
    super.key,
    required this.gold,
    required this.crystals,
    required this.commanderLevel,
    required this.ownedCombatMercenaries,
    required this.ownedServiceMercenaries,
    required this.activeDispatch,
    required this.lastReport,
    required this.campaignCycle,
    this.contentStage = 4,
    required this.onDeploy,
    required this.onRoster,
    required this.onEquipment,
    required this.onCodex,
    required this.onForge,
    required this.onMissions,
    required this.onServices,
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
  final List<MercenarySpec> ownedCombatMercenaries;
  final List<MercenarySpec> ownedServiceMercenaries;
  final ActiveDispatch? activeDispatch;
  final BattleReport? lastReport;
  final int campaignCycle;
  final int contentStage;
  final VoidCallback onDeploy;
  final VoidCallback onRoster;
  final VoidCallback onEquipment;
  final VoidCallback onCodex;
  final VoidCallback onForge;
  final VoidCallback onMissions;
  final VoidCallback onServices;
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
                            mercenaries: ownedCombatMercenaries,
                            serviceMercenaries: ownedServiceMercenaries
                                .where(
                                  (mercenary) =>
                                      activeDispatch?.mercenaryId !=
                                      mercenary.id,
                                )
                                .toList(growable: false),
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
                                  if (contentStage >= 2) ...[
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
                                  ],
                                  if (contentStage >= 4)
                                    NavButton(
                                      icon: Icons.storefront_outlined,
                                      label: '상점',
                                      onTap: onShop,
                                    ),
                                  if (contentStage >= 3)
                                    NavButton(
                                      icon: Icons.menu_book_outlined,
                                      label: '임무',
                                      onTap: onMissions,
                                      badge: missionBadge > 0,
                                    ),
                                  if (contentStage >= 4)
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
                                  const SizedBox(height: 7),
                                  if (contentStage >= 3) ...[
                                    FantasyButton(
                                      label: activeDispatch == null
                                          ? '용병단 작전실'
                                          : '파견 작전 진행 중',
                                      icon: Icons.route_outlined,
                                      onTap: onServices,
                                    ),
                                    const SizedBox(height: 7),
                                  ],
                                  if (contentStage >= 2)
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
  const _CampLifeLayer({
    required this.compact,
    required this.woundedCount,
    required this.mercenaries,
    required this.serviceMercenaries,
  });

  final bool compact;
  final int woundedCount;
  final List<MercenarySpec> mercenaries;
  final List<MercenarySpec> serviceMercenaries;

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
      final phase = Curves.easeInOut.transform(_controller.value);
      return Stack(
        children: [
          for (var index = 0; index < widget.mercenaries.length; index++)
            Align(
              alignment: _campActorAlignments[index],
              child: _CampActor(
                key: ValueKey('camp-actor-${widget.mercenaries[index].id}'),
                mercenary: widget.mercenaries[index],
                framePhase: (phase + index * .137) % 1,
                height: widget.compact ? 58 : 82,
              ),
            ),
          for (
            var index = 0;
            index < math.min(widget.serviceMercenaries.length, 4);
            index++
          )
            Align(
              alignment: _campServiceAlignments[index],
              child: _CampActor(
                key: ValueKey(
                  'camp-service-${widget.serviceMercenaries[index].id}',
                ),
                mercenary: widget.serviceMercenaries[index],
                framePhase: (phase + index * .31) % 1,
                height: widget.compact ? 48 : 66,
              ),
            ),
          Positioned(
            left: 0,
            top: 4,
            child: _CampActivityChip(
              icon: Icons.forum_outlined,
              label:
                  '상주 영웅 ${widget.mercenaries.length}/8 '
                  '· 생활 용병 ${widget.serviceMercenaries.length} '
                  '${widget.woundedCount > 0 ? '· 부상자 보고' : '· 다음 계약 준비'}',
            ),
          ),
        ],
      );
    },
  );
}

class _CampActor extends StatelessWidget {
  const _CampActor({
    super.key,
    required this.mercenary,
    required this.framePhase,
    required this.height,
  });

  final MercenarySpec mercenary;
  final double framePhase;
  final double height;

  @override
  Widget build(BuildContext context) {
    final visual = mercenary.visual;
    if (visual.hasStandaloneWorldSprite) {
      final bob = math.sin(framePhase * math.pi * 2) * 1.5;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            color: const Color(0xbb080a0e),
            child: Text(
              '${mercenary.name.split(' ').first} · ${_campActivityById[mercenary.id] ?? '계약 준비'}',
              style: const TextStyle(fontSize: 7, color: Color(0xffe1c889)),
            ),
          ),
          Transform.translate(
            offset: Offset(0, bob),
            child: SizedBox(
              height: height,
              width: height,
              child: Image.asset(
                'assets/images/${visual.worldSpriteAsset}',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
              ),
            ),
          ),
        ],
      );
    }
    final idleFrames = visual.battleFrameIndices.first;
    final frame =
        idleFrames[(framePhase * idleFrames.length).floor().clamp(
          0,
          idleFrames.length - 1,
        )];
    final frameWidth = height * 288 / 256;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          color: const Color(0xbb080a0e),
          child: Text(
            '${mercenary.name.split(' ').first} · ${_campActivityById[mercenary.id] ?? '계약 준비'}',
            style: const TextStyle(fontSize: 7, color: Color(0xffe1c889)),
          ),
        ),
        SizedBox(
          height: height,
          width: frameWidth,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxWidth: frameWidth * visual.battleColumns,
              maxHeight: height * 5,
              child: Transform.translate(
                offset: Offset(-frame * frameWidth, 0),
                child: SizedBox(
                  width: frameWidth * visual.battleColumns,
                  height: height * 5,
                  child: Image.asset(
                    'assets/images/${visual.battleSpriteAsset!}',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const _campActorAlignments = <Alignment>[
  Alignment(-.88, .78),
  Alignment(.88, .78),
  Alignment(-.42, .62),
  Alignment(.42, .62),
  Alignment(-.72, .18),
  Alignment(.72, .18),
  Alignment(-.25, -.08),
  Alignment(.25, -.08),
];

const _campServiceAlignments = <Alignment>[
  Alignment(-.95, -.46),
  Alignment(.95, -.46),
  Alignment(-.62, -.34),
  Alignment(.62, -.34),
];

const _campActivityById = <String, String>{
  'luna': '야간 경계',
  'kael': '장비 점검',
  'sera': '마력 조율',
  'nyra': '전술 기록',
  'aurel': '방패 수련',
  'vesta': '계약 검토',
  'rask': '창날 정비',
  'iris': '월광 명상',
  'mira': '의무소 순찰',
  'garr': '신병 훈련',
  'elka': '공성 장비 해체',
  'soren': '전선 관측',
  'talia': '전리품 감정',
  'fenn': '전령로 확인',
  'corva': '정보 보고',
  'silas': '보급 장부 정리',
};

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
