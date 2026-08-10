import 'dart:async';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/content/game_content_repository.dart';
import '../core/content/game_visuals.dart';
import '../core/persistence/save_repository.dart';
import '../core/theme/game_theme.dart';
import '../domain/battle_models.dart';
import '../domain/battlefield_events.dart';
import '../domain/battle_rewards.dart';
import '../domain/camp_meta.dart';
import '../domain/enemy_catalog.dart';
import '../domain/economy.dart';
import '../domain/game_data.dart';
import '../domain/game_settings.dart';
import '../domain/progression.dart';
import '../domain/run_growth.dart';
import '../game/survivor_game.dart';

part '../core/widgets/collection_components.dart';
part '../core/widgets/fantasy_components.dart';
part '../core/widgets/game_cards.dart';
part '../core/widgets/map_painter.dart';
part '../features/battle/battle_screen.dart';
part '../features/battle/ultimate_overlay.dart';
part '../features/camp/camp_screen.dart';
part '../features/camp/forge_screen.dart';
part '../features/camp/mission_screen.dart';
part '../features/contracts/contract_screens.dart';
part '../features/equipment/equipment_screen.dart';
part '../features/codex/enemy_codex_screen.dart';
part '../features/mercenaries/mercenary_screens.dart';
part '../features/results/result_screen.dart';
part '../features/recruitment/recruitment_screen.dart';
part '../features/shop/shop_screen.dart';
part '../features/settings/settings_screen.dart';
part '../features/tutorial/tutorial_overlay.dart';

const gameContent = StaticGameContentRepository();

class EclipseMercenariesApp extends StatelessWidget {
  const EclipseMercenariesApp({
    super.key,
    this.saveRepository,
    this.enableTutorial = true,
  });

  final SaveRepository? saveRepository;
  final bool enableTutorial;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '월식 용병단',
      theme: buildGameTheme(),
      home: GameShell(
        saveRepository: saveRepository,
        enableTutorial: enableTutorial,
      ),
    );
  }
}

enum AppScene {
  camp,
  contracts,
  mercenarySelect,
  equipment,
  roster,
  detail,
  battle,
  result,
  enemyCodex,
  forge,
  missions,
  recruitment,
  shop,
  settings,
}

class GameShell extends StatefulWidget {
  const GameShell({
    super.key,
    this.saveRepository,
    required this.enableTutorial,
  });

