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

enum MissionCategory { prologue, growth, war, faction, mastery }

enum MissionRequirement {
  immediate,
  inventoryTotal,
  weaponLevel,
  commanderLevel,
  ownedMercenaries,
  factionReputation,
  operationProgress,
}

class MissionSpec {
  const MissionSpec({
    required this.id,
    required this.level,
    required this.title,
    required this.description,
    required this.rewardLabel,
    required this.category,
    required this.requirement,
    required this.target,
    this.prerequisiteId,
    this.inventoryReward = const {},
    this.goldReward = 0,
  });

  final String id;
  final int level;
  final String title;
  final String description;
  final String rewardLabel;
  final MissionCategory category;
  final MissionRequirement requirement;
  final int target;
  final String? prerequisiteId;
  final Map<String, int> inventoryReward;
  final int goldReward;
}

const releaseMissions = <MissionSpec>[
  MissionSpec(
    id: 'camp_arrival',
    level: 1,
    title: '첫 보급품 확인',
    description: '용병단 캠프의 보급 담당관과 대화한다.',
    rewardLabel: '야전 식량 ×2 · 전장 고철 ×3',
    category: MissionCategory.prologue,
    requirement: MissionRequirement.immediate,
    target: 1,
    inventoryReward: {'field_ration': 2, 'war_scrap': 3},
  ),
  MissionSpec(
    id: 'field_scavenger',
    level: 2,
    title: '전장의 몫',
    description: '전리품을 합계 3개 이상 확보한다.',
    rewardLabel: '1,200 골드',
    category: MissionCategory.prologue,
    requirement: MissionRequirement.inventoryTotal,
    target: 3,
    prerequisiteId: 'camp_arrival',
    goldReward: 1200,
  ),
  MissionSpec(
    id: 'tempered_edge',
    level: 3,
    title: '단련된 칼날',
    description: '무기 하나를 영구 레벨 2 이상으로 강화한다.',
    rewardLabel: '피 묻은 계약 인장 ×2',
    category: MissionCategory.prologue,
    requirement: MissionRequirement.weaponLevel,
    target: 2,
    prerequisiteId: 'field_scavenger',
    inventoryReward: {'contract_seal': 2},
  ),
  MissionSpec(
    id: 'commander_3',
    level: 4,
    title: '단장의 첫 명성',
    description: '단장 레벨 3을 달성한다.',
    rewardLabel: '1,500 골드',
    category: MissionCategory.growth,
    requirement: MissionRequirement.commanderLevel,
    target: 3,
    prerequisiteId: 'tempered_edge',
    goldReward: 1500,
  ),
  MissionSpec(
    id: 'weapon_3',
    level: 5,
    title: '숙련된 병기',
    description: '무기 하나를 영구 레벨 3으로 강화한다.',
    rewardLabel: '단련된 흑철 ×2',
    category: MissionCategory.growth,
    requirement: MissionRequirement.weaponLevel,
    target: 3,
    prerequisiteId: 'commander_3',
    inventoryReward: {'tempered_iron': 2},
  ),
  MissionSpec(
    id: 'roster_2',
    level: 6,
    title: '두 자루의 검',
    description: '용병 2명을 계약한다.',
    rewardLabel: '고급 용병 계약서 ×1',
    category: MissionCategory.growth,
    requirement: MissionRequirement.ownedMercenaries,
    target: 2,
    prerequisiteId: 'weapon_3',
    inventoryReward: {'contract_ticket': 1},
  ),
  MissionSpec(
    id: 'commander_6',
    level: 7,
    title: '이름을 알리다',
    description: '단장 레벨 6을 달성한다.',
    rewardLabel: '2,500 골드',
    category: MissionCategory.growth,
    requirement: MissionRequirement.commanderLevel,
    target: 6,
    prerequisiteId: 'roster_2',
    goldReward: 2500,
  ),
  MissionSpec(
    id: 'weapon_5',
    level: 8,
    title: '병기의 진가',
    description: '무기 하나를 영구 레벨 5로 강화한다.',
    rewardLabel: '전장 고철 ×6',
    category: MissionCategory.growth,
    requirement: MissionRequirement.weaponLevel,
    target: 5,
    prerequisiteId: 'commander_6',
    inventoryReward: {'war_scrap': 6},
  ),
  MissionSpec(
    id: 'roster_3',
    level: 9,
    title: '작은 용병단',
    description: '용병 3명을 계약한다.',
    rewardLabel: '크리스탈 대신 계약서 ×2',
    category: MissionCategory.growth,
    requirement: MissionRequirement.ownedMercenaries,
    target: 3,
    prerequisiteId: 'weapon_5',
    inventoryReward: {'contract_ticket': 2},
  ),
  MissionSpec(
    id: 'operation_1',
    level: 10,
    title: '첫 전쟁 기록',
    description: '세력 작전을 1단계 이상 진행한다.',
    rewardLabel: '피 묻은 계약 인장 ×3',
    category: MissionCategory.war,
    requirement: MissionRequirement.operationProgress,
    target: 1,
    prerequisiteId: 'roster_3',
    inventoryReward: {'contract_seal': 3},
  ),
  MissionSpec(
    id: 'reputation_20',
    level: 11,
    title: '신뢰의 대가',
    description: '한 세력의 평판 20을 달성한다.',
    rewardLabel: '3,000 골드',
    category: MissionCategory.faction,
    requirement: MissionRequirement.factionReputation,
    target: 20,
    prerequisiteId: 'operation_1',
    goldReward: 3000,
  ),
  MissionSpec(
    id: 'commander_10',
    level: 12,
    title: '정식 계약자',
    description: '단장 레벨 10을 달성한다.',
    rewardLabel: '장교 지도함 ×1',
    category: MissionCategory.growth,
    requirement: MissionRequirement.commanderLevel,
    target: 10,
    prerequisiteId: 'reputation_20',
    inventoryReward: {'officer_map': 1},
  ),
  MissionSpec(
    id: 'weapon_8',
    level: 13,
    title: '전장의 애병',
    description: '무기 하나를 영구 레벨 8로 강화한다.',
    rewardLabel: '단련된 흑철 ×4',
    category: MissionCategory.mastery,
    requirement: MissionRequirement.weaponLevel,
    target: 8,
    prerequisiteId: 'commander_10',
    inventoryReward: {'tempered_iron': 4},
  ),
  MissionSpec(
    id: 'roster_4',
    level: 14,
    title: '네 개의 깃발',
    description: '용병 4명을 계약한다.',
    rewardLabel: '고급 용병 계약서 ×2',
    category: MissionCategory.growth,
    requirement: MissionRequirement.ownedMercenaries,
    target: 4,
    prerequisiteId: 'weapon_8',
    inventoryReward: {'contract_ticket': 2},
  ),
  MissionSpec(
    id: 'operation_2',
    level: 15,
    title: '흔들리는 전선',
    description: '세력 작전을 합계 2단계 진행한다.',
    rewardLabel: '노병의 증표 ×2',
    category: MissionCategory.war,
    requirement: MissionRequirement.operationProgress,
    target: 2,
    prerequisiteId: 'roster_4',
    inventoryReward: {'veteran_badge': 2},
  ),
  MissionSpec(
    id: 'reputation_40',
    level: 16,
    title: '고용주의 신뢰',
    description: '한 세력의 평판 40을 달성한다.',
    rewardLabel: '4,500 골드',
    category: MissionCategory.faction,
    requirement: MissionRequirement.factionReputation,
    target: 40,
    prerequisiteId: 'operation_2',
    goldReward: 4500,
  ),
  MissionSpec(
    id: 'commander_15',
    level: 17,
    title: '전쟁 중개인',
    description: '단장 레벨 15를 달성한다.',
    rewardLabel: '왕실 칙서 ×1',
    category: MissionCategory.growth,
    requirement: MissionRequirement.commanderLevel,
    target: 15,
    prerequisiteId: 'reputation_40',
    inventoryReward: {'royal_writ': 1},
  ),
  MissionSpec(
    id: 'weapon_12',
    level: 18,
    title: '장인의 검증',
    description: '무기 하나를 영구 레벨 12로 강화한다.',
    rewardLabel: '공성 핵 ×1',
    category: MissionCategory.mastery,
    requirement: MissionRequirement.weaponLevel,
    target: 12,
    prerequisiteId: 'commander_15',
    inventoryReward: {'siege_core': 1},
  ),
  MissionSpec(
    id: 'roster_6',
    level: 19,
    title: '전열 완성',
    description: '용병 6명을 계약한다.',
    rewardLabel: '고급 용병 계약서 ×3',
    category: MissionCategory.growth,
    requirement: MissionRequirement.ownedMercenaries,
    target: 6,
    prerequisiteId: 'weapon_12',
    inventoryReward: {'contract_ticket': 3},
  ),
  MissionSpec(
    id: 'operation_4',
    level: 20,
    title: '대륙의 전쟁',
    description: '세력 작전을 합계 4단계 진행한다.',
    rewardLabel: '7,000 골드',
    category: MissionCategory.war,
    requirement: MissionRequirement.operationProgress,
    target: 4,
    prerequisiteId: 'roster_6',
    goldReward: 7000,
  ),
  MissionSpec(
    id: 'reputation_80',
    level: 21,
    title: '맹약의 칼날',
    description: '한 세력의 평판 80을 달성한다.',
    rewardLabel: '전쟁 영웅 계약서 ×1',
    category: MissionCategory.faction,
    requirement: MissionRequirement.factionReputation,
    target: 80,
    prerequisiteId: 'operation_4',
    inventoryReward: {'war_hero_contract': 1},
  ),
  MissionSpec(
    id: 'commander_20',
    level: 22,
    title: '전장의 이름',
    description: '단장 레벨 20을 달성한다.',
    rewardLabel: '10,000 골드',
    category: MissionCategory.mastery,
    requirement: MissionRequirement.commanderLevel,
    target: 20,
    prerequisiteId: 'reputation_80',
    goldReward: 10000,
  ),
  MissionSpec(
    id: 'weapon_15',
    level: 23,
    title: '전설의 병기',
    description: '무기 하나를 영구 레벨 15로 강화한다.',
    rewardLabel: '월광천 ×5',
    category: MissionCategory.mastery,
    requirement: MissionRequirement.weaponLevel,
    target: 15,
    prerequisiteId: 'commander_20',
    inventoryReward: {'mooncloth': 5},
  ),
  MissionSpec(
    id: 'roster_8',
    level: 24,
    title: '월식 용병단',
    description: '용병 8명을 모두 계약한다.',
    rewardLabel: '왕실 칙서 ×2 · 15,000 골드',
    category: MissionCategory.mastery,
    requirement: MissionRequirement.ownedMercenaries,
    target: 8,
    prerequisiteId: 'weapon_15',
    inventoryReward: {'royal_writ': 2},
    goldReward: 15000,
  ),
];

