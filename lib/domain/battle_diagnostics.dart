import 'battle_models.dart';

class BattleDiagnosticRecord {
  const BattleDiagnosticRecord({
    required this.recordedAtUtc,
    required this.contentVersion,
    required this.seed,
    required this.contractId,
    required this.mercenaryId,
    required this.weaponId,
    required this.outcome,
    required this.duration,
    required this.kills,
    required this.peakActiveUnits,
    required this.frameTimeP95Ms,
    required this.terminationReason,
  });

  final String recordedAtUtc;
  final int contentVersion;
  final int seed;
  final String contractId;
  final String mercenaryId;
  final String weaponId;
  final String outcome;
  final String duration;
  final int kills;
  final int peakActiveUnits;
  final double frameTimeP95Ms;
  final String terminationReason;

  factory BattleDiagnosticRecord.fromReport({
    required BattleReport report,
    required int contentVersion,
    required int seed,
    required String contractId,
    required String mercenaryId,
    required String weaponId,
    DateTime? recordedAt,
  }) => BattleDiagnosticRecord(
    recordedAtUtc: (recordedAt ?? DateTime.now()).toUtc().toIso8601String(),
    contentVersion: contentVersion,
    seed: seed,
    contractId: contractId,
    mercenaryId: mercenaryId,
    weaponId: weaponId,
    outcome: report.outcome.name,
    duration: report.time,
    kills: report.kills,
    peakActiveUnits: report.peakActiveUnits,
    frameTimeP95Ms: report.frameTimeP95Ms,
    terminationReason: switch (report.outcome) {
      BattleOutcome.victory => 'objective_completed',
      BattleOutcome.retreat => 'tactical_retreat',
      BattleOutcome.defeat => 'mercenary_defeated',
    },
  );

  Map<String, Object> toJson() => {
    'recordedAtUtc': recordedAtUtc,
    'contentVersion': contentVersion,
    'seed': seed,
    'contractId': contractId,
    'mercenaryId': mercenaryId,
    'weaponId': weaponId,
    'outcome': outcome,
    'duration': duration,
    'kills': kills,
    'peakActiveUnits': peakActiveUnits,
    'frameTimeP95Ms': frameTimeP95Ms,
    'terminationReason': terminationReason,
  };

  factory BattleDiagnosticRecord.fromJson(Map<String, Object?> json) =>
      BattleDiagnosticRecord(
        recordedAtUtc: json['recordedAtUtc'] as String? ?? '',
        contentVersion: (json['contentVersion'] as num?)?.toInt() ?? 0,
        seed: (json['seed'] as num?)?.toInt() ?? 0,
        contractId: json['contractId'] as String? ?? 'unknown',
        mercenaryId: json['mercenaryId'] as String? ?? 'unknown',
        weaponId: json['weaponId'] as String? ?? 'unknown',
        outcome: json['outcome'] as String? ?? 'unknown',
        duration: json['duration'] as String? ?? '00:00',
        kills: (json['kills'] as num?)?.toInt() ?? 0,
        peakActiveUnits: (json['peakActiveUnits'] as num?)?.toInt() ?? 0,
        frameTimeP95Ms: (json['frameTimeP95Ms'] as num?)?.toDouble() ?? 0,
        terminationReason: json['terminationReason'] as String? ?? 'unknown',
      );
}

abstract final class BattleDiagnosticRules {
  static const capacity = 20;

  static List<BattleDiagnosticRecord> append(
    List<BattleDiagnosticRecord> existing,
    BattleDiagnosticRecord value,
  ) {
    final next = [...existing, value];
    if (next.length <= capacity) return next;
    return next.sublist(next.length - capacity);
  }
}
