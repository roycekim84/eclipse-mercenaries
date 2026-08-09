import 'dart:math' as math;

enum LootRarity { common, uncommon, rare, epic, legendary }

class LootItemSpec {
  const LootItemSpec({
    required this.id,
    required this.name,
    required this.rarity,
    required this.description,
  });

  final String id;
  final String name;
  final LootRarity rarity;
  final String description;
}

class LootDrop {
  const LootDrop({
    required this.id,
    required this.name,
    required this.rarity,
    required this.quantity,
    required this.source,
  });

  final String id;
  final String name;
  final LootRarity rarity;
  final int quantity;
  final String source;
}

class RewardBreakdown {
  const RewardBreakdown({
    required this.contractGold,
    required this.objectiveGold,
    required this.combatGold,
    required this.eventGold,
    required this.contractXp,
    required this.objectiveXp,
    required this.combatXp,
    required this.eventXp,
    required this.rewardMultiplier,
    required this.preservationRate,
    required this.keptGold,
    required this.keptXp,
  });

  final int contractGold;
  final int objectiveGold;
  final int combatGold;
  final int eventGold;
  final int contractXp;
  final int objectiveXp;
  final int combatXp;
  final int eventXp;
  final double rewardMultiplier;
  final double preservationRate;
  final int keptGold;
  final int keptXp;

  int get grossGold =>
      ((contractGold + objectiveGold + combatGold + eventGold) *
              rewardMultiplier)
          .round();
  int get grossXp =>
      ((contractXp + objectiveXp + combatXp + eventXp) * rewardMultiplier)
          .round();
}

class BattleAward {
  const BattleAward({
    required this.title,
    required this.detail,
    required this.honors,
  });

  final String title;
  final String detail;
  final List<String> honors;
}

abstract final class BattleRewardRules {
  static double preservationRate(String outcome) => switch (outcome) {
    'victory' => 1,
    'retreat' => .5,
    _ => .2,
  };

  static RewardBreakdown calculate({
    required int contractGold,
    required int contractXp,
    required int kills,
    required int completedObjectives,
    required int eventGold,
    required int eventXp,
    required double eventMultiplier,
    required double preservationRate,
  }) {
    final objectiveGold = completedObjectives * 300;
    final objectiveXp = completedObjectives * 100;
    final combatGold = kills * 8;
    final combatXp = kills * 3;
    final grossGold =
        ((contractGold + objectiveGold + combatGold + eventGold) *
                eventMultiplier)
            .round();
    final grossXp =
        ((contractXp + objectiveXp + combatXp + eventXp) * eventMultiplier)
            .round();
    return RewardBreakdown(
      contractGold: contractGold,
      objectiveGold: objectiveGold,
      combatGold: combatGold,
      eventGold: eventGold,
      contractXp: contractXp,
      objectiveXp: objectiveXp,
      combatXp: combatXp,
      eventXp: eventXp,
      rewardMultiplier: eventMultiplier,
      preservationRate: preservationRate,
      keptGold: math.max(0, (grossGold * preservationRate).round()),
      keptXp: math.max(0, (grossXp * preservationRate).round()),
    );
  }

  static BattleAward award({
    required int kills,
    required int alliedKills,
    required double objectiveRatio,
    required bool evacuation,
    required bool commanderSurvived,
    required bool enemyCommanderDefeated,
    required int ultimateActivations,
    required int completedObjectives,
    required int eventCount,
  }) {
    final title = enemyCommanderDefeated
        ? '지휘관 사냥꾼'
        : objectiveRatio >= .9
        ? evacuation
              ? '최후의 호위'
              : '북문의 철벽'
        : ultimateActivations > 0
        ? '월식의 집행자'
        : kills >= math.max(20, alliedKills ~/ 2)
        ? '전장의 칼날'
        : '계약의 수호자';
    final detail = switch (title) {
      '지휘관 사냥꾼' => '적 지휘 체계를 무너뜨려 전황을 뒤집었습니다.',
      '최후의 호위' => '철수 행렬을 끝까지 지켜 계약을 완수했습니다.',
      '북문의 철벽' => '성문 방어선을 흔들림 없이 유지했습니다.',
      '월식의 집행자' => '고유 궁극기로 전장의 흐름을 끊었습니다.',
      '전장의 칼날' => '가장 치열한 교전선에서 높은 전과를 세웠습니다.',
      _ => '계약 목표를 우선하며 용병단의 손실을 억제했습니다.',
    };
    return BattleAward(
      title: title,
      detail: detail,
      honors: [
        if (kills >= 100) '백인참',
        if (commanderSurvived) '지휘 체계 보전',
        if (enemyCommanderDefeated) '적 지휘관 격퇴',
        if (completedObjectives >= 3) '전술 목표 완수',
        if (ultimateActivations > 0) '궁극기 $ultimateActivations회',
        if (eventCount >= 2) '사건 대응 $eventCount회',
      ],
    );
  }
}

