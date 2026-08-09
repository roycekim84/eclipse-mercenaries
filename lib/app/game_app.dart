import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/content/game_content_repository.dart';
import '../core/content/game_visuals.dart';
import '../core/persistence/save_repository.dart';
import '../core/theme/game_theme.dart';
import '../domain/battle_models.dart';
import '../domain/game_data.dart';
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
part '../features/mercenaries/mercenary_screens.dart';
part '../features/results/result_screen.dart';

const gameContent = StaticGameContentRepository();

class EclipseMercenariesApp extends StatelessWidget {
  const EclipseMercenariesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '월식 용병단',
      theme: buildGameTheme(),
      home: const GameShell(),
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
}

class GameShell extends StatefulWidget {
  const GameShell({super.key});

  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> {
  final SaveRepository _saveRepository = InMemorySaveRepository();
  AppScene scene = AppScene.camp;
  BattlefieldContract selected = contracts.first;
  late AccountSave account;
  late MercenarySpec selectedMercenary;
  late WeaponSpec equippedWeapon;
  AppScene equipmentReturn = AppScene.camp;
  BattleReport? report;

  int get gold => account.gold;
  int get crystals => account.crystals;

  @override
  void initState() {
    super.initState();
    account = _saveRepository.load();
    selectedMercenary = gameContent.mercenaryById(account.selectedMercenaryId);
    equippedWeapon = gameContent.weaponById(
      account.equippedWeaponByMercenary[selectedMercenary.id] ??
          selectedMercenary.signatureWeaponId,
    );
  }

  void go(AppScene next) => setState(() => scene = next);

  void openEquipment(AppScene returnTo) {
    setState(() {
      equipmentReturn = returnTo;
      scene = AppScene.equipment;
    });
  }

  void finishBattle(BattleReport value) {
    setState(() {
      report = value;
      account = account.copyWith(gold: account.gold + value.gold);
      _saveRepository.save(account);
      scene = AppScene.result;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            onSelect: (mercenary) {
              setState(() {
                selectedMercenary = mercenary;
                equippedWeapon = gameContent.weaponById(
                  account.equippedWeaponByMercenary[mercenary.id] ??
                      mercenary.signatureWeaponId,
                );
                account = account.copyWith(selectedMercenaryId: mercenary.id);
                _saveRepository.save(account);
              });
            },
            onBack: () => go(AppScene.contracts),
            onEquipment: () => openEquipment(AppScene.mercenarySelect),
            onDeploy: () => go(AppScene.battle),
          ),
          AppScene.equipment => EquipmentScreen(
            key: const ValueKey('equipment'),
            mercenary: selectedMercenary,
            equipped: equippedWeapon,
            onEquip: (weapon) {
              setState(() {
                equippedWeapon = weapon;
                account = account.copyWith(
                  equippedWeaponByMercenary: {
                    ...account.equippedWeaponByMercenary,
                    selectedMercenary.id: weapon.id,
                  },
                );
                _saveRepository.save(account);
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
            onExit: () => go(AppScene.camp),
            onVictory: finishBattle,
          ),
          AppScene.result => ResultScreen(
            key: const ValueKey('result'),
            report: report!,
            onCamp: () => go(AppScene.camp),
            onReplay: () => go(AppScene.battle),
          ),
        },
      ),
    );
  }
}

class BattlefieldContract {
  const BattlefieldContract({
    required this.name,
    required this.subtitle,
    required this.power,
    required this.reward,
    required this.color,
    required this.icon,
  });
  final String name;
  final String subtitle;
  final int power;
  final int reward;
  final Color color;
  final IconData icon;
}

const contracts = [
  BattlefieldContract(
    name: '성문 방어전',
    subtitle: '새벽까지 북문을 사수하라',
    power: 18000,
    reward: 3000,
    color: Color(0xff334d6f),
    icon: Icons.shield_outlined,
  ),
  BattlefieldContract(
    name: '철수전',
    subtitle: '부상병과 보급대를 호위하라',
    power: 22000,
    reward: 4500,
    color: Color(0xff8c6031),
    icon: Icons.directions_run,
  ),
  BattlefieldContract(
    name: '적 지휘관 암살',
    subtitle: '혼란 속에서 지휘관을 제거하라',
    power: 25000,
    reward: 5000,
    color: Color(0xff733b3e),
    icon: Icons.gps_fixed,
  ),
];