  final SaveRepository? saveRepository;
  final bool enableTutorial;

  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> {
  late final SaveRepository _saveRepository;
  AppScene scene = AppScene.camp;
  BattlefieldContract selected = contracts.first;
  AccountSave? _account;
  late MercenarySpec selectedMercenary;
  late WeaponSpec equippedWeapon;
  AppScene equipmentReturn = AppScene.camp;
  BattleReport? report;
  GrowthReceipt? growthReceipt;
  bool _rewardApplied = false;
  String? saveNotice;
  String? actionNotice;
  int tutorialStep = 0;

  AccountSave get account => _account!;
  int get gold => account.gold;
  int get crystals => account.crystals;

  void updateSettings(GameSettings settings) {
    _updateAccount(account.copyWith(settings: settings), '환경 설정을 저장했습니다.');
  }

  void completeTutorial() {
    _updateAccount(
      account.copyWith(
        settings: account.settings.copyWith(tutorialCompleted: true),
      ),
      '첫 계약 안내를 완료했습니다.',
    );
  }

  @override
  void initState() {
    super.initState();
    _saveRepository =
        widget.saveRepository ??
        JsonSaveRepository(SharedPreferencesKeyValueStore());
    unawaited(_loadSave());
  }

  Future<void> _loadSave() async {
    AccountSave loaded;
    try {
      loaded = await _saveRepository.load();
    } on Object {
      loaded = AccountSave.initial();
      saveNotice = '저장소를 불러오지 못해 안전한 기본 상태로 시작했습니다.';
    }
    final mercenaryIds = gameContent.mercenaries
        .map((mercenary) => mercenary.id)
        .toSet();
    final mercenaryId = mercenaryIds.contains(loaded.selectedMercenaryId)
        ? loaded.selectedMercenaryId
        : 'luna';
    selectedMercenary = gameContent.mercenaryById(mercenaryId);
    final weaponIds = gameContent.weapons.map((weapon) => weapon.id).toSet();
    final savedWeapon = loaded.equippedWeaponByMercenary[mercenaryId];
    final weaponId = weaponIds.contains(savedWeapon)
        ? savedWeapon!
        : selectedMercenary.signatureWeaponId;
    equippedWeapon = gameContent.weaponById(weaponId);
    if (mercenaryId != loaded.selectedMercenaryId || savedWeapon != weaponId) {
      loaded = loaded.copyWith(
        selectedMercenaryId: mercenaryId,
        equippedWeaponByMercenary: {
          ...loaded.equippedWeaponByMercenary,
          mercenaryId: weaponId,
        },
      );
      try {
        await _saveRepository.save(loaded);
      } on Object {
        saveNotice = '복구한 장착 정보를 저장하지 못했습니다.';
      }
    }
    if (!mounted) return;
    setState(() => _account = loaded);
  }

  Future<void> _persistAccount() async {
    try {
      await _saveRepository.save(account);
    } on Object {
      if (!mounted) return;
      setState(() {
        saveNotice = '자동 저장에 실패했습니다. 현재 실행의 진행 상태는 유지됩니다.';
      });
    }
  }

  void go(AppScene next) => setState(() => scene = next);

  void openEquipment(AppScene returnTo) {
    setState(() {
      equipmentReturn = returnTo;
      scene = AppScene.equipment;
    });
  }

  void _updateAccount(AccountSave next, String notice) {
    setState(() {
      _account = next;
      actionNotice = notice;
    });
    unawaited(_persistAccount());
  }

  void trainMercenary(MercenarySpec mercenary) {
    final progress = account.mercenaryProgress[mercenary.id]!;
    final rations = account.inventory['field_ration'] ?? 0;
    if (!CampMetaRules.canTrain(
      gold: gold,
      rations: rations,
      progress: progress,
    )) {
      setState(
        () => actionNotice = progress.level >= progress.levelCap
            ? '현재 승급 단계의 레벨 한계입니다.'
            : '골드 또는 야전 식량이 부족합니다.',
      );
      return;
    }
    final nextProgress = ProgressionRules.addMercenaryXp(
      progress,
      CampMetaRules.trainingXp,
    );
    _updateAccount(
      account.copyWith(
        gold: gold - CampMetaRules.trainingGoldCost,
        inventory: {...account.inventory, 'field_ration': rations - 1},
        mercenaryProgress: {
          ...account.mercenaryProgress,
          mercenary.id: nextProgress,
        },
      ),
      '${mercenary.name} 훈련 완료 · 경험치 +${CampMetaRules.trainingXp}',
    );
  }

  void ascendMercenary(MercenarySpec mercenary) {
    final progress = account.mercenaryProgress[mercenary.id]!;
    final seals = account.inventory['contract_seal'] ?? 0;
    final cost = ProgressionRules.ascensionCost(progress.ascension);
    if (!ProgressionRules.canAscend(progress, seals)) {
      setState(
        () => actionNotice = progress.level < progress.levelCap
            ? 'Lv.${progress.levelCap} 달성 후 승급할 수 있습니다.'
            : '피 묻은 계약 인장이 $cost개 필요합니다.',
      );
      return;
    }
    _updateAccount(
      account.copyWith(
        inventory: {...account.inventory, 'contract_seal': seals - cost},
        mercenaryProgress: {
          ...account.mercenaryProgress,
          mercenary.id: ProgressionRules.ascend(
            progress,
            availableSigils: seals,
          ),
        },
      ),
      '${mercenary.name} 승급 완료 · 레벨 상한 +5',
    );
  }

  void forgeWeapon(WeaponSpec weapon) {
    final scrap = account.inventory['war_scrap'] ?? 0;
    if (!CampMetaRules.canForge(gold: gold, scrap: scrap)) {
      setState(() => actionNotice = '강화에는 700 골드와 전장 고철 2개가 필요합니다.');
      return;
    }
    final progress = account.weaponProgress[weapon.id]!;
    if (progress.level >= 20) {
      setState(() => actionNotice = '이미 최대 강화 단계입니다.');
      return;
    }
    _updateAccount(
      account.copyWith(
        gold: gold - CampMetaRules.forgeGoldCost,
        inventory: {...account.inventory, 'war_scrap': scrap - 2},
        weaponProgress: {
          ...account.weaponProgress,
          weapon.id: ProgressionRules.addWeaponXp(
            progress,
            CampMetaRules.forgeXp,
          ),
        },
      ),
      '${weapon.name} 강화 완료 · 무기 경험치 +${CampMetaRules.forgeXp}',
    );
  }

  void craftTemperedIron() {
    final scrap = account.inventory['war_scrap'] ?? 0;
    if (scrap < 3) {
      setState(() => actionNotice = '제작에는 전장 고철 3개가 필요합니다.');
      return;
    }
    _updateAccount(
      account.copyWith(
        inventory: {
          ...account.inventory,
          'war_scrap': scrap - 3,
          'tempered_iron': (account.inventory['tempered_iron'] ?? 0) + 1,
        },
      ),
      '단련된 흑철을 제작했습니다.',
    );
  }

  void dismantleTemperedIron() {
    final iron = account.inventory['tempered_iron'] ?? 0;
    if (iron < 1) {
      setState(() => actionNotice = '분해할 단련된 흑철이 없습니다.');
      return;
    }
    _updateAccount(
      account.copyWith(
        inventory: {
          ...account.inventory,
          'tempered_iron': iron - 1,
          'war_scrap': (account.inventory['war_scrap'] ?? 0) + 2,
        },
      ),
      '흑철을 분해해 전장 고철 2개를 회수했습니다.',
    );
  }

  void claimMission(MissionSpec mission) {
    if (account.claimedMissionIds.contains(mission.id) ||
        !CampMetaRules.missionComplete(
          mission.id,
          inventory: account.inventory,
          weaponProgress: account.weaponProgress,
        )) {
      return;
    }
    final inventory = Map<String, int>.of(account.inventory);
    for (final entry in CampMetaRules.missionInventoryReward(
      mission.id,
    ).entries) {
      inventory[entry.key] = (inventory[entry.key] ?? 0) + entry.value;
    }
    _updateAccount(
      account.copyWith(
        gold: gold + CampMetaRules.missionGoldReward(mission.id),
        inventory: inventory,
        claimedMissionIds: {...account.claimedMissionIds, mission.id},
      ),
      '${mission.title} 보상을 수령했습니다.',
    );
  }

  RecruitmentReceipt? recruitMercenaries(int count) {
    final tickets = account.inventory['contract_ticket'] ?? 0;
    if (!RecruitmentRules.canRecruit(
      count: count,
      crystals: crystals,
      tickets: tickets,
    )) {
      setState(
        () => actionNotice = count == 1
            ? '계약서 또는 크리스탈이 부족합니다.'
            : '10회 모집에는 크리스탈 2,700개가 필요합니다.',
      );
      return null;
    }
    final ticketSpent = count == 1 && tickets > 0 ? 1 : 0;
    final crystalSpent = ticketSpent > 0
        ? 0
        : count == 1
        ? RecruitmentRules.singleCrystalCost
        : RecruitmentRules.tenCrystalCost;
    final results = RecruitmentRules.roll(
      startIndex: account.recruitmentCount,
      count: count,
    );
    final copies = Map<String, int>.of(account.mercenaryCopies);
    final duplicateTokens = <String, int>{};
    final inventory = Map<String, int>.of(account.inventory);
    for (final id in results) {
      final duplicate = (copies[id] ?? 0) > 0;
      copies[id] = (copies[id] ?? 0) + 1;
      if (duplicate) {
        duplicateTokens[id] =
            (duplicateTokens[id] ?? 0) + RecruitmentRules.duplicateTokenReward;
        final tokenId = '${id}_token';
        inventory[tokenId] =
            (inventory[tokenId] ?? 0) + RecruitmentRules.duplicateTokenReward;
      }
    }
    if (ticketSpent > 0) inventory['contract_ticket'] = tickets - ticketSpent;
    final receipt = RecruitmentReceipt(
      mercenaryIds: results,
      duplicateTokens: duplicateTokens,
      crystalsSpent: crystalSpent,
      ticketsSpent: ticketSpent,
    );
    _updateAccount(
      account.copyWith(
        crystals: crystals - crystalSpent,
        recruitmentCount: account.recruitmentCount + count,
        mercenaryCopies: copies,
        inventory: inventory,
      ),
      '$count명과 용병 계약을 체결했습니다.',
    );
    return receipt;
  }

  void purchaseShopProduct(ShopProductSpec product) {
    final purchased = account.shopPurchaseCounts[product.id] ?? 0;
    final balance = ShopRules.balanceFor(
      product.currency,
      gold: gold,
      warSeals: account.warSeals,
      honor: account.honor,
    );
    if (!ShopRules.canPurchase(
      product: product,
      balance: balance,
      purchased: purchased,
    )) {
      setState(
        () => actionNotice = purchased >= product.purchaseLimit
            ? '이번 갱신의 구매 한도에 도달했습니다.'
            : '${shopCurrencyName(product.currency)}이 부족합니다.',
      );
      return;
    }
    _updateAccount(
      account.copyWith(
        gold: product.currency == ShopCurrency.gold
            ? gold - product.price
            : gold,
        warSeals: product.currency == ShopCurrency.warSeal
            ? account.warSeals - product.price
            : account.warSeals,
        honor: product.currency == ShopCurrency.honor
            ? account.honor - product.price
            : account.honor,
        inventory: {
          ...account.inventory,
          product.itemId:
              (account.inventory[product.itemId] ?? 0) + product.quantity,
        },
        shopPurchaseCounts: {
          ...account.shopPurchaseCounts,
          product.id: purchased + 1,
        },
      ),
      '${product.name} ×${product.quantity} 구매 완료',
    );
  }

  void refreshShop() {
    if (crystals < ShopRules.refreshCrystalCost) {
      setState(() => actionNotice = '상점 갱신에 필요한 크리스탈이 부족합니다.');
      return;
    }
    _updateAccount(
      account.copyWith(
        crystals: crystals - ShopRules.refreshCrystalCost,
        shopPurchaseCounts: {},
        shopRefreshCount: account.shopRefreshCount + 1,
      ),
      '상점 목록을 갱신했습니다. 구매 한도가 초기화됩니다.',
    );
  }

  int get claimableMissionCount => alphaMissions
      .where(
        (mission) =>
            !account.claimedMissionIds.contains(mission.id) &&
            CampMetaRules.missionComplete(
              mission.id,
              inventory: account.inventory,
              weaponProgress: account.weaponProgress,
            ),
      )
      .length;

  Future<void> finishBattle(BattleReport value) async {
    if (_rewardApplied) return;
    _rewardApplied = true;
    final mercenaryBefore =
        account.mercenaryProgress[selectedMercenary.id] ??
        MercenaryProgress(level: selectedMercenary.level, xp: 0, ascension: 0);
    final weaponBefore =
        account.weaponProgress[equippedWeapon.id] ??
        const WeaponProgress(level: 1, xp: 0, stage: 1);
    final mercenaryAfter = ProgressionRules.addMercenaryXp(
      mercenaryBefore,
      value.xp,
    );
    final weaponXp = (value.xp / 2).round();
    final weaponAfter = ProgressionRules.addWeaponXp(weaponBefore, weaponXp);
    final inventoryAdded = ProgressionRules.lootQuantities(value.lootDrops);
    final nextAccount = account.copyWith(
      gold: account.gold + value.gold,
      mercenaryProgress: {
        ...account.mercenaryProgress,
        selectedMercenary.id: mercenaryAfter,
      },
      weaponProgress: {
        ...account.weaponProgress,
        equippedWeapon.id: weaponAfter,
      },
      inventory: {
        ...account.inventory,
        for (final entry in inventoryAdded.entries)
          entry.key: (account.inventory[entry.key] ?? 0) + entry.value,
      },
    );
    try {
      await _saveRepository.save(nextAccount);
    } on Object {
      saveNotice = '자동 저장에 실패했습니다. 현재 실행의 진행 상태는 유지됩니다.';
    }
    if (!mounted) return;
    setState(() {
      _account = nextAccount;
      report = value;
      growthReceipt = GrowthReceipt(
        mercenaryId: selectedMercenary.id,
        mercenaryBefore: mercenaryBefore,
        mercenaryAfter: mercenaryAfter,
        mercenaryXpGained: value.xp,
        weaponId: equippedWeapon.id,
        weaponBefore: weaponBefore,
        weaponAfter: weaponAfter,
        weaponXpGained: weaponXp,
        inventoryAdded: inventoryAdded,
      );
      scene = AppScene.result;
    });
  }

  void startBattle() {
    setState(() {
      _rewardApplied = false;
      report = null;
      growthReceipt = null;
      scene = AppScene.battle;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_account == null) {
      return Scaffold(
        body: DarkBackdrop(
          child: Semantics(
            label: '용병단 저장 데이터를 불러오는 중',
            liveRegion: true,
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xffc49a54)),
            ),
          ),
        ),
      );
    }
    final media = MediaQuery.of(context);
    final baseScale = media.textScaler.scale(1);
    final preferredScale = baseScale * (account.settings.largeText ? 1.15 : 1);
    final effectiveScale = preferredScale.clamp(1.0, 1.3).toDouble();
    final showTutorial =
        widget.enableTutorial &&
        !account.settings.tutorialCompleted &&
        scene == AppScene.camp;
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(effectiveScale)),
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: switch (scene) {
                AppScene.camp => CampScreen(
                  key: const ValueKey('camp'),
                  gold: gold,
                  crystals: crystals,
                  onDeploy: () => go(AppScene.contracts),
                  onRoster: () => go(AppScene.roster),
                  onEquipment: () => openEquipment(AppScene.camp),
                  onCodex: () => go(AppScene.enemyCodex),
                  onForge: () => go(AppScene.forge),
                  onMissions: () => go(AppScene.missions),
                  missionBadge: claimableMissionCount,
                  onRecruitment: () => go(AppScene.recruitment),
                  onShop: () => go(AppScene.shop),
                  onSettings: () => go(AppScene.settings),
                  statusNotice: saveNotice,
                ),
                AppScene.contracts => ContractScreen(
                  key: const ValueKey('contracts'),
                  selected: selected,
                  onSelect: (value) => setState(() => selected = value),
                  onBack: () => go(AppScene.camp),
                  onDeploy: () => go(AppScene.mercenarySelect),
                ),
                AppScene.mercenarySelect => MercenarySelectScreen(
                  key: const ValueKey('mercenary-select'),
                  selected: selectedMercenary,
                  equippedWeapon: equippedWeapon,
                  mercenaryProgress: account.mercenaryProgress,
                  onSelect: (mercenary) {
                    setState(() {
                      selectedMercenary = mercenary;
                      equippedWeapon = gameContent.weaponById(
                        account.equippedWeaponByMercenary[mercenary.id] ??
                            mercenary.signatureWeaponId,
                      );
                      _account = account.copyWith(
                        selectedMercenaryId: mercenary.id,
                      );
                      unawaited(_persistAccount());
                    });
                  },
                  onBack: () => go(AppScene.contracts),
                  onEquipment: () => openEquipment(AppScene.mercenarySelect),
                  onDeploy: startBattle,
                ),
                AppScene.equipment => EquipmentScreen(
                  key: const ValueKey('equipment'),
                  mercenary: selectedMercenary,
                  equipped: equippedWeapon,
                  weaponProgress: account.weaponProgress,
                  onEquip: (weapon) {
                    setState(() {
                      equippedWeapon = weapon;
                      _account = account.copyWith(
                        equippedWeaponByMercenary: {
                          ...account.equippedWeaponByMercenary,
                          selectedMercenary.id: weapon.id,
                        },
                      );
                      unawaited(_persistAccount());
                    });
                  },
                  onBack: () => go(equipmentReturn),
                ),
                AppScene.roster => RosterScreen(
                  key: const ValueKey('roster'),
                  onBack: () => go(AppScene.camp),
                  mercenaryProgress: account.mercenaryProgress,
                  onSelect: (mercenary) {
                    setState(() {
                      selectedMercenary = mercenary;
                      scene = AppScene.detail;
                    });
                  },
                ),
                AppScene.detail => MercenaryDetailScreen(
                  key: const ValueKey('detail'),
                  mercenary: selectedMercenary,
                  progress: account.mercenaryProgress[selectedMercenary.id]!,
                  equippedWeapon: gameContent.weaponById(
                    account.equippedWeaponByMercenary[selectedMercenary.id] ??
                        selectedMercenary.signatureWeaponId,
                  ),
                  weaponProgress: account.weaponProgress,
                  inventory: account.inventory,
                  gold: gold,
                  notice: actionNotice,
                  onTrain: () => trainMercenary(selectedMercenary),
                  onAscend: () => ascendMercenary(selectedMercenary),
                  onEquipment: () => openEquipment(AppScene.detail),
                  onBack: () => go(AppScene.roster),
                ),
                AppScene.battle => BattleScreen(
                  key: ValueKey(
                    'battle-${DateTime.now().millisecondsSinceEpoch}',
                  ),
                  contract: selected,
                  mercenary: selectedMercenary,
                  weapon: equippedWeapon,
                  mercenaryProgress:
                      account.mercenaryProgress[selectedMercenary.id] ??
                      MercenaryProgress(
                        level: selectedMercenary.level,
                        xp: 0,
                        ascension: 0,
                      ),
                  weaponProgress:
                      account.weaponProgress[equippedWeapon.id] ??
                      const WeaponProgress(level: 1, xp: 0, stage: 1),
                  reducedEffects: account.settings.reducedFlash,
                  onExit: () => go(AppScene.camp),
                  onVictory: finishBattle,
                ),
                AppScene.result => ResultScreen(
                  key: const ValueKey('result'),
                  report: report!,
                  growthReceipt: growthReceipt!,
                  saveNotice: saveNotice,
                  onCamp: () => go(AppScene.camp),
                  onReplay: startBattle,
                ),
                AppScene.enemyCodex => EnemyCodexScreen(
                  key: const ValueKey('enemy-codex'),
                  onBack: () => go(AppScene.camp),
                ),
                AppScene.forge => ForgeScreen(
                  key: const ValueKey('forge'),
                  weapons: gameContent.weapons,
                  progress: account.weaponProgress,
                  inventory: account.inventory,
                  gold: gold,
                  notice: actionNotice,
                  onEnhance: forgeWeapon,
                  onCraft: craftTemperedIron,
                  onDismantle: dismantleTemperedIron,
                  onBack: () => go(AppScene.camp),
                ),
                AppScene.missions => MissionScreen(
                  key: const ValueKey('missions'),
                  inventory: account.inventory,
                  weaponProgress: account.weaponProgress,
                  claimedMissionIds: account.claimedMissionIds,
                  notice: actionNotice,
                  onClaim: claimMission,
                  onBack: () => go(AppScene.camp),
                ),
                AppScene.recruitment => RecruitmentScreen(
                  key: const ValueKey('recruitment'),
                  crystals: crystals,
                  tickets: account.inventory['contract_ticket'] ?? 0,
                  mercenaryCopies: account.mercenaryCopies,
                  notice: actionNotice,
                  onRecruit: recruitMercenaries,
                  onRoster: () => go(AppScene.roster),
                  onBack: () => go(AppScene.camp),
                ),
                AppScene.shop => ShopScreen(
                  key: const ValueKey('shop'),
                  gold: gold,
                  crystals: crystals,
                  warSeals: account.warSeals,
                  honor: account.honor,
                  inventory: account.inventory,
                  purchaseCounts: account.shopPurchaseCounts,
                  refreshCount: account.shopRefreshCount,
                  notice: actionNotice,
                  onPurchase: purchaseShopProduct,
                  onRefresh: refreshShop,
                  onBack: () => go(AppScene.camp),
                ),
                AppScene.settings => SettingsScreen(
                  key: const ValueKey('settings'),
                  settings: account.settings,
                  notice: actionNotice,
                  onChanged: updateSettings,
                  onReplayTutorial: () {
                    setState(() {
                      tutorialStep = 0;
                      scene = AppScene.camp;
                      _account = account.copyWith(
                        settings: account.settings.copyWith(
                          tutorialCompleted: false,
                        ),
                      );
                      unawaited(_persistAccount());
                    });
                  },
                  onBack: () => go(AppScene.camp),
                ),
              },
            ),
            if (showTutorial)
              TutorialOverlay(
                step: tutorialStep,
                onNext: () {
                  if (tutorialStep >= tutorialSteps.length - 1) {
                    completeTutorial();
                  } else {
                    setState(() => tutorialStep++);
                  }
                },
                onSkip: completeTutorial,
              ),
          ],
        ),
      ),
    );
  }
}

