part of '../../app/game_app.dart';

class RosterScreen extends StatelessWidget {
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
  Widget build(BuildContext context) => DarkBackdrop(
    child: SafeArea(
      child: Column(
        children: [
          TitleBar(title: '용병 명부', subtitle: '보유 용병  3 / 100', onBack: onBack),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                ChipLabel('전체'),
                SizedBox(width: 6),
                ChipLabel('종족'),
                SizedBox(width: 6),
                ChipLabel('직업'),
                Spacer(),
                Icon(Icons.tune, color: Color(0xffd8bd7b)),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 210,
                childAspectRatio: .76,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: gameContent.mercenaries.length,
              itemBuilder: (_, index) {
                final mercenary = gameContent.mercenaries[index];
                return _RosterCard(
                  mercenary: mercenary,
                  progress: mercenaryProgress[mercenary.id]!,
                  onTap: () => onSelect(mercenary),
                );
              },
            ),
          ),
        ],
      ),
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
                  'Lv.${progress.level} / ${progress.levelCap}  ·  ${mercenary.race}',
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
    final bonusLevels = progress.level - mercenary.level;
    final power = (mercenary.power * (1 + bonusLevels * .025)).round();
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
          ('공격력', '${mercenary.baseDamage * 715 + bonusLevels * 54}'),
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
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Icon(weapon.visual.icon, size: 72, color: weapon.visual.color),
        ),
        Text(
          weapon.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          '${weapon.grade} · 영구 Lv.${progress.level} · ${progress.stage}단계',
          textAlign: TextAlign.center,
          style: TextStyle(color: weapon.visual.color),
        ),
        const Divider(color: Color(0xff5e5038), height: 25),
        Text(
          weapon.description,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (signature) ChipLabel('고유 장비 · 궁극기 활성화'),
        const SizedBox(height: 14),
        FantasyButton(
          label: '장비 변경',
          icon: Icons.auto_awesome_mosaic_outlined,
          onTap: onEquipment,
        ),
      ],
    );
  }
}

class _SkillTab extends StatelessWidget {
  const _SkillTab({required this.mercenary, required this.weapon});
  final MercenarySpec mercenary;
  final WeaponSpec weapon;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(14),
    children: [
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
      _SkillRow(
        title: '무기 특성 · ${weapon.name}',
        detail: weapon.description,
        icon: weapon.visual.icon,
      ),
      _SkillRow(
        title: '궁극기 · ${mercenary.ultimate}',
        detail: weapon.ownerId == mercenary.id
            ? '고유무기 공명 활성화 · 전장을 뒤집는 광역 필살기'
            : '고유무기 장착 시 활성화',
        icon: Icons.auto_awesome,
      ),
    ],
  );
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({
    required this.title,
    required this.detail,
    required this.icon,
  });
  final String title;
  final String detail;
  final IconData icon;
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
        Icon(icon, color: const Color(0xffc7a6df)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xffffd27c),
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
  _ => '종족 고유의 전장 적응력을 발휘한다.',
};

String _story(String id) => switch (id) {
  'luna' =>
    '달이 뜨지 않는 밤에도 루나는 그림자를 찾는다. 멸망한 변경 도시의 마지막 길잡이였던 그녀는 이제 가장 위험한 계약만을 골라 전장을 건넌다.',
  'kael' =>
    '제국의 사냥개라 불리던 카일은 주인의 깃발을 찢고 자유 용병이 되었다. 그는 선봉에서 싸우지만, 퇴로를 가장 오래 지키는 자이기도 하다.',
  'sera' =>
    '세라의 유리불꽃은 적에게는 환각을, 동료에게는 귀환할 길을 보여 준다. 그녀가 찾는 것은 돈보다 오래된 전쟁의 진실이다.',
  _ => '아직 공개되지 않은 용병단의 기록이다.',
};
