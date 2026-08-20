part of '../../app/game_app.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.report,
    required this.growthReceipt,
    this.saveNotice,
    this.onRetrySave,
    required this.onCamp,
    required this.onReplay,
  });
  final BattleReport report;
  final GrowthReceipt growthReceipt;
  final String? saveNotice;
  final VoidCallback? onRetrySave;
  final VoidCallback onCamp;
  final VoidCallback onReplay;
  @override
  Widget build(BuildContext context) {
    if (report.isIntroBattle) {
      return _IntroBattleResult(
        report: report,
        receipt: growthReceipt,
        onNext: onCamp,
        onReplay: onReplay,
      );
    }
    final title = switch (report.outcome) {
      BattleOutcome.victory => 'VICTORY',
      BattleOutcome.retreat => 'RETREAT',
      BattleOutcome.defeat => 'DEFEAT',
    };
    final objectiveIcon = switch (report.battlefield) {
      BattlefieldType.gateDefense => Icons.castle_outlined,
      BattlefieldType.evacuation ||
      BattlefieldType.supplyEscort => Icons.local_shipping_outlined,
      BattlefieldType.assassination => Icons.gps_fixed,
      BattlefieldType.ambush => Icons.visibility_off_outlined,
      BattlefieldType.fortressRetake => Icons.flag_outlined,
    };
    final objectiveResult = switch (report.battlefield) {
      BattlefieldType.gateDefense =>
        '성문 내구도 ${(report.objectiveHpRatio * 100).round()}%',
      BattlefieldType.evacuation || BattlefieldType.supplyEscort =>
        '호위 탈출 ${report.escortEscaped} / ${report.escortTotal}',
      BattlefieldType.assassination =>
        report.enemyCommanderDefeated ? '적 지휘관 제거 완료' : '적 지휘관 이탈',
      BattlefieldType.ambush => '기습 전과 ${report.kills}명',
      BattlefieldType.fortressRetake =>
        report.enemyCommanderDefeated ? '요새 지휘부 제압' : '수비대 전력 약화',
    };
    final battlefieldArt = switch (report.battlefield) {
      BattlefieldType.gateDefense =>
        'assets/images/battlefield/north_gate_battlefield.png',
      BattlefieldType.evacuation =>
        'assets/images/battlefield/ashwind_road_v2.png',
      BattlefieldType.supplyEscort || BattlefieldType.ambush =>
        'assets/images/battlefield/black_forest_route.png',
      BattlefieldType.assassination =>
        'assets/images/battlefield/twilight_siege_plain.png',
      BattlefieldType.fortressRetake =>
        'assets/images/battlefield/white_night_fortress.png',
    };
    final subtitle = switch (report.outcome) {
      BattleOutcome.victory => '계약 완수 · ${report.contractName}',
      BattleOutcome.retreat => '전술적 철수 · 획득 보상의 50% 보존',
      BattleOutcome.defeat => '계약 실패 · 획득 보상의 20% 회수',
    };
    final titleColor = switch (report.outcome) {
      BattleOutcome.victory => const Color(0xffffd27c),
      BattleOutcome.retreat => const Color(0xff8fc6d8),
      BattleOutcome.defeat => const Color(0xffe37268),
    };
    final landscape = MediaQuery.sizeOf(context).width >= 900;
    if (landscape) {
      return _LandscapeResultScreen(
        report: report,
        growthReceipt: growthReceipt,
        saveNotice: saveNotice,
        onRetrySave: onRetrySave,
        onCamp: onCamp,
        onReplay: onReplay,
        title: title,
        subtitle: subtitle,
        titleColor: titleColor,
        objectiveIcon: objectiveIcon,
        objectiveResult: objectiveResult,
        battlefieldArt: battlefieldArt,
      );
    }
    return DarkBackdrop(
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: .16,
              child: Image.asset(
                battlefieldArt,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: GoldPanel(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: .82, end: 1),
                          duration: const Duration(milliseconds: 720),
                          curve: Curves.easeOutBack,
                          builder: (_, value, child) =>
                              Transform.scale(scale: value, child: child),
                          child: Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'Cinzel',
                              color: titleColor,
                              fontSize: 42,
                              letterSpacing: 7,
                              shadows: [
                                Shadow(
                                  color: titleColor.withValues(alpha: .5),
                                  blurRadius: 22,
                                ),
                              ],
                            ),
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
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 16,
                          runSpacing: 6,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PremiumGameIcon(
                                  objectiveIcon,
                                  size: 16,
                                  color: Color(0xffd6bd81),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  objectiveResult,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            if (report.completedBonusIds.isNotEmpty)
                              Text(
                                '전술 보너스 ${report.completedBonusIds.length}개',
                                style: const TextStyle(
                                  color: Color(0xffffd27c),
                                ),
                              ),
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
                          ],
                        ),
                        const SizedBox(height: 14),
                        _MvpPanel(
                          award: report.award,
                          mercenaryId: growthReceipt.mercenaryId,
                        ),
                        const SizedBox(height: 18),
                        const Divider(color: Color(0xff665536)),
                        const SizedBox(height: 12),
                        _RewardBreakdownPanel(
                          breakdown: report.rewardBreakdown,
                        ),
                        const SizedBox(height: 10),
                        _PermanentGrowthPanel(receipt: growthReceipt),
                        if (saveNotice != null) ...[
                          const SizedBox(height: 8),
                          StatusBanner(
                            message: saveNotice!,
                            isError: true,
                            actionLabel: onRetrySave == null ? null : '저장 재시도',
                            onAction: onRetrySave,
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '획득 전리품',
                            style: TextStyle(color: Color(0xffd6bd81)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (report.lootDrops.isEmpty)
                          const GameStatePanel(
                            icon: Icons.inventory_2_outlined,
                            title: '회수한 전리품 없음',
                            message:
                                '계약 골드와 경험치는 정상 반영되었습니다.\n다음 전장에서는 정예와 사건 목표를 노려보세요.',
                          )
                        else
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var i = 0; i < report.lootDrops.length; i++)
                                _LootDropCard(
                                  drop: report.lootDrops[i],
                                  revealIndex: i,
                                ),
                            ],
                          ),
                        if (report.eventRecords.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xff665536)),
                          const SizedBox(height: 10),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '전장 사건 기록',
                              style: TextStyle(color: Color(0xffd6bd81)),
                            ),
                          ),
                          const SizedBox(height: 9),
                          for (final record in report.eventRecords)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: _EventRecordRow(record: record),
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
        ],
      ),
    );
  }
}

