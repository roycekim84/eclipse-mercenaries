import 'battle_models.dart';

enum EnemyRank { common, elite, boss }

enum EnemyFaction { vargarEmpire, cinderCoven, freeBlades }

enum EnemyAbility {
  none,
  brace,
  volley,
  charge,
  hex,
  breach,
  flank,
  blast,
  riposte,
  bloodNova,
  commandSiege,
  huntMark,
}

enum BossPatternType { chargeLine, bombardment, commandWave }

class BossPatternSpec {
  const BossPatternSpec({
    required this.type,
    required this.name,
    required this.warning,
    required this.telegraphSeconds,
  });

  final BossPatternType type;
  final String name;
  final String warning;
  final double telegraphSeconds;
}

class BossTelegraph {
  const BossTelegraph({
    required this.bossName,
    required this.pattern,
    required this.phase,
    required this.secondsLeft,
  });

  final String bossName;
  final BossPatternSpec pattern;
  final int phase;
  final double secondsLeft;
}

abstract final class BossPatternCatalog {
  static const siegeMarshal = <BossPatternSpec>[
    BossPatternSpec(
      type: BossPatternType.chargeLine,
      name: '파성 돌진',
      warning: '붉은 진로를 벗어나십시오.',
      telegraphSeconds: 1.45,
    ),
    BossPatternSpec(
      type: BossPatternType.bombardment,
      name: '흑철 포격',
      warning: '표적 원에서 이탈하십시오.',
      telegraphSeconds: 1.7,
    ),
    BossPatternSpec(
      type: BossPatternType.commandWave,
      name: '공성 총동원',
      warning: '공성 증원대가 진입합니다.',
      telegraphSeconds: 1.25,
    ),
  ];

  static const huntCaptain = <BossPatternSpec>[
    BossPatternSpec(
      type: BossPatternType.bombardment,
      name: '사냥 표식',
      warning: '표식이 고정되기 전에 이동하십시오.',
      telegraphSeconds: 1.55,
    ),
    BossPatternSpec(
      type: BossPatternType.chargeLine,
      name: '회색 섬광',
      warning: '돌진 궤도를 피하십시오.',
      telegraphSeconds: 1.2,
    ),
    BossPatternSpec(
      type: BossPatternType.commandWave,
      name: '추격대 호출',
      warning: '호위대 측면에 증원이 도착합니다.',
      telegraphSeconds: 1.3,
    ),
  ];

  static List<BossPatternSpec> forBoss(String bossId) =>
      bossId == 'hunt_captain' ? huntCaptain : siegeMarshal;
}

class EnemyArchetypeSpec {
  const EnemyArchetypeSpec({
    required this.id,
    required this.name,
    required this.faction,
    required this.rank,
    required this.role,
    required this.ability,
    required this.abilityDescription,
    required this.lore,
    required this.hpBonus,
    required this.damageBonus,
    required this.defenseBonus,
    required this.speedMultiplier,
    this.rareDropId,
  });

  final String id;
  final String name;
  final EnemyFaction faction;
  final EnemyRank rank;
  final UnitRole role;
  final EnemyAbility ability;
  final String abilityDescription;
  final String lore;
  final int hpBonus;
  final int damageBonus;
  final int defenseBonus;
  final double speedMultiplier;
  final String? rareDropId;
}

