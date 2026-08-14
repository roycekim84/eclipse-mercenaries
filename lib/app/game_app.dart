import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/content/game_content_repository.dart';
import '../core/content/game_visuals.dart';
import '../core/audio/game_audio_feedback.dart';
import '../core/persistence/save_repository.dart';
import '../core/theme/game_theme.dart';
import '../domain/battle_models.dart';
import '../domain/battle_diagnostics.dart';
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
part '../core/widgets/landscape_hint.dart';
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
      title: '월식 용병단: Eclipse Mercenaries',
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
  State<GameShell> createState() => GameShellState();
}

class GameShellState extends State<GameShell> {
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
  Future<void> _saveQueue = Future<void>.value();

  AccountSave get account => _account!;
  int get gold => account.gold;
  int get crystals => account.crystals;

  void updateSettings(GameSettings settings) {
    setState(() {
      _account = account.copyWith(settings: settings);
      actionNotice = null;
    });
    unawaited(_persistAccount());
    unawaited(GameAudioFeedback.applySettings(settings));
    if (settings.soundEnabled) {
      unawaited(GameAudioFeedback.campAmbience(settings));
    } else {
      unawaited(GameAudioFeedback.stopMusic());
    }
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
    final catalogMercenaryIds = gameContent.mercenaries
        .map((mercenary) => mercenary.id)
        .toSet();
    final mercenaryIds = loaded.mercenaryProgress.keys
        .where(catalogMercenaryIds.contains)
        .toSet();
    final mercenaryId = mercenaryIds.contains(loaded.selectedMercenaryId)
        ? loaded.selectedMercenaryId
        : 'luna';
    selectedMercenary = gameContent.mercenaryById(mercenaryId);
    final weaponIds = gameContent.weapons.map((weapon) => weapon.id).toSet();
    final savedWeapon = loaded.equippedWeaponByMercenary[mercenaryId];
    final weaponId =
        weaponIds.contains(savedWeapon) &&
            loaded.weaponProgress.containsKey(savedWeapon)
        ? savedWeapon!
        : loaded.weaponProgress.containsKey(selectedMercenary.signatureWeaponId)
        ? selectedMercenary.signatureWeaponId
        : 'iron_sword';
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
    unawaited(GameAudioFeedback.campAmbience(loaded.settings));
  }

  Future<void> _persistAccount() async {
    final snapshot = account;
    _saveQueue = _saveQueue
        .catchError((_) {
          // A prior failed write must not poison later automatic saves.
        })
        .then((_) => _saveRepository.save(snapshot));
    try {
      await _saveQueue;
    } on Object {
      if (!mounted) return;
      setState(() {
        saveNotice = '자동 저장에 실패했습니다. 현재 실행의 진행 상태는 유지됩니다.';
      });
    }
  }

  Future<void> retrySave() async {
    try {
      await _saveRepository.save(account);
      if (!mounted) return;
      setState(() {
        saveNotice = null;
        actionNotice = '진행 상태를 안전하게 저장했습니다.';
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        saveNotice = '저장 재시도에 실패했습니다. 연결 상태와 저장 공간을 확인해 주세요.';
      });
    }
  }

  void go(AppScene next) {
    unawaited(
      GameAudioFeedback.cue(
        next == AppScene.camp ? AudioCue.back : AudioCue.navigation,
        account.settings,
      ),
    );
    if (next == AppScene.recruitment) {
      unawaited(GameAudioFeedback.recruitmentAmbience(account.settings));
    } else if (next != AppScene.battle && next != AppScene.result) {
      unawaited(GameAudioFeedback.campAmbience(account.settings));
    }
    setState(() => scene = next);
  }

  void openEquipment(AppScene returnTo) {
    unawaited(GameAudioFeedback.cue(AudioCue.navigation, account.settings));
    setState(() {
      equipmentReturn = returnTo;
      scene = AppScene.equipment;
    });
  }

