part of '../../app/game_app.dart';

class EnemyCodexScreen extends StatefulWidget {
  const EnemyCodexScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<EnemyCodexScreen> createState() => _EnemyCodexScreenState();
}

class _EnemyCodexScreenState extends State<EnemyCodexScreen> {
  EnemyRank? filter;
  late EnemyArchetypeSpec selected;

  @override
  void initState() {
    super.initState();
    selected = gameContent.enemies.first;
  }

  List<EnemyArchetypeSpec> get visible => filter == null
      ? gameContent.enemies
      : gameContent.enemies
            .where((enemy) => enemy.rank == filter)
            .toList(growable: false);

  void setFilter(EnemyRank? value) {
    setState(() {
      filter = value;
      if (!visible.contains(selected)) selected = visible.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final commonCount = gameContent.enemies
        .where((enemy) => enemy.rank == EnemyRank.common)
        .length;
    final eliteCount = gameContent.enemies
        .where((enemy) => enemy.rank == EnemyRank.elite)
        .length;
    final bossCount = gameContent.enemies
        .where((enemy) => enemy.rank == EnemyRank.boss)
        .length;
    return DarkBackdrop(
      child: SafeArea(
        child: Column(
          children: [
            TitleBar(
              title: '전장 도감',
              subtitle: '조우한 세력과 병력의 전술 정보를 열람합니다',
              onBack: widget.onBack,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  EnemyFilterChip(
                    label: '전체 ${gameContent.enemies.length}',
                    selected: filter == null,
                    onTap: () => setFilter(null),
                  ),
                  EnemyFilterChip(
                    label: '일반 $commonCount',
                    selected: filter == EnemyRank.common,
                    onTap: () => setFilter(EnemyRank.common),
                  ),
                  EnemyFilterChip(
                    label: '정예 $eliteCount',
                    selected: filter == EnemyRank.elite,
                    onTap: () => setFilter(EnemyRank.elite),
                  ),
                  EnemyFilterChip(
                    label: '지휘관 $bossCount',
                    selected: filter == EnemyRank.boss,
                    onTap: () => setFilter(EnemyRank.boss),
                  ),
                  const Spacer(),
                  Text(
                    '전술 기록  ${gameContent.enemies.length}종 · 전장 조우 시 상세 갱신',
                    style: const TextStyle(
                      color: Color(0xffd6bd81),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 850;
                  final list = GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: compact ? 2 : 3,
                      mainAxisExtent: 98,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final enemy = visible[index];
                      return EnemyCodexCard(
                        enemy: enemy,
                        selected: selected.id == enemy.id,
                        onTap: () => setState(() => selected = enemy),
                      );
                    },
                  );
                  if (compact) {
                    return Column(
                      children: [
                        Expanded(child: list),
                        SizedBox(
                          height: 205,
                          child: EnemyCodexDetail(enemy: selected),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(flex: 6, child: list),
                      SizedBox(
                        width: 390,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
                          child: EnemyCodexDetail(enemy: selected),
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

class EnemyFilterChip extends StatelessWidget {
  const EnemyFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 7),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? const Color(0xff503c25) : const Color(0xff171a20),
        border: Border.all(
          color: selected ? const Color(0xffd1ad64) : const Color(0xff51462f),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: selected ? const Color(0xffffd784) : Colors.white60,
        ),
      ),
    ),
  );
}

class EnemyCodexCard extends StatelessWidget {
  const EnemyCodexCard({
    super.key,
    required this.enemy,
    required this.selected,
    required this.onTap,
  });

  final EnemyArchetypeSpec enemy;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            enemy.visual.color.withValues(alpha: .42),
            const Color(0xff0d1015),
          ],
        ),
        border: Border.all(
          color: selected ? const Color(0xffffd477) : const Color(0xff55462f),
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                GameAssetArt(
                  asset: enemyArtAsset(enemy),
                  fallbackIcon: enemy.visual.icon,
                  fallbackColor: enemy.visual.color,
                  size: 62,
                ),
                if (enemy.rank != EnemyRank.common)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: enemy.rank == EnemyRank.boss
                            ? const Color(0xffffd16c)
                            : const Color(0xffc895e3),
                      ),
                    ),
                  ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xee101319),
                      border: Border.all(color: enemy.visual.color),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      enemy.visual.icon,
                      size: 12,
                      color: enemy.visual.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 6, 8, 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enemy.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${enemyFactionName(enemy.faction)} · ${enemyRankName(enemy.rank)}',
                    style: TextStyle(fontSize: 9, color: enemy.visual.color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    enemy.abilityDescription,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 8, color: Colors.white54),
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

class EnemyCodexDetail extends StatelessWidget {
  const EnemyCodexDetail({super.key, required this.enemy});

  final EnemyArchetypeSpec enemy;

  @override
  Widget build(BuildContext context) => GoldPanel(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: enemy.visual.color.withValues(alpha: .16),
                  border: Border.all(color: enemy.visual.color),
                ),
                child: GameAssetArt(
                  asset: enemyArtAsset(enemy),
                  fallbackIcon: enemy.visual.icon,
                  fallbackColor: enemy.visual.color,
                  size: 64,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enemy.name,
                      style: const TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${enemyFactionName(enemy.faction)} · ${enemyRankName(enemy.rank)} · ${unitRoleName(enemy.role)}',
                      style: TextStyle(fontSize: 10, color: enemy.visual.color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('전술 특성', style: TextStyle(color: Color(0xffd6bd81))),
          const SizedBox(height: 5),
          Text(enemy.abilityDescription, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 14),
          const Text('전장 기록', style: TextStyle(color: Color(0xffd6bd81))),
          const SizedBox(height: 5),
          Text(
            enemy.lore,
            style: const TextStyle(
              height: 1.45,
              fontSize: 10,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: CodexStat('체력', '${100 + enemy.hpBonus}')),
              Expanded(child: CodexStat('공격', '${10 + enemy.damageBonus}')),
              Expanded(child: CodexStat('방어', '${enemy.defenseBonus}')),
              Expanded(
                child: CodexStat(
                  '속도',
                  '${(enemy.speedMultiplier * 100).round()}%',
                ),
              ),
            ],
          ),
          if (enemy.rareDropId != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0x443f2852),
                border: Border.all(color: const Color(0xff8d6aa0)),
              ),
              child: Text(
                '희귀 전리품  ${rareDropName(enemy.rareDropId!)}',
                style: const TextStyle(fontSize: 10, color: Color(0xffd6a8ee)),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class CodexStat extends StatelessWidget {
  const CodexStat(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: const TextStyle(fontSize: 8, color: Colors.white38)),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(fontSize: 11, color: Color(0xffffd27c)),
      ),
    ],
  );
}

String signed(int value) => value >= 0 ? '+$value' : '$value';

String enemyRankName(EnemyRank rank) => switch (rank) {
  EnemyRank.common => '일반',
  EnemyRank.elite => '정예',
  EnemyRank.boss => '지휘관',
};

String unitRoleName(UnitRole role) => switch (role) {
  UnitRole.infantry => '보병',
  UnitRole.shield => '방패병',
  UnitRole.archer => '궁병',
  UnitRole.cavalry => '기병',
  UnitRole.mage => '마법병',
  UnitRole.siege => '공성병기',
  UnitRole.commander => '지휘관',
};

String rareDropName(String id) => switch (id) {
  'nameless_spur' => '이름 없는 박차',
  'blood_ember' => '응고된 혈화',
  'marshal_seal' => '공성군감의 인장',
  'hunter_insignia' => '추격대장의 표식',
  _ => id,
};
