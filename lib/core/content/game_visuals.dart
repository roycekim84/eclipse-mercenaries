import 'package:flutter/material.dart';

import '../../domain/game_data.dart';

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
};

extension MercenaryVisualLookup on MercenarySpec {
  MercenaryVisual get visual => _mercenaryVisuals[id]!;
}

extension WeaponVisualLookup on WeaponSpec {
  WeaponVisual get visual => _weaponVisuals[id]!;
}

IconData gameIcon(String id) => switch (id) {
  'movement' => Icons.directions_run,
  'battle_instinct' => Icons.local_fire_department,
  'rapid_drill' => Icons.speed,
  'swift_step' => Icons.directions_run,
  'keen_eye' => Icons.visibility,
  'luna' => Icons.pets,
  'kael' => Icons.change_history,
  'sera' => Icons.auto_awesome,
  _ => _weaponVisuals[id]?.icon ?? Icons.auto_awesome,
};