const alphaEnemyArchetypes = <EnemyArchetypeSpec>[
  EnemyArchetypeSpec(
    id: 'vargar_conscript',
    name: '바르가르 징집병',
    faction: EnemyFaction.vargarEmpire,
    rank: EnemyRank.common,
    role: UnitRole.infantry,
    ability: EnemyAbility.none,
    abilityDescription: '밀집 대형으로 전선을 압박한다.',
    lore: '정복지에서 강제로 징집된 제국의 가장 흔한 보병.',
    hpBonus: 0,
    damageBonus: 0,
    defenseBonus: 0,
    speedMultiplier: 1,
  ),
  EnemyArchetypeSpec(
    id: 'iron_guard',
    name: '흑철 방패병',
    faction: EnemyFaction.vargarEmpire,
    rank: EnemyRank.common,
    role: UnitRole.shield,
    ability: EnemyAbility.brace,
    abilityDescription: '흑철 방패로 받는 피해를 추가로 경감한다.',
    lore: '황실 제철소의 흑철 방패로 진격로를 닫는 중장보병.',
    hpBonus: 3,
    damageBonus: 0,
    defenseBonus: 18,
    speedMultiplier: .9,
  ),
  EnemyArchetypeSpec(
    id: 'vargar_longbow',
    name: '제국 장궁병',
    faction: EnemyFaction.vargarEmpire,
    rank: EnemyRank.common,
    role: UnitRole.archer,
    ability: EnemyAbility.volley,
    abilityDescription: '세 번째 사격이 더 큰 피해를 준다.',
    lore: '북부 주둔군에서 차출된 장거리 제압 사수.',
    hpBonus: 0,
    damageBonus: 0,
    defenseBonus: 0,
    speedMultiplier: .95,
  ),
  EnemyArchetypeSpec(
    id: 'black_lancer',
    name: '흑기창 기병',
    faction: EnemyFaction.vargarEmpire,
    rank: EnemyRank.common,
    role: UnitRole.cavalry,
    ability: EnemyAbility.charge,
    abilityDescription: '첫 근접 공격이 강화된 돌격 피해를 준다.',
    lore: '검은 장창으로 방어선의 틈을 노리는 제국 경기병.',
    hpBonus: 2,
    damageBonus: 1,
    defenseBonus: 4,
    speedMultiplier: 1.12,
  ),
  EnemyArchetypeSpec(
    id: 'cinder_hexer',
    name: '잿불 주술병',
    faction: EnemyFaction.cinderCoven,
    rank: EnemyRank.common,
    role: UnitRole.mage,
    ability: EnemyAbility.hex,
    abilityDescription: '범위 공격으로 대상의 이동을 둔화한다.',
    lore: '재와 뼛가루로 전장의 원한을 불러내는 종군 술사.',
    hpBonus: 1,
    damageBonus: 1,
    defenseBonus: 2,
    speedMultiplier: .94,
  ),
  EnemyArchetypeSpec(
    id: 'siege_ram',
    name: '철갑 파성추',
    faction: EnemyFaction.vargarEmpire,
    rank: EnemyRank.common,
    role: UnitRole.siege,
    ability: EnemyAbility.breach,
    abilityDescription: '성문과 호위 대상에 추가 피해를 준다.',
    lore: '흑철 머리를 씌운 제국 공성대의 이동식 파성추.',
    hpBonus: 8,
    damageBonus: 3,
    defenseBonus: 12,
    speedMultiplier: .78,
  ),
  EnemyArchetypeSpec(
    id: 'free_skirmisher',
    name: '회색단 척후병',
    faction: EnemyFaction.freeBlades,
    rank: EnemyRank.common,
    role: UnitRole.infantry,
    ability: EnemyAbility.flank,
    abilityDescription: '빠르게 플레이어와 호위 행렬의 측면을 노린다.',
    lore: '전황을 따라 고용주를 바꾸는 독립 용병단의 척후병.',
    hpBonus: -1,
    damageBonus: 1,
    defenseBonus: -2,
    speedMultiplier: 1.28,
  ),
  EnemyArchetypeSpec(
    id: 'powder_sapper',
    name: '화약 공병',
    faction: EnemyFaction.freeBlades,
    rank: EnemyRank.common,
    role: UnitRole.siege,
    ability: EnemyAbility.blast,
    abilityDescription: '목표 공격 시 폭발 피해를 가한다.',
    lore: '채굴용 화약을 공성 무기로 전용한 위험한 기술자.',
    hpBonus: -5,
    damageBonus: 2,
    defenseBonus: -8,
    speedMultiplier: 1.16,
  ),
  EnemyArchetypeSpec(
    id: 'nameless_knight',
    name: '이름 없는 기사',
    faction: EnemyFaction.vargarEmpire,
    rank: EnemyRank.elite,
    role: UnitRole.cavalry,
    ability: EnemyAbility.riposte,
    abilityDescription: '높은 방어력과 빠른 연속 공격을 사용한다.',
    lore: '휘장을 버리고 전공만을 좇는 제국의 추방 기사.',
    hpBonus: 24,
    damageBonus: 4,
    defenseBonus: 22,
    speedMultiplier: 1.08,
    rareDropId: 'nameless_spur',
  ),
  EnemyArchetypeSpec(
    id: 'blood_cantor',
    name: '혈송 사제',
    faction: EnemyFaction.cinderCoven,
    rank: EnemyRank.elite,
    role: UnitRole.mage,
    ability: EnemyAbility.bloodNova,
    abilityDescription: '공격할 때 주변 대상에게 마법 피해를 전파한다.',
    lore: '전사자의 마지막 숨을 노래로 엮는 잿불 교단의 사제.',
    hpBonus: 18,
    damageBonus: 3,
    defenseBonus: 12,
    speedMultiplier: .92,
    rareDropId: 'blood_ember',
  ),
  EnemyArchetypeSpec(
    id: 'siege_marshal',
    name: '공성군감 드라벤',
    faction: EnemyFaction.vargarEmpire,
    rank: EnemyRank.boss,
    role: UnitRole.commander,
    ability: EnemyAbility.commandSiege,
    abilityDescription: '주변 공성 병력의 공격 주기와 이동속도를 강화한다.',
    lore: '일곱 요새를 함락한 바르가르 제국의 노련한 공성 지휘관.',
    hpBonus: 48,
    damageBonus: 5,
    defenseBonus: 30,
    speedMultiplier: .88,
    rareDropId: 'marshal_seal',
  ),
  EnemyArchetypeSpec(
    id: 'hunt_captain',
    name: '추격대장 모르바',
    faction: EnemyFaction.freeBlades,
    rank: EnemyRank.boss,
    role: UnitRole.commander,
    ability: EnemyAbility.huntMark,
    abilityDescription: '호위 대상을 노리는 추격병의 이동속도를 강화한다.',
    lore: '놓친 표적이 없다는 회색단의 냉혹한 추격대장.',
    hpBonus: 40,
    damageBonus: 6,
    defenseBonus: 22,
    speedMultiplier: 1.12,
    rareDropId: 'hunter_insignia',
  ),
];

abstract final class EnemyCatalog {
  static final List<EnemyArchetypeSpec> common = List.unmodifiable(
    alphaEnemyArchetypes.where((enemy) => enemy.rank == EnemyRank.common),
  );

  static final List<EnemyArchetypeSpec> elite = List.unmodifiable(
    alphaEnemyArchetypes.where((enemy) => enemy.rank == EnemyRank.elite),
  );

  static final List<EnemyArchetypeSpec> boss = List.unmodifiable(
    alphaEnemyArchetypes.where((enemy) => enemy.rank == EnemyRank.boss),
  );

  static EnemyArchetypeSpec byId(String id) =>
      alphaEnemyArchetypes.firstWhere((enemy) => enemy.id == id);
}
