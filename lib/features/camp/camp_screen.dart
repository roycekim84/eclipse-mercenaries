part of '../../app/game_app.dart';

class CampScreen extends StatelessWidget {
  const CampScreen({
    super.key,
    required this.gold,
    required this.crystals,
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
  });
  final int gold;
  final int crystals;
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

  @override
  Widget build(BuildContext context) {
    return SceneFrame(
      background: 'assets/images/mercenary_camp.png',
      child: SafeArea(
        child: Column(
          children: [
            TopBar(gold: gold, crystals: crystals, onSettings: onSettings),
            if (statusNotice != null)
              StatusBanner(message: statusNotice!, isError: true),
            Expanded(
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final compactHeight = constraints.maxHeight < 440;
                  return Row(
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
