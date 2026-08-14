import 'package:flutter/material.dart';

import '../../domain/battle_models.dart';
import '../../domain/battlefield_events.dart';
import '../../domain/game_data.dart';
import '../../domain/enemy_catalog.dart';

class MercenaryVisual {
  const MercenaryVisual({
    required this.color,
    required this.accent,
    required this.icon,
    required this.portraitAsset,
    this.battleSpriteAsset,
    required this.battleDisplaySize,
    required this.battleColumns,
    required this.battleFrameIndices,
    this.worldSpriteAsset,
    this.battleGroundAnchorY = .93,
    this.battleCombatOrigin = const Offset(.14, -.44),
    this.portraitAlignment = Alignment.topCenter,
    this.portraitScale = 1,
    this.rosterAlignment = const Alignment(0, -.72),
    this.rosterScale = 1.85,
    this.recruitAlignment = Alignment.topCenter,
  });

  final Color color;
  final Color accent;
  final IconData icon;
  final String portraitAsset;

  /// Animated battle sheet. Null for non-deployable service mercenaries.
  final String? battleSpriteAsset;
  final double battleDisplaySize;
  final int battleColumns;
  final List<List<int>> battleFrameIndices;

  /// A standalone transparent sprite used by non-deployable service
  /// mercenaries in the camp and during support calls. Deployable heroes keep
  /// using their authored animation sheet.
  final String? worldSpriteAsset;
  final double battleGroundAnchorY;
  final Offset battleCombatOrigin;
  final Alignment portraitAlignment;
  final double portraitScale;
  final Alignment rosterAlignment;
  final double rosterScale;
  final Alignment recruitAlignment;

