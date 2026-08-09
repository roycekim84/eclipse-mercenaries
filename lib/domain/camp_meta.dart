import 'battle_rewards.dart';
import 'progression.dart';

class MissionSpec {
  const MissionSpec({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardLabel,
  });

  final String id;
  final String title;
  final String description;
  final String rewardLabel;
}

const alphaMissions = <MissionSpec>[
  MissionSpec(
    id: 'camp_arrival',
    title: '첫 보급품 확인',
    description: '용병단 캠프의 보급 담당관과 대화한다.',
    rewardLabel: '야전 식량 ×2 · 전장 고철 ×3',
  ),
  MissionSpec(
    id: 'field_scavenger',
    title: '전장의 몫',
    description: '전리품을 합계 3개 이상 확보한다.',
    rewardLabel: '1,200 골드',
  ),
  MissionSpec(
    id: 'tempered_edge',
    title: '단련된 칼날',
    description: '무기 하나를 영구 레벨 2 이상으로 강화한다.',
    rewardLabel: '피 묻은 계약 인장 ×2',
  ),
];

abstract final class CampMetaRules {
  static const trainingGoldCost = 1000;
  static const trainingRationCost = 1;
  static const trainingXp = 900;
  static const forgeGoldCost = 700;
  static const forgeScrapCost = 2;
  static const forgeXp = 500;

  static bool canTrain({
    required int gold,
    required int rations,
    required MercenaryProgress progress,
  }) =>
      progress.level < progress.levelCap &&
      gold >= trainingGoldCost &&
      rations >= trainingRationCost;

  static bool canForge({required int gold, required int scrap}) =>
      gold >= forgeGoldCost && scrap >= forgeScrapCost;

  static bool missionComplete(
    String id, {
    required Map<String, int> inventory,
    required Map<String, WeaponProgress> weaponProgress,
  }) => switch (id) {
    'camp_arrival' => true,
    'field_scavenger' =>
      inventory.values.fold<int>(0, (sum, value) => sum + value) >= 3,
    'tempered_edge' => weaponProgress.values.any((value) => value.level >= 2),
    _ => false,
  };

  static Map<String, int> missionInventoryReward(String id) => switch (id) {
    'camp_arrival' => const {'field_ration': 2, 'war_scrap': 3},
    'tempered_edge' => const {'contract_seal': 2},
    _ => const {},
  };

  static int missionGoldReward(String id) => id == 'field_scavenger' ? 1200 : 0;
}

const lootAcquisitionSources = <String, String>{
  'war_scrap': '모든 전장 · 일반 전리품',
  'field_ration': '모든 전장 · 보급마차 사건',
  'tempered_iron': '대장간 제작 · 전장 전리품',
  'mooncloth': '마법병 처치 · 희귀 사건',
  'officer_map': '전장 목표 · 지휘관 처치',
  'contract_seal': '임무 보상 · 전쟁 계약',
  'veteran_badge': '정예 처치 · 고난도 계약',
  'red_moon_shard': '전설 사건 「붉은 달」',
  'royal_writ': '극희귀 사건 「왕의 친정」',
  'nameless_spur': '이름 없는 기사 처치',
  'blood_ember': '잿불 교단 정예 처치',
  'marshal_seal': '공성군감 처치',
  'hunter_insignia': '추격대장 처치',
};

LootItemSpec? lootItemById(String id) {
  for (final item in alphaLootTable) {
    if (item.id == id) return item;
  }
  return null;
}
