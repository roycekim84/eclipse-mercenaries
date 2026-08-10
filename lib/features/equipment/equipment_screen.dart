part of '../../app/game_app.dart';

class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({
    super.key,
    required this.mercenary,
    required this.equipped,
    required this.weaponProgress,
    required this.equippedGear,
    required this.onEquip,
    required this.onEquipGear,
    required this.onBack,
  });
  final MercenarySpec mercenary;
  final WeaponSpec equipped;
  final Map<String, WeaponProgress> weaponProgress;
  final Map<GearSlot, GearSpec> equippedGear;
  final ValueChanged<WeaponSpec> onEquip;
  final void Function(GearSlot slot, GearSpec gear) onEquipGear;
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
                    child: Column(
                      children: [
                        GearLoadoutStrip(
                          equipped: equippedGear,
                          onSelect: (slot) => _showGearPicker(
                            context,
                            slot: slot,
                            equipped: equippedGear[slot]!,
                            onEquip: onEquipGear,
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: constraints.maxWidth < 760
                                      ? 2
                                      : 3,
                                  childAspectRatio: 1.05,
                                  crossAxisSpacing: 9,
                                  mainAxisSpacing: 9,
                                ),
                            itemCount: gameContent.weapons.length,
                            itemBuilder: (_, index) {
                              final weapon = gameContent.weapons[index];
                              final active = weapon.id == equipped.id;
                              final progress = weaponProgress[weapon.id];
                              return WeaponGridCard(
                                weapon: weapon,
                                active: active,
                                progress: progress,
                                onTap: () => onEquip(weapon),
                              );
                            },
                          ),
                        ),
                      ],
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

  Future<void> _showGearPicker(
    BuildContext context, {
    required GearSlot slot,
    required GearSpec equipped,
    required void Function(GearSlot slot, GearSpec gear) onEquip,
  }) => showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 390),
        child: GoldPanel(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${gearSlotName(slot)} 교체',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '강화 실패나 파괴 없이 즉시 출전 빌드에 반영됩니다.',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      for (final gear in betaGearCatalog.where(
                        (item) => item.slot == slot,
                      ))
                        GearPickerCard(
                          gear: gear,
                          active: gear.id == equipped.id,
                          onTap: () {
                            onEquip(slot, gear);
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

String gearSlotName(GearSlot slot) => switch (slot) {
  GearSlot.armor => '방어구',
  GearSlot.accessory => '장신구',
  GearSlot.tactical => '전술 도구',
};

IconData gearSlotIcon(GearSlot slot) => switch (slot) {
  GearSlot.armor => Icons.shield_outlined,
  GearSlot.accessory => Icons.diamond_outlined,
  GearSlot.tactical => Icons.explore_outlined,
};

class GearLoadoutStrip extends StatelessWidget {
  const GearLoadoutStrip({
    super.key,
    required this.equipped,
    required this.onSelect,
  });

  final Map<GearSlot, GearSpec> equipped;
  final ValueChanged<GearSlot> onSelect;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 76,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          for (final slot in GearSlot.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => onSelect(slot),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xcc12151c),
                      border: Border.all(color: const Color(0xff75613d)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          gearSlotIcon(slot),
                          color: const Color(0xffd8bd7b),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gearSlotName(slot),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 9,
                                ),
                              ),
                              Text(
                                equipped[slot]!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class WeaponGridCard extends StatelessWidget {
  const WeaponGridCard({
    super.key,
    required this.weapon,
    required this.active,
    required this.progress,
    required this.onTap,
  });
  final WeaponSpec weapon;
  final bool active;
  final WeaponProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
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
          color: active ? const Color(0xffffcf70) : const Color(0xff584b35),
          width: active ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(weapon.visual.icon, color: weapon.visual.color, size: 28),
          const Spacer(),
          Text(
            weapon.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            '${weapon.grade} · ATK ${weapon.attack}',
            style: const TextStyle(fontSize: 10, color: Colors.white54),
          ),
          Text(
            '영구 Lv.${progress?.level ?? 1} · ${progress?.stage ?? 1}단계',
            style: const TextStyle(fontSize: 9, color: Color(0xffc7a6df)),
          ),
          if (weapon.ownerId != null)
            const Text(
              '고유 장비',
              style: TextStyle(color: Color(0xffffc66d), fontSize: 9),
            ),
        ],
      ),
    ),
  );
}

class GearPickerCard extends StatelessWidget {
  const GearPickerCard({
    super.key,
    required this.gear,
    required this.active,
    required this.onTap,
  });
  final GearSpec gear;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: active ? const Color(0xff2e2435) : const Color(0xff14171e),
          border: Border.all(
            color: active ? const Color(0xffffcf70) : const Color(0xff514736),
          ),
        ),
        child: Row(
          children: [
            Icon(
              gearSlotIcon(gear.slot),
              color: const Color(0xffd8bd7b),
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${gear.name} · ${gear.grade}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    gear.description,
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                  Text(
                    _gearStatSummary(gear),
                    style: const TextStyle(
                      color: Color(0xff9dd7b0),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (active) const ChipLabel('장착 중'),
          ],
        ),
      ),
    ),
  );
}

String _gearStatSummary(GearSpec gear) => [
  if (gear.hpPercent != 0)
    'HP ${gear.hpPercent > 0 ? '+' : ''}${gear.hpPercent}%',
  if (gear.damagePercent != 0)
    '공격 ${gear.damagePercent > 0 ? '+' : ''}${gear.damagePercent}%',
  if (gear.speedPercent != 0)
    '이동 ${gear.speedPercent > 0 ? '+' : ''}${gear.speedPercent}%',
  if (gear.criticalChance != 0) '치명 +${gear.criticalChance}%',
  if (gear.dashCooldownPercent != 0) '대시 -${gear.dashCooldownPercent}%',
  if (gear.tacticalCooldownPercent != 0) '전술 -${gear.tacticalCooldownPercent}%',
].join(' · ');

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
