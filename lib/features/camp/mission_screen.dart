part of '../../app/game_app.dart';

class MissionScreen extends StatelessWidget {
  const MissionScreen({
    super.key,
    required this.inventory,
    required this.weaponProgress,
    required this.claimedMissionIds,
    required this.notice,
    required this.onClaim,
    required this.onBack,
  });
  final Map<String, int> inventory;
  final Map<String, WeaponProgress> weaponProgress;
  final Set<String> claimedMissionIds;
  final String? notice;
  final ValueChanged<MissionSpec> onClaim;
  final VoidCallback onBack;

  int get currentMissionLevel => alphaMissions
      .firstWhere(
        (mission) => !claimedMissionIds.contains(mission.id),
        orElse: () => alphaMissions.last,
      )
      .level;

  @override
  Widget build(BuildContext context) => DarkBackdrop(
    child: SafeArea(
      child: Column(
        children: [
          TitleBar(
            title: '용병단 임무',
            subtitle: '초심자 작전 Lv.$currentMissionLevel · 계약과 성장을 기록하는 전쟁 일지',
            onBack: onBack,
          ),
          if (notice != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: const Color(0x553b2d18),
              child: Text(
                notice!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xffffd27c), fontSize: 11),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: alphaMissions.length,
              itemBuilder: (_, index) {
                final mission = alphaMissions[index];
                final claimed = claimedMissionIds.contains(mission.id);
                final unlocked = CampMetaRules.missionUnlocked(
                  mission.id,
                  claimedMissionIds,
                );
                final complete = CampMetaRules.missionComplete(
                  mission.id,
                  inventory: inventory,
                  weaponProgress: weaponProgress,
                );
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xee22242b), Color(0xee0c0e13)],
                    ),
                    border: Border.all(
                      color: complete
                          ? const Color(0xff9a7945)
                          : const Color(0xff4b463c),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: claimed
                            ? const Color(0xff33483a)
                            : const Color(0xff352b20),
                        child: Icon(
                          claimed ? Icons.check : Icons.description_outlined,
                          color: claimed
                              ? const Color(0xff83c99a)
                              : const Color(0xffd4b778),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lv.${mission.level}  ${mission.title}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              mission.description,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '보상  ${mission.rewardLabel}',
                              style: const TextStyle(
                                color: Color(0xffffd27c),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 118,
                        child: claimed
                            ? const ChipLabel('수령 완료')
                            : !unlocked
                            ? const ChipLabel('이전 임무 필요')
                            : FantasyButton(
                                label: complete ? '보상 수령' : '진행 중',
                                icon: complete
                                    ? Icons.card_giftcard
                                    : Icons.hourglass_bottom,
                                onTap: complete
                                    ? () => onClaim(mission)
                                    : () {},
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
