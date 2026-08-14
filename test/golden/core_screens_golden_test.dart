import 'package:eclipse_mercenaries/app/game_app.dart';
import 'package:eclipse_mercenaries/core/theme/game_theme.dart';
import 'package:eclipse_mercenaries/core/content/game_visuals.dart';
import 'package:eclipse_mercenaries/domain/battle_models.dart';
import 'package:eclipse_mercenaries/domain/battle_rewards.dart';
import 'package:eclipse_mercenaries/domain/game_data.dart';
import 'package:eclipse_mercenaries/domain/progression.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('camp visual baseline at 1280x720', (tester) async {
    await _setGoldenSurface(tester);
    await tester.pumpWidget(
      _GoldenShell(
        child: TickerMode(
          enabled: false,
          child: CampScreen(
            gold: 45678,
            crystals: 3250,
            commanderLevel: 15,
            ownedCombatMercenaries: gameContent.mercenaries
                .where((mercenary) => mercenary.duty == MercenaryDuty.combat)
                .toList(growable: false),
            lastReport: null,
            campaignCycle: 30,
            onDeploy: _noop,
            onRoster: _noop,
            onEquipment: _noop,
            onCodex: _noop,
            onForge: _noop,
            onMissions: _noop,
            missionBadge: 2,
            onRecruitment: _noop,
            onShop: _noop,
            onSettings: _noop,
            statusNotice: null,
            onRetrySave: _noop,
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(CampScreen));
      await Future.wait([
        precacheImage(
          const AssetImage('assets/images/mercenary_camp.png'),
          context,
        ),
        ...gameContent.mercenaries
            .where((mercenary) => mercenary.duty == MercenaryDuty.combat)
            .map(
              (mercenary) => precacheImage(
                AssetImage(
                  'assets/images/${mercenary.visual.battleSpriteAsset}',
                ),
                context,
              ),
            ),
      ]);
    });
    await _settleImages(tester);
    final titleParagraph = tester.renderObject<RenderParagraph>(
      find.text('월영 Lv.15'),
    );
    expect(titleParagraph.text.style?.fontFamily, 'NotoSansKR');

    await expectLater(
      find.byType(CampScreen),
      matchesGoldenFile('goldens/camp_1280x720.png'),
    );
  });

  testWidgets('contract map visual baseline at 1280x720', (tester) async {
    await _setGoldenSurface(tester);
    await tester.pumpWidget(
      _GoldenShell(
        child: ContractScreen(
          selected: contracts.first,
          commanderLevel: 15,
          factionReputation: const {
            'aurum_league': 18,
            'ember_principality': 8,
            'grey_banner': 4,
          },
          operationProgress: const {
            'operation_northwall': 0,
            'operation_ashroad': 0,
            'operation_greyknife': 0,
          },
          onSelect: (_) {},
          onBack: _noop,
          onDeploy: _noop,
        ),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(ContractScreen));
      await Future.wait([
        precacheImage(
          const AssetImage('assets/images/ui/war_contract_map.jpg'),
          context,
        ),
        for (final contract in contracts)
          precacheImage(
            AssetImage(battlefieldArtAsset(contract.condition)),
            context,
          ),
      ]);
    });
    await _settleImages(tester);

    await expectLater(
      find.byType(ContractScreen),
      matchesGoldenFile('goldens/contracts_1280x720.png'),
    );
  });

  testWidgets('result visual baseline at 1280x720', (tester) async {
    await _setGoldenSurface(tester);
    final reward = BattleRewardRules.calculate(
      contractGold: 3000,
      contractXp: 1200,
      kills: 128,
      completedObjectives: 3,
      eventGold: 400,
      eventXp: 150,
      eventMultiplier: 1.1,
      preservationRate: 1,
    );
    await tester.pumpWidget(
      _GoldenShell(
        child: ResultScreen(
          report: BattleReport(
            time: '13:24',
            kills: 128,
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
                source: '정예 기사',
              ),
              LootDrop(
                id: 'mooncloth',
                name: '월광천 조각',
                rarity: LootRarity.uncommon,
                quantity: 2,
                source: '계약 보상',
              ),
            ],
            award: const BattleAward(
              title: '북문의 철벽',
              detail: '성문 방어선을 흔들림 없이 유지했습니다.',
              honors: ['백인참', '전술 목표 완수'],
            ),
            peakActiveUnits: 500,
            frameTimeP95Ms: 16.8,
            performance: const BattlePerformanceMetrics(
              sampleCount: 512,
              updateP95Ms: 5.8,
              aiP95Ms: 2.4,
              combatP95Ms: 1.3,
              weaponsP95Ms: 0.7,
              renderCpuP95Ms: 3.1,
              spatialBuckets: 264,
              peakProjectiles: 64,
              peakEffects: 83,
              peakDamageNumbers: 34,
            ),
            completedBonusIds: const ['gate_guard', 'elite_hunter'],
            commanderSurvived: true,
            enemyCommanderDefeated: true,
          ),
          growthReceipt: const GrowthReceipt(
            mercenaryId: 'luna',
            mercenaryBefore: MercenaryProgress(level: 45, xp: 0, ascension: 0),
            mercenaryAfter: MercenaryProgress(
              level: 45,
              xp: 1650,
              ascension: 0,
            ),
            mercenaryXpGained: 1650,
            weaponId: 'moon_blades',
            weaponBefore: WeaponProgress(level: 1, xp: 0, stage: 1),
            weaponAfter: WeaponProgress(level: 2, xp: 475, stage: 1),
            weaponXpGained: 825,
            inventoryAdded: {'officer_map': 1, 'mooncloth': 2},
          ),
          onCamp: _noop,
          onReplay: _noop,
        ),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(ResultScreen));
      await Future.wait([
        precacheImage(
          AssetImage(gameContent.mercenaryById('luna').visual.portraitAsset),
          context,
        ),
        precacheImage(
          const AssetImage('assets/images/shop/final/officer_map.png'),
          context,
        ),
        precacheImage(
          const AssetImage('assets/images/shop/final/mooncloth.png'),
          context,
        ),
      ]);
    });
    await _settleImages(tester);

    await expectLater(
      find.byType(ResultScreen),
      matchesGoldenFile('goldens/result_1280x720.png'),
    );
  });
}

class _GoldenShell extends StatelessWidget {
  const _GoldenShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = buildGameTheme();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: DefaultTextStyle(
        style: theme.textTheme.bodyMedium!.copyWith(fontFamily: 'NotoSansKR'),
        child: RepaintBoundary(child: child),
      ),
    );
  }
}

Future<void> _setGoldenSurface(WidgetTester tester) async {
  await Future.wait([
    _loadFonts('NotoSansKR', const [
      'assets/fonts/NotoSansKR-Regular.ttf',
      'assets/fonts/NotoSansKR-Bold.ttf',
    ]),
    _loadFonts('Cinzel', const ['assets/fonts/Cinzel-Variable.ttf']),
    _loadFonts('MaterialIcons', const ['fonts/MaterialIcons-Regular.otf']),
  ]);
  TestWidgetsFlutterBinding
          .instance
          .platformDispatcher
          .views
          .first
          .devicePixelRatio =
      1;
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _settleImages(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void _noop() {}

Future<void> _loadFonts(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}
