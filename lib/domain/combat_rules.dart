enum DamageKind { physical, magical, pure }

enum StatusEffectType { none, bleed, burn, slow }

class DamageRequest {
  const DamageRequest({
    required this.baseDamage,
    required this.defense,
    required this.criticalChance,
    required this.criticalRoll,
    this.kind = DamageKind.physical,
    this.damageMultiplier = 1,
    this.status = StatusEffectType.none,
    this.statusChance = 0,
    this.statusRoll = 1,
  });

  final int baseDamage;
  final int defense;
  final double criticalChance;
  final double criticalRoll;
  final DamageKind kind;
  final double damageMultiplier;
  final StatusEffectType status;
  final double statusChance;
  final double statusRoll;
}

class DamageResult {
  const DamageResult({
    required this.amount,
    required this.isCritical,
    required this.appliedStatus,
  });

  final int amount;
  final bool isCritical;
  final StatusEffectType appliedStatus;
}

abstract final class DamageResolver {
  static const double criticalMultiplier = 1.5;

  static DamageResult resolve(DamageRequest request) {
    final defense = request.kind == DamageKind.pure
        ? 0
        : request.defense.clamp(0, 9999);
    final mitigated =
        request.baseDamage.clamp(0, 999999) * 100 / (100 + defense);
    final isCritical =
        request.criticalRoll < (request.criticalChance.clamp(0, 100) / 100);
    final critical = isCritical ? criticalMultiplier : 1.0;
    final amount = (mitigated * critical * request.damageMultiplier)
        .round()
        .clamp(1, 999999);
    final appliedStatus =
        request.status != StatusEffectType.none &&
            request.statusRoll < request.statusChance.clamp(0, 1)
        ? request.status
        : StatusEffectType.none;
    return DamageResult(
      amount: amount,
      isCritical: isCritical,
      appliedStatus: appliedStatus,
    );
  }
}
