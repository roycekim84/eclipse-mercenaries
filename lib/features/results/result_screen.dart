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
  Widget build(BuildContext context) {
    final victory = report.outcome == BattleOutcome.victory;
    final title = victory ? 'VICTORY' : 'DEFEAT';
    final subtitle = victory ? '계약 완수 · 성문 방어선 사수' : '계약 실패 · 북문 함락';
    final titleColor = victory
        ? const Color(0xffffd27c)
        : const Color(0xffe37268);
    return DarkBackdrop(
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
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'serif',
                        color: titleColor,
                        fontSize: 42,
                        letterSpacing: 7,
                      ),
                    ),
                    Text(subtitle, style: TextStyle(color: Colors.white54)),
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
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.castle_outlined,
                          size: 16,
                          color: Color(0xffd6bd81),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '성문 내구도 ${(report.objectiveHpRatio * 100).round()}%',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (report.completedBonusIds.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          Text(
                            '전술 보너스 ${report.completedBonusIds.length}개',
                            style: const TextStyle(color: Color(0xffffd27c)),
                          ),
                        ],
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
                    Row(
                      children: [
                        Loot(
                          icon: Icons.monetization_on,
                          amount: '${report.gold}',
                        ),
                        Loot(
                          icon: Icons.shield_outlined,
                          amount: '${report.alliedKills}',
                        ),
                        Loot(
                          icon: Icons.workspace_premium_outlined,
                          amount: '${report.completedBonusIds.length}',
                        ),
                        Loot(icon: Icons.science, amount: '${report.xp}'),
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
}

// Shared premium fantasy UI components.
