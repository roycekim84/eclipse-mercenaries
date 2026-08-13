part of '../../app/game_app.dart';

// The first contract sits below the legend and the final branch is pushed
// outward so an expanded selection card never covers a neighbouring node.
const _contractXFactors = [.12, .30, .48, .66, .84, .88];
const _contractYFactors = [.66, .53, .20, .51, .20, .72];

class ContractScreen extends StatelessWidget {
  const ContractScreen({
    super.key,
    required this.selected,
    required this.commanderLevel,
    required this.factionReputation,
    required this.operationProgress,
    required this.onSelect,
    required this.onBack,
    required this.onDeploy,
  });
  final BattlefieldContract selected;
  final int commanderLevel;
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
                        child: Image.asset(
                          'assets/images/ui/war_contract_map.jpg',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x4405090f),
                                Color(0x1105090f),
                                Color(0xbb05070b),
                              ],
                              stops: [0, .55, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        top: 10,
                        child: _WarMapLegend(
                          factionReputation: factionReputation,
                          operationProgress: operationProgress,
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _ContractRoutePainter(
                              selectedIndex: contracts.indexOf(selected),
                            ),
                          ),
                        ),
                      ),
                      ...List.generate(contracts.length, (index) {
                        final item = contracts[index];
                        final locked =
                            commanderLevel < item.requiredCommanderLevel;
                        final nodeAreaHeight = (constraints.maxHeight - 112)
                            .clamp(180.0, constraints.maxHeight)
                            .toDouble();
                        final x =
                            constraints.maxWidth * _contractXFactors[index];
                        final y = nodeAreaHeight * _contractYFactors[index];
                        final safeTop = (y - 48)
                            .clamp(18.0, nodeAreaHeight - 100)
                            .toDouble();
                        return Positioned(
                          left: x - 77,
                          top: safeTop,
                          child: ContractMarker(
                            contract: item,
                            faction: FactionRules.byId(item.factionId),
                            selected: selected == item,
                            locked: locked,
                            onTap: locked ? () {} : () => onSelect(item),
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
                                label:
                                    commanderLevel <
                                        selected.requiredCommanderLevel
                                    ? '단장 Lv.${selected.requiredCommanderLevel} 필요'
                                    : '계약 수락 · 출전',
                                icon: Icons.gavel,
                                prominent: true,
                                onTap:
                                    commanderLevel <
                                        selected.requiredCommanderLevel
                                    ? () {}
                                    : onDeploy,
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

class _ContractRoutePainter extends CustomPainter {
  const _ContractRoutePainter({required this.selectedIndex});

  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final nodeAreaHeight = (size.height - 112).clamp(180.0, size.height);
    final points = List.generate(_contractXFactors.length, (index) {
      final y = nodeAreaHeight * _contractYFactors[index];
      final safeTop = (y - 48).clamp(18.0, nodeAreaHeight - 100);
      return Offset(size.width * _contractXFactors[index], safeTop + 22);
    });
    final route = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final controlX = (previous.dx + current.dx) / 2;
      route.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0x885d5036)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xffb69a5c)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    for (var index = 0; index < points.length; index++) {
      final center = points[index];
      final marker = Path()
        ..moveTo(center.dx, center.dy - (index == selectedIndex ? 9 : 6))
        ..lineTo(center.dx + (index == selectedIndex ? 9 : 6), center.dy)
        ..lineTo(center.dx, center.dy + (index == selectedIndex ? 9 : 6))
        ..lineTo(center.dx - (index == selectedIndex ? 9 : 6), center.dy)
        ..close();
      canvas.drawPath(
        marker,
        Paint()
          ..color = index == selectedIndex
              ? const Color(0xffffd36e)
              : const Color(0xff6f603e),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ContractRoutePainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex;
}

class _WarMapLegend extends StatelessWidget {
  const _WarMapLegend({
    required this.factionReputation,
    required this.operationProgress,
  });

  final Map<String, int> factionReputation;
  final Map<String, int> operationProgress;

  @override
  Widget build(BuildContext context) {
    final completedFronts = operationProgress.values
        .where((progress) => progress >= 2)
        .length;
    final totalReputation = factionReputation.values.fold<int>(
      0,
      (sum, reputation) => sum + reputation,
    );
    final status = completedFronts >= 2
        ? '용병단 우세'
        : totalReputation >= 60
        ? '전선 안정'
        : '격전 지속';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xd5090b10),
        border: Border.all(color: const Color(0xff765f3b)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PremiumGameIcon(Icons.map_outlined, size: 14),
          const SizedBox(width: 6),
          Text('대륙 전황 · $status', style: const TextStyle(fontSize: 9)),
          const SizedBox(width: 12),
          const Text(
            '● 아군 계약',
            style: TextStyle(fontSize: 8, color: Color(0xff78aed2)),
          ),
          const SizedBox(width: 8),
          const Text(
            '● 격전지',
            style: TextStyle(fontSize: 8, color: Color(0xffd06d62)),
          ),
        ],
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

  List<MercenarySpec> get _ownedMercenaries => gameContent.mercenaries
      .where((mercenary) => widget.mercenaryProgress.containsKey(mercenary.id))
      .toList(growable: false);

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
    final index = _ownedMercenaries.indexWhere(
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
                  itemCount: _ownedMercenaries.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: 10, height: 10),
                  itemBuilder: (_, index) {
                    final mercenary = _ownedMercenaries[index];
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
                  progress: widget.mercenaryProgress[widget.selected.id]!,
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
                alignment: mercenary.visual.rosterAlignment,
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
                      '전투력 ${ProgressionRules.displayPower(catalogPower: mercenary.power, catalogLevel: mercenary.level, permanentLevel: progress?.level ?? 1)}',
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
    required this.progress,
    required this.onEquipment,
    required this.onDeploy,
  });
  final MercenarySpec mercenary;
  final WeaponSpec weapon;
  final MercenaryProgress progress;
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
                alignment: mercenary.visual.portraitAlignment,
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
                          '${mercenary.race} · ${mercenary.job}   전투력 ${ProgressionRules.displayPower(catalogPower: mercenary.power, catalogLevel: mercenary.level, permanentLevel: progress.level)}',
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
