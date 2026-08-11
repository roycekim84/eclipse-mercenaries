part of '../../app/game_app.dart';

class RosterScreen extends StatefulWidget {
  const RosterScreen({
    super.key,
    required this.onBack,
    required this.onSelect,
    required this.mercenaryProgress,
  });
  final VoidCallback onBack;
  final ValueChanged<MercenarySpec> onSelect;
  final Map<String, MercenaryProgress> mercenaryProgress;

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  String? raceFilter;
  String? jobFilter;

  List<MercenarySpec> get owned => gameContent.mercenaries
      .where((mercenary) => widget.mercenaryProgress.containsKey(mercenary.id))
      .toList(growable: false);

  List<MercenarySpec> get visible => owned
      .where(
        (mercenary) =>
            (raceFilter == null || mercenary.race == raceFilter) &&
            (jobFilter == null || mercenary.job == jobFilter),
      )
      .toList(growable: false);

  @override
  Widget build(BuildContext context) => DarkBackdrop(
    child: SafeArea(
      child: Column(
        children: [
          TitleBar(
            title: '용병 명부',
            subtitle:
                '보유 용병  ${widget.mercenaryProgress.length} / ${gameContent.mercenaries.length}',
            onBack: widget.onBack,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
            child: Row(
              children: [
                _RosterFilterButton(
                  label: '전체',
                  selected: raceFilter == null && jobFilter == null,
                  onTap: () => setState(() {
                    raceFilter = null;
                    jobFilter = null;
                  }),
                ),
                const SizedBox(width: 6),
                PopupMenuButton<String>(
                  onSelected: (value) => setState(() => raceFilter = value),
                  itemBuilder: (_) => owned
                      .map((mercenary) => mercenary.race)
                      .toSet()
                      .map(
                        (race) => PopupMenuItem(value: race, child: Text(race)),
                      )
                      .toList(),
                  child: _RosterFilterButton(
                    label: raceFilter ?? '종족',
                    selected: raceFilter != null,
                  ),
                ),
                const SizedBox(width: 6),
                PopupMenuButton<String>(
                  onSelected: (value) => setState(() => jobFilter = value),
                  itemBuilder: (_) => owned
                      .map((mercenary) => mercenary.job)
                      .toSet()
                      .map((job) => PopupMenuItem(value: job, child: Text(job)))
                      .toList(),
                  child: _RosterFilterButton(
                    label: jobFilter ?? '직업',
                    selected: jobFilter != null,
                  ),
                ),
                const Spacer(),
                Text(
                  '${visible.length}명 표시',
                  style: const TextStyle(fontSize: 9, color: Color(0xffd8bd7b)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.tune, color: Color(0xffd8bd7b)),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                childAspectRatio: MediaQuery.sizeOf(context).height < 500
                    ? .82
                    : .72,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: visible.length,
              itemBuilder: (_, index) {
                final mercenary = visible[index];
                return _RosterCard(
                  mercenary: mercenary,
                  progress: widget.mercenaryProgress[mercenary.id]!,
                  onTap: () => widget.onSelect(mercenary),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _RosterFilterButton extends StatelessWidget {
  const _RosterFilterButton({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? const Color(0xff3d3020) : const Color(0xff171a20),
        border: Border.all(
          color: selected ? const Color(0xffd1ad64) : const Color(0xff57492f),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10)),
    ),
  );
}

class _RosterCard extends StatelessWidget {
  const _RosterCard({
    required this.mercenary,
    required this.progress,
    required this.onTap,
  });
  final MercenarySpec mercenary;
  final MercenaryProgress progress;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: GoldPanel(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: Transform.scale(
              scale: 1.9,
              alignment: Alignment.topCenter,
              child: Image.asset(
                mercenary.visual.portraitAsset,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -.78),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xf006080c)],
                stops: [.42, 1],
              ),
            ),
          ),
          Positioned(
            left: 9,
            right: 9,
            bottom: 9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mercenary.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Lv.${progress.level} · ${mercenary.race} · ${mercenary.job}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.white60),
                ),
                const Text(
                  '★★★★★',
                  style: TextStyle(color: Color(0xffffc95d), fontSize: 11),
                ),
              ],
            ),
          ),
          Positioned(
            right: 7,
            top: 7,
            child: Icon(
              mercenary.visual.icon,
              size: 18,
              color: mercenary.visual.accent,
            ),
          ),
        ],
      ),
    ),
  );
}

