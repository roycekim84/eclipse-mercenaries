part of '../../app/game_app.dart';

class ContractScreen extends StatelessWidget {
  const ContractScreen({
    super.key,
    required this.selected,
    required this.factionReputation,
    required this.operationProgress,
    required this.onSelect,
    required this.onBack,
    required this.onDeploy,
  });
  final BattlefieldContract selected;
  final Map<String, int> factionReputation;
  final Map<String, int> operationProgress;
  final ValueChanged<BattlefieldContract> onSelect;
  final VoidCallback onBack;
  final VoidCallback onDeploy;

  @override
  Widget build(BuildContext context) {
    return DarkBackdrop(
      child: SafeArea(
        child: Column(
          children: [
            TitleBar(
              title: '전쟁 계약',
              subtitle: '참여할 전쟁을 선택하십시오',
              onBack: onBack,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: MapPainter()),
                      ),
                      ...List.generate(contracts.length, (index) {
                        final item = contracts[index];
                        const xFactors = [.12, .30, .48, .66, .84, .75];
                        const yFactors = [.18, .49, .16, .48, .18, .67];
                        final nodeAreaHeight = (constraints.maxHeight - 112)
                            .clamp(180.0, constraints.maxHeight)
                            .toDouble();
                        final x = constraints.maxWidth * xFactors[index];
                        final y = nodeAreaHeight * yFactors[index];
                        final safeTop = (y - 48)
                            .clamp(18.0, nodeAreaHeight - 100)
                            .toDouble();
                        return Positioned(
                          left: x - 76,
                          top: safeTop,
                          child: ContractMarker(
                            contract: item,
                            faction: FactionRules.byId(item.factionId),
                            selected: selected == item,
                            onTap: () => onSelect(item),
                          ),
                        );
                      }),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Row(
                          children: [
                            Expanded(
                              child: ContractSummary(
                                contract: selected,
                                faction: FactionRules.byId(selected.factionId),
                                reputation:
                                    factionReputation[selected.factionId] ?? 0,
                                operation: WarOperationRules.forFaction(
                                  selected.factionId,
                                ),
                                operationProgress:
                                    operationProgress[WarOperationRules.forFaction(
                                      selected.factionId,
                                    ).id] ??
                                    0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 210,
                              child: FantasyButton(
                                label: '계약 수락 · 출전',
                                icon: Icons.gavel,
                                prominent: true,
                                onTap: onDeploy,
                              ),
                            ),
                          ],
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

class MercenarySelectScreen extends StatefulWidget {
  const MercenarySelectScreen({
    super.key,
    required this.selected,
    required this.equippedWeapon,
    required this.mercenaryProgress,
    required this.onSelect,
    required this.onBack,
    required this.onEquipment,
    required this.onDeploy,
  });

  final MercenarySpec selected;
  final WeaponSpec equippedWeapon;
  final Map<String, MercenaryProgress> mercenaryProgress;
  final ValueChanged<MercenarySpec> onSelect;
  final VoidCallback onBack;
  final VoidCallback onEquipment;
  final VoidCallback onDeploy;

  @override
  State<MercenarySelectScreen> createState() => _MercenarySelectScreenState();
}

class _MercenarySelectScreenState extends State<MercenarySelectScreen> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelection());
  }

  @override
  void didUpdateWidget(covariant MercenarySelectScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected.id != widget.selected.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelection());
    }
  }

  void _revealSelection() {
    if (!_controller.hasClients) return;
    final index = gameContent.mercenaries.indexWhere(
      (mercenary) => mercenary.id == widget.selected.id,
    );
    if (index < 0) return;
    final itemExtent = MediaQuery.sizeOf(context).width < 760 ? 220.0 : 138.0;
    _controller.animateTo(
      (index * itemExtent).clamp(0, _controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DarkBackdrop(
    child: SafeArea(
      child: Column(
        children: [
          TitleBar(
            title: '출전 용병 선택',
            subtitle: '이번 계약에 파견할 용병을 선택하십시오',
            onBack: widget.onBack,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final cards = ListView.separated(
                  controller: _controller,
                  scrollDirection: compact ? Axis.horizontal : Axis.vertical,
                  padding: const EdgeInsets.all(12),
                  itemCount: gameContent.mercenaries.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: 10, height: 10),
                  itemBuilder: (_, index) {
                    final mercenary = gameContent.mercenaries[index];
                    return SizedBox(
                      width: compact ? 210 : double.infinity,
                      height: compact ? double.infinity : 128,
                      child: DeploymentMercenaryCard(
                        mercenary: mercenary,
                        progress: widget.mercenaryProgress[mercenary.id],
                        selected: widget.selected.id == mercenary.id,
                        onTap: () => widget.onSelect(mercenary),
                      ),
                    );
                  },
                );
                final detail = DeploymentSummary(
                  mercenary: widget.selected,
                  weapon: widget.equippedWeapon,
                  onEquipment: widget.onEquipment,
                  onDeploy: widget.onDeploy,
                );
                return compact
                    ? Column(
                        children: [
                          Expanded(child: cards),
                          SizedBox(height: 205, child: detail),
                        ],
                      )
                    : Row(
                        children: [
                          SizedBox(width: 330, child: cards),
                          Expanded(child: detail),
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

class DeploymentMercenaryCard extends StatelessWidget {
  const DeploymentMercenaryCard({
    super.key,
    required this.mercenary,
    required this.progress,
    required this.selected,
    required this.onTap,
  });
  final MercenarySpec mercenary;
  final MercenaryProgress? progress;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: const Color(0xff11131a),
          border: Border.all(
            color: selected ? const Color(0xffffcf70) : const Color(0xff5d5038),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x557957a0), blurRadius: 16)]
              : null,
        ),
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: .72,
              child: Image.asset(
                mercenary.visual.portraitAsset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mercenary.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${mercenary.race} / ${mercenary.job}',
                      style: TextStyle(
                        color: mercenary.visual.accent,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '전투력 ${mercenary.power}',
                      style: const TextStyle(
                        color: Color(0xffd7bd7d),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Lv.${progress?.level ?? mercenary.level}  ★★★★★',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DeploymentSummary extends StatelessWidget {
  const DeploymentSummary({
    super.key,
    required this.mercenary,
    required this.weapon,
    required this.onEquipment,
    required this.onDeploy,
  });
  final MercenarySpec mercenary;
  final WeaponSpec weapon;
  final VoidCallback onEquipment;
  final VoidCallback onDeploy;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: GoldPanel(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 300,
            child: Opacity(
              opacity: .42,
              child: Image.asset(
                mercenary.visual.portraitAsset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xff11141b),
                  Color(0xdd11141b),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).height < 500 ? 10 : 18,
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mercenary.epithet,
                          style: TextStyle(
                            color: mercenary.visual.accent,
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          mercenary.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${mercenary.race} · ${mercenary.job}   전투력 ${mercenary.power}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '개인 특성 · ${mercenary.trait}',
                          style: const TextStyle(
                            color: Color(0xffffd27c),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          mercenary.traitDescription,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xaa0b0d12),
                            border: Border.all(color: weapon.visual.color),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                weapon.visual.icon,
                                color: weapon.visual.color,
                              ),
                              const SizedBox(width: 9),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    weapon.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${weapon.grade} · 공격력 ${weapon.attack}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '궁극기  ${mercenary.ultimate}',
                          style: TextStyle(
                            color: weapon.ownerId == mercenary.id
                                ? const Color(0xffc7a6df)
                                : Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: FantasyButton(
                        label: '장비 변경',
                        icon: Icons.auto_awesome_mosaic_outlined,
                        onTap: onEquipment,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FantasyButton(
                        label: '이 용병으로 출전',
                        icon: Icons.gavel,
                        prominent: true,
                        onTap: onDeploy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