class BattlefieldContract {
  const BattlefieldContract({
    required this.id,
    required this.battlefield,
    required this.condition,
    required this.name,
    required this.subtitle,
    required this.power,
    required this.reward,
    required this.xp,
    required this.color,
    required this.icon,
  });
  final String id;
  final BattlefieldType battlefield;
  final BattlefieldCondition condition;
  final String name;
  final String subtitle;
  final int power;
  final int reward;
  final int xp;
  final Color color;
  final IconData icon;
}

const contracts = [
  BattlefieldContract(
    id: 'north_gate_defense',
    battlefield: BattlefieldType.gateDefense,
    condition: BattlefieldCondition.moonlitNight,
    name: '성문 방어전',
    subtitle: '새벽까지 북문을 사수하라',
    power: 18000,
    reward: 3000,
    xp: 1200,
    color: Color(0xff334d6f),
    icon: Icons.shield_outlined,
  ),
  BattlefieldContract(
    id: 'ashwind_evacuation',
    battlefield: BattlefieldType.evacuation,
    condition: BattlefieldCondition.ashWind,
    name: '철수전',
    subtitle: '부상병과 보급대를 호위하라',
    power: 22000,
    reward: 4500,
    xp: 1450,
    color: Color(0xff8c6031),
    icon: Icons.directions_run,
  ),
  BattlefieldContract(
    id: 'commander_assassination',
    battlefield: BattlefieldType.gateDefense,
    condition: BattlefieldCondition.moonlitNight,
    name: '적 지휘관 암살',
    subtitle: '혼란 속에서 지휘관을 제거하라',
    power: 25000,
    reward: 5000,
    xp: 1750,
    color: Color(0xff733b3e),
    icon: Icons.gps_fixed,
  ),
];
