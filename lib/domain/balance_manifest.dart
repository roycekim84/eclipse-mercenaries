import 'dart:convert';

class BalanceManifest {
  const BalanceManifest({
    required this.version,
    required this.enemyHpMultiplier,
    required this.rewardMultiplier,
    required this.spawnMultiplier,
    required this.signature,
  });

  static const bundled = BalanceManifest(
    version: 'beta-1',
    enemyHpMultiplier: 1,
    rewardMultiplier: 1,
    spawnMultiplier: 1,
    signature: '7d9f4f9c',
  );

  final String version;
  final double enemyHpMultiplier;
  final double rewardMultiplier;
  final double spawnMultiplier;
  final String signature;

  String get canonical =>
      '$version|$enemyHpMultiplier|$rewardMultiplier|$spawnMultiplier';

  bool get isValid =>
      signature == signatureFor(canonical) &&
      enemyHpMultiplier >= .7 &&
      enemyHpMultiplier <= 1.5 &&
      rewardMultiplier >= .5 &&
      rewardMultiplier <= 2 &&
      spawnMultiplier >= .5 &&
      spawnMultiplier <= 1.5;

  factory BalanceManifest.fromJson(Map<String, Object?> json) =>
      BalanceManifest(
        version: json['version'] as String? ?? '',
        enemyHpMultiplier: (json['enemyHpMultiplier'] as num?)?.toDouble() ?? 0,
        rewardMultiplier: (json['rewardMultiplier'] as num?)?.toDouble() ?? 0,
        spawnMultiplier: (json['spawnMultiplier'] as num?)?.toDouble() ?? 0,
        signature: json['signature'] as String? ?? '',
      );

  static BalanceManifest? tryDecode(String? source) {
    if (source == null) return null;
    try {
      final raw = jsonDecode(source);
      if (raw is! Map) return null;
      final value = BalanceManifest.fromJson(Map<String, Object?>.from(raw));
      return value.isValid ? value : null;
    } on FormatException {
      return null;
    }
  }

  static String signatureFor(String source) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(source)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}

class BalanceManifestResolution {
  const BalanceManifestResolution(this.manifest, this.source);

  final BalanceManifest manifest;
  final String source;
}

abstract final class BalanceManifestRules {
  static BalanceManifestResolution resolve({
    String? remoteJson,
    String? lastKnownGoodJson,
  }) {
    final remote = BalanceManifest.tryDecode(remoteJson);
    if (remote != null) return BalanceManifestResolution(remote, 'remote');
    final cached = BalanceManifest.tryDecode(lastKnownGoodJson);
    if (cached != null) {
      return BalanceManifestResolution(cached, 'last_known_good');
    }
    return const BalanceManifestResolution(BalanceManifest.bundled, 'bundled');
  }
}
