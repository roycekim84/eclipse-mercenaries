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
