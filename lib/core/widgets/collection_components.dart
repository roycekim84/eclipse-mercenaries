part of '../../app/game_app.dart';

class MercenaryCard extends StatelessWidget {
  const MercenaryCard({super.key, required this.index, required this.onTap});
  final int index;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    const names = ['루나', '카일', '세라', '미엘', '라비', '노아', '아린', '로웬'];
    const colors = [
      Color(0xff49335c),
      Color(0xff51433b),
      Color(0xff374b61),
      Color(0xff694a37),
      Color(0xff604041),
      Color(0xff3f5547),
      Color(0xff49465f),
      Color(0xff654e3b),
    ];
    return GestureDetector(
      onTap: onTap,
      child: GoldPanel(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors[index], const Color(0xff0a0b0e)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: index < gameContent.mercenaries.length
                  ? Image.asset(
                      gameContent.mercenaries[index].visual.portraitAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    )
                  : Icon(
                      [
                        Icons.shield,
                        Icons.auto_awesome,
                        Icons.bolt,
                        Icons.health_and_safety,
                        Icons.architecture,
                        Icons.local_fire_department,
                        Icons.air,
                      ][index - 1],
                      color: Colors.white12,
                      size: 88,
                    ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xee07080b)],
                    stops: [.42, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    names[index],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Lv.${45 - index * 3}',
                    style: const TextStyle(fontSize: 11, color: Colors.white60),
                  ),
                  Text(
                    index < 3 ? '★★★★★' : '★★★★',
                    style: const TextStyle(
                      color: Color(0xffffc95d),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 7,
              top: 7,
              child: Icon(
                index == 0 ? Icons.dark_mode : Icons.change_history,
                size: 16,
                color: const Color(0xffdfc180),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  const StatRow(this.label, this.value, {super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    ),
  );
}

class ResultStat extends StatelessWidget {
  const ResultStat(this.label, this.value, {super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      const SizedBox(height: 5),
      Text(
        value,
        style: const TextStyle(
          color: Color(0xffffd27c),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    ],
  );
}

class Loot extends StatelessWidget {
  const Loot({super.key, required this.icon, required this.amount});
  final IconData icon;
  final String amount;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xff11141a),
        border: Border.all(color: const Color(0xff54472f)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xffb9a5db)),
          const SizedBox(height: 4),
          Text(amount, style: const TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
}
