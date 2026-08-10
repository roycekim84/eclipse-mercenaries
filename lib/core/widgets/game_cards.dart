part of '../../app/game_app.dart';

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
        width: 190,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
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
              child: Icon(contract.icon, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: const Color(0xdd0a0c11),
              child: Text(
                '${contract.name}\n${faction.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  height: 1.25,
                ),
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
  });
  final BattlefieldContract contract;
  final FactionSpec faction;
  final int reputation;
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
                  '${contract.name} · ${faction.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${contract.subtitle}  |  ${FactionRules.rankName(reputation)} · 평판 $reputation  |  ${faction.rewardStyle}',
                  style: const TextStyle(fontSize: 10, color: Colors.white54),
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
