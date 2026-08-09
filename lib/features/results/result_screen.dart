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
    final evacuation = report.battlefield == BattlefieldType.evacuation;
    final subtitle = evacuation
        ? victory
              ? '계약 완수 · 철수 행렬 호위 성공'
              : '계약 실패 · 철수 인원 손실'
        : victory
        ? '계약 완수 · 성문 방어선 사수'
        : '계약 실패 · 북문 함락';
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
                        Icon(
                          evacuation
                              ? Icons.local_shipping_outlined
                              : Icons.castle_outlined,
                          size: 16,
                          color: Color(0xffd6bd81),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          evacuation
                              ? '호위 탈출 ${report.escortEscaped} / ${report.escortTotal}'
                              : '성문 내구도 ${(report.objectiveHpRatio * 100).round()}%',
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
                    const SizedBox(height: 9),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ResultTag(
                          icon: Icons.shield_outlined,
                          label: report.commanderSurvived
                              ? '아군 지휘관 생존'
                              : '아군 지휘관 전사',
                          positive: report.commanderSurvived,
                        ),
                        ResultTag(
                          icon: Icons.flag_outlined,
                          label: report.enemyCommanderDefeated
                              ? '적 지휘관 격퇴'
                              : '적 지휘관 이탈',
                          positive: report.enemyCommanderDefeated,
                        ),
                        ResultTag(
                          icon: Icons.speed,
                          label:
                              '최대 ${report.peakActiveUnits} 유닛 · P95 ${report.frameTimeP95Ms.toStringAsFixed(1)}ms',
                          positive: report.frameTimeP95Ms <= 20,
                        ),
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
                    if (report.rareDropIds.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 7,
                        runSpacing: 6,
                        children: [
                          for (final dropId in report.rareDropIds)
                            ResultTag(
                              icon: Icons.auto_awesome,
                              label: '희귀 · ${rareDropName(dropId)}',
                              positive: true,
                            ),
                        ],
                      ),
                    ],
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

class ResultTag extends StatelessWidget {
  const ResultTag({
    super.key,
    required this.icon,
    required this.label,
    required this.positive,
  });

  final IconData icon;
  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? const Color(0xffffd27c) : const Color(0xffad9087);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x6610141b),
        border: Border.all(color: color.withValues(alpha: .45)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}

// Shared premium fantasy UI components.
