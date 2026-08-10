import 'battle_rewards.dart';
import 'progression.dart';

class FactionSpec {
  const FactionSpec({
    required this.id,
    required this.name,
    required this.rewardStyle,
    required this.description,
  });

  final String id;
  final String name;
  final String rewardStyle;
  final String description;
}

const betaFactions = <FactionSpec>[
  FactionSpec(
    id: 'aurum_league',
    name: '아우룸 자유연맹',
    rewardStyle: '골드·보급',
    description: '북부 도시들의 방어 동맹. 독립 용병단을 적극 고용한다.',
  ),
  FactionSpec(
    id: 'ember_principality',
    name: '잿불 공국',
    rewardStyle: '마력 재료·장비',
    description: '화산 지대의 마도 국가. 철수와 호위 계약을 중시한다.',
  ),
  FactionSpec(
    id: 'grey_banner',
    name: '회색 깃발 의회',
    rewardStyle: '명예·희귀 지도',
    description: '용병 회사들의 느슨한 의회. 위험한 특수 계약을 중개한다.',
  ),
];

abstract final class FactionRules {
  static FactionSpec byId(String id) =>
      betaFactions.firstWhere((faction) => faction.id == id);

  static int reputationGain(String outcome) => switch (outcome) {
    'victory' => 12,
    'retreat' => 5,
    _ => 2,
  };

  static String rankName(int reputation) => switch (reputation) {
    >= 120 => '맹약 용병단',
    >= 60 => '신뢰받는 전우',
    >= 25 => '정식 계약자',
    _ => '낯선 칼날',
  };
}

class WarOperationSpec {
  const WarOperationSpec({
    required this.id,
    required this.factionId,
    required this.title,
    required this.stages,
  });

  final String id;
  final String factionId;
  final String title;
  final List<String> stages;
}

const betaWarOperations = <WarOperationSpec>[
  WarOperationSpec(
    id: 'operation_northwall',
    factionId: 'aurum_league',
    title: '북벽의 마지막 불씨',
    stages: ['보급로 정찰', '북문 방어', '공성군감 추격'],
  ),
  WarOperationSpec(
    id: 'operation_ashroad',
    factionId: 'ember_principality',
    title: '재의 길 철수령',
    stages: ['부상병 집결', '잿바람 철수', '후위대 구출'],
  ),
  WarOperationSpec(
    id: 'operation_greyknife',
    factionId: 'grey_banner',
    title: '회색 칼날의 증명',
    stages: ['내통자 색출', '지휘관 암살', '전술지도 회수'],
  ),
];

abstract final class WarOperationRules {
  static WarOperationSpec forFaction(String factionId) => betaWarOperations
      .firstWhere((operation) => operation.factionId == factionId);

  static int advance(int currentStage, String outcome) => outcome == 'victory'
      ? (currentStage + 1).clamp(0, 2)
      : currentStage.clamp(0, 2);

  static String stageLabel(WarOperationSpec operation, int progress) {
    final index = progress.clamp(0, operation.stages.length - 1);
    return '${index + 1}/${operation.stages.length} · ${operation.stages[index]}';
  }
}

class CampWorldState {
  const CampWorldState({
    required this.period,
    required this.weather,
    required this.headline,
    required this.detail,
    required this.woundedCount,
  });

  factory CampWorldState.resolve({
    required int campaignCycle,
    String? outcome,
    String? contractName,
    double objectiveHpRatio = 1,
  }) {
    const periods = ['황혼', '깊은 밤', '새벽'];
    const weather = ['맑음', '옅은 비', '북풍'];
    final wounded = outcome == null
        ? 0
        : outcome == 'victory'
        ? (objectiveHpRatio < .7 ? 3 : 1)
        : outcome == 'retreat'
        ? 5
        : 8;
    final headline = outcome == null
        ? '다음 고용주를 기다리는 밤'
        : outcome == 'victory'
        ? '$contractName 승전대 귀환'
        : outcome == 'retreat'
        ? '$contractName 철수대 귀환'
        : '$contractName 패잔병 수습 중';
    return CampWorldState(
      period: periods[campaignCycle % periods.length],
      weather: weather[campaignCycle % weather.length],
      headline: headline,
      detail: wounded == 0
          ? '천막마다 다음 계약을 준비하고 있습니다.'
          : '의무소 부상자 $wounded명 · 보급품과 장비를 점검하십시오.',
      woundedCount: wounded,
    );
  }

  final String period;
  final String weather;
  final String headline;
  final String detail;
  final int woundedCount;
}

enum GearSlot { armor, accessory, tactical }

class GearSpec {
  const GearSpec({
    required this.id,
    required this.name,
    required this.slot,
    required this.grade,
    required this.description,
    this.hpPercent = 0,
    this.damagePercent = 0,
    this.speedPercent = 0,
    this.criticalChance = 0,
    this.dashCooldownPercent = 0,
    this.tacticalCooldownPercent = 0,
  });

