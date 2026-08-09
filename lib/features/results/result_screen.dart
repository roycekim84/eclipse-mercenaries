part of '../../app/game_app.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.report,
    required this.onCamp,
    required this.onReplay,
  });
  final BattleReport report;
  final VoidCallback onCamp;
  final VoidCallback onReplay;
  @override
  Widget build(BuildContext context) => DarkBackdrop(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: GoldPanel(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'VICTORY',
                    style: TextStyle(
                      fontFamily: 'serif',
                      color: Color(0xffffd27c),
                      fontSize: 42,
                      letterSpacing: 7,
                    ),
                  ),
                  const Text(
                    '계약 완수 · 성문 방어선 사수',
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ResultStat('전투 시간', report.time),
                      ResultStat('처치 수', '${report.kills}'),
                      ResultStat('획득 골드', '${report.gold}'),
                      ResultStat('경험치', '${report.xp}'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: Color(0xff665536)),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '획득 전리품',
                      style: TextStyle(color: Color(0xffd6bd81)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Loot(icon: Icons.monetization_on, amount: '3,240'),
                      Loot(icon: Icons.diamond, amount: '12'),
                      Loot(icon: Icons.auto_fix_high, amount: '1'),
                      Loot(icon: Icons.science, amount: '4'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FantasyButton(
                          label: '캠프로 귀환',
                          icon: Icons.home_outlined,
                          onTap: onCamp,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FantasyButton(
                          label: '다시 출전',
                          icon: Icons.gavel,
                          prominent: true,
                          onTap: onReplay,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// Shared premium fantasy UI components.