const alphaLootTable = <LootItemSpec>[
  LootItemSpec(
    id: 'war_scrap',
    name: '전장 고철',
    rarity: LootRarity.common,
    description: '대장간에서 기초 강화 재료로 사용한다.',
  ),
  LootItemSpec(
    id: 'field_ration',
    name: '야전 식량',
    rarity: LootRarity.common,
    description: '다음 계약을 준비하는 보급품이다.',
  ),
  LootItemSpec(
    id: 'tempered_iron',
    name: '단련된 흑철',
    rarity: LootRarity.uncommon,
    description: '무기 성장 단계에 사용하는 금속 재료다.',
  ),
  LootItemSpec(
    id: 'mooncloth',
    name: '월광천 조각',
    rarity: LootRarity.uncommon,
    description: '마력 장비의 안감을 보강한다.',
  ),
  LootItemSpec(
    id: 'officer_map',
    name: '장교의 전술지도',
    rarity: LootRarity.rare,
    description: '고급 계약과 전술 연구에 사용한다.',
  ),
  LootItemSpec(
    id: 'contract_seal',
    name: '피 묻은 계약 인장',
    rarity: LootRarity.rare,
    description: '전쟁 상점에서 가치를 인정받는 증표다.',
  ),
  LootItemSpec(
    id: 'veteran_badge',
    name: '노병의 휘장',
    rarity: LootRarity.epic,
    description: '정예 용병의 성장에 사용하는 희귀 증표다.',
  ),
  LootItemSpec(
    id: 'red_moon_shard',
    name: '붉은 달의 파편',
    rarity: LootRarity.legendary,
    description: '붉은 달 아래에서만 응결되는 전설 재료다.',
  ),
  LootItemSpec(
    id: 'royal_writ',
    name: '파손된 왕명서',
    rarity: LootRarity.legendary,
    description: '왕의 친정을 증명하는 최고 등급 전리품이다.',
  ),
];

abstract final class BattleLootRules {
  static List<LootDrop> resolve({
    required int seed,
    required int completedObjectives,
    required int eventCount,
    required List<String> rareDropIds,
    required List<String> eventChoiceIds,
    required double preservationRate,
  }) {
    final random = math.Random(seed ^ 0x7f4a7c15);
    final rolled = <LootDrop>[];
    final rollCount = 2 + completedObjectives + math.min(2, eventCount);
    for (var i = 0; i < rollCount; i++) {
      final rarityRoll = random.nextInt(100);
      final rarity = rarityRoll < 5
          ? LootRarity.epic
          : rarityRoll < 24
          ? LootRarity.rare
          : rarityRoll < 60
          ? LootRarity.uncommon
          : LootRarity.common;
      final candidates = alphaLootTable
          .where((item) => item.rarity == rarity)
          .toList();
      final item = candidates[random.nextInt(candidates.length)];
      rolled.add(_drop(item, '전투 전리품'));
    }
    for (final id in rareDropIds) {
      rolled.add(_specialDrop(id));
    }
    if (eventChoiceIds.contains('embrace_red_moon')) {
      rolled.add(_drop(_byId('red_moon_shard'), '전설 사건'));
    }
    if (eventChoiceIds.contains('challenge_royal_guard')) {
      rolled.add(_drop(_byId('royal_writ'), '왕의 친정'));
    }

    final merged = <String, LootDrop>{};
    for (final drop in rolled) {
      final old = merged[drop.id];
      merged[drop.id] = old == null
          ? drop
          : LootDrop(
              id: drop.id,
              name: drop.name,
              rarity: drop.rarity,
              quantity: old.quantity + drop.quantity,
              source: old.source == drop.source
                  ? old.source
                  : '${old.source} · ${drop.source}',
            );
    }
    final sorted = merged.values.toList()
      ..sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
    if (preservationRate >= 1 || sorted.isEmpty) return sorted;
    final keepCount = math.max(1, (sorted.length * preservationRate).ceil());
    return sorted.take(keepCount).toList();
  }

  static LootDrop _specialDrop(String id) {
    const names = {
      'nameless_spur': '이름 없는 박차',
      'blood_ember': '응고된 혈화',
      'marshal_seal': '공성군감의 인장',
      'hunter_insignia': '추격대장의 표식',
    };
    final boss = id == 'marshal_seal' || id == 'hunter_insignia';
    return LootDrop(
      id: id,
      name: names[id] ?? id,
      rarity: boss ? LootRarity.epic : LootRarity.rare,
      quantity: 1,
      source: boss ? '적 지휘관' : '정예 처치',
    );
  }

  static LootItemSpec _byId(String id) =>
      alphaLootTable.firstWhere((item) => item.id == id);

  static LootDrop _drop(LootItemSpec item, String source) => LootDrop(
    id: item.id,
    name: item.name,
    rarity: item.rarity,
    quantity: 1,
    source: source,
  );
}
