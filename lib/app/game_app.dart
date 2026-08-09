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
import '../domain/enemy_catalog.dart';
import '../domain/game_data.dart';
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
part '../features/contracts/contract_screens.dart';
part '../features/equipment/equipment_screen.dart';
part '../features/codex/enemy_codex_screen.dart';
part '../features/mercenaries/mercenary_screens.dart';
part '../features/results/result_screen.dart';

const gameContent = StaticGameContentRepository();

class EclipseMercenariesApp extends StatelessWidget {
  const EclipseMercenariesApp({super.key, this.saveRepository});

  final SaveRepository? saveRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '월식 용병단',
      theme: buildGameTheme(),
      home: GameShell(saveRepository: saveRepository),
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
}

class GameShell extends StatefulWidget {
  const GameShell({super.key, this.saveRepository});

  final SaveRepository? saveRepository;

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

  AccountSave get account => _account!;
  int get gold => account.gold;
  int get crystals => account.crystals;

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
      return const Scaffold(
        body: DarkBackdrop(
          child: Center(
            child: CircularProgressIndicator(color: Color(0xffc49a54)),
          ),
        ),
      );
    }
    return Scaffold(
      body: AnimatedSwitcher(
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
                _account = account.copyWith(selectedMercenaryId: mercenary.id);
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
            onSelect: () => go(AppScene.detail),
          ),
          AppScene.detail => MercenaryDetailScreen(
            key: const ValueKey('detail'),
            onBack: () => go(AppScene.roster),
          ),
          AppScene.battle => BattleScreen(
            key: ValueKey('battle-${DateTime.now().millisecondsSinceEpoch}'),
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
        },
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
