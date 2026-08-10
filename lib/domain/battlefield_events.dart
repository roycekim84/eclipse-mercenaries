import 'dart:math' as math;

enum BattlefieldEventRarity { common, special, rare, legendary }

enum BattlefieldEventEffect {
  reinforcements,
  supplyWagon,
  eliteKnight,
  woundedCommander,
  mercenaryIntervention,
  monsterIncursion,
  redMoon,
  royalPresence,
}

class BattlefieldEventChoiceSpec {
  const BattlefieldEventChoiceSpec({
    required this.id,
    required this.label,
    required this.description,
    required this.resultText,
    this.retreat = false,
  });

  final String id;
  final String label;
  final String description;
  final String resultText;
  final bool retreat;
}

class BattlefieldEventSpec {
  const BattlefieldEventSpec({
    required this.id,
    required this.title,
    required this.rarity,
    required this.effect,
    required this.description,
    required this.weight,
    required this.minProgress,
    required this.choices,
  });

  final String id;
  final String title;
  final BattlefieldEventRarity rarity;
  final BattlefieldEventEffect effect;
  final String description;
  final int weight;
  final double minProgress;
  final List<BattlefieldEventChoiceSpec> choices;
}

class BattlefieldEventRecord {
  const BattlefieldEventRecord({
    required this.eventId,
    required this.title,
    required this.choiceId,
    required this.choiceLabel,
    required this.resultText,
    required this.rarity,
  });

  final String eventId;
  final String title;
  final String choiceId;
  final String choiceLabel;
  final String resultText;
  final BattlefieldEventRarity rarity;
}

