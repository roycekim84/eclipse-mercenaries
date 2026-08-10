part of '../../app/game_app.dart';

class ForgeScreen extends StatefulWidget {
  const ForgeScreen({
    super.key,
    required this.weapons,
    required this.progress,
    required this.inventory,
    required this.gold,
    required this.notice,
    required this.onEnhance,
    required this.onCraft,
    required this.onDismantle,
    required this.onBack,
  });

  final List<WeaponSpec> weapons;
  final Map<String, WeaponProgress> progress;
  final Map<String, int> inventory;
  final int gold;
  final String? notice;
  final ValueChanged<WeaponSpec> onEnhance;
  final VoidCallback onCraft;
  final VoidCallback onDismantle;
  final VoidCallback onBack;

  @override
  State<ForgeScreen> createState() => _ForgeScreenState();
}

class _ForgeScreenState extends State<ForgeScreen> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    final weapon = widget.weapons[selected];
    final progress = widget.progress[weapon.id]!;
    final nextXp = ProgressionRules.weaponXpToNext(progress.level);
    return DarkBackdrop(
      child: SafeArea(
        child: Column(
          children: [
            TitleBar(
              title: '대장간',
              subtitle: '강화 · 제작 · 분해 · 전리품 도감',
              onBack: widget.onBack,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final compact = constraints.maxWidth < 760;
                  final weaponList = _ForgeWeaponList(
                    weapons: widget.weapons,
                    progress: widget.progress,
                    selected: selected,
                    onSelect: (value) => setState(() => selected = value),
                  );
                  final detail = _ForgeDetail(
                    weapon: weapon,
                    progress: progress,
                    nextXp: nextXp,
                    inventory: widget.inventory,
                    gold: widget.gold,
                    notice: widget.notice,
                    onEnhance: () => widget.onEnhance(weapon),
                    onCraft: widget.onCraft,
                    onDismantle: widget.onDismantle,
                  );
                  return compact
                      ? Column(
                          children: [
                            SizedBox(height: 155, child: weaponList),
                            Expanded(child: detail),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(flex: 4, child: weaponList),
                            Expanded(flex: 6, child: detail),
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

class _ForgeWeaponList extends StatelessWidget {
  const _ForgeWeaponList({
    required this.weapons,
    required this.progress,
    required this.selected,
    required this.onSelect,
  });
  final List<WeaponSpec> weapons;
  final Map<String, WeaponProgress> progress;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.all(12),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 180,
      mainAxisExtent: 72,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    ),
    itemCount: weapons.length,
    itemBuilder: (_, index) {
      final weapon = weapons[index];
      final growth = progress[weapon.id]!;
      return InkWell(
        onTap: () => onSelect(index),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xdd12151b),
            border: Border.all(
              color: selected == index
                  ? const Color(0xffffcf70)
                  : const Color(0xff584b35),
              width: selected == index ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              GameAssetArt(
                asset: weaponArtAsset(weapon.id),
                fallbackIcon: weapon.visual.icon,
                fallbackColor: weapon.visual.color,
                size: 34,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weapon.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Lv.${growth.level} · ${growth.stage}단계',
                      style: const TextStyle(
                        color: Color(0xffc7a6df),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ForgeDetail extends StatelessWidget {
  const _ForgeDetail({
    required this.weapon,
    required this.progress,
    required this.nextXp,
    required this.inventory,
    required this.gold,
    required this.notice,
    required this.onEnhance,
    required this.onCraft,
    required this.onDismantle,
  });
  final WeaponSpec weapon;
  final WeaponProgress progress;
  final int nextXp;
  final Map<String, int> inventory;
  final int gold;
  final String? notice;
  final VoidCallback onEnhance;
  final VoidCallback onCraft;
  final VoidCallback onDismantle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
    child: DefaultTabController(
      length: 3,
      child: GoldPanel(
        child: Column(
          children: [
            const TabBar(
              labelColor: Color(0xffffd27c),
              unselectedLabelColor: Colors.white54,
              indicatorColor: Color(0xffc49a54),
              tabs: [
                Tab(text: '강화'),
                Tab(text: '제작 / 분해'),
                Tab(text: '전리품 도감'),
              ],
            ),
            if (notice != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                color: const Color(0x553b2d18),
                child: Text(
                  notice!,
                  style: const TextStyle(
                    color: Color(0xffffd27c),
                    fontSize: 11,
                  ),
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                          children: [
                            Row(
                              children: [
                                GameAssetArt(
                                  asset: weaponArtAsset(weapon.id),
                                  fallbackIcon: weapon.visual.icon,
                                  fallbackColor: weapon.visual.color,
                                  size: 64,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        weapon.name,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${weapon.grade} · Lv.${progress.level} · 성장 ${progress.stage}단계',
                                        style: TextStyle(
                                          color: weapon.visual.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Meter(
                              value: progress.level >= 20
                                  ? 1
                                  : progress.xp / nextXp,
                              color: weapon.visual.color,
                            ),
                            const SizedBox(height: 7),
                            Text(
                              progress.level >= 20
                                  ? 'MAX'
                                  : '무기 경험치 ${progress.xp} / $nextXp',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white60,
                              ),
                            ),
                            const Divider(color: Color(0xff665536), height: 28),
                            StatRow('보유 골드', '$gold'),
                            StatRow('전장 고철', '${inventory['war_scrap'] ?? 0}'),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                        child: Column(
                          children: [
                            FantasyButton(
                              label: '담금질  +${CampMetaRules.forgeXp} EXP',
                              icon: Icons.handyman,
                              onTap: onEnhance,
                              prominent: true,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '소모: 700 골드 · 전장 고철 2개',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      _ForgeRecipe(
                        title: '단련된 흑철 제작',
                        detail: '전장 고철 3개 → 단련된 흑철 1개',
                        icon: Icons.local_fire_department,
                        button: '제작',
                        onTap: onCraft,
                      ),
                      const SizedBox(height: 12),
                      _ForgeRecipe(
                        title: '흑철 분해',
                        detail: '단련된 흑철 1개 → 전장 고철 2개',
                        icon: Icons.recycling,
                        button: '분해',
                        onTap: onDismantle,
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(14),
                    children: lootAcquisitionSources.entries.map((entry) {
                      final item = lootItemById(entry.key);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0x9911151c),
                          border: Border.all(color: const Color(0xff4e4434)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              color: Color(0xffbda2d4),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item?.name ?? entry.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    entry.value,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '×${inventory[entry.key] ?? 0}',
                              style: const TextStyle(
                                color: Color(0xffffd27c),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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

class _ForgeRecipe extends StatelessWidget {
  const _ForgeRecipe({
    required this.title,
    required this.detail,
    required this.icon,
    required this.button,
    required this.onTap,
  });
  final String title;
  final String detail;
  final IconData icon;
  final String button;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xaa15171d),
      border: Border.all(color: const Color(0xff68583c)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 34, color: const Color(0xffd09a58)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                detail,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 92,
          child: FantasyButton(
            label: button,
            icon: Icons.chevron_right,
            onTap: onTap,
          ),
        ),
      ],
    ),
  );
}
