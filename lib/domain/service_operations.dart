import 'dart:math' as math;

import 'battle_models.dart';
import 'game_data.dart';

enum DispatchRisk { low, medium, high }

enum DispatchEventType { supplyCache, shortcut, ambush, fieldMerchant }

class DispatchMissionSpec {
  const DispatchMissionSpec({
    required this.id,
    required this.name,
    required this.region,
    required this.description,
    required this.durationSeconds,
    required this.baseSuccessChance,
    required this.risk,
    required this.gold,
    required this.itemId,
    required this.itemAmount,
    required this.preferredMercenaryIds,
  });

  final String id;
  final String name;
  final String region;
  final String description;
  final int durationSeconds;
  final int baseSuccessChance;
  final DispatchRisk risk;
  final int gold;
  final String itemId;
  final int itemAmount;
  final Set<String> preferredMercenaryIds;
}

class ActiveDispatch {
  const ActiveDispatch({
    required this.missionId,
    required this.mercenaryId,
    required this.startedAtEpochMs,
    required this.durationSeconds,
    required this.seed,
  });

  final String missionId;
  final String mercenaryId;
  final int startedAtEpochMs;
  final int durationSeconds;
  final int seed;

  int get completesAtEpochMs => startedAtEpochMs + durationSeconds * 1000;

  bool isCompleteAt(DateTime now) =>
      now.millisecondsSinceEpoch >= completesAtEpochMs;

  Duration remainingAt(DateTime now) => Duration(
    milliseconds: math.max(0, completesAtEpochMs - now.millisecondsSinceEpoch),
  );

  Map<String, Object> toJson() => {
    'missionId': missionId,
    'mercenaryId': mercenaryId,
    'startedAtEpochMs': startedAtEpochMs,
    'durationSeconds': durationSeconds,
    'seed': seed,
  };

  factory ActiveDispatch.fromJson(Map<String, Object?> json) => ActiveDispatch(
    missionId: json['missionId'] as String? ?? '',
    mercenaryId: json['mercenaryId'] as String? ?? '',
    startedAtEpochMs: (json['startedAtEpochMs'] as num?)?.toInt() ?? 0,
    durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 60,
    seed: (json['seed'] as num?)?.toInt() ?? 1,
  );
}

class DispatchResolution {
  const DispatchResolution({
    required this.success,
    required this.event,
    required this.gold,
    required this.itemId,
    required this.itemAmount,
    required this.injurySeconds,
    required this.summary,
  });

  final bool success;
  final DispatchEventType event;
  final int gold;
  final String itemId;
  final int itemAmount;
  final int injurySeconds;
  final String summary;
}

abstract final class ServiceOperationRules {
  static const maxSupportSkillLevel = 5;

  static const missions = <DispatchMissionSpec>[
    DispatchMissionSpec(
      id: 'nearby_supply_run',
      name: '북문 보급품 회수',
      region: '북문 외곽',
      description: '버려진 보급 수레를 수색하고 야전 물자를 회수합니다.',
      durationSeconds: 300,
      baseSuccessChance: 88,
      risk: DispatchRisk.low,
      gold: 650,
      itemId: 'field_ration',
      itemAmount: 2,
      preferredMercenaryIds: {'talia', 'fenn'},
    ),
    DispatchMissionSpec(
      id: 'ashroad_courier',
      name: '잿바람 급행 계약',
      region: '잿바람 철수로',
      description: '전선을 우회해 계약 문서와 전황 보고서를 전달합니다.',
      durationSeconds: 900,
      baseSuccessChance: 78,
      risk: DispatchRisk.medium,
      gold: 1200,
      itemId: 'contract_ticket',
      itemAmount: 1,
      preferredMercenaryIds: {'fenn', 'corva'},
    ),
    DispatchMissionSpec(
      id: 'blackforest_salvage',
      name: '검은숲 전리품 감정',
      region: '검은숲 보급로',
      description: '마물과 약탈단을 피해 희귀 제작 재료를 확보합니다.',
      durationSeconds: 1800,
      baseSuccessChance: 70,
      risk: DispatchRisk.medium,
      gold: 1750,
      itemId: 'tempered_iron',
      itemAmount: 2,
      preferredMercenaryIds: {'talia', 'silas'},
    ),
    DispatchMissionSpec(
      id: 'whitewall_intelligence',
      name: '백야 요새 잠입 보고',
      region: '백야 설원',
      description: '적 보급망과 지휘 체계를 정찰해 고급 전술 자료를 탈취합니다.',
      durationSeconds: 3600,
      baseSuccessChance: 62,
      risk: DispatchRisk.high,
      gold: 2800,
      itemId: 'tactical_dossier',
      itemAmount: 2,
      preferredMercenaryIds: {'corva', 'silas'},
    ),
  ];

