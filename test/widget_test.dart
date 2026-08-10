import 'package:eclipse_mercenaries/app/game_app.dart';
import 'package:eclipse_mercenaries/core/persistence/save_repository.dart';
import 'package:eclipse_mercenaries/domain/battle_models.dart';
import 'package:eclipse_mercenaries/domain/battle_rewards.dart';
import 'package:eclipse_mercenaries/domain/game_settings.dart';
import 'package:eclipse_mercenaries/domain/progression.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('camp renders primary actions', (tester) async {
    await tester.pumpWidget(
      EclipseMercenariesApp(
        saveRepository: InMemorySaveRepository(),
        enableTutorial: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('전쟁터 출전'), findsOneWidget);
    expect(find.text('용병 모집'), findsOneWidget);
    expect(find.text('대장간'), findsOneWidget);
  });

  testWidgets('first launch tutorial completes and persists', (tester) async {
    final repository = InMemorySaveRepository();
    await tester.pumpWidget(EclipseMercenariesApp(saveRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('독립 용병단의 단장'), findsOneWidget);
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('첫 전쟁 계약'), findsOneWidget);
    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();

    expect(find.text('독립 용병단의 단장'), findsNothing);
    final restored = await repository.load();
    expect(restored.settings.tutorialCompleted, isTrue);
  });

  testWidgets('accessibility, controls, and performance settings persist', (
    tester,
  ) async {
    final repository = InMemorySaveRepository();
    await tester.pumpWidget(
      EclipseMercenariesApp(saveRepository: repository, enableTutorial: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('환경 설정'), findsOneWidget);
    await tester.tap(find.text('섬광 줄이기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저사양 전투 모드'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('가상 스틱'));
    await tester.tap(find.text('가상 스틱'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('목표 위협'));
    await tester.tap(find.text('목표 위협'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('큰 글자'));
    await tester.pumpAndSettle();

    final restored = await repository.load();
    expect(restored.settings.reducedFlash, isTrue);
    expect(restored.settings.performanceMode, isTrue);
    expect(restored.settings.largeText, isTrue);
    expect(restored.settings.battleInputMode, BattleInputMode.virtualStick);
    expect(
      restored.settings.autoTargetPriority,
      AutoTargetPriority.objectiveThreat,
    );
  });

  testWidgets('contract flows into mercenary selection', (tester) async {
    await tester.pumpWidget(
      EclipseMercenariesApp(
        saveRepository: InMemorySaveRepository(),
        enableTutorial: false,
      ),
    );
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
    await tester.pumpWidget(
      EclipseMercenariesApp(
        saveRepository: InMemorySaveRepository(),
        enableTutorial: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('장비'));
    await tester.pumpAndSettle();
    expect(find.text('장비 / 무기'), findsOneWidget);
    expect(find.text('월광쌍검'), findsWidgets);
    expect(find.text('혈아대검'), findsOneWidget);
    expect(find.text('유리불꽃 지팡이'), findsOneWidget);
  });

  testWidgets('camp codex exposes enemy catalog and filters', (tester) async {
    await tester.pumpWidget(
      EclipseMercenariesApp(
        saveRepository: InMemorySaveRepository(),
        enableTutorial: false,
      ),
    );
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

  testWidgets('mercenary detail exposes five growth tabs', (tester) async {
    await tester.pumpWidget(
      EclipseMercenariesApp(
        saveRepository: InMemorySaveRepository(),
        enableTutorial: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('용병'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('루나 벨하르트'));
    await tester.pumpAndSettle();

    expect(find.text('정보'), findsOneWidget);
    expect(find.text('레벨업'), findsOneWidget);
    expect(find.text('장비'), findsOneWidget);
    expect(find.text('스킬'), findsOneWidget);
    expect(find.text('스토리'), findsOneWidget);
    await tester.tap(find.text('레벨업'));
    await tester.pumpAndSettle();
    expect(find.textContaining('전술 훈련'), findsOneWidget);
    expect(find.textContaining('승급 · 상한'), findsOneWidget);
  });

  testWidgets('mission reward persists and unlocks forge resources', (
    tester,
  ) async {
    final repository = InMemorySaveRepository();
    await tester.pumpWidget(
      EclipseMercenariesApp(saveRepository: repository, enableTutorial: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('임무'));
    await tester.pumpAndSettle();
    expect(find.text('용병단 임무'), findsOneWidget);
    await tester.tap(find.text('보상 수령').first);
    await tester.pumpAndSettle();

    final restored = await repository.load();
    expect(restored.claimedMissionIds, contains('camp_arrival'));
    expect(restored.inventory['field_ration'], 2);
    expect(restored.inventory['war_scrap'], 3);
  });

  testWidgets('recruitment reveals a mercenary and persists duplicate tokens', (
    tester,
  ) async {
    final repository = InMemorySaveRepository();
    await tester.pumpWidget(
      EclipseMercenariesApp(saveRepository: repository, enableTutorial: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('용병 모집'));
    await tester.pumpAndSettle();
    expect(find.text('특별 용병 계약'), findsOneWidget);
    await tester.tap(find.textContaining('1회 계약'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('용병 계약 완료'), findsOneWidget);
    expect(find.textContaining('전용 증표 +10'), findsOneWidget);
    final restored = await repository.load();
    expect(restored.crystals, 2950);
    expect(restored.recruitmentCount, 1);
    expect(restored.inventory['sera_token'], 10);
  });

  testWidgets('general shop confirms purchase and persists inventory', (
    tester,
  ) async {
    final repository = InMemorySaveRepository();
    await tester.pumpWidget(
      EclipseMercenariesApp(saveRepository: repository, enableTutorial: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('상점'));
    await tester.pumpAndSettle();
    expect(find.text('용병단 상점'), findsOneWidget);
    await tester.tap(find.text('골드 800').first);
    await tester.pumpAndSettle();
    expect(find.text('야전 식량 꾸러미 구매'), findsOneWidget);
    await tester.tap(find.text('구매 확정'));
    await tester.pumpAndSettle();

    final restored = await repository.load();
    expect(restored.gold, 44878);
    expect(restored.inventory['field_ration'], 2);
    expect(restored.shopPurchaseCounts['ration_pack'], 1);
  });

  testWidgets('save failure offers an actionable retry from camp', (
    tester,
  ) async {
    final repository = _FlakySaveRepository();
    await tester.pumpWidget(
      EclipseMercenariesApp(saveRepository: repository, enableTutorial: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('섬광 줄이기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('저장 재시도'), findsOneWidget);
    repository.shouldFail = false;
    await tester.tap(find.text('저장 재시도'));
    await tester.pumpAndSettle();

    expect(find.text('저장 재시도'), findsNothing);
    expect(repository.value.settings.reducedFlash, isTrue);
  });

  testWidgets('alpha loop reaches result and returns rewards to camp', (
    tester,
  ) async {
    final repository = InMemorySaveRepository();
    await tester.pumpWidget(
      EclipseMercenariesApp(saveRepository: repository, enableTutorial: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('전쟁터 출전'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('계약 수락 · 출전'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 용병으로 출전'));
    await tester.pump();
    final reward = BattleRewardRules.calculate(
      contractGold: 3000,
      contractXp: 1200,
      kills: 12,
      completedObjectives: 1,
      eventGold: 0,
      eventXp: 0,
      eventMultiplier: 1,
      preservationRate: 1,
    );
    await tester
        .state<GameShellState>(find.byType(GameShell))
        .finishBattle(
          BattleReport(
            time: '00:45',
            kills: 12,
            gold: reward.keptGold,
            xp: reward.keptXp,
            contractName: '성문 방어전',
            rewardBreakdown: reward,
            lootDrops: const [],
            award: const BattleAward(
              title: '계약 완수',
              detail: '북문 방어선을 유지했습니다.',
              honors: [],
            ),
          ),
        );
    await tester.pumpAndSettle();

    expect(find.text('VICTORY'), findsOneWidget);
    expect(find.text('보상 명세'), findsOneWidget);
    await tester.ensureVisible(find.text('캠프로 귀환'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('캠프로 귀환'));
    await tester.pumpAndSettle();
    expect(find.text('전쟁터 출전'), findsOneWidget);
    final restored = await repository.load();
    expect(restored.gold, greaterThan(45678));
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
      performance: const BattlePerformanceMetrics(
        sampleCount: 512,
        updateP95Ms: 5.8,
        aiP95Ms: 2.4,
        combatP95Ms: 1.3,
        weaponsP95Ms: .7,
        renderCpuP95Ms: 3.1,
        spatialBuckets: 264,
        peakProjectiles: 64,
        peakEffects: 83,
        peakDamageNumbers: 34,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ResultScreen(
          report: report,
          growthReceipt: const GrowthReceipt(
            mercenaryId: 'luna',
            mercenaryBefore: MercenaryProgress(level: 45, xp: 0, ascension: 0),
            mercenaryAfter: MercenaryProgress(
              level: 45,
              xp: 1500,
              ascension: 0,
            ),
            mercenaryXpGained: 1500,
            weaponId: 'moon_blades',
            weaponBefore: WeaponProgress(level: 1, xp: 0, stage: 1),
            weaponAfter: WeaponProgress(level: 2, xp: 400, stage: 1),
            weaponXpGained: 750,
            inventoryAdded: {'officer_map': 1},
          ),
          onCamp: () {},
          onReplay: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MVP · 북문의 철벽'), findsOneWidget);
    expect(find.text('보상 명세'), findsOneWidget);
    expect(find.text('희귀 · 장교의 전술지도'), findsOneWidget);
    expect(find.text('성능 프로파일'), findsOneWidget);
    expect(find.textContaining('렌더 CPU'), findsOneWidget);
  });

  testWidgets('result screen explains a valid empty loot state', (
    tester,
  ) async {
    final reward = BattleRewardRules.calculate(
      contractGold: 3000,
      contractXp: 1200,
      kills: 0,
      completedObjectives: 0,
      eventGold: 0,
      eventXp: 0,
      eventMultiplier: 1,
      preservationRate: 1,
    );
    final report = BattleReport(
      time: '00:45',
      kills: 0,
      gold: reward.keptGold,
      xp: reward.keptXp,
      contractName: '성문 방어전',
      rewardBreakdown: reward,
      lootDrops: const [],
      award: const BattleAward(
        title: '계약 완수',
        detail: '전열을 유지했습니다.',
        honors: [],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ResultScreen(
          report: report,
          growthReceipt: const GrowthReceipt(
            mercenaryId: 'luna',
            mercenaryBefore: MercenaryProgress(level: 45, xp: 0, ascension: 0),
            mercenaryAfter: MercenaryProgress(
              level: 45,
              xp: 1200,
              ascension: 0,
            ),
            mercenaryXpGained: 1200,
            weaponId: 'moon_blades',
            weaponBefore: WeaponProgress(level: 1, xp: 0, stage: 1),
            weaponAfter: WeaponProgress(level: 2, xp: 250, stage: 1),
            weaponXpGained: 600,
            inventoryAdded: {},
          ),
          onCamp: () {},
          onReplay: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('회수한 전리품 없음'), findsOneWidget);
    expect(find.textContaining('계약 골드와 경험치는 정상 반영'), findsOneWidget);
  });
}

class _FlakySaveRepository implements SaveRepository {
  AccountSave value = AccountSave.initial();
  bool shouldFail = true;

  @override
  SaveLoadSource lastLoadSource = SaveLoadSource.initial;

  @override
  Future<AccountSave> load() async => value;

  @override
  Future<AccountSave> reset() async {
    value = AccountSave.initial();
    return value;
  }

  @override
  Future<void> save(AccountSave value) async {
    if (shouldFail) throw StateError('simulated save failure');
    this.value = value;
  }
}
