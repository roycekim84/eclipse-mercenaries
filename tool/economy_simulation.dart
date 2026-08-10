import 'dart:io';

import 'package:eclipse_mercenaries/domain/economy.dart';

void main() {
  final simulation = BetaEconomySimulator.simulateSevenDays();
  stdout.writeln('# Beta economy · deterministic 7-day simulation');
  stdout.writeln('| Day | Gold | Crystals | War seals | Honor |');
  stdout.writeln('|---:|---:|---:|---:|---:|');
  for (final day in simulation.days) {
    stdout.writeln(
      '| ${day.day} | ${day.gold} | ${day.crystals} | '
      '${day.warSeals} | ${day.honor} |',
    );
  }
  if (simulation.hasProgressBlock) {
    throw StateError('A required beta currency became negative.');
  }
}