class MercenaryDetailScreen extends StatelessWidget {
  const MercenaryDetailScreen({
    super.key,
    required this.mercenary,
    required this.progress,
    required this.equippedWeapon,
    required this.weaponProgress,
    required this.inventory,
    required this.gold,
    required this.notice,
    required this.onTrain,
    required this.onAscend,
    required this.onEquipment,
    required this.onBack,
  });
  final MercenarySpec mercenary;
  final MercenaryProgress progress;
  final WeaponSpec equippedWeapon;
  final Map<String, WeaponProgress> weaponProgress;
  final Map<String, int> inventory;
  final int gold;
  final String? notice;
  final VoidCallback onTrain;
  final VoidCallback onAscend;
  final VoidCallback onEquipment;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => DarkBackdrop(
    child: SafeArea(
      child: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            TitleBar(
              title: '용병 상세',
              subtitle: mercenary.epithet,
              onBack: onBack,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final portrait = MercenaryPortrait(mercenary: mercenary);
                  final details = _MercenaryTabs(
                    mercenary: mercenary,
                    progress: progress,
                    equippedWeapon: equippedWeapon,
                    weaponProgress: weaponProgress[equippedWeapon.id]!,
                    inventory: inventory,
                    gold: gold,
                    notice: notice,
                    onTrain: onTrain,
                    onAscend: onAscend,
                    onEquipment: onEquipment,
                  );
                  if (constraints.maxWidth < 700) {
                    return Column(
                      children: [
                        SizedBox(
                          height: 210,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: portrait,
                          ),
                        ),
                        Expanded(child: details),
                      ],
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(flex: 5, child: portrait),
                        const SizedBox(width: 12),
                        Expanded(flex: 6, child: details),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class MercenaryPortrait extends StatelessWidget {
  const MercenaryPortrait({super.key, required this.mercenary});
  final MercenarySpec mercenary;
  @override
  Widget build(BuildContext context) => GoldPanel(
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          mercenary.visual.portraitAsset,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
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
        Positioned(
          left: 16,
          bottom: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mercenary.id.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xffd8bd7d),
                  fontSize: 10,
                  letterSpacing: 3,
                ),
              ),
              Text(
                mercenary.name,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '★★★★★  ${mercenary.race} / ${mercenary.job}',
                style: const TextStyle(color: Color(0xffffcf67)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MercenaryTabs extends StatelessWidget {
  const _MercenaryTabs({
    required this.mercenary,
    required this.progress,
    required this.equippedWeapon,
    required this.weaponProgress,
    required this.inventory,
    required this.gold,
    required this.notice,
    required this.onTrain,
    required this.onAscend,
    required this.onEquipment,
  });
  final MercenarySpec mercenary;
  final MercenaryProgress progress;
  final WeaponSpec equippedWeapon;
  final WeaponProgress weaponProgress;
  final Map<String, int> inventory;
  final int gold;
  final String? notice;
  final VoidCallback onTrain;
  final VoidCallback onAscend;
  final VoidCallback onEquipment;

  @override
  Widget build(BuildContext context) => GoldPanel(
    child: Column(
      children: [
        const TabBar(
          isScrollable: true,
          labelColor: Color(0xffffd27c),
          unselectedLabelColor: Colors.white54,
          indicatorColor: Color(0xffc49a54),
          tabs: [
            Tab(text: '정보'),
            Tab(text: '레벨업'),
            Tab(text: '장비'),
            Tab(text: '스킬'),
            Tab(text: '스토리'),
          ],
        ),
        if (notice != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0x553b2d18),
            child: Text(
              notice!,
              style: const TextStyle(color: Color(0xffffd27c), fontSize: 10),
            ),
          ),
        Expanded(
          child: TabBarView(
            children: [
              _InfoTab(mercenary: mercenary, progress: progress),
              _GrowthTab(
                mercenary: mercenary,
                progress: progress,
                inventory: inventory,
                gold: gold,
                onTrain: onTrain,
                onAscend: onAscend,
              ),
              _EquipmentTab(
                mercenary: mercenary,
                weapon: equippedWeapon,
                progress: weaponProgress,
                onEquipment: onEquipment,
              ),
              _SkillTab(mercenary: mercenary, weapon: equippedWeapon),
              _StoryTab(mercenary: mercenary),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.mercenary, required this.progress});
  final MercenarySpec mercenary;
  final MercenaryProgress progress;
  @override
  Widget build(BuildContext context) {
    final power = ProgressionRules.displayPower(
      catalogPower: mercenary.power,
      catalogLevel: mercenary.level,
      permanentLevel: progress.level,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(
              'Lv.${progress.level} / ${progress.levelCap}',
              style: const TextStyle(color: Color(0xff87b9d5)),
            ),
            const Spacer(),
            Text(
              '전투력  $power',
              style: const TextStyle(
                color: Color(0xffffcf67),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...[
          (
            'HP',
            '${(mercenary.maxHp * ProgressionRules.mercenaryHpMultiplier(mercenary.level, progress.level)).round()}',
          ),
          (
            '공격력',
            '${(mercenary.baseDamage * 715 * (.45 + .55 * progress.level / mercenary.level)).round()}',
          ),
          ('방어력', '${920 + progress.level * 4}'),
          ('치명타', mercenary.style == CombatStyle.blades ? '32.5%' : '18.0%'),
          ('회피', mercenary.style == CombatStyle.blades ? '24.1%' : '12.0%'),
          ('공격속도', (1 / mercenary.attackInterval).toStringAsFixed(2)),
        ].map((e) => StatRow(e.$1, e.$2)),
        const Divider(color: Color(0xff5e5038)),
        Text(
          '고유 특성 · ${mercenary.trait}',
          style: const TextStyle(
            color: Color(0xffffd27c),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          mercenary.traitDescription,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0x553f2852),
            border: Border.all(color: const Color(0xff745887)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '종족 특성 · ${mercenary.race}',
                style: const TextStyle(color: Color(0xffcda9e3), fontSize: 11),
              ),
              Text(
                _raceTrait(mercenary.race),
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
              const Divider(color: Color(0xff5e5038), height: 18),
              Text(
                '고유무기  ${gameContent.weapons.firstWhere((weapon) => weapon.id == mercenary.signatureWeaponId).name}',
                style: const TextStyle(color: Color(0xffffd27c), fontSize: 11),
              ),
              Text(
                '궁극기  ${mercenary.ultimate}',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GrowthTab extends StatelessWidget {
  const _GrowthTab({
    required this.mercenary,
    required this.progress,
    required this.inventory,
    required this.gold,
    required this.onTrain,
    required this.onAscend,
  });
  final MercenarySpec mercenary;
  final MercenaryProgress progress;
  final Map<String, int> inventory;
  final int gold;
  final VoidCallback onTrain;
  final VoidCallback onAscend;
  @override
  Widget build(BuildContext context) {
    final capped = progress.level >= progress.levelCap;
    final requiredXp = ProgressionRules.mercenaryXpToNext(progress.level);
    final sealCost = ProgressionRules.ascensionCost(progress.ascension);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Lv.${progress.level} / ${progress.levelCap}  ·  승급 ${progress.ascension} / 2',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Meter(
          value: capped ? 1 : progress.xp / requiredXp,
          color: mercenary.visual.accent,
        ),
        const SizedBox(height: 5),
        Text(
          capped ? '현재 단계 MAX' : '${progress.xp} / $requiredXp EXP',
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const Divider(color: Color(0xff5e5038), height: 28),
        StatRow('보유 골드', '$gold'),
        StatRow('야전 식량', '${inventory['field_ration'] ?? 0}'),
        StatRow('계약 인장', '${inventory['contract_seal'] ?? 0}'),
        const SizedBox(height: 12),
        FantasyButton(
          label: '전술 훈련  +${CampMetaRules.trainingXp} EXP',
          icon: Icons.fitness_center,
          onTap: onTrain,
          prominent: !capped,
        ),
        const SizedBox(height: 6),
        const Text(
          '소모: 1,000 골드 · 야전 식량 1개',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 12),
        FantasyButton(
          label: progress.ascension >= 2 ? '최종 승급 완료' : '승급 · 상한 +5',
          icon: Icons.star_outline,
          onTap: onAscend,
        ),
        const SizedBox(height: 6),
        Text(
          '조건: Lv.${progress.levelCap} · 계약 인장 $sealCost개',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}

class _EquipmentTab extends StatelessWidget {
  const _EquipmentTab({
    required this.mercenary,
    required this.weapon,
    required this.progress,
    required this.onEquipment,
  });
  final MercenarySpec mercenary;
  final WeaponSpec weapon;
  final WeaponProgress progress;
  final VoidCallback onEquipment;
  @override
  Widget build(BuildContext context) {
    final signature = weapon.ownerId == mercenary.id;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 126,
              height: 126,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xff090b10),
                border: Border.all(color: weapon.visual.color, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: weapon.visual.color.withValues(alpha: .22),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Image.asset(
                weaponArtAsset(weapon.id),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => Icon(
                  weapon.visual.icon,
                  size: 58,
                  color: weapon.visual.color,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weapon.name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${weapon.grade} · 영구 Lv.${progress.level} · 성장 ${progress.stage}단계',
                    style: TextStyle(color: weapon.visual.color),
                  ),
                  const SizedBox(height: 8),
                  _EquipmentStatLine('공격력', '${weapon.attack}'),
                  _EquipmentStatLine('치명타', '${weapon.crit}%'),
                  _EquipmentStatLine(
                    '공격속도',
                    weapon.speed >= 0
                        ? '+${weapon.speed}%'
                        : '${weapon.speed}%',
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(color: Color(0xff5e5038), height: 20),
        Text(
          '무기 특성',
          style: TextStyle(
            color: weapon.visual.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(weapon.description, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 9),
        if (signature)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x663c2850),
              border: Border.all(color: const Color(0xff8e67a5)),
            ),
            child: Text(
              '고유 장비 공명 · 궁극기 「${mercenary.ultimate}」 활성화',
              style: const TextStyle(
                color: Color(0xffddb7f0),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        const SizedBox(height: 10),
        FantasyButton(
          label: '장비 변경',
          icon: Icons.auto_awesome_mosaic_outlined,
          onTap: onEquipment,
        ),
      ],
    );
  }
}

class _EquipmentStatLine extends StatelessWidget {
  const _EquipmentStatLine(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ],
    ),
  );
}

class _SkillTab extends StatelessWidget {
  const _SkillTab({required this.mercenary, required this.weapon});
  final MercenarySpec mercenary;
  final WeaponSpec weapon;
  @override
  Widget build(BuildContext context) {
    final signature = gameContent.weapons.firstWhere(
      (candidate) => candidate.id == mercenary.signatureWeaponId,
    );
    final resonanceActive = weapon.id == signature.id;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const _SkillSectionLabel(
          title: '캐릭터 고유 능력',
          detail: '장비와 관계없이 항상 적용되는 영구 능력',
        ),
        _SkillRow(
          title: '종족 특성 · ${mercenary.race}',
          detail: _raceTrait(mercenary.race),
          icon: mercenary.visual.icon,
        ),
        _SkillRow(
          title: '개인 특성 · ${mercenary.trait}',
          detail: mercenary.traitDescription,
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 5),
        _SkillSectionLabel(
          title: '고유무기 공명',
          detail: resonanceActive
              ? '${signature.name} 장착 중 · 궁극기 활성화'
              : '현재 ${weapon.name} 장착 중 · ${signature.name} 장착 시 활성화',
          active: resonanceActive,
        ),
        _SkillRow(
          title: '고유무기 · ${signature.name}',
          detail: signature.description,
          icon: signature.visual.icon,
          active: resonanceActive,
        ),
        _SkillRow(
          title: '궁극기 · ${mercenary.ultimate}',
          detail: resonanceActive
              ? '공명 활성화 · 궁극기 게이지 충전 및 발동 가능'
              : '공명 비활성 · 고유무기를 장착해야 발동 가능',
          icon: resonanceActive ? Icons.auto_awesome : Icons.lock_outline,
          active: resonanceActive,
        ),
        const SizedBox(height: 5),
        const _SkillSectionLabel(
          title: '런 전용 성장',
          detail: '전투 중 획득한 무기·전술서는 해당 출전에서만 유지됩니다.',
        ),
      ],
    );
  }
}

class _SkillSectionLabel extends StatelessWidget {
  const _SkillSectionLabel({
    required this.title,
    required this.detail,
    this.active = true,
  });
  final String title;
  final String detail;
  final bool active;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 2, 2, 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: active ? const Color(0xffffd27c) : Colors.white38,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          detail,
          style: const TextStyle(color: Colors.white54, fontSize: 9.5),
        ),
      ],
    ),
  );
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({
    required this.title,
    required this.detail,
    required this.icon,
    this.active = true,
  });
  final String title;
  final String detail;
  final IconData icon;
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0x9911151c),
      border: Border.all(color: const Color(0xff514634)),
    ),
    child: Row(
      children: [
        Icon(icon, color: active ? const Color(0xffc7a6df) : Colors.white30),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: active ? const Color(0xffffd27c) : Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                detail,
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StoryTab extends StatelessWidget {
  const _StoryTab({required this.mercenary});
  final MercenarySpec mercenary;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Text(
        '「${mercenary.epithet}」',
        style: const TextStyle(
          color: Color(0xffffd27c),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        _story(mercenary.id),
        style: const TextStyle(
          color: Colors.white70,
          height: 1.65,
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        '용병단 기록',
        style: TextStyle(color: Color(0xffc7a6df), fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),
      const Text(
        '충성은 나라가 아니라 계약에 묶인다. 그러나 동료를 버리지 않는다는 조항만큼은, 누구도 명령하지 않았다.',
        style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.5),
      ),
    ],
  );
}

String _raceTrait(String race) => switch (race) {
  '묘족' => '치명타와 회피에 특화되며 이동 속도가 빠르다.',
  '늑대족' => '연속 처치와 출혈을 통해 전투가 길수록 강해진다.',
  '여우족' => '마법, 환영, 상태이상 연계에 특화된다.',
  '토끼족' => '기동과 선제 공격에 특화되며 원거리 교전에서 유리하다.',
  '사슴족' => '방어와 아군 보호에 특화되며 전선 유지력이 높다.',
  '조류계' => '전황 파악과 전술 연계에 특화되며 재사용 주기를 단축한다.',
  '파충류계' => '집중과 관통에 특화되며 자리를 지킬수록 강해진다.',
  '환수계' => '마법과 무기 공격을 교차해 공명 피해를 증폭한다.',
  _ => '종족 고유의 전장 적응력을 발휘한다.',
};

String _story(String id) => switch (id) {
  'luna' =>
    '달이 뜨지 않는 밤에도 루나는 그림자를 찾는다. 멸망한 변경 도시의 마지막 길잡이였던 그녀는 이제 가장 위험한 계약만을 골라 전장을 건넌다.',
  'kael' =>
    '제국의 사냥개라 불리던 카일은 주인의 깃발을 찢고 자유 용병이 되었다. 그는 선봉에서 싸우지만, 퇴로를 가장 오래 지키는 자이기도 하다.',
  'sera' =>
    '세라의 유리불꽃은 적에게는 환각을, 동료에게는 귀환할 길을 보여 준다. 그녀가 찾는 것은 돈보다 오래된 전쟁의 진실이다.',
  'nyra' =>
    '니라는 국경 우편대를 지키던 척후병이었다. 마지막 전령을 살려 보낸 날, 그녀는 왕관 대신 살아 돌아오는 병사들의 편에 서기로 맹세했다.',
  'aurel' =>
    '아우렐의 뿔에는 멸망한 숲 왕국의 금장이 남아 있다. 그는 방패를 세울 때마다 잃어버린 백성의 이름을 읊고, 그 누구도 자신의 뒤에서 쓰러지게 두지 않는다.',
  'vesta' =>
    '베스타는 계약서를 읽는 것보다 거짓말을 듣는 데 익숙하다. 깃펜과 주술서를 함께 든 그녀는 전쟁의 승패보다 누가 전쟁을 팔아 이익을 얻는지 기록한다.',
  'rask' =>
    '라스크는 용병단을 습격했다가 사로잡힌 사냥꾼이었다. 단장은 그의 창보다 굶주린 마을의 사정을 먼저 보았고, 그는 그 빚을 갚기 위해 가장 위험한 선봉을 맡는다.',
  'iris' =>
    '아이리스는 오래된 환수의 피와 월식의 저주를 함께 물려받았다. 그녀는 마력을 두려워하지 않는 동료를 찾아 용병단에 왔고, 밤마다 봉인된 달의 목소리를 기록한다.',
  _ => '이 용병의 기록은 계약 서고에서 복원 중이다.',
};
