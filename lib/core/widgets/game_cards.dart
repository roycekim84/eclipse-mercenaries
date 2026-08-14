part of '../../app/game_app.dart';

class GameAssetArt extends StatelessWidget {
  const GameAssetArt({
    super.key,
    required this.asset,
    required this.fallbackIcon,
    required this.fallbackColor,
    this.size = 48,
  });

  final String asset;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: ClipRect(
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, error, stack) {
          assert(() {
            throw FlutterError('출시 에셋 누락: $asset\n$error');
          }());
          return DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xff2b1012),
              border: Border.all(color: const Color(0xffd9675d)),
            ),
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: fallbackColor,
                size: size * .48,
              ),
            ),
          );
        },
      ),
    ),
  );
}

class ContractMarker extends StatelessWidget {
  const ContractMarker({
    super.key,
    required this.contract,
    required this.faction,
    required this.selected,
    required this.locked,
    this.onTap,
  });
  final BattlefieldContract contract;
  final FactionSpec faction;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 154,
      height: 82,
      child: Align(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: selected ? 154 : 58,
          height: selected ? 82 : 58,
          decoration: BoxDecoration(
            color: const Color(0xee0a0c11),
            border: Border.all(
              color: selected
                  ? const Color(0xffffd36e)
                  : locked
                  ? const Color(0xff665f51)
                  : const Color(0xffb59657),
              width: selected ? 2.4 : 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: selected ? const Color(0x995d431d) : Colors.black87,
                blurRadius: selected ? 18 : 8,
              ),
            ],
          ),
          child: ClipRect(
            child: selected
                ? _SelectedContractNode(contract: contract, faction: faction)
                : _CompactContractNode(contract: contract, locked: locked),
          ),
        ),
      ),
    ),
  );
}

class ContractMarkerArt extends StatelessWidget {
  const ContractMarkerArt({
    super.key,
    required this.contract,
    this.size = 44,
    this.locked = false,
  });

  final BattlefieldContract contract;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final index = contracts.indexWhere((item) => item.id == contract.id);
    final sourceIndex = index < 0 ? 0 : index.clamp(0, 5);
    return SizedBox.square(
      dimension: size,
      child: ShaderMask(
        blendMode: BlendMode.modulate,
        shaderCallback: (bounds) => LinearGradient(
          colors: locked
              ? const [Color(0xff777777), Color(0xff777777)]
              : const [Colors.white, Colors.white],
        ).createShader(bounds),
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -sourceIndex * size,
                top: -size,
                width: size * 6,
                height: size * 3,
                child: Image.asset(
                  'assets/images/ui/contract_marker_atlas_v2.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactContractNode extends StatelessWidget {
  const _CompactContractNode({required this.contract, required this.locked});
  final BattlefieldContract contract;
  final bool locked;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        battlefieldArtAsset(contract.condition),
        fit: BoxFit.cover,
        alignment: Alignment.center,
        color: locked ? const Color(0xaa646464) : null,
        colorBlendMode: locked ? BlendMode.saturation : null,
      ),
      const ColoredBox(color: Color(0x44000000)),
      Center(
        child: ContractMarkerArt(contract: contract, size: 48, locked: locked),
      ),
      Positioned(
        left: 4,
        right: 4,
        bottom: 3,
        child: Text(
          locked
              ? 'Lv.${contract.requiredCommanderLevel}'
              : '${contract.power ~/ 1000}K',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 7, color: Colors.white70),
        ),
      ),
    ],
  );
}

class _SelectedContractNode extends StatelessWidget {
  const _SelectedContractNode({required this.contract, required this.faction});
  final BattlefieldContract contract;
  final FactionSpec faction;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(battlefieldArtAsset(contract.condition), fit: BoxFit.cover),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x22000000), Color(0xf2080a0e)],
          ),
        ),
      ),
      Positioned(
        left: 7,
        top: 7,
        child: ContractMarkerArt(contract: contract, size: 24),
      ),
      Positioned(
        left: 34,
        right: 6,
        top: 7,
        child: Text(
          contract.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        ),
      ),
      Positioned(
        left: 34,
        right: 6,
        top: 24,
        child: Text(
          '${faction.name} · ${contract.battlefieldName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: contract.color, fontSize: 7.5),
        ),
      ),
      Positioned(
        left: 7,
        right: 7,
        bottom: 6,
        child: Row(
          children: [
            Expanded(
              child: Text(
                '권장 ${contract.power ~/ 1000}K',
                style: const TextStyle(color: Color(0xffd8bd7b), fontSize: 7.5),
              ),
            ),
            Text(
              '${contract.reward} G',
              style: const TextStyle(color: Colors.white70, fontSize: 7.5),
            ),
          ],
        ),
      ),
    ],
  );
}

class ContractSummary extends StatelessWidget {
  const ContractSummary({
    super.key,
    required this.contract,
    required this.faction,
    required this.reputation,
    required this.operation,
    required this.operationProgress,
  });
  final BattlefieldContract contract;
  final FactionSpec faction;
  final int reputation;
  final WarOperationSpec operation;
  final int operationProgress;
  @override
  Widget build(BuildContext context) => GoldPanel(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          PremiumGameIcon(contract.icon, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${contract.name} · ${contract.battlefieldName} · ${faction.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${contract.subtitle}  |  ${FactionRules.rankName(reputation)} · 평판 $reputation  |  ${faction.rewardStyle}',
                  style: const TextStyle(fontSize: 10, color: Colors.white54),
                ),
                Text(
                  '${operation.title} · ${WarOperationRules.stageLabel(operation, operationProgress)}',
                  style: const TextStyle(fontSize: 9, color: Color(0xffb795cf)),
                ),
              ],
            ),
          ),
          Text(
            '권장 ${contract.power}\n${contract.reward} G · ${contract.xp} XP',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, color: Color(0xffd6bd82)),
          ),
        ],
      ),
    ),
  );
}

class SkillOrb extends StatelessWidget {
  const SkillOrb({
    super.key,
    required this.icon,
    required this.label,
    this.compact = false,
  });
  final IconData icon;
  final String label;
  final bool compact;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: compact ? 3 : 6),
    child: Container(
      width: compact ? 34 : 50,
      height: compact ? 34 : 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xff68408b), Color(0xff161225)],
        ),
        border: Border.all(color: const Color(0xffba94cb), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PremiumGameIcon(icon, size: compact ? 18 : 24),
          Text(label, style: TextStyle(fontSize: compact ? 6 : 8)),
        ],
      ),
    ),
  );
}

class ChipLabel extends StatelessWidget {
  const ChipLabel(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 7),
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xff20222b),
      border: Border.all(color: const Color(0xff635438)),
    ),
    child: Text(label, style: const TextStyle(fontSize: 11)),
  );
}
