part of '../../app/game_app.dart';

class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({
    super.key,
    required this.mercenary,
    required this.equipped,
    required this.weaponProgress,
    required this.onEquip,
    required this.onBack,
  });
  final MercenarySpec mercenary;
  final WeaponSpec equipped;
  final Map<String, WeaponProgress> weaponProgress;
  final ValueChanged<WeaponSpec> onEquip;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => DarkBackdrop(
    child: SafeArea(
      child: Column(
        children: [
          TitleBar(
            title: '장비 / 무기',
            subtitle: '${mercenary.name}의 출전 장비',
            onBack: onBack,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) => Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth < 760 ? 2 : 3,
                        childAspectRatio: 1.05,
                        crossAxisSpacing: 9,
                        mainAxisSpacing: 9,
                      ),
                      itemCount: gameContent.weapons.length,
                      itemBuilder: (_, index) {
                        final weapon = gameContent.weapons[index];
                        final active = weapon.id == equipped.id;
                        final progress = weaponProgress[weapon.id];
                        return InkWell(
                          onTap: () => onEquip(weapon),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  weapon.visual.color.withValues(alpha: .35),
                                  const Color(0xff0d0f14),
                                ],
                              ),
                              border: Border.all(
                                color: active
                                    ? const Color(0xffffcf70)
                                    : const Color(0xff584b35),
                                width: active ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  weapon.visual.icon,
                                  color: weapon.visual.color,
                                  size: 28,
                                ),
                                const Spacer(),
                                Text(
                                  weapon.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${weapon.grade} · ATK ${weapon.attack}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white54,
                                  ),
                                ),
                                Text(
                                  '영구 Lv.${progress?.level ?? 1} · ${progress?.stage ?? 1}단계',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xffc7a6df),
                                  ),
                                ),
                                if (weapon.ownerId != null)
                                  const Text(
                                    '고유 장비',
                                    style: TextStyle(
                                      color: Color(0xffffc66d),
                                      fontSize: 9,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: WeaponDetailPanel(
                      mercenary: mercenary,
                      weapon: equipped,
                      progress: weaponProgress[equipped.id],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class WeaponDetailPanel extends StatelessWidget {
  const WeaponDetailPanel({
    super.key,
    required this.mercenary,
    required this.weapon,
    required this.progress,
  });
  final MercenarySpec mercenary;
  final WeaponSpec weapon;
  final WeaponProgress? progress;

  @override
  Widget build(BuildContext context) {
    final signature = weapon.ownerId == mercenary.id;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      child: GoldPanel(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(
                  weapon.visual.icon,
                  size: 84,
                  color: weapon.visual.color,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                weapon.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${weapon.grade} 등급',
                style: TextStyle(color: weapon.visual.color),
              ),
              Text(
                '영구 Lv.${progress?.level ?? 1} · 성장 ${progress?.stage ?? 1}단계',
                style: const TextStyle(color: Color(0xffc7a6df), fontSize: 11),
              ),
              const Divider(color: Color(0xff665536)),
              StatRow('공격력', '${weapon.attack}'),
              StatRow('치명타', '${weapon.crit}%'),
              StatRow(
                '공격속도',
                '${weapon.speed >= 0 ? '+' : ''}${weapon.speed}%',
              ),
              const SizedBox(height: 10),
              const Text('무기 특성', style: TextStyle(color: Color(0xffffd27c))),
              Text(
                weapon.description,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const Spacer(),
              if (weapon.ownerId != null) const ChipLabel('고유 장비'),
              if (signature)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0x553f2852),
                    border: Border.all(color: const Color(0xff9069a5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xffcaa6df)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '궁극기 활성화\n${mercenary.ultimate}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