const alphaBattlefieldEvents = <BattlefieldEventSpec>[
  BattlefieldEventSpec(
    id: 'enemy_reinforcements',
    title: '적군 증원',
    rarity: BattlefieldEventRarity.common,
    effect: BattlefieldEventEffect.reinforcements,
    description: '북동쪽 능선에서 적 증원부대가 접근하고 있습니다.',
    weight: 34,
    minProgress: .18,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'stand_and_fight',
        label: '전투 준비',
        description: '증원군과 교전하고 추가 전과 보상을 노립니다.',
        resultText: '적 증원군을 정면으로 맞이했습니다.',
      ),
      BattlefieldEventChoiceSpec(
        id: 'tactical_retreat',
        label: '전술적 후퇴',
        description: '현재 전리품 일부를 보존하고 전장에서 이탈합니다.',
        resultText: '증원군 도착 전에 전술적으로 철수했습니다.',
        retreat: true,
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'supply_wagon',
    title: '보급마차 발견',
    rarity: BattlefieldEventRarity.special,
    effect: BattlefieldEventEffect.supplyWagon,
    description: '주인 없는 보급마차가 교전선 옆에 멈춰 있습니다.',
    weight: 24,
    minProgress: .22,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'secure_supplies',
        label: '보급품 확보',
        description: '위험을 감수하고 골드와 전투 물자를 회수합니다.',
        resultText: '보급품과 전쟁 자금을 확보했습니다.',
      ),
      BattlefieldEventChoiceSpec(
        id: 'hold_objective',
        label: '목표 우선',
        description: '행렬과 방어선을 이탈하지 않습니다.',
        resultText: '보급마차를 포기하고 전장 목표를 유지했습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'nameless_knight',
    title: '정예기사 등장',
    rarity: BattlefieldEventRarity.rare,
    effect: BattlefieldEventEffect.eliteKnight,
    description: '휘장을 버린 이름 없는 기사가 결투를 청합니다.',
    weight: 15,
    minProgress: .28,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'accept_duel',
        label: '결투 수락',
        description: '희귀 전리품을 지닌 정예기사를 전장에 호출합니다.',
        resultText: '이름 없는 기사의 결투를 받아들였습니다.',
      ),
      BattlefieldEventChoiceSpec(
        id: 'decline_duel',
        label: '교전 회피',
        description: '목표를 우선하며 결투를 피합니다.',
        resultText: '기사와 거리를 두고 임무를 계속했습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'wounded_commander',
    title: '아군 지휘관 부상',
    rarity: BattlefieldEventRarity.special,
    effect: BattlefieldEventEffect.woundedCommander,
    description: '아군 지휘관이 적진에 고립되어 지원을 요청합니다.',
    weight: 20,
    minProgress: .3,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'rescue_commander',
        label: '구조 작전',
        description: '지휘관을 회복시키고 아군 전열을 강화합니다.',
        resultText: '지휘관을 구출해 전선으로 복귀시켰습니다.',
      ),
      BattlefieldEventChoiceSpec(
        id: 'maintain_mission',
        label: '임무 유지',
        description: '계약 목표를 위해 구조 요청을 거절합니다.',
        resultText: '냉정하게 계약 목표를 우선했습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'independent_mercenaries',
    title: '독립 용병단 난입',
    rarity: BattlefieldEventRarity.rare,
    effect: BattlefieldEventEffect.mercenaryIntervention,
    description: '회색 자유단이 더 높은 보수를 제안하라고 요구합니다.',
    weight: 14,
    minProgress: .34,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'hire_company',
        label: '매수한다',
        description: '전쟁 보수 일부를 지급하고 아군 증원을 얻습니다.',
        resultText: '회색 자유단이 임시 아군으로 참전했습니다.',
      ),
      BattlefieldEventChoiceSpec(
        id: 'fight_company',
        label: '거절하고 교전',
        description: '추가 적을 상대하고 전리품을 확보합니다.',
        resultText: '회색 자유단과 적대 계약을 맺었습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'monster_incursion',
    title: '마물 난입',
    rarity: BattlefieldEventRarity.special,
    effect: BattlefieldEventEffect.monsterIncursion,
    description: '피 냄새를 맡은 마물 무리가 교전선으로 몰려옵니다.',
    weight: 18,
    minProgress: .38,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'hunt_monsters',
        label: '마물 사냥',
        description: '위험한 무리를 끌어내 추가 보상을 노립니다.',
        resultText: '마물 무리를 전장 중앙으로 유인했습니다.',
      ),
      BattlefieldEventChoiceSpec(
        id: 'tighten_lines',
        label: '전열 유지',
        description: '방어 진형을 강화하고 난입을 견딥니다.',
        resultText: '전열을 좁혀 마물의 접근을 막았습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'red_moon',
    title: '붉은 달',
    rarity: BattlefieldEventRarity.legendary,
    effect: BattlefieldEventEffect.redMoon,
    description: '붉은 달빛이 전장을 덮어 모든 살의를 증폭시킵니다.',
    weight: 6,
    minProgress: .45,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'embrace_red_moon',
        label: '붉은 달을 받아들인다',
        description: '적이 강화되지만 경험치와 전리품 보상이 크게 증가합니다.',
        resultText: '붉은 달 아래에서 더 큰 위험과 보상을 선택했습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'royal_presence',
    title: '왕의 친정',
    rarity: BattlefieldEventRarity.legendary,
    effect: BattlefieldEventEffect.royalPresence,
    description: '적국의 최고 지휘관이 친위대와 함께 전장에 나타났습니다.',
    weight: 3,
    minProgress: .58,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'challenge_royal_guard',
        label: '친위대에 도전',
        description: '최고 지휘관과 정예병을 호출하고 전설 보상을 노립니다.',
        resultText: '최고 지휘관의 친위대와 결전을 시작했습니다.',
      ),
      BattlefieldEventChoiceSpec(
        id: 'royal_retreat',
        label: '명예로운 후퇴',
        description: '현재 보상의 일부를 보존하고 즉시 철수합니다.',
        resultText: '최고 지휘관과의 무모한 결전을 피했습니다.',
        retreat: true,
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'scattered_arrows',
    title: '낙오한 화살통',
    rarity: BattlefieldEventRarity.common,
    effect: BattlefieldEventEffect.supplyWagon,
    description: '후퇴한 궁병대가 화살과 식량을 남겼습니다.',
    weight: 30,
    minProgress: .12,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'salvage_arrows',
        label: '회수',
        description: '짧게 전열을 이탈해 물자를 챙깁니다.',
        resultText: '쓸 만한 군수품을 회수했습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'mudslide',
    title: '진창 붕괴',
    rarity: BattlefieldEventRarity.common,
    effect: BattlefieldEventEffect.reinforcements,
    description: '폭격으로 무너진 진창이 진군로를 막았습니다.',
    weight: 28,
    minProgress: .16,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'clear_mud',
        label: '길을 연다',
        description: '아군과 함께 진창을 정리합니다.',
        resultText: '전선 이동로를 다시 열었습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'lost_standard',
    title: '잃어버린 군기',
    rarity: BattlefieldEventRarity.common,
    effect: BattlefieldEventEffect.woundedCommander,
    description: '쓰러진 기수 곁에 아군 군기가 남아 있습니다.',
    weight: 27,
    minProgress: .18,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'raise_standard',
        label: '군기 회수',
        description: '군기를 높이 들어 전열을 독려합니다.',
        resultText: '흩어진 아군이 다시 집결했습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'field_medic',
    title: '야전 의무병',
    rarity: BattlefieldEventRarity.common,
    effect: BattlefieldEventEffect.woundedCommander,
    description: '의무병이 짧은 응급 처치를 제안합니다.',
    weight: 29,
    minProgress: .2,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'accept_aid',
        label: '치료 허용',
        description: '지휘관과 목표 부대를 치료합니다.',
        resultText: '부상자들이 다시 전열에 섰습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'broken_bridge',
    title: '부서진 부교',
    rarity: BattlefieldEventRarity.common,
    effect: BattlefieldEventEffect.reinforcements,
    description: '보급로의 임시 다리가 반쯤 무너졌습니다.',
    weight: 25,
    minProgress: .22,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'repair_bridge',
        label: '응급 보수',
        description: '전장 고철로 통행로를 보강합니다.',
        resultText: '보급대가 다시 움직이기 시작했습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'deserters',
    title: '적 탈영병',
    rarity: BattlefieldEventRarity.common,
    effect: BattlefieldEventEffect.mercenaryIntervention,
    description: '적 탈영병들이 정보를 대가로 통행을 요구합니다.',
    weight: 24,
    minProgress: .24,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'buy_intel',
        label: '정보 매입',
        description: '소액의 전쟁 자금으로 진형 정보를 삽니다.',
        resultText: '적 증원 경로를 미리 파악했습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'fog_bank',
    title: '전장 안개',
    rarity: BattlefieldEventRarity.common,
    effect: BattlefieldEventEffect.monsterIncursion,
    description: '짙은 안개가 양군의 시야를 동시에 삼켰습니다.',
    weight: 26,
    minProgress: .26,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'hold_in_fog',
        label: '대형 유지',
        description: '표식을 따라 천천히 전진합니다.',
        resultText: '매복 없이 안개 지대를 통과했습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'powder_cache',
    title: '화약 저장고',
    rarity: BattlefieldEventRarity.common,
    effect: BattlefieldEventEffect.supplyWagon,
    description: '버려진 공성 화약통이 참호에 남아 있습니다.',
    weight: 23,
    minProgress: .28,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'detonate_cache',
        label: '기폭',
        description: '적 접근에 맞춰 화약을 폭발시킵니다.',
        resultText: '폭발로 적 선봉을 흔들었습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'fallen_courier',
    title: '쓰러진 전령',
    rarity: BattlefieldEventRarity.common,
    effect: BattlefieldEventEffect.supplyWagon,
    description: '봉인된 작전 문서를 지닌 전령을 발견했습니다.',
    weight: 22,
    minProgress: .3,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'recover_orders',
        label: '명령서 회수',
        description: '문서를 계약 장부에 보관합니다.',
        resultText: '고용주가 원하는 전술 정보를 확보했습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'wyvern_shadow',
    title: '와이번의 그림자',
    rarity: BattlefieldEventRarity.special,
    effect: BattlefieldEventEffect.monsterIncursion,
    description: '날개 달린 마물이 전열 위를 선회합니다.',
    weight: 16,
    minProgress: .32,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'bait_wyvern',
        label: '유인 사격',
        description: '와이번을 적 진형으로 유도합니다.',
        resultText: '와이번이 적 후열을 덮쳤습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'cursed_well',
    title: '저주받은 우물',
    rarity: BattlefieldEventRarity.special,
    effect: BattlefieldEventEffect.redMoon,
    description: '검붉은 마력이 솟는 오래된 우물을 발견했습니다.',
    weight: 15,
    minProgress: .34,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'seal_well',
        label: '봉인',
        description: '마력을 억누르고 계약 보상을 확보합니다.',
        resultText: '저주를 봉인해 전열의 혼란을 막았습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'night_raid',
    title: '야간 기습대',
    rarity: BattlefieldEventRarity.special,
    effect: BattlefieldEventEffect.reinforcements,
    description: '횃불을 끈 적 기습대가 측면으로 접근합니다.',
    weight: 17,
    minProgress: .36,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'counter_raid',
        label: '역기습',
        description: '소수 정예를 이끌고 먼저 타격합니다.',
        resultText: '기습대의 선봉을 꺾었습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'artillery_duel',
    title: '공성포 대결',
    rarity: BattlefieldEventRarity.special,
    effect: BattlefieldEventEffect.eliteKnight,
    description: '양군 공성포가 같은 고지를 조준합니다.',
    weight: 14,
    minProgress: .4,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'mark_artillery',
        label: '표적 지시',
        description: '적 포대 좌표를 아군에게 전달합니다.',
        resultText: '적 공성포를 먼저 침묵시켰습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'dragon_flyover',
    title: '고룡의 비행',
    rarity: BattlefieldEventRarity.rare,
    effect: BattlefieldEventEffect.monsterIncursion,
    description: '거대한 용이 전장 상공에서 양군을 내려다봅니다.',
    weight: 9,
    minProgress: .44,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'avoid_dragon',
        label: '무기 숨기기',
        description: '도발하지 않고 비행 경로를 피합니다.',
        resultText: '고룡은 전장을 지나쳐 갔습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'rival_captain',
    title: '경쟁 용병단장',
    rarity: BattlefieldEventRarity.rare,
    effect: BattlefieldEventEffect.mercenaryIntervention,
    description: '라이벌 용병단장이 전과 경쟁을 제안합니다.',
    weight: 10,
    minProgress: .48,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'accept_rivalry',
        label: '경쟁 수락',
        description: '정예 증원을 상대하고 명예를 노립니다.',
        resultText: '전과 경쟁이 시작되었습니다.',
      ),
    ],
  ),
  BattlefieldEventSpec(
    id: 'ancient_relic',
    title: '고대 전쟁 유물',
    rarity: BattlefieldEventRarity.rare,
    effect: BattlefieldEventEffect.supplyWagon,
    description: '무너진 제단에서 마력이 흐르는 병기를 찾았습니다.',
    weight: 8,
    minProgress: .52,
    choices: [
      BattlefieldEventChoiceSpec(
        id: 'secure_relic',
        label: '유물 확보',
        description: '위험을 감수하고 봉인을 해제합니다.',
        resultText: '희귀한 전쟁 유물을 확보했습니다.',
      ),
    ],
  ),
];

abstract final class BattlefieldEventRules {
  static BattlefieldEventSpec? pickNext({
    required List<BattlefieldEventSpec> definitions,
    required Set<String> triggeredIds,
    required double progress,
    required math.Random random,
  }) {
    final eligible = definitions
        .where(
          (event) =>
              !triggeredIds.contains(event.id) && progress >= event.minProgress,
        )
        .toList();
    if (eligible.isEmpty) return null;
    final total = eligible.fold<int>(0, (sum, event) => sum + event.weight);
    var roll = random.nextInt(total);
    for (final event in eligible) {
      roll -= event.weight;
      if (roll < 0) return event;
    }
    return eligible.last;
  }
}