  static int supportSkillLevel(Map<String, int> levels, String mercenaryId) =>
      (levels[mercenaryId] ?? 1).clamp(1, maxSupportSkillLevel);

  static int supportUpgradeTokenCost(int currentLevel) => currentLevel * 10;

  static int dispatchMasteryLevel(int completed) => switch (completed) {
    >= 25 => 5,
    >= 15 => 4,
    >= 8 => 3,
    >= 3 => 2,
    _ => 1,
  };

  static int successChance({
    required DispatchMissionSpec mission,
    required String mercenaryId,
    required int completed,
  }) {
    final affinity = mission.preferredMercenaryIds.contains(mercenaryId)
        ? 12
        : 0;
    final mastery = (dispatchMasteryLevel(completed) - 1) * 3;
    return (mission.baseSuccessChance + affinity + mastery).clamp(35, 98);
  }

  static DispatchEventType eventFor(int seed) =>
      DispatchEventType.values[seed.abs() % DispatchEventType.values.length];

  static DispatchResolution resolve({
    required ActiveDispatch active,
    required DispatchMissionSpec mission,
    required int completed,
  }) {
    final chance = successChance(
      mission: mission,
      mercenaryId: active.mercenaryId,
      completed: completed,
    );
    final roll = math.Random(active.seed).nextInt(100);
    final success = roll < chance;
    final event = eventFor(active.seed ~/ 7 + active.durationSeconds);
    final eventGoldMultiplier = switch (event) {
      DispatchEventType.supplyCache => 1.20,
      DispatchEventType.fieldMerchant => 1.12,
      DispatchEventType.shortcut => 1.05,
      DispatchEventType.ambush => .88,
    };
    final masteryMultiplier = 1 + (dispatchMasteryLevel(completed) - 1) * .06;
    final rewardMultiplier = success
        ? eventGoldMultiplier * masteryMultiplier
        : .28;
    final injury = !success && mission.risk != DispatchRisk.low
        ? (mission.risk == DispatchRisk.high ? 600 : 300)
        : 0;
    final eventName = switch (event) {
      DispatchEventType.supplyCache => '숨겨진 보급고 발견',
      DispatchEventType.shortcut => '현지 길잡이의 지름길',
      DispatchEventType.ambush => '약탈단의 매복',
      DispatchEventType.fieldMerchant => '야전 상인과의 거래',
    };
    return DispatchResolution(
      success: success,
      event: event,
      gold: (mission.gold * rewardMultiplier).round(),
      itemId: mission.itemId,
      itemAmount: success
          ? mission.itemAmount +
                (event == DispatchEventType.supplyCache ? 1 : 0)
          : 0,
      injurySeconds: injury,
      summary: '${success ? '파견 성공' : '부분 철수'} · $eventName',
    );
  }

  static ({String supportId, String dispatchId}) recommendationFor(
    ContractObjective objective,
  ) => switch (objective) {
    ContractObjective.defense => (supportId: 'garr', dispatchId: 'silas'),
    ContractObjective.evacuation => (supportId: 'mira', dispatchId: 'fenn'),
    ContractObjective.supplyEscort => (supportId: 'mira', dispatchId: 'talia'),
    ContractObjective.assassination => (
      supportId: 'soren',
      dispatchId: 'corva',
    ),
    ContractObjective.ambush => (supportId: 'soren', dispatchId: 'fenn'),
    ContractObjective.fortressRetake => (
      supportId: 'elka',
      dispatchId: 'silas',
    ),
  };

  static String riskLabel(DispatchRisk risk) => switch (risk) {
    DispatchRisk.low => '안전',
    DispatchRisk.medium => '주의',
    DispatchRisk.high => '위험',
  };

  static String serviceSkillName(MercenarySpec mercenary) =>
      switch (mercenary.id) {
        'mira' => '응급 전선',
        'garr' => '노병의 방벽',
        'elka' => '공성 해체',
        'soren' => '무흔 표식',
        'talia' => '전리품 감정',
        'fenn' => '질풍 전달',
        'corva' => '흑익 정보망',
        'silas' => '전시 조달',
        _ => mercenary.trait,
      };
}
