part of '../../app/game_app.dart';

class MissionScreen extends StatefulWidget {
  const MissionScreen({
    super.key,
    required this.inventory,
    required this.weaponProgress,
    required this.claimedMissionIds,
    required this.commanderLevel,
    required this.ownedMercenaries,
    required this.factionReputation,
    required this.operationProgress,
    required this.notice,
    required this.onClaim,
    required this.onBack,
  });
  final Map<String, int> inventory;
  final Map<String, WeaponProgress> weaponProgress;
  final Set<String> claimedMissionIds;
  final int commanderLevel;
  final int ownedMercenaries;
  final Map<String, int> factionReputation;
  final Map<String, int> operationProgress;
  final String? notice;
  final ValueChanged<MissionSpec> onClaim;
  final VoidCallback onBack;
  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  MissionCategory? selectedCategory;
  String categoryLabel(MissionCategory? value) => switch (value) {
    null => '전체',
    MissionCategory.prologue => '서장',
    MissionCategory.growth => '성장',
    MissionCategory.war => '전쟁',
    MissionCategory.faction => '세력',
    MissionCategory.mastery => '업적',
  };
  IconData categoryIcon(MissionCategory value) => switch (value) {
    MissionCategory.prologue => Icons.history_edu_outlined,
    MissionCategory.growth => Icons.trending_up,
    MissionCategory.war => Icons.gavel,
    MissionCategory.faction => Icons.flag_outlined,
    MissionCategory.mastery => Icons.workspace_premium_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final missions = selectedCategory == null
        ? releaseMissions
        : releaseMissions
              .where((mission) => mission.category == selectedCategory)
              .toList(growable: false);
    final claimed = widget.claimedMissionIds.length.clamp(
      0,
      releaseMissions.length,
    );
    return DarkBackdrop(
      child: SafeArea(
        child: Column(
          children: [
            TitleBar(
              title: '용병단 임무',
              subtitle:
                  '전쟁 일지 $claimed / ${releaseMissions.length} · 성장과 세력 계약을 기록합니다',
              onBack: widget.onBack,
            ),
            if (widget.notice != null) StatusBanner(message: widget.notice!),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(
                children: [
                  for (final category in <MissionCategory?>[
                    null,
                    ...MissionCategory.values,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: InkWell(
                        onTap: () =>
                            setState(() => selectedCategory = category),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: selectedCategory == category
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xff6c4b24),
                                      Color(0xff352615),
                                    ],
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Color(0xff20232c),
                                      Color(0xff101219),
                                    ],
                                  ),
                            border: Border.all(
                              color: selectedCategory == category
                                  ? const Color(0xffffd27c)
                                  : const Color(0xff665536),
                            ),
                          ),
                          child: Text(
                            categoryLabel(category),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    '완료 ${(claimed / releaseMissions.length * 100).round()}%',
                    style: const TextStyle(
                      color: Color(0xffd8bd7b),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(14),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.sizeOf(context).width >= 900
                      ? 3
                      : 2,
                  mainAxisExtent: 154,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: missions.length,
                itemBuilder: (_, index) => _MissionCard(
                  mission: missions[index],
                  inventory: widget.inventory,
                  weaponProgress: widget.weaponProgress,
                  claimedMissionIds: widget.claimedMissionIds,
                  commanderLevel: widget.commanderLevel,
                  ownedMercenaries: widget.ownedMercenaries,
                  factionReputation: widget.factionReputation,
                  operationProgress: widget.operationProgress,
                  icon: categoryIcon(missions[index].category),
                  onClaim: widget.onClaim,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.mission,
    required this.inventory,
    required this.weaponProgress,
    required this.claimedMissionIds,
    required this.commanderLevel,
    required this.ownedMercenaries,
    required this.factionReputation,
    required this.operationProgress,
    required this.icon,
    required this.onClaim,
  });
  final MissionSpec mission;
  final Map<String, int> inventory;
  final Map<String, WeaponProgress> weaponProgress;
  final Set<String> claimedMissionIds;
  final int commanderLevel;
  final int ownedMercenaries;
  final Map<String, int> factionReputation;
  final Map<String, int> operationProgress;
  final IconData icon;
  final ValueChanged<MissionSpec> onClaim;
  @override
  Widget build(BuildContext context) {
    final claimed = claimedMissionIds.contains(mission.id);
    final unlocked = CampMetaRules.missionUnlocked(
      mission.id,
      claimedMissionIds,
    );
    final progress = CampMetaRules.missionProgress(
      mission,
      inventory: inventory,
      weaponProgress: weaponProgress,
      commanderLevel: commanderLevel,
      ownedMercenaries: ownedMercenaries,
      factionReputation: factionReputation,
      operationProgress: operationProgress,
    ).clamp(0, mission.target);
    final complete = progress >= mission.target;
    return GoldPanel(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PremiumGameIcon(
                  claimed ? Icons.workspace_premium_outlined : icon,
                  size: 28,
                  color: claimed
                      ? const Color(0xff7ac28d)
                      : const Color(0xffd8bd7b),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lv.${mission.level} · ${mission.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        mission.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: mission.target <= 0 ? 1 : progress / mission.target,
                minHeight: 5,
                backgroundColor: const Color(0xff090b10),
                color: complete
                    ? const Color(0xffffd27c)
                    : const Color(0xff758fb0),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$progress / ${mission.target}   ·   보상 ${mission.rewardLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xffd7bd7c), fontSize: 8.5),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: claimed
                  ? const ChipLabel('수령 완료')
                  : !unlocked
                  ? const ChipLabel('선행 임무 필요')
                  : FantasyButton(
                      label: complete ? '보상 수령' : '진행 중',
                      icon: complete
                          ? Icons.card_giftcard
                          : Icons.hourglass_bottom,
                      onTap: complete ? () => onClaim(mission) : () {},
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
