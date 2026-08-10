part of '../../app/game_app.dart';

class CampScreen extends StatelessWidget {
  const CampScreen({
    super.key,
    required this.gold,
    required this.crystals,
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
            TopBar(gold: gold, crystals: crystals, onSettings: onSettings),
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
                                    icon: Icons.local_fire_department_outlined,
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
                                    icon: Icons.description_outlined,
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
                      Positioned(
                        left: 118,
                        right: 306,
                        bottom: compactHeight ? 8 : 18,
                        height: 58,
                        child: _CampFacilityStrip(
                          woundedCount: worldState.woundedCount,
                          onCommand: onDeploy,
                          onForge: onForge,
                          onGuild: onRecruitment,
                          onMerchant: onShop,
                          onInfirmary: onRoster,
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
        const Icon(
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

class _CampFacilityStrip extends StatelessWidget {
  const _CampFacilityStrip({
    required this.woundedCount,
    required this.onCommand,
    required this.onForge,
    required this.onGuild,
    required this.onMerchant,
    required this.onInfirmary,
  });

  final int woundedCount;
  final VoidCallback onCommand;
  final VoidCallback onForge;
  final VoidCallback onGuild;
  final VoidCallback onMerchant;
  final VoidCallback onInfirmary;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _FacilityMarker(
        icon: Icons.map_outlined,
        label: '지휘 천막',
        onTap: onCommand,
      ),
      _FacilityMarker(
        icon: Icons.handyman_outlined,
        label: '대장간 시설',
        onTap: onForge,
      ),
      _FacilityMarker(
        icon: Icons.groups_2_outlined,
        label: '용병 길드',
        onTap: onGuild,
      ),
      _FacilityMarker(
        icon: Icons.storefront_outlined,
        label: '상인',
        onTap: onMerchant,
      ),
      _FacilityMarker(
        icon: Icons.medical_services_outlined,
        label: woundedCount > 0 ? '의무소 $woundedCount' : '의무소',
        alert: woundedCount > 0,
        onTap: onInfirmary,
      ),
    ],
  );
}

class _FacilityMarker extends StatelessWidget {
  const _FacilityMarker({
    required this.icon,
    required this.label,
    required this.onTap,
    this.alert = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool alert;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label 시설',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xd915171d),
            border: Border.all(
              color: alert ? const Color(0xffbb5750) : const Color(0xff8b744a),
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: const Color(0xffe2c57d)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 8)),
            ],
          ),
        ),
      ),
    ),
  );
}
