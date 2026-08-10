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
        errorBuilder: (_, _, _) =>
            Icon(fallbackIcon, color: fallbackColor, size: size * .58),
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
    required this.onTap,
  });
  final BattlefieldContract contract;
  final FactionSpec faction;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedScale(
      scale: selected ? 1.08 : 1,
      duration: const Duration(milliseconds: 180),
      child: SizedBox(
        width: 152,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: contract.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xffffd36e)
                      : const Color(0xff8d7952),
                  width: selected ? 3 : 1,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black87, blurRadius: 12),
                ],
              ),
              child: Icon(contract.icon, color: Colors.white, size: 23),
            ),
            const SizedBox(height: 4),
            Container(
              width: 148,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              color: const Color(0xdd0a0c11),
              child: Column(
                children: [
                  Text(
                    contract.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                  Text(
                    contract.battlefieldName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: contract.color.withValues(alpha: .9),
                      fontSize: 8,
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
          Icon(contract.icon, color: const Color(0xffd4b56f)),
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
  const SkillOrb({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: Container(
      width: 50,
      height: 50,
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
          Icon(icon, size: 20, color: Colors.white),
          Text(label, style: const TextStyle(fontSize: 8)),
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
