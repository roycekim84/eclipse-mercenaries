import 'dart:io';

import 'package:eclipse_mercenaries/domain/content_catalog.dart';

void main(List<String> arguments) {
  final issues = ContentCatalogValidator.validate(alphaContentCatalog);
  if (issues.isNotEmpty) {
    stderr.writeln('Content audit failed with ${issues.length} issue(s):');
    for (final issue in issues) {
      stderr.writeln('- $issue');
    }
    exitCode = 1;
    return;
  }

  final snapshot = AlphaBalanceSnapshot.calculate(alphaContentCatalog);
  stdout.writeln('# Content audit · version ${alphaContentCatalog.version}');
  stdout.writeln();
  stdout.writeln('| Catalog | Count |');
  stdout.writeln('|---|---:|');
  stdout.writeln('| Mercenaries | ${alphaContentCatalog.mercenaries.length} |');
  stdout.writeln('| Weapons | ${alphaContentCatalog.weapons.length} |');
  stdout.writeln('| Enemies | ${alphaContentCatalog.enemies.length} |');
  stdout.writeln('| Events | ${alphaContentCatalog.events.length} |');
  stdout.writeln('| Loot | ${alphaContentCatalog.loot.length} |');
  stdout.writeln(
    '| Shop products | ${alphaContentCatalog.shopProducts.length} |',
  );
  stdout.writeln();
  stdout.writeln('## Mercenary base DPS index');
  for (final entry in snapshot.mercenaryDamagePerSecond.entries) {
    stdout.writeln('- ${entry.key}: ${entry.value.toStringAsFixed(2)}');
  }
  stdout.writeln();
  stdout.writeln('## Weapon power index');
  for (final entry in snapshot.weaponPowerIndex.entries) {
    stdout.writeln('- ${entry.key}: ${entry.value.toStringAsFixed(1)}');
  }
  stdout.writeln();
  stdout.writeln(
    '- Sample victory reward/min: '
    '${snapshot.sampleRewardGoldPerMinute.toStringAsFixed(0)} gold, '
    '${snapshot.sampleRewardXpPerMinute.toStringAsFixed(0)} XP',
  );
  stdout.writeln('- Weapon Lv.1→20 XP: ${snapshot.weaponLevelOneToTwentyXp}');
  stdout.writeln();
  stdout.writeln('Content references and balance baseline are valid.');
}
