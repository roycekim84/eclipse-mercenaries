part of '../../app/game_app.dart';

class CampScreen extends StatelessWidget {
  const CampScreen({
    super.key,
    required this.gold,
    required this.crystals,
    required this.onDeploy,
    required this.onRoster,
    required this.onEquipment,
  });
  final int gold;
  final int crystals;
  final VoidCallback onDeploy;
  final VoidCallback onRoster;
  final VoidCallback onEquipment;

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
                            onTap: onEquipment,
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