  bool get hasStandaloneWorldSprite => worldSpriteAsset != null;
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
    battleDisplaySize: 82,
    battleColumns: 8,
    battleFrameIndices: [
      [0, 1, 2, 3, 4, 5, 6, 7],
      [0, 1, 2, 3, 4, 5, 6, 7],
      [0, 1, 2, 3, 4, 5],
      [0, 1, 2, 3, 4, 5],
      [0, 1, 2, 3, 4, 5, 6, 7],
    ],
    portraitAlignment: Alignment(0, -.04),
    rosterAlignment: Alignment(0, -.7),
    rosterScale: 1.82,
    recruitAlignment: Alignment(0, -.05),
  ),
  'kael': MercenaryVisual(
    color: Color(0xff49312f),
    accent: Color(0xffd47b67),
    icon: Icons.change_history,
    portraitAsset: 'assets/images/kael_rozenfang.png',
    battleSpriteAsset: 'characters/kael_battle_sheet.png',
    battleDisplaySize: 76,
    battleColumns: 8,
    battleFrameIndices: [
      [0, 1, 2, 3, 4, 5, 6, 7],
      [0, 1, 2, 3, 4, 5, 6, 7],
      [0, 1, 5, 6, 7, 6],
      [0, 1, 2, 3],
      [0, 1, 2, 3, 4, 5, 6, 7],
    ],
    battleCombatOrigin: Offset(.22, -.42),
    portraitAlignment: Alignment(0, -.02),
    rosterAlignment: Alignment(0, -.67),
    rosterScale: 1.78,
    recruitAlignment: Alignment(0, -.03),
  ),
  'sera': MercenaryVisual(
    color: Color(0xff273d50),
    accent: Color(0xff79c9de),
    icon: Icons.auto_awesome,
    portraitAsset: 'assets/images/sera_inarion.png',
    battleSpriteAsset: 'characters/sera_battle_sheet.png',
    battleDisplaySize: 80,
    battleColumns: 8,
    battleFrameIndices: [
      [0, 1, 2, 3, 4, 5, 6, 7],
      [0, 1, 2, 3, 4, 5, 6, 7],
      [0, 1, 5, 6, 5, 1],
      [0, 1, 2, 3],
      [0, 1, 2, 3, 4, 5, 6],
    ],
    battleCombatOrigin: Offset(.2, -.58),
    portraitAlignment: Alignment(0, -.03),
    rosterAlignment: Alignment(0, -.69),
    rosterScale: 1.8,
    recruitAlignment: Alignment(0, -.04),
  ),
  'nyra': MercenaryVisual(
    color: Color(0xff183c43),
    accent: Color(0xff62d1c5),
    icon: Icons.cruelty_free,
    portraitAsset: 'assets/images/nyra_vale_profile_v2.png',
    battleSpriteAsset: 'characters/nyra_battle_sheet.png',
    battleDisplaySize: 78,
    battleColumns: 7,
    battleFrameIndices: [
      [0, 1, 2, 3, 4, 5, 6],
      [0, 1, 2, 3, 4, 5, 6],
      [0, 1, 2, 3, 4, 5],
      [0, 1, 2, 3],
      [0, 1, 2, 3, 4, 5, 6],
    ],
    portraitScale: 1.04,
    rosterAlignment: Alignment(0, -.68),
    rosterScale: 1.76,
  ),
  'aurel': MercenaryVisual(
    color: Color(0xff454331),
    accent: Color(0xffffd477),
    icon: Icons.shield_outlined,
    portraitAsset: 'assets/images/aurel_hart_profile_v2.png',
    battleSpriteAsset: 'characters/aurel_battle_sheet.png',
    battleDisplaySize: 74,
    battleColumns: 7,
    battleFrameIndices: [
      [0, 1, 2, 3, 4, 5, 6],
      [0, 1, 2, 3, 4, 5, 6],
      [0, 1, 2, 3, 4, 5],
      [0, 1, 2, 3],
      [0, 1, 2, 3, 4, 5, 6],
    ],
    battleGroundAnchorY: .94,
    portraitScale: 1.08,
    rosterAlignment: Alignment(0, -.66),
    rosterScale: 1.74,
  ),
  'vesta': MercenaryVisual(
    color: Color(0xff4a2631),
    accent: Color(0xffd99180),
    icon: Icons.menu_book_outlined,
    portraitAsset: 'assets/images/vesta_corven_profile_v2.png',
    battleSpriteAsset: 'characters/vesta_battle_sheet.png',
    battleDisplaySize: 86,
    battleColumns: 7,
    battleFrameIndices: [
      [0, 1, 2, 3, 4, 5, 6],
      [0, 1, 2, 3, 4, 5, 6],
      [0, 1, 2, 3, 4, 5],
      [0, 1, 2, 3],
      [0, 1, 2, 3, 4, 5, 6],
    ],
    battleCombatOrigin: Offset(.18, -.55),
    portraitScale: 1.06,
    rosterAlignment: Alignment(0, -.7),
    rosterScale: 1.8,
  ),
  'rask': MercenaryVisual(
    color: Color(0xff263b30),
    accent: Color(0xff8eb47a),
    icon: Icons.push_pin,
    portraitAsset: 'assets/images/rask_draven_profile_v2.png',
    battleSpriteAsset: 'characters/rask_battle_sheet.png',
    battleDisplaySize: 84,
    battleColumns: 7,
    battleFrameIndices: [
      [0, 1, 2, 3, 4, 5, 6],
      [0, 1, 2, 3, 4, 5, 6],
      [0, 1, 2, 3, 4, 5],
      [0, 1, 2, 3],
      [0, 1, 2, 3, 4, 5, 6],
    ],
    battleCombatOrigin: Offset(.24, -.46),
    portraitScale: 1.06,
    rosterAlignment: Alignment(0, -.63),
    rosterScale: 1.72,
  ),
  'iris': MercenaryVisual(
    color: Color(0xff302b52),
    accent: Color(0xffa794ef),
    icon: Icons.diamond_outlined,
    portraitAsset: 'assets/images/iris_noctis_profile_v2.png',
    battleSpriteAsset: 'characters/iris_battle_sheet.png',
    battleDisplaySize: 86,
    battleColumns: 7,
    battleFrameIndices: [
      [0, 1, 2, 3, 4, 5, 6],
      [0, 1, 2, 3, 4, 5, 6],
      [0, 1, 2, 3, 4, 5],
      [0, 1, 2, 3],
      [0, 1, 2, 3, 4, 5, 6],
    ],
    battleCombatOrigin: Offset(.18, -.5),
    portraitScale: 1.06,
    rosterAlignment: Alignment(0, -.67),
    rosterScale: 1.78,
  ),
  'mira': MercenaryVisual(
    color: Color(0xff26382f),
    accent: Color(0xff9bc394),
    icon: Icons.medical_services_outlined,
    portraitAsset: 'assets/images/mercenaries/mira.png',
    worldSpriteAsset: 'characters/mira_service_sprite.png',
    battleDisplaySize: 78,
    battleColumns: 8,
    battleFrameIndices: [
      [0],
      [0],
      [0],
      [0],
      [0],
    ],
    portraitAlignment: Alignment(0, -.12),
    rosterAlignment: Alignment(0, -.55),
    rosterScale: 1.32,
  ),
  'garr': MercenaryVisual(
    color: Color(0xff273647),
    accent: Color(0xff90a9c7),
    icon: Icons.shield_outlined,
    portraitAsset: 'assets/images/mercenaries/garr.png',
    worldSpriteAsset: 'characters/garr_service_sprite.png',
    battleDisplaySize: 78,
    battleColumns: 7,
    battleFrameIndices: [
      [0],
      [0],
      [0],
      [0],
      [0],
    ],
    portraitAlignment: Alignment(0, -.12),
    rosterAlignment: Alignment(0, -.55),
    rosterScale: 1.32,
  ),
  'talia': MercenaryVisual(
    color: Color(0xff4a292b),
    accent: Color(0xffd28b72),
    icon: Icons.inventory_2_outlined,
    portraitAsset: 'assets/images/mercenaries/talia.png',
    worldSpriteAsset: 'characters/talia_service_sprite.png',
    battleDisplaySize: 78,
    battleColumns: 7,
    battleFrameIndices: [
      [0],
      [0],
      [0],
      [0],
      [0],
    ],
    portraitAlignment: Alignment(0, -.12),
    rosterAlignment: Alignment(0, -.55),
    rosterScale: 1.32,
  ),
  'fenn': MercenaryVisual(
    color: Color(0xff30394a),
    accent: Color(0xffd9bd7c),
    icon: Icons.forward_to_inbox_outlined,
    portraitAsset: 'assets/images/mercenaries/fenn.png',
    worldSpriteAsset: 'characters/fenn_service_sprite.png',
    battleDisplaySize: 78,
    battleColumns: 7,
    battleFrameIndices: [
      [0],
      [0],
      [0],
      [0],
      [0],
    ],
    portraitAlignment: Alignment(0, -.12),
    rosterAlignment: Alignment(0, -.55),
    rosterScale: 1.32,
  ),
  'elka': MercenaryVisual(
    color: Color(0xff3c302c),
    accent: Color(0xffc49667),
    icon: Icons.engineering_outlined,
    portraitAsset: 'assets/images/mercenaries/elka.png',
    worldSpriteAsset: 'characters/elka_service_sprite.png',
    battleDisplaySize: 78,
    battleColumns: 7,
    battleFrameIndices: [
      [0],
      [0],
      [0],
      [0],
      [0],
    ],
    portraitAlignment: Alignment(0, -.12),
    rosterAlignment: Alignment(0, -.55),
    rosterScale: 1.32,
  ),
  'soren': MercenaryVisual(
    color: Color(0xff26382e),
    accent: Color(0xff84aa72),
    icon: Icons.travel_explore,
    portraitAsset: 'assets/images/mercenaries/soren.png',
    worldSpriteAsset: 'characters/soren_service_sprite.png',
    battleDisplaySize: 78,
    battleColumns: 7,
    battleFrameIndices: [
      [0],
      [0],
      [0],
      [0],
      [0],
    ],
    portraitAlignment: Alignment(0, -.12),
    rosterAlignment: Alignment(0, -.55),
    rosterScale: 1.32,
  ),
  'corva': MercenaryVisual(
    color: Color(0xff282944),
    accent: Color(0xff9899ca),
    icon: Icons.mark_email_unread_outlined,
    portraitAsset: 'assets/images/mercenaries/corva.png',
    worldSpriteAsset: 'characters/corva_service_sprite.png',
    battleDisplaySize: 78,
    battleColumns: 7,
    battleFrameIndices: [
      [0],
      [0],
      [0],
      [0],
      [0],
    ],
    portraitAlignment: Alignment(0, -.12),
    rosterAlignment: Alignment(0, -.55),
    rosterScale: 1.32,
  ),
  'silas': MercenaryVisual(
    color: Color(0xff263d3d),
    accent: Color(0xff76b5ad),
    icon: Icons.local_shipping_outlined,
    portraitAsset: 'assets/images/mercenaries/silas.png',
    worldSpriteAsset: 'characters/silas_service_sprite.png',
    battleDisplaySize: 78,
    battleColumns: 8,
    battleFrameIndices: [
      [0],
      [0],
      [0],
      [0],
      [0],
    ],
    portraitAlignment: Alignment(0, -.12),
    rosterAlignment: Alignment(0, -.55),
    rosterScale: 1.32,
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

String weaponArtAsset(String id) => 'assets/images/items/$id.png';

String? lootArtAsset(String id) => switch (id) {
  'contract_seal' ||
  'contract_ticket' ||
  'field_medicine' ||
  'field_ration' ||
  'mooncloth' ||
  'officer_map' ||
  'royal_writ' ||
  'siege_core' ||
  'tempered_iron' ||
  'veteran_badge' ||
  'war_hero_contract' ||
  'war_scrap' => 'assets/images/shop/final/$id.png',
  _ => null,
};

String battlefieldEventArtAsset(
  BattlefieldEventEffect effect,
) => switch (effect) {
  BattlefieldEventEffect.reinforcements =>
    'assets/images/events/reinforcements.png',
  BattlefieldEventEffect.eliteKnight => 'assets/images/events/elite_knight.png',
  BattlefieldEventEffect.supplyWagon => 'assets/images/events/supply_wagon.png',
  BattlefieldEventEffect.woundedCommander =>
    'assets/images/events/wounded_commander.png',
  BattlefieldEventEffect.mercenaryIntervention =>
    'assets/images/events/mercenary_intervention.png',
  BattlefieldEventEffect.monsterIncursion =>
    'assets/images/events/monster_incursion.png',
  BattlefieldEventEffect.redMoon => 'assets/images/events/red_moon.png',
  BattlefieldEventEffect.royalPresence =>
    'assets/images/events/royal_presence.png',
};

String battlefieldArtAsset(BattlefieldCondition condition) =>
    switch (condition) {
      BattlefieldCondition.moonlitNight =>
        'assets/images/battlefield/north_gate_battlefield.png',
      BattlefieldCondition.ashWind =>
        'assets/images/battlefield/ashwind_road_v2.png',
      BattlefieldCondition.blackForest =>
        'assets/images/battlefield/black_forest_route.png',
      BattlefieldCondition.whiteNight =>
        'assets/images/battlefield/white_night_fortress.png',
      BattlefieldCondition.twilightSiege =>
        'assets/images/battlefield/twilight_siege_plain.png',
    };

String enemyArtAsset(EnemyArchetypeSpec enemy) {
  final authoredVariant = switch (enemy.id) {
    'iron_guard' => 'veteran_shield',
    'vargar_longbow' => 'crimson_marksman',
    'black_lancer' => 'lancer_officer',
    'cinder_hexer' => 'ash_hexer',
    'powder_sapper' => 'plague_sapper',
    'free_skirmisher' => 'ochre_skirmisher',
    'bone_warder' || 'frost_paladin' => 'frost_veteran',
    'siege_alchemist' => 'siege_engineer',
    'siege_marshal' || 'dusk_general' => 'battle_commander',
    _ => null,
  };
  if (authoredVariant != null) {
    return 'assets/images/enemies/$authoredVariant.png';
  }
  if (enemy.rank == EnemyRank.boss) {
    return switch (enemy.id) {
      'hunt_captain' => 'assets/images/enemies/cavalry.png',
      'forest_warlord' => 'assets/images/enemies/skirmisher.png',
      'frost_castellan' => 'assets/images/enemies/frost_elite.png',
      'dusk_general' => 'assets/images/enemies/warlord.png',
      _ => 'assets/images/enemies/commander.png',
    };
  }
  if (enemy.role == UnitRole.commander) {
    return 'assets/images/enemies/commander.png';
  }
  if (enemy.rank == EnemyRank.elite) {
    return switch (enemy.role) {
      UnitRole.archer => 'assets/images/enemies/archer.png',
      UnitRole.cavalry => 'assets/images/enemies/cavalry.png',
      UnitRole.mage =>
        enemy.faction == EnemyFaction.cinderCoven
            ? 'assets/images/enemies/mage.png'
            : 'assets/images/enemies/frost_elite.png',
      UnitRole.siege => 'assets/images/enemies/siege.png',
      UnitRole.shield => 'assets/images/enemies/frost_elite.png',
      _ => 'assets/images/enemies/skirmisher.png',
    };
  }
  if (enemy.ability == EnemyAbility.flank ||
      enemy.ability == EnemyAbility.huntMark) {
    return 'assets/images/enemies/skirmisher.png';
  }
  return switch (enemy.role) {
    UnitRole.archer => 'assets/images/enemies/archer.png',
    UnitRole.cavalry => 'assets/images/enemies/cavalry.png',
    UnitRole.mage => 'assets/images/enemies/mage.png',
    UnitRole.siege => 'assets/images/enemies/siege.png',
    UnitRole.shield => 'assets/images/enemies/frost_elite.png',
    _ => 'assets/images/enemies/infantry.png',
  };
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
  'mira' => Icons.medical_services_outlined,
  'garr' => Icons.shield_outlined,
  'talia' => Icons.inventory_2_outlined,
  'fenn' => Icons.forward_to_inbox_outlined,
  'elka' => Icons.engineering_outlined,
  'soren' => Icons.travel_explore,
  'corva' => Icons.mark_email_unread_outlined,
  'silas' => Icons.local_shipping_outlined,
  _ => _weaponVisuals[id]?.icon ?? Icons.auto_awesome,
};