@Deprecated('Use releaseMissions')
const alphaMissions = releaseMissions;

abstract final class CampMetaRules {
  static const trainingGoldCost = 1000;
  static const trainingRationCost = 1;
  static const trainingXp = 900;
  static const forgeGoldCost = 700;
  static const forgeScrapCost = 2;
  static const forgeXp = 500;

  static bool missionUnlocked(String id, Set<String> claimedMissionIds) {
    final mission = releaseMissions.firstWhere((item) => item.id == id);
    return mission.prerequisiteId == null ||
        claimedMissionIds.contains(mission.prerequisiteId);
  }

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

  static int missionProgress(
    MissionSpec mission, {
    required Map<String, int> inventory,
    required Map<String, WeaponProgress> weaponProgress,
    int commanderLevel = 1,
    int ownedMercenaries = 1,
    Map<String, int> factionReputation = const {},
    Map<String, int> operationProgress = const {},
  }) => switch (mission.requirement) {
    MissionRequirement.immediate => 1,
    MissionRequirement.inventoryTotal => inventory.values.fold<int>(
      0,
      (sum, value) => sum + value,
    ),
    MissionRequirement.weaponLevel => weaponProgress.values.fold<int>(
      0,
      (best, value) => value.level > best ? value.level : best,
    ),
    MissionRequirement.commanderLevel => commanderLevel,
    MissionRequirement.ownedMercenaries => ownedMercenaries,
    MissionRequirement.factionReputation => factionReputation.values.fold<int>(
      0,
      (best, value) => value > best ? value : best,
    ),
    MissionRequirement.operationProgress => operationProgress.values.fold<int>(
      0,
      (sum, value) => sum + value,
    ),
  };

  static bool missionComplete(
    String id, {
    required Map<String, int> inventory,
    required Map<String, WeaponProgress> weaponProgress,
    int commanderLevel = 1,
    int ownedMercenaries = 1,
    Map<String, int> factionReputation = const {},
    Map<String, int> operationProgress = const {},
  }) {
    final mission = releaseMissions.firstWhere((item) => item.id == id);
    return missionProgress(
          mission,
          inventory: inventory,
          weaponProgress: weaponProgress,
          commanderLevel: commanderLevel,
          ownedMercenaries: ownedMercenaries,
          factionReputation: factionReputation,
          operationProgress: operationProgress,
        ) >=
        mission.target;
  }

  static Map<String, int> missionInventoryReward(String id) =>
      releaseMissions.firstWhere((item) => item.id == id).inventoryReward;

  static int missionGoldReward(String id) =>
      releaseMissions.firstWhere((item) => item.id == id).goldReward;
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