  void _updateAccount(AccountSave next, String notice) {
    unawaited(GameAudioFeedback.confirmation(account.settings));
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
      unawaited(GameAudioFeedback.cue(AudioCue.error, account.settings));
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
        gold: gold - CampMetaRules.trainingGoldCostFor(progress),
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
      unawaited(GameAudioFeedback.cue(AudioCue.error, account.settings));
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
      '${mercenary.name} ${ProgressionRules.gradeName(progress.ascension + 1)}급 승급 · Lv.1부터 새 전공을 시작합니다.',
    );
  }

  void limitBreakMercenary(MercenarySpec mercenary) {
    final progress = account.mercenaryProgress[mercenary.id]!;
    final tokenId = '${mercenary.id}_token';
    final dedicated = account.inventory[tokenId] ?? 0;
    final legacy = account.inventory['legacy_sigil'] ?? 0;
    final cost = ProgressionRules.limitBreakTokenCost(progress.stars);
    if (progress.stars >= 5 || dedicated + legacy < cost) {
      setState(
        () => actionNotice = progress.stars >= 5
            ? '이미 ★5 한계돌파를 완료했습니다.'
            : '전용 증표와 전승 인장이 합계 $cost개 필요합니다.',
      );
      return;
    }
    final useDedicated = dedicated.clamp(0, cost);
    final useLegacy = cost - useDedicated;
    _updateAccount(
      account.copyWith(
        inventory: {
          ...account.inventory,
          tokenId: dedicated - useDedicated,
          'legacy_sigil': legacy - useLegacy,
        },
        mercenaryProgress: {
          ...account.mercenaryProgress,
          mercenary.id: ProgressionRules.limitBreak(progress),
        },
      ),
      '${mercenary.name} ★${progress.stars + 1} 한계돌파 완료',
    );
  }

  void forgeWeapon(WeaponSpec weapon) {
    final scrap = account.inventory['war_scrap'] ?? 0;
    final progress = account.weaponProgress[weapon.id]!;
    final forgeCost = CampMetaRules.forgeGoldCostFor(progress);
    if (!CampMetaRules.canForge(gold: gold, scrap: scrap, progress: progress)) {
      unawaited(GameAudioFeedback.cue(AudioCue.error, account.settings));
      setState(() => actionNotice = '강화에는 $forgeCost 골드와 전장 고철 2개가 필요합니다.');
      return;
    }
    if (progress.level >= 20) {
      unawaited(GameAudioFeedback.cue(AudioCue.error, account.settings));
      setState(() => actionNotice = '이미 최대 강화 단계입니다.');
      return;
    }
    _updateAccount(
      account.copyWith(
        gold: gold - forgeCost,
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
    unawaited(GameAudioFeedback.cue(AudioCue.forge, account.settings));
  }

  void craftTemperedIron() {
    final scrap = account.inventory['war_scrap'] ?? 0;
    if (scrap < 3) {
      unawaited(GameAudioFeedback.cue(AudioCue.error, account.settings));
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
      unawaited(GameAudioFeedback.cue(AudioCue.error, account.settings));
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
        !CampMetaRules.missionUnlocked(mission.id, account.claimedMissionIds) ||
        !CampMetaRules.missionComplete(
          mission.id,
          inventory: account.inventory,
          weaponProgress: account.weaponProgress,
          commanderLevel: account.commanderLevel,
          ownedMercenaries: account.mercenaryProgress.length,
          factionReputation: account.factionReputation,
          operationProgress: account.operationProgress,
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
    unawaited(GameAudioFeedback.cue(AudioCue.reward, account.settings));
  }

  RecruitmentReceipt? recruitMercenaries(int count) {
    final tickets = account.inventory['contract_ticket'] ?? 0;
    if (!RecruitmentRules.canRecruit(
      count: count,
      crystals: crystals,
      tickets: tickets,
    )) {
      unawaited(GameAudioFeedback.cue(AudioCue.error, account.settings));
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
    // The first contract is a designed onboarding beat: it always opens the
    // support slot with Mira instead of risking a duplicate of starter Luna.
    final results = account.recruitmentCount == 0 && count == 1
        ? <String>[RecruitmentRules.onboardingRecruitId]
        : RecruitmentRules.roll(
            startIndex: account.recruitmentCount,
            count: count,
            random: math.Random.secure(),
          );
    final copies = Map<String, int>.of(account.mercenaryCopies);
    final mercenaryProgress = Map<String, MercenaryProgress>.of(
      account.mercenaryProgress,
    );
    final equippedWeapons = Map<String, String>.of(
      account.equippedWeaponByMercenary,
    );
    final equippedGear = Map<String, String>.of(
      account.equippedGearByMercenary,
    );
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
        inventory['legacy_sigil'] = (inventory['legacy_sigil'] ?? 0) + 2;
      } else {
        mercenaryProgress[id] = const MercenaryProgress(
          level: 1,
          xp: 0,
          ascension: 0,
        );
        equippedWeapons[id] = 'iron_sword';
        equippedGear['$id:armor'] = 'moonweave_guard';
        equippedGear['$id:accessory'] = 'nightfang_charm';
        equippedGear['$id:tactical'] = 'moonstep_hook';
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
        mercenaryProgress: mercenaryProgress,
        equippedWeaponByMercenary: equippedWeapons,
        equippedGearByMercenary: equippedGear,
        inventory: inventory,
      ),
      '$count명과 용병 계약을 체결했습니다.',
    );
    unawaited(
      GameAudioFeedback.cue(AudioCue.recruitContract, account.settings),
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
    unawaited(GameAudioFeedback.cue(AudioCue.purchase, account.settings));
  }

  void refreshShop() {
    if (crystals < ShopRules.refreshCrystalCost) {
      unawaited(GameAudioFeedback.cue(AudioCue.error, account.settings));
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

  int get claimableMissionCount => releaseMissions
      .where(
        (mission) =>
            !account.claimedMissionIds.contains(mission.id) &&
            CampMetaRules.missionUnlocked(
              mission.id,
              account.claimedMissionIds,
            ) &&
            CampMetaRules.missionComplete(
              mission.id,
              inventory: account.inventory,
              weaponProgress: account.weaponProgress,
              commanderLevel: account.commanderLevel,
              ownedMercenaries: account.mercenaryProgress.length,
              factionReputation: account.factionReputation,
              operationProgress: account.operationProgress,
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
    final supportId = account.selectedSupportMercenaryId;
    final dispatchId = account.selectedDispatchMercenaryId;
    final dispatchXpBonus = dispatchId == 'fenn' ? (value.xp * .08).round() : 0;
    final earnedXp = value.xp + dispatchXpBonus;
    final mercenaryAfter = ProgressionRules.addMercenaryXp(
      mercenaryBefore,
      earnedXp,
    );
    final weaponXp = (earnedXp / 2).round();
    final weaponAfter = ProgressionRules.addWeaponXp(weaponBefore, weaponXp);
    final inventoryAdded = ProgressionRules.lootQuantities(value.lootDrops);
    final commanderProgress = ProgressionRules.addCommanderXp(
      account.commanderLevel,
      account.commanderXp,
      (earnedXp / 2).round(),
    );
    final factionId = selected.factionId;
    final operation = WarOperationRules.forFaction(factionId);
    final reputationGain =
        FactionRules.reputationGain(value.outcome.name) +
        (dispatchId == 'corva' ? 2 : 0);
    final warSealGain = switch (value.outcome) {
      BattleOutcome.victory => 12 + value.completedBonusIds.length * 2,
      BattleOutcome.retreat => 5,
      BattleOutcome.defeat => 2,
    };
    final honorGain = switch (value.outcome) {
      BattleOutcome.victory =>
        4 +
            (value.enemyCommanderDefeated ? 4 : 0) +
            (value.commanderSurvived ? 2 : 0),
      BattleOutcome.retreat => value.commanderSurvived ? 2 : 0,
      BattleOutcome.defeat => 0,
    };
    final patronGoldBonus =
        factionId == 'aurum_league' && value.outcome == BattleOutcome.victory
        ? 300
        : 0;
    final dispatchGoldBonus = dispatchId == 'talia'
        ? (value.gold * .18).round()
        : 0;
    final medicRecoveryBonus =
        supportId == 'mira' && value.outcome != BattleOutcome.victory
        ? (value.gold * .10).round()
        : 0;
    final serviceInventory = <String, int>{
      if (supportId == 'mira') 'field_medicine': 1,
      if (supportId == 'elka') 'war_scrap': 1,
      if (dispatchId == 'talia') 'field_ration': 1,
      if (dispatchId == 'silas') 'tempered_iron': 1,
    };
    final nextAccount = account.copyWith(
      commanderLevel: commanderProgress.level,
      commanderXp: commanderProgress.xp,
      gold:
          account.gold +
          value.gold +
          patronGoldBonus +
          dispatchGoldBonus +
          medicRecoveryBonus,
      warSeals: account.warSeals + warSealGain,
      honor: account.honor + honorGain,
      factionReputation: {
        ...account.factionReputation,
        factionId: (account.factionReputation[factionId] ?? 0) + reputationGain,
      },
      operationProgress: {
        ...account.operationProgress,
        operation.id: WarOperationRules.advance(
          account.operationProgress[operation.id] ?? 0,
          value.outcome.name,
        ),
      },
      clearedContractIds: value.outcome == BattleOutcome.victory
          ? {...account.clearedContractIds, selected.id}
          : account.clearedContractIds,
      dispatchProgress: {
        ...account.dispatchProgress,
        ?dispatchId:
            (account.dispatchProgress[dispatchId] ?? 0) +
            (value.outcome == BattleOutcome.victory ? 1 : 0),
      },
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
        for (final entry in serviceInventory.entries)
          entry.key:
              (account.inventory[entry.key] ?? 0) +
              (inventoryAdded[entry.key] ?? 0) +
              entry.value,
      },
      battleDiagnostics: BattleDiagnosticRules.append(
        account.battleDiagnostics,
        BattleDiagnosticRecord.fromReport(
          report: value,
          contentVersion: gameContent.contentVersion,
          seed: 19,
          contractId: selected.id,
          mercenaryId: selectedMercenary.id,
          weaponId: equippedWeapon.id,
        ),
      ),
    );
    try {
      await _saveRepository.save(nextAccount);
    } on Object {
      saveNotice = '자동 저장에 실패했습니다. 현재 실행의 진행 상태는 유지됩니다.';
    }
    if (!mounted) return;
    unawaited(GameAudioFeedback.result(value.outcome, account.settings));
    setState(() {
      _account = nextAccount;
      report = value;
      final receiptInventory = <String, int>{...inventoryAdded};
      for (final entry in serviceInventory.entries) {
        receiptInventory[entry.key] =
            (receiptInventory[entry.key] ?? 0) + entry.value;
      }
      growthReceipt = GrowthReceipt(
        mercenaryId: selectedMercenary.id,
        mercenaryBefore: mercenaryBefore,
        mercenaryAfter: mercenaryAfter,
        mercenaryXpGained: earnedXp,
        weaponId: equippedWeapon.id,
        weaponBefore: weaponBefore,
        weaponAfter: weaponAfter,
        weaponXpGained: weaponXp,
        inventoryAdded: receiptInventory,
      );
      scene = AppScene.result;
    });
  }

  void startBattle() {
    if (!selectedMercenary.canDeploy) {
      setState(
        () => actionNotice =
            '${selectedMercenary.name}은 ${mercenaryDutyName(selectedMercenary.duty)} 전담 용병입니다. 출전 영웅을 선택하십시오.',
      );
      return;
    }
    unawaited(
      GameAudioFeedback.battleAmbience(account.settings, selected.battlefield),
    );
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
          child: const Center(
            child: SizedBox(
              width: 330,
              child: GameStatePanel(
                icon: Icons.shield_outlined,
                title: '용병단 기록 불러오는 중',
                message: '캠프 장부와 출전 준비 상태를 확인하고 있습니다.',
                loading: true,
              ),
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
    final showLandscapeHint =
        media.size.width < 600 || media.size.height > media.size.width;
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(effectiveScale)),
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(.025, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: child,
                ),
              ),
              child: switch (scene) {
                AppScene.camp => CampScreen(
                  key: const ValueKey('camp'),
                  gold: gold,
                  crystals: crystals,
                  commanderLevel: account.commanderLevel,
                  lastReport: report,
                  campaignCycle:
                      account.recruitmentCount +
                      account.factionReputation.values.fold(0, (a, b) => a + b),
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
                  onRetrySave: retrySave,
                ),
                AppScene.contracts => ContractScreen(
                  key: const ValueKey('contracts'),
                  selected: selected,
                  commanderLevel: account.commanderLevel,
                  factionReputation: account.factionReputation,
                  operationProgress: account.operationProgress,
                  onSelect: (value) => setState(() => selected = value),
                  onBack: () => go(AppScene.camp),
                  onDeploy: () => go(AppScene.mercenarySelect),
                ),
                AppScene.mercenarySelect => MercenarySelectScreen(
                  key: const ValueKey('mercenary-select'),
                  selected: selectedMercenary,
                  equippedWeapon: equippedWeapon,
                  mercenaryProgress: account.mercenaryProgress,
                  selectedSupportId: account.selectedSupportMercenaryId,
                  selectedDispatchId: account.selectedDispatchMercenaryId,
                  onSupportSelect: (mercenary) => _updateAccount(
                    account.copyWith(selectedSupportMercenaryId: mercenary?.id),
                    mercenary == null
                        ? '지원 용병 배치를 해제했습니다.'
                        : '${mercenary.name}을 지원 슬롯에 배치했습니다.',
                  ),
                  onDispatchSelect: (mercenary) => _updateAccount(
                    account.copyWith(
                      selectedDispatchMercenaryId: mercenary?.id,
                    ),
                    mercenary == null
                        ? '파견 용병 배치를 해제했습니다.'
                        : '${mercenary.name}을 파견 슬롯에 배치했습니다.',
                  ),
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
                  equippedGear: {
                    for (final slot in GearSlot.values)
                      slot: GearRules.byId(
                        account.equippedGearByMercenary[GearRules.key(
                          selectedMercenary.id,
                          slot,
                        )]!,
                      ),
                  },
                  onEquip: (weapon) {
                    unawaited(
                      GameAudioFeedback.cue(AudioCue.equip, account.settings),
                    );
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
                  onEquipGear: (slot, gear) {
                    unawaited(
                      GameAudioFeedback.cue(AudioCue.equip, account.settings),
                    );
                    _updateAccount(
                      account.copyWith(
                        equippedGearByMercenary: {
                          ...account.equippedGearByMercenary,
                          GearRules.key(selectedMercenary.id, slot): gear.id,
                        },
                      ),
                      '${gear.name} 장착 완료',
                    );
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
                  onLimitBreak: () => limitBreakMercenary(selectedMercenary),
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
                  performanceMode: account.settings.performanceMode,
                  screenShakeEnabled: account.settings.screenShakeEnabled,
                  soundEnabled: account.settings.soundEnabled,
                  audioSettings: account.settings,
                  inputMode: account.settings.battleInputMode,
                  targetPriority: account.settings.autoTargetPriority,
                  gearBonus: applySupportCombatBonus(
                    base: GearRules.combatBonus(
                      GearSlot.values.map(
                        (slot) =>
                            account.equippedGearByMercenary[GearRules.key(
                              selectedMercenary.id,
                              slot,
                            )]!,
                      ),
                    ),
                    supportId: account.selectedSupportMercenaryId,
                    contract: selected,
                  ),
                  onExit: () => go(AppScene.camp),
                  onVictory: finishBattle,
                ),
                AppScene.result => ResultScreen(
                  key: const ValueKey('result'),
                  report: report!,
                  growthReceipt: growthReceipt!,
                  saveNotice: saveNotice,
                  onRetrySave: retrySave,
                  onCamp: () => go(AppScene.camp),
                  onReplay: startBattle,
                ),
                AppScene.enemyCodex => EnemyCodexScreen(
                  key: const ValueKey('enemy-codex'),
                  onBack: () => go(AppScene.camp),
                ),
                AppScene.forge => ForgeScreen(
                  key: const ValueKey('forge'),
                  weapons: gameContent.weapons
                      .where(
                        (weapon) =>
                            account.weaponProgress.containsKey(weapon.id),
                      )
                      .toList(growable: false),
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
                  commanderLevel: account.commanderLevel,
                  ownedMercenaries: account.mercenaryProgress.length,
                  factionReputation: account.factionReputation,
                  operationProgress: account.operationProgress,
                  notice: actionNotice,
                  onClaim: claimMission,
                  onBack: () => go(AppScene.camp),
                ),
                AppScene.recruitment => RecruitmentScreen(
                  key: const ValueKey('recruitment'),
                  crystals: crystals,
                  tickets: account.inventory['contract_ticket'] ?? 0,
                  recruitmentCount: account.recruitmentCount,
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
                  diagnostics: account.battleDiagnostics,
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
            if (showLandscapeHint) const LandscapeHintBanner(),
          ],
        ),
      ),
    );
  }
}

class BattlefieldContract {
  const BattlefieldContract({
    required this.id,
    required this.factionId,
    required this.battlefield,
    required this.condition,
    required this.objective,
    required this.battlefieldName,
    required this.name,
    required this.subtitle,
    required this.power,
    required this.requiredCommanderLevel,
    required this.reward,
    required this.xp,
    required this.color,
    required this.icon,
    required this.balance,
  });
  final String id;
  final String factionId;
  final BattlefieldType battlefield;
  final BattlefieldCondition condition;
  final ContractObjective objective;
  final String battlefieldName;
  final String name;
  final String subtitle;
  final int power;
  final int requiredCommanderLevel;
  final int reward;
  final int xp;
  final Color color;
  final IconData icon;
  final StageBalanceProfile balance;
}

GearCombatBonus applySupportCombatBonus({
  required GearCombatBonus base,
  required String? supportId,
  required BattlefieldContract contract,
}) {
  final defensive = supportId == 'garr' ? 1.12 : 1.0;
  final hunting =
      supportId == 'soren' &&
          (contract.objective == ContractObjective.ambush ||
              contract.objective == ContractObjective.assassination)
      ? 1.10
      : 1.0;
  return GearCombatBonus(
    hpMultiplier: base.hpMultiplier * defensive,
    damageMultiplier: base.damageMultiplier * hunting,
    speedMultiplier: base.speedMultiplier,
    criticalChance: base.criticalChance,
    dashCooldownMultiplier: base.dashCooldownMultiplier,
    tacticalCooldownMultiplier: base.tacticalCooldownMultiplier,
  );
}

const contracts = [
  BattlefieldContract(
    id: 'north_gate_defense',
    factionId: 'aurum_league',
    battlefield: BattlefieldType.gateDefense,
    condition: BattlefieldCondition.moonlitNight,
    objective: ContractObjective.defense,
    battlefieldName: '북문 성벽',
    name: '성문 방어전',
    subtitle: '새벽까지 북문을 사수하라',
    power: 8000,
    requiredCommanderLevel: 1,
    reward: 3000,
    xp: 1200,
    color: Color(0xff334d6f),
    icon: Icons.shield_outlined,
    balance: StageBalanceProfile.baseline(),
  ),
  BattlefieldContract(
    id: 'ashwind_evacuation',
    factionId: 'ember_principality',
    battlefield: BattlefieldType.evacuation,
    condition: BattlefieldCondition.ashWind,
    objective: ContractObjective.evacuation,
    battlefieldName: '잿바람 철수로',
    name: '철수전',
    subtitle: '부상병과 보급대를 호위하라',
    power: 10500,
    requiredCommanderLevel: 3,
    reward: 3800,
    xp: 1450,
    color: Color(0xff8c6031),
    icon: Icons.directions_run,
    balance: StageBalanceProfile(
      durationSeconds: 70,
      unitCount: 580,
      initialDeployment: 100,
      activePopulationTarget: 200,
      reinforcementInterval: 4.7,
      enemyHpMultiplier: 1.06,
      enemyDamageBonus: 1,
      enemySpeedMultiplier: 1.04,
      eliteStride: 80,
      firstEventAt: 15,
      eventInterval: 17,
    ),
  ),
  BattlefieldContract(
    id: 'commander_assassination',
    factionId: 'grey_banner',
    battlefield: BattlefieldType.assassination,
    condition: BattlefieldCondition.twilightSiege,
    objective: ContractObjective.assassination,
    battlefieldName: '황혼 공성 평원',
    name: '적 지휘관 암살',
    subtitle: '혼란 속에서 지휘관을 제거하라',
    power: 13500,
    requiredCommanderLevel: 5,
    reward: 4700,
    xp: 1750,
    color: Color(0xff733b3e),
    icon: Icons.gps_fixed,
    balance: StageBalanceProfile(
      durationSeconds: 75,
      unitCount: 650,
      initialDeployment: 108,
      activePopulationTarget: 215,
      reinforcementInterval: 4.4,
      enemyHpMultiplier: 1.12,
      enemyDamageBonus: 1,
      enemySpeedMultiplier: 1.06,
      eliteStride: 72,
      firstEventAt: 14,
      eventInterval: 16,
    ),
  ),
  BattlefieldContract(
    id: 'black_forest_supply',
    factionId: 'aurum_league',
    battlefield: BattlefieldType.supplyEscort,
    condition: BattlefieldCondition.blackForest,
    objective: ContractObjective.supplyEscort,
    battlefieldName: '검은숲 보급로',
    name: '보급부대 호위',
    subtitle: '검은숲을 지나 전선에 군량을 전달하라',
    power: 17000,
    requiredCommanderLevel: 8,
    reward: 5700,
    xp: 1900,
    color: Color(0xff315844),
    icon: Icons.local_shipping_outlined,
    balance: StageBalanceProfile(
      durationSeconds: 80,
      unitCount: 720,
      initialDeployment: 116,
      activePopulationTarget: 230,
      reinforcementInterval: 4.1,
      enemyHpMultiplier: 1.18,
      enemyDamageBonus: 2,
      enemySpeedMultiplier: 1.07,
      eliteStride: 65,
      firstEventAt: 14,
      eventInterval: 15,
    ),
  ),
  BattlefieldContract(
    id: 'black_forest_ambush',
    factionId: 'grey_banner',
    battlefield: BattlefieldType.ambush,
    condition: BattlefieldCondition.blackForest,
    objective: ContractObjective.ambush,
    battlefieldName: '검은숲 보급로',
    name: '적 진지 기습',
    subtitle: '안개 속에서 적 병력 120명을 격파하라',
    power: 21500,
    requiredCommanderLevel: 12,
    reward: 6900,
    xp: 2300,
    color: Color(0xff3f4d36),
    icon: Icons.visibility_off_outlined,
    balance: StageBalanceProfile(
      durationSeconds: 90,
      unitCount: 820,
      initialDeployment: 124,
      activePopulationTarget: 250,
      reinforcementInterval: 3.8,
      enemyHpMultiplier: 1.25,
      enemyDamageBonus: 2,
      enemySpeedMultiplier: 1.10,
      eliteStride: 58,
      firstEventAt: 13,
      eventInterval: 14,
    ),
  ),
  BattlefieldContract(
    id: 'white_night_retake',
    factionId: 'ember_principality',
    battlefield: BattlefieldType.fortressRetake,
    condition: BattlefieldCondition.whiteNight,
    objective: ContractObjective.fortressRetake,
    battlefieldName: '백야 설원 요새',
    name: '요새 탈환',
    subtitle: '빙결 요새의 지휘관과 수비대를 제거하라',
    power: 27000,
    requiredCommanderLevel: 16,
    reward: 8400,
    xp: 2900,
    color: Color(0xff547287),
    icon: Icons.castle_outlined,
    balance: StageBalanceProfile(
      durationSeconds: 100,
      unitCount: 940,
      initialDeployment: 132,
      activePopulationTarget: 270,
      reinforcementInterval: 3.5,
      enemyHpMultiplier: 1.33,
      enemyDamageBonus: 3,
      enemySpeedMultiplier: 1.12,
      eliteStride: 52,
      firstEventAt: 12,
      eventInterval: 13,
    ),
  ),
  BattlefieldContract(
    id: 'veteran_northwall',
    factionId: 'aurum_league',
    battlefield: BattlefieldType.gateDefense,
    condition: BattlefieldCondition.moonlitNight,
    objective: ContractObjective.defense,
    battlefieldName: '북벽 외성',
    name: '정예 · 무너진 외성',
    subtitle: '정예 공성대의 세 차례 돌격을 저지하라',
    power: 32000,
    requiredCommanderLevel: 18,
    reward: 9800,
    xp: 3400,
    color: Color(0xff5f4930),
    icon: Icons.military_tech_outlined,
    balance: StageBalanceProfile(
      durationSeconds: 105,
      unitCount: 1050,
      initialDeployment: 138,
      activePopulationTarget: 285,
      reinforcementInterval: 3.25,
      enemyHpMultiplier: 1.48,
      enemyDamageBonus: 4,
      enemySpeedMultiplier: 1.13,
      eliteStride: 42,
      firstEventAt: 12,
      eventInterval: 13,
    ),
  ),
  BattlefieldContract(
    id: 'grey_bounty_hunt',
    factionId: 'grey_banner',
    battlefield: BattlefieldType.assassination,
    condition: BattlefieldCondition.blackForest,
    objective: ContractObjective.assassination,
    battlefieldName: '검은숲 현상금 지대',
    name: '현상금 · 세 개의 목',
    subtitle: '이름난 지휘관들을 차례로 추적하라',
    power: 36500,
    requiredCommanderLevel: 22,
    reward: 11800,
    xp: 3900,
    color: Color(0xff594062),
    icon: Icons.track_changes,
    balance: StageBalanceProfile(
      durationSeconds: 110,
      unitCount: 1120,
      initialDeployment: 142,
      activePopulationTarget: 295,
      reinforcementInterval: 3.05,
      enemyHpMultiplier: 1.62,
      enemyDamageBonus: 5,
      enemySpeedMultiplier: 1.16,
      eliteStride: 36,
      firstEventAt: 11,
      eventInterval: 12,
    ),
  ),
  BattlefieldContract(
    id: 'nightmare_ashroad',
    factionId: 'ember_principality',
    battlefield: BattlefieldType.evacuation,
    condition: BattlefieldCondition.ashWind,
    objective: ContractObjective.evacuation,
    battlefieldName: '핏빛 잿바람길',
    name: '악몽 · 붉은 철수령',
    subtitle: '붉은 달 아래 마지막 부상병까지 철수시켜라',
    power: 42000,
    requiredCommanderLevel: 26,
    reward: 14200,
    xp: 4700,
    color: Color(0xff73383a),
    icon: Icons.nightlight_round,
    balance: StageBalanceProfile(
      durationSeconds: 120,
      unitCount: 1250,
      initialDeployment: 150,
      activePopulationTarget: 315,
      reinforcementInterval: 2.85,
      enemyHpMultiplier: 1.78,
      enemyDamageBonus: 6,
      enemySpeedMultiplier: 1.19,
      eliteStride: 31,
      firstEventAt: 10,
      eventInterval: 11,
    ),
  ),
  BattlefieldContract(
    id: 'royal_commander_finale',
    factionId: 'grey_banner',
    battlefield: BattlefieldType.fortressRetake,
    condition: BattlefieldCondition.twilightSiege,
    objective: ContractObjective.fortressRetake,
    battlefieldName: '황혼 왕성 전면',
    name: '지휘관전 · 왕의 친정',
    subtitle: '왕의 친위대와 최고 지휘관을 격파하라',
    power: 50000,
    requiredCommanderLevel: 30,
    reward: 18000,
    xp: 5600,
    color: Color(0xff8b6939),
    icon: Icons.workspace_premium_outlined,
    balance: StageBalanceProfile(
      durationSeconds: 135,
      unitCount: 1400,
      initialDeployment: 160,
      activePopulationTarget: 340,
      reinforcementInterval: 2.65,
      enemyHpMultiplier: 1.95,
      enemyDamageBonus: 7,
      enemySpeedMultiplier: 1.21,
      eliteStride: 26,
      firstEventAt: 9,
      eventInterval: 10,
    ),
  ),
];