class _IntroBattleResult extends StatelessWidget {
  const _IntroBattleResult({
    required this.report,
    required this.receipt,
    required this.onNext,
    required this.onReplay,
  });

  final BattleReport report;
  final GrowthReceipt receipt;
  final VoidCallback onNext;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) => SceneFrame(
    background: 'assets/images/battlefield/north_gate_battlefield.png',
    child: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: GoldPanel(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Row(
                children: [
                  SizedBox(
                    width: 280,
                    child: Image.asset(
                      gameContent.mercenaryById('luna').visual.portraitAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.outcome == BattleOutcome.victory
                              ? 'VICTORY'
                              : '다시 전열을 정비하라',
                          style: const TextStyle(
                            color: Color(0xffffd27c),
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report.outcome == BattleOutcome.victory
                              ? '북문을 지켰습니다. 월식 용병단의 첫 계약이 시작됩니다.'
                              : '전투 감각은 익혔습니다. 즉시 다시 도전할 수 있습니다.',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            ResultStat('처치', '${report.kills}'),
                            ResultStat('골드', '+${report.gold}'),
                            ResultStat(
                              '루나 성장',
                              '+${receipt.mercenaryXpGained} XP',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        StatusBanner(
                          message: report.outcome == BattleOutcome.victory
                              ? '해금: 용병단 캠프 · 용병 모집'
                              : '이동하며 적과 거리를 벌리면 자동 공격이 이어집니다.',
                        ),
                        const SizedBox(height: 18),
                        FantasyButton(
                          label: report.outcome == BattleOutcome.victory
                              ? '캠프로 귀환'
                              : '즉시 재도전',
                          icon: Icons.gavel,
                          prominent: true,
                          onTap: report.outcome == BattleOutcome.victory
                              ? onNext
                              : onReplay,
                        ),
                        const SizedBox(height: 8),
                        if (report.outcome == BattleOutcome.victory)
                          TextButton(
                            onPressed: onReplay,
                            child: const Text('같은 전투 다시 하기'),
                          ),
                      ],
                    ),
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

class _LandscapeResultScreen extends StatelessWidget {
  const _LandscapeResultScreen({
    required this.report,
    required this.growthReceipt,
    required this.saveNotice,
    required this.onRetrySave,
    required this.onCamp,
    required this.onReplay,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.objectiveIcon,
    required this.objectiveResult,
    required this.battlefieldArt,
  });

  final BattleReport report;
  final GrowthReceipt growthReceipt;
  final String? saveNotice;
  final VoidCallback? onRetrySave;
  final VoidCallback onCamp;
  final VoidCallback onReplay;
  final String title;
  final String subtitle;
  final Color titleColor;
  final IconData objectiveIcon;
  final String objectiveResult;
  final String battlefieldArt;

  @override
  Widget build(BuildContext context) => DarkBackdrop(
    child: Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: .2,
            child: Image.asset(battlefieldArt, fit: BoxFit.cover),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GoldPanel(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      flex: 11,
                      child: Column(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'Cinzel',
                              color: titleColor,
                              fontSize: 38,
                              letterSpacing: 7,
                              shadows: [
                                Shadow(color: titleColor, blurRadius: 18),
                              ],
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(color: Colors.white54),
                          ),
                          const SizedBox(height: 13),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ResultStat('전투 시간', report.time),
                              ResultStat('처치 수', '${report.kills}'),
                              ResultStat('획득 골드', '${report.gold}'),
                              ResultStat('경험치', '${report.xp}'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PremiumGameIcon(objectiveIcon, size: 18),
                              const SizedBox(width: 7),
                              Text(objectiveResult),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 7,
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
                              if (report.completedBonusIds.isNotEmpty)
                                ResultTag(
                                  icon: Icons.military_tech_outlined,
                                  label:
                                      '전술 보너스 ${report.completedBonusIds.length}개',
                                  positive: true,
                                ),
                            ],
                          ),
                          const SizedBox(height: 11),
                          _MvpPanel(
                            award: report.award,
                            mercenaryId: growthReceipt.mercenaryId,
                          ),
                          const SizedBox(height: 10),
                          _PermanentGrowthPanel(receipt: growthReceipt),
                        ],
                      ),
                    ),
                    const VerticalDivider(color: Color(0xff665536), width: 28),
                    Expanded(
                      flex: 9,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _RewardBreakdownPanel(
                            breakdown: report.rewardBreakdown,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '핵심 전리품',
                            style: TextStyle(color: Color(0xffd6bd81)),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (
                                        var i = 0;
                                        i < report.lootDrops.length;
                                        i++
                                      )
                                        _LootDropCard(
                                          drop: report.lootDrops[i],
                                          revealIndex: i,
                                        ),
                                      if (report.lootDrops.isEmpty)
                                        const Text(
                                          '계약 보상만 회수했습니다.',
                                          style: TextStyle(
                                            color: Colors.white54,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (report.eventRecords.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    const Divider(color: Color(0xff665536)),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '전장 사건 기록',
                                      style: TextStyle(
                                        color: Color(0xffd6bd81),
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    for (final record in report.eventRecords)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: _EventRecordRow(record: record),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (saveNotice != null)
                            StatusBanner(
                              message: saveNotice!,
                              isError: true,
                              actionLabel: onRetrySave == null
                                  ? null
                                  : '저장 재시도',
                              onAction: onRetrySave,
                            ),
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              Expanded(
                                child: FantasyButton(
                                  label: '캠프로 귀환',
                                  icon: Icons.home_outlined,
                                  onTap: onCamp,
                                ),
                              ),
                              const SizedBox(width: 9),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _PermanentGrowthPanel extends StatelessWidget {
  const _PermanentGrowthPanel({required this.receipt});

  final GrowthReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final mercenary = gameContent.mercenaryById(receipt.mercenaryId);
    final weapon = gameContent.weaponById(receipt.weaponId);
    final mercenaryLevelUp =
        receipt.mercenaryAfter.level > receipt.mercenaryBefore.level;
    final weaponLevelUp =
        receipt.weaponAfter.level > receipt.weaponBefore.level;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x66201c32),
        border: Border.all(color: const Color(0x665f4b73)),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up, color: Color(0xffc7a6df), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: _GrowthLine(
              name: mercenary.name,
              level: receipt.mercenaryAfter.level,
              xp: receipt.mercenaryAfter.xp,
              nextXp: ProgressionRules.mercenaryXpToNext(
                receipt.mercenaryAfter.level,
              ),
              gained: receipt.mercenaryXpGained,
              levelUp: mercenaryLevelUp,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _GrowthLine(
              name: weapon.name,
              level: receipt.weaponAfter.level,
              xp: receipt.weaponAfter.xp,
              nextXp: ProgressionRules.weaponXpToNext(
                receipt.weaponAfter.level,
              ),
              gained: receipt.weaponXpGained,
              levelUp: weaponLevelUp,
              stage: receipt.weaponAfter.stage,
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthLine extends StatelessWidget {
  const _GrowthLine({
    required this.name,
    required this.level,
    required this.xp,
    required this.nextXp,
    required this.gained,
    required this.levelUp,
    this.stage,
  });

  final String name;
  final int level;
  final int xp;
  final int nextXp;
  final int gained;
  final bool levelUp;
  final int? stage;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ),
          Text(
            'Lv.$level${stage == null ? '' : ' · $stage단계'}',
            style: TextStyle(
              color: levelUp
                  ? const Color(0xffffd27c)
                  : const Color(0xffc7a6df),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          minHeight: 4,
          value: nextXp <= 0 ? 1 : (xp / nextXp).clamp(0, 1),
          backgroundColor: const Color(0xff171923),
          color: const Color(0xff8e6eae),
        ),
      ),
      const SizedBox(height: 3),
      Text(
        '+$gained XP · $xp / $nextXp${levelUp ? '  LEVEL UP' : ''}',
        style: const TextStyle(fontSize: 8, color: Colors.white38),
      ),
    ],
  );
}

class _MvpPanel extends StatelessWidget {
  const _MvpPanel({required this.award, required this.mercenaryId});

  final BattleAward award;
  final String mercenaryId;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0x88392717), Color(0x88201c32)],
      ),
      border: Border.all(color: const Color(0x88c49a54)),
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffffd27c), width: 1.4),
            boxShadow: const [
              BoxShadow(color: Color(0x668e6732), blurRadius: 12),
            ],
          ),
          child: ClipRect(
            child: Image.asset(
              gameContent.mercenaryById(mercenaryId).visual.portraitAsset,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -.45),
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MVP · ${award.title}',
                style: const TextStyle(
                  color: Color(0xffffd27c),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                award.detail,
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ],
          ),
        ),
        if (award.honors.isNotEmpty)
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 5,
              runSpacing: 4,
              children: [
                for (final honor in award.honors)
                  ResultTag(
                    icon: Icons.military_tech_outlined,
                    label: honor,
                    positive: true,
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _RewardBreakdownPanel extends StatelessWidget {
  const _RewardBreakdownPanel({required this.breakdown});

  final RewardBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('계약', breakdown.contractGold, breakdown.contractXp),
      ('목표', breakdown.objectiveGold, breakdown.objectiveXp),
      ('전과', breakdown.combatGold, breakdown.combatXp),
      ('사건', breakdown.eventGold, breakdown.eventXp),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0x6610141b),
      child: Column(
        children: [
          Row(
            children: [
              const Text('보상 명세', style: TextStyle(color: Color(0xffd6bd81))),
              const Spacer(),
              if (breakdown.rewardMultiplier > 1)
                Text(
                  '사건 배율 ×${breakdown.rewardMultiplier.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xffc28adc),
                    fontSize: 10,
                  ),
                ),
              const SizedBox(width: 10),
              Text(
                '보존 ${(breakdown.preservationRate * 100).round()}%',
                style: const TextStyle(color: Color(0xff8fc6d8), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              for (final entry in entries)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        entry.$1,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${entry.$2 >= 0 ? '+' : ''}${entry.$2} G  ·  ${entry.$3 >= 0 ? '+' : ''}${entry.$3} XP',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            '산출 ${breakdown.grossGold} G / ${breakdown.grossXp} XP  →  회수 ${breakdown.keptGold} G / ${breakdown.keptXp} XP',
            style: const TextStyle(
              color: Color(0xffffd27c),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _LootDropCard extends StatelessWidget {
  const _LootDropCard({required this.drop, required this.revealIndex});

  final LootDrop drop;
  final int revealIndex;

  @override
  Widget build(BuildContext context) {
    final color = switch (drop.rarity) {
      LootRarity.common => const Color(0xffaab4bf),
      LootRarity.uncommon => const Color(0xff70bc83),
      LootRarity.rare => const Color(0xff66b9da),
      LootRarity.epic => const Color(0xffc28adc),
      LootRarity.legendary => const Color(0xffffbd5d),
    };
    final rarity = switch (drop.rarity) {
      LootRarity.common => '일반',
      LootRarity.uncommon => '고급',
      LootRarity.rare => '희귀',
      LootRarity.epic => '영웅',
      LootRarity.legendary => '전설',
    };
    final asset = lootArtAsset(drop.id);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + revealIndex * 120),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0, 1),
        child: Transform.scale(scale: .9 + value * .1, child: child),
      ),
      child: Container(
        width: 205,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: .18), const Color(0xff10131a)],
          ),
          border: Border.all(color: color.withValues(alpha: .72)),
          boxShadow: drop.rarity.index >= LootRarity.epic.index
              ? [BoxShadow(color: color.withValues(alpha: .18), blurRadius: 10)]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xbb080b11),
                border: Border.all(color: color.withValues(alpha: .8)),
              ),
              child: asset == null
                  ? PremiumGameIcon(
                      drop.rarity == LootRarity.legendary
                          ? Icons.auto_awesome
                          : Icons.inventory_2_outlined,
                      color: color,
                      size: 26,
                    )
                  : Image.asset(
                      asset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$rarity · ${drop.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${drop.source}  ×${drop.quantity}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white38, fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventRecordRow extends StatelessWidget {
  const _EventRecordRow({required this.record});

  final BattlefieldEventRecord record;

  @override
  Widget build(BuildContext context) {
    final color = switch (record.rarity) {
      BattlefieldEventRarity.common => const Color(0xffb6bdc8),
      BattlefieldEventRarity.special => const Color(0xff79b7d9),
      BattlefieldEventRarity.rare => const Color(0xffb58be3),
      BattlefieldEventRarity.legendary => const Color(0xffffc65e),
    };
    final rarity = switch (record.rarity) {
      BattlefieldEventRarity.common => '일반',
      BattlefieldEventRarity.special => '특수',
      BattlefieldEventRarity.rare => '희귀',
      BattlefieldEventRarity.legendary => '전설',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x6610141b),
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: Row(
        children: [
          Text(
            '$rarity · ${record.title}',
            style: TextStyle(color: color, fontSize: 11),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${record.choiceLabel} — ${record.resultText}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
          ),
        ],
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