  final String id;
  final String name;
  final GearSlot slot;
  final String grade;
  final String description;
  final int hpPercent;
  final int damagePercent;
  final int speedPercent;
  final int criticalChance;
  final int dashCooldownPercent;
  final int tacticalCooldownPercent;
}

class GearCombatBonus {
  const GearCombatBonus({
    required this.hpMultiplier,
    required this.damageMultiplier,
    required this.speedMultiplier,
    required this.criticalChance,
    required this.dashCooldownMultiplier,
    required this.tacticalCooldownMultiplier,
  });

  const GearCombatBonus.none()
    : hpMultiplier = 1,
      damageMultiplier = 1,
      speedMultiplier = 1,
      criticalChance = 0,
      dashCooldownMultiplier = 1,
      tacticalCooldownMultiplier = 1;

  final double hpMultiplier;
  final double damageMultiplier;
  final double speedMultiplier;
  final int criticalChance;
  final double dashCooldownMultiplier;
  final double tacticalCooldownMultiplier;
}

const betaGearCatalog = <GearSpec>[
  GearSpec(
    id: 'black_iron_coat',
    name: '흑철 사슬 외투',
    slot: GearSlot.armor,
    grade: '희귀',
    description: '전선 돌파에 맞춘 중량 외투. 체력과 공격을 함께 보강한다.',
    hpPercent: 14,
    damagePercent: 4,
  ),
  GearSpec(
    id: 'moonweave_guard',
    name: '월광천 전투복',
    slot: GearSlot.armor,
    grade: '영웅',
    description: '가벼운 월광천이 체력과 기동성을 유지한다.',
    hpPercent: 8,
    speedPercent: 8,
  ),
  GearSpec(
    id: 'veteran_plate',
    name: '노병의 흉갑',
    slot: GearSlot.armor,
    grade: '전설',
    description: '살아 돌아온 용병들의 흉갑. 최대 체력을 크게 높인다.',
    hpPercent: 22,
    speedPercent: -4,
  ),
  GearSpec(
    id: 'nightfang_charm',
    name: '밤송곳니 부적',
    slot: GearSlot.accessory,
    grade: '영웅',
    description: '어둠 속 급소를 드러내 치명타와 공격력을 높인다.',
    damagePercent: 6,
    criticalChance: 7,
  ),
  GearSpec(
    id: 'windrunner_ring',
    name: '질풍 주자의 반지',
    slot: GearSlot.accessory,
    grade: '희귀',
    description: '발걸음과 대시 회복을 빠르게 만든다.',
    speedPercent: 10,
    dashCooldownPercent: 14,
  ),
  GearSpec(
    id: 'commander_medal',
    name: '전선 지휘 훈장',
    slot: GearSlot.accessory,
    grade: '전설',
    description: '전술 명령과 공격 리듬을 동시에 강화한다.',
    damagePercent: 5,
    tacticalCooldownPercent: 18,
  ),
  GearSpec(
    id: 'smoke_charge',
    name: '연막 화약통',
    slot: GearSlot.tactical,
    grade: '희귀',
    description: '대시와 전술 명령 재사용 시간을 함께 단축한다.',
    dashCooldownPercent: 10,
    tacticalCooldownPercent: 10,
  ),
  GearSpec(
    id: 'officer_map_case',
    name: '장교 지도함',
    slot: GearSlot.tactical,
    grade: '영웅',
    description: '전선 정보로 특별 행동의 순환을 크게 개선한다.',
    tacticalCooldownPercent: 22,
  ),
  GearSpec(
    id: 'moonstep_hook',
    name: '월보 갈고리',
    slot: GearSlot.tactical,
    grade: '전설',
    description: '기동 전술용 갈고리. 공격과 대시를 강화한다.',
    damagePercent: 4,
    dashCooldownPercent: 20,
  ),
];

abstract final class GearRules {
  static GearSpec byId(String id) =>
      betaGearCatalog.firstWhere((gear) => gear.id == id);

  static GearCombatBonus combatBonus(Iterable<String> gearIds) {
    final gear = gearIds.map(byId);
    var hp = 0;
    var damage = 0;
    var speed = 0;
    var critical = 0;
    var dash = 0;
    var tactical = 0;
    for (final item in gear) {
      hp += item.hpPercent;
      damage += item.damagePercent;
      speed += item.speedPercent;
      critical += item.criticalChance;
      dash += item.dashCooldownPercent;
      tactical += item.tacticalCooldownPercent;
    }
    return GearCombatBonus(
      hpMultiplier: 1 + hp / 100,
      damageMultiplier: 1 + damage / 100,
      speedMultiplier: 1 + speed / 100,
      criticalChance: critical,
      dashCooldownMultiplier: 1 - dash.clamp(0, 50) / 100,
      tacticalCooldownMultiplier: 1 - tactical.clamp(0, 50) / 100,
    );
  }

  static String key(String mercenaryId, GearSlot slot) =>
      '$mercenaryId:${slot.name}';
}

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
