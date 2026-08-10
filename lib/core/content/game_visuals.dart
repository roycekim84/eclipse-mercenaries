import 'package:flutter/material.dart';

import '../../domain/game_data.dart';
import '../../domain/enemy_catalog.dart';

class MercenaryVisual {
  const MercenaryVisual({
    required this.color,
    required this.accent,
    required this.icon,
    required this.portraitAsset,
    required this.battleSpriteAsset,
  });

  final Color color;
  final Color accent;
  final IconData icon;
  final String portraitAsset;
  final String battleSpriteAsset;
}

class WeaponVisual {
  const WeaponVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

class EnemyVisual {
  const EnemyVisual({required this.color, required this.icon});

  final Color color;
  final IconData icon;
}

const _mercenaryVisuals = <String, MercenaryVisual>{
  'luna': MercenaryVisual(
    color: Color(0xff342342),
    accent: Color(0xffb690d0),
    icon: Icons.pets,
    portraitAsset: 'assets/images/luna_belhardt.png',
    battleSpriteAsset: 'characters/luna_battle_sheet.png',
  ),
  'kael': MercenaryVisual(
    color: Color(0xff49312f),
    accent: Color(0xffd47b67),
    icon: Icons.change_history,
    portraitAsset: 'assets/images/kael_rozenfang.png',
    battleSpriteAsset: 'characters/kael_battle_sheet.png',
  ),
  'sera': MercenaryVisual(
    color: Color(0xff273d50),
    accent: Color(0xff79c9de),
    icon: Icons.auto_awesome,
    portraitAsset: 'assets/images/sera_inarion.png',
    battleSpriteAsset: 'characters/sera_battle_sheet.png',
  ),
  'nyra': MercenaryVisual(
    color: Color(0xff183c43),
    accent: Color(0xff62d1c5),
    icon: Icons.cruelty_free,
    portraitAsset: 'assets/images/nyra_vale.png',
    battleSpriteAsset: 'characters/luna_battle_sheet.png',
  ),
  'aurel': MercenaryVisual(
    color: Color(0xff454331),
    accent: Color(0xffffd477),
    icon: Icons.shield_outlined,
    portraitAsset: 'assets/images/aurel_hart.png',
    battleSpriteAsset: 'characters/kael_battle_sheet.png',
  ),
  'vesta': MercenaryVisual(
    color: Color(0xff4a2631),
    accent: Color(0xffd99180),
    icon: Icons.menu_book_outlined,
    portraitAsset: 'assets/images/vesta_corven.png',
    battleSpriteAsset: 'characters/sera_battle_sheet.png',
  ),
  'rask': MercenaryVisual(
    color: Color(0xff263b30),
    accent: Color(0xff8eb47a),
    icon: Icons.push_pin,
    portraitAsset: 'assets/images/rask_draven.png',
    battleSpriteAsset: 'characters/kael_battle_sheet.png',
  ),
  'iris': MercenaryVisual(
    color: Color(0xff302b52),
    accent: Color(0xffa794ef),
    icon: Icons.diamond_outlined,
    portraitAsset: 'assets/images/iris_noctis.png',
    battleSpriteAsset: 'characters/sera_battle_sheet.png',
  ),
};

const _weaponVisuals = <String, WeaponVisual>{
  'moon_blades': WeaponVisual(
    icon: Icons.auto_fix_high,
    color: Color(0xff71518f),
  ),
  'blood_fang': WeaponVisual(icon: Icons.gavel, color: Color(0xff8a413c)),
  'glass_flame': WeaponVisual(icon: Icons.flare, color: Color(0xff39768a)),
  'iron_sword': WeaponVisual(icon: Icons.gavel, color: Color(0xff5d6570)),
  'war_bow': WeaponVisual(icon: Icons.architecture, color: Color(0xff75603d)),
  'ember_orb': WeaponVisual(
    icon: Icons.local_fire_department,
    color: Color(0xff934d35),
  ),
  'guard_spear': WeaponVisual(icon: Icons.push_pin, color: Color(0xff516a75)),
  'shadow_knife': WeaponVisual(icon: Icons.bolt, color: Color(0xff55466f)),
  'gale_string': WeaponVisual(
    icon: Icons.architecture,
    color: Color(0xff398b85),
  ),
  'sunwall_aegis': WeaponVisual(
    icon: Icons.shield_outlined,
    color: Color(0xffb89542),
  ),
  'corvus_codex': WeaponVisual(
    icon: Icons.menu_book_outlined,
    color: Color(0xff8b455b),
  ),
  'verdigris_halberd': WeaponVisual(
    icon: Icons.push_pin,
    color: Color(0xff45684d),
  ),
  'noctis_crescent': WeaponVisual(
    icon: Icons.nightlight_round,
    color: Color(0xff7461bd),
  ),
  'frost_standard': WeaponVisual(icon: Icons.ac_unit, color: Color(0xff6392a8)),
  'spirit_lantern': WeaponVisual(
    icon: Icons.local_fire_department_outlined,
    color: Color(0xff6b9b91),
  ),
  'storm_feathers': WeaponVisual(icon: Icons.air, color: Color(0xff8c718c)),
};

extension MercenaryVisualLookup on MercenarySpec {
  MercenaryVisual get visual => _mercenaryVisuals[id]!;
}

extension WeaponVisualLookup on WeaponSpec {
  WeaponVisual get visual => _weaponVisuals[id]!;
}

extension EnemyVisualLookup on EnemyArchetypeSpec {
  Color get factionColor => switch (faction) {
    EnemyFaction.vargarEmpire => const Color(0xffb84d45),
    EnemyFaction.cinderCoven => const Color(0xff9b5b9f),
    EnemyFaction.freeBlades => const Color(0xffb88449),
  };

  IconData get abilityIcon => switch (ability) {
    EnemyAbility.brace => Icons.shield_outlined,
    EnemyAbility.volley => Icons.architecture,
    EnemyAbility.charge => Icons.trending_flat,
    EnemyAbility.hex || EnemyAbility.bloodNova => Icons.auto_awesome,
    EnemyAbility.breach || EnemyAbility.blast => Icons.brightness_7,
    EnemyAbility.flank || EnemyAbility.huntMark => Icons.directions_run,
    EnemyAbility.riposte => Icons.gavel,
    EnemyAbility.commandSiege => Icons.flag,
    EnemyAbility.none => Icons.person_outline,
  };

  EnemyVisual get visual => EnemyVisual(color: factionColor, icon: abilityIcon);
}

String enemyFactionName(EnemyFaction faction) => switch (faction) {
  EnemyFaction.vargarEmpire => '바르가르 제국',
  EnemyFaction.cinderCoven => '잿불 교단',
  EnemyFaction.freeBlades => '회색 자유단',
};

IconData gameIcon(String id) => switch (id) {
  'movement' => Icons.directions_run,
  'battle_instinct' => Icons.local_fire_department,
  'rapid_drill' => Icons.speed,
  'swift_step' => Icons.directions_run,
  'keen_eye' => Icons.visibility,
  'luna' => Icons.pets,
  'kael' => Icons.change_history,
  'sera' => Icons.auto_awesome,
  'nyra' => Icons.cruelty_free,
  'aurel' => Icons.shield_outlined,
  'vesta' => Icons.menu_book_outlined,
  'rask' => Icons.push_pin,
  'iris' => Icons.diamond_outlined,
  _ => _weaponVisuals[id]?.icon ?? Icons.auto_awesome,
};
