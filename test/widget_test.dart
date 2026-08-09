import 'package:eclipse_mercenaries/app/game_app.dart';
import 'package:eclipse_mercenaries/domain/battle_models.dart';
import 'package:eclipse_mercenaries/domain/battle_rewards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('camp renders primary actions', (tester) async {
    await tester.pumpWidget(const EclipseMercenariesApp());
    await tester.pumpAndSettle();

    expect(find.text('전쟁터 출전'), findsOneWidget);
    expect(find.text('용병 모집'), findsOneWidget);
    expect(find.text('대장간'), findsOneWidget);
  });

  testWidgets('contract flows into mercenary selection', (tester) async {
    await tester.pumpWidget(const EclipseMercenariesApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('전쟁터 출전'));
    await tester.pumpAndSettle();
    expect(find.text('전쟁 계약'), findsOneWidget);

    await tester.tap(find.text('계약 수락 · 출전'));
    await tester.pumpAndSettle();
    expect(find.text('출전 용병 선택'), findsOneWidget);
    expect(find.text('루나 벨하르트'), findsWidgets);
    expect(find.text('카일 로젠팽'), findsOneWidget);
    expect(find.text('세라 이나리온'), findsOneWidget);
  });

  testWidgets('equipment screen exposes alpha weapon set', (tester) async {
    await tester.pumpWidget(const EclipseMercenariesApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('장비'));
    await tester.pumpAndSettle();
    expect(find.text('장비 / 무기'), findsOneWidget);
    expect(find.text('월광쌍검'), findsWidgets);
    expect(find.text('혈아대검'), findsOneWidget);
    expect(find.text('유리불꽃 지팡이'), findsOneWidget);
  });

  testWidgets('camp codex exposes enemy catalog and filters', (tester) async {
    await tester.pumpWidget(const EclipseMercenariesApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('도감'));
    await tester.pumpAndSettle();

    expect(find.text('전장 도감'), findsOneWidget);
    expect(find.text('전체 12'), findsOneWidget);
    expect(find.text('일반 8'), findsOneWidget);
    expect(find.text('정예 2'), findsOneWidget);
    expect(find.text('지휘관 2'), findsOneWidget);
    expect(find.text('바르가르 징집병'), findsWidgets);
  });

  testWidgets('result screen exposes reward loot and MVP details', (
    tester,
  ) async {
    final reward = BattleRewardRules.calculate(
      contractGold: 3000,
      contractXp: 1200,
      kills: 100,
      completedObjectives: 3,
      eventGold: 0,
      eventXp: 0,
      eventMultiplier: 1,
      preservationRate: 1,
    );
    final report = BattleReport(
      time: '00:45',
      kills: 100,
      gold: reward.keptGold,
      xp: reward.keptXp,
      contractName: '성문 방어전',
      rewardBreakdown: reward,
      lootDrops: const [
        LootDrop(
          id: 'officer_map',
          name: '장교의 전술지도',
          rarity: LootRarity.rare,
          quantity: 1,
          source: '전투 전리품',
        ),
      ],
      award: const BattleAward(
        title: '북문의 철벽',
        detail: '성문 방어선을 흔들림 없이 유지했습니다.',
        honors: [],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ResultScreen(report: report, onCamp: () {}, onReplay: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MVP · 북문의 철벽'), findsOneWidget);
    expect(find.text('보상 명세'), findsOneWidget);
    expect(find.text('희귀 · 장교의 전술지도'), findsOneWidget);
  });
}
