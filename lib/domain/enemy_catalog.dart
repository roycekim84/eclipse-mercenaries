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

  static const forestWarlord = <BossPatternSpec>[
    BossPatternSpec(
      type: BossPatternType.chargeLine,
      name: '수림 매복참',
      warning: '안개 속 돌진선을 벗어나십시오.',
      telegraphSeconds: 1.3,
    ),
    BossPatternSpec(
      type: BossPatternType.bombardment,
      name: '독안개 덫',
      warning: '초록 표식 지대를 피하십시오.',
      telegraphSeconds: 1.6,
    ),
    BossPatternSpec(
      type: BossPatternType.commandWave,
      name: '약탈대 호출',
      warning: '검은숲 측면 증원이 진입합니다.',
      telegraphSeconds: 1.25,
    ),
  ];

  static const frostCastellan = <BossPatternSpec>[
    BossPatternSpec(
      type: BossPatternType.bombardment,
      name: '백야 빙창진',
      warning: '빙결 원에서 이탈하십시오.',
      telegraphSeconds: 1.75,
    ),
    BossPatternSpec(
      type: BossPatternType.chargeLine,
      name: '빙벽 돌파',
      warning: '푸른 돌진선을 피하십시오.',
      telegraphSeconds: 1.45,
    ),
    BossPatternSpec(
      type: BossPatternType.commandWave,
      name: '설원 수비령',
      warning: '빙벽 성기사단이 집결합니다.',
      telegraphSeconds: 1.35,
    ),
  ];

  static const duskGeneral = <BossPatternSpec>[
    BossPatternSpec(
      type: BossPatternType.bombardment,
      name: '황혼 유성포',
      warning: '포격 표적에서 벗어나십시오.',
      telegraphSeconds: 1.55,
    ),
    BossPatternSpec(
      type: BossPatternType.chargeLine,
      name: '혈화 참진',
      warning: '붉은 참격로를 피하십시오.',
      telegraphSeconds: 1.25,
    ),
    BossPatternSpec(
      type: BossPatternType.commandWave,
      name: '잿불 총공세',
      warning: '교단 정예대가 진입합니다.',
      telegraphSeconds: 1.3,
    ),
  ];

  static List<BossPatternSpec> forBoss(String bossId) => switch (bossId) {
    'hunt_captain' => huntCaptain,
    'forest_warlord' => forestWarlord,
    'frost_castellan' => frostCastellan,
    'dusk_general' => duskGeneral,
    _ => siegeMarshal,
  };
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
  EnemyArchetypeSpec(
    id: 'vargar_crossbow',
    name: '제국 쇠뇌수',
    faction: EnemyFaction.vargarEmpire,
    rank: EnemyRank.common,
    role: UnitRole.archer,
    ability: EnemyAbility.volley,
    abilityDescription: '느리지만 방패를 관통하는 일제 사격을 가한다.',
    lore: '요새 수비를 위해 쇠뇌 운용을 익힌 제국 사수.',
    hpBonus: 1,
    damageBonus: 1,
    defenseBonus: 2,
    speedMultiplier: .88,
  ),
  EnemyArchetypeSpec(
    id: 'cinder_hound',
    name: '잿불 사냥견',
    faction: EnemyFaction.cinderCoven,
    rank: EnemyRank.common,
    role: UnitRole.cavalry,
    ability: EnemyAbility.charge,
    abilityDescription: '불붙은 돌진으로 플레이어를 집요하게 추격한다.',
    lore: '교단의 화로에서 길들인 전투 마물.',
    hpBonus: 1,
    damageBonus: 1,
    defenseBonus: 0,
    speedMultiplier: 1.22,
  ),
  EnemyArchetypeSpec(
    id: 'bone_warder',
    name: '골편 수호병',
    faction: EnemyFaction.cinderCoven,
    rank: EnemyRank.common,
    role: UnitRole.shield,
    ability: EnemyAbility.brace,
    abilityDescription: '뼈 방패를 세워 마법과 투사체 피해를 버틴다.',
    lore: '전사자의 유골로 갑주를 만든 교단 방패병.',
    hpBonus: 4,
    damageBonus: 0,
    defenseBonus: 14,
    speedMultiplier: .86,
  ),
  EnemyArchetypeSpec(
    id: 'free_bowman',
    name: '회색단 궁수',
    faction: EnemyFaction.freeBlades,
    rank: EnemyRank.common,
    role: UnitRole.archer,
    ability: EnemyAbility.flank,
    abilityDescription: '측면으로 이동해 호위 대상의 빈틈을 노린다.',
    lore: '값을 더 부르는 쪽으로 활을 돌리는 용병 사수.',
    hpBonus: 0,
    damageBonus: 1,
    defenseBonus: 0,
    speedMultiplier: 1.08,
  ),
  EnemyArchetypeSpec(
    id: 'fog_stalker',
    name: '안개 추적자',
    faction: EnemyFaction.freeBlades,
    rank: EnemyRank.common,
    role: UnitRole.infantry,
    ability: EnemyAbility.huntMark,
    abilityDescription: '안개 속에서 플레이어에게 추적 표식을 남긴다.',
    lore: '검은숲의 지형과 냄새를 읽는 현지 길잡이.',
    hpBonus: 0,
    damageBonus: 2,
    defenseBonus: 1,
    speedMultiplier: 1.18,
  ),
  EnemyArchetypeSpec(
    id: 'frost_mage',
    name: '백야 서리술사',
    faction: EnemyFaction.vargarEmpire,
    rank: EnemyRank.common,
    role: UnitRole.mage,
    ability: EnemyAbility.hex,
    abilityDescription: '빙결 마법으로 이동과 공격 리듬을 늦춘다.',
    lore: '설원 요새의 혹한을 무기로 다루는 종군 마도사.',
    hpBonus: 2,
    damageBonus: 1,
    defenseBonus: 4,
    speedMultiplier: .9,
  ),
  EnemyArchetypeSpec(
    id: 'chain_rider',
    name: '사슬 기병',
    faction: EnemyFaction.freeBlades,
    rank: EnemyRank.common,
    role: UnitRole.cavalry,
    ability: EnemyAbility.flank,
    abilityDescription: '사슬창으로 호위 행렬을 끌어내려 한다.',
    lore: '철수전을 전문으로 방해하는 약탈 기병.',
    hpBonus: 3,
    damageBonus: 1,
    defenseBonus: 3,
    speedMultiplier: 1.15,
  ),
  EnemyArchetypeSpec(
    id: 'siege_alchemist',
    name: '공성 연금병',
    faction: EnemyFaction.cinderCoven,
    rank: EnemyRank.common,
    role: UnitRole.siege,
    ability: EnemyAbility.blast,
    abilityDescription: '부식 화약으로 목표물의 방어를 깎는다.',
    lore: '교단과 제국 사이에서 화약 비법을 파는 연금술사.',
    hpBonus: 5,
    damageBonus: 3,
    defenseBonus: 5,
    speedMultiplier: .82,
  ),
  EnemyArchetypeSpec(
    id: 'blackforest_reaver',
    name: '검은숲 약탈귀',
    faction: EnemyFaction.freeBlades,
    rank: EnemyRank.elite,
    role: UnitRole.infantry,
    ability: EnemyAbility.flank,
    abilityDescription: '짙은 안개를 타고 후열을 연속 습격한다.',
    lore: '숲을 통과한 보급대를 단 한 번도 놓치지 않은 약탈자.',
    hpBonus: 22,
    damageBonus: 4,
    defenseBonus: 14,
    speedMultiplier: 1.2,
    rareDropId: 'veteran_badge',
  ),
  EnemyArchetypeSpec(
    id: 'frost_paladin',
    name: '빙벽 성기사',
    faction: EnemyFaction.vargarEmpire,
    rank: EnemyRank.elite,
    role: UnitRole.shield,
    ability: EnemyAbility.riposte,
    abilityDescription: '방패로 공격을 받아낸 뒤 강하게 반격한다.',
    lore: '백야 설원 요새에 맹세한 북방의 수호 기사.',
    hpBonus: 30,
    damageBonus: 3,
    defenseBonus: 28,
    speedMultiplier: .86,
    rareDropId: 'tempered_iron',
  ),
  EnemyArchetypeSpec(
    id: 'cinder_witch',
    name: '회진 마녀',
    faction: EnemyFaction.cinderCoven,
    rank: EnemyRank.elite,
    role: UnitRole.mage,
    ability: EnemyAbility.bloodNova,
    abilityDescription: '연속 폭발로 밀집한 아군 진형을 해체한다.',
    lore: '재가 된 전우의 기억을 주문으로 태우는 마녀.',
    hpBonus: 20,
    damageBonus: 5,
    defenseBonus: 10,
    speedMultiplier: 1.0,
    rareDropId: 'red_moon_shard',
  ),
  EnemyArchetypeSpec(
    id: 'grey_duelist',
    name: '회색단 결투관',
    faction: EnemyFaction.freeBlades,
    rank: EnemyRank.elite,
    role: UnitRole.cavalry,
    ability: EnemyAbility.riposte,
    abilityDescription: '플레이어를 지목해 고속 연속 공격을 펼친다.',
    lore: '계약보다 자신의 결투 기록을 중시하는 위험한 용병.',
    hpBonus: 24,
    damageBonus: 5,
    defenseBonus: 18,
    speedMultiplier: 1.16,
    rareDropId: 'nameless_spur',
  ),
  EnemyArchetypeSpec(
    id: 'forest_warlord',
    name: '수림장군 발테르',
    faction: EnemyFaction.freeBlades,
    rank: EnemyRank.boss,
    role: UnitRole.commander,
    ability: EnemyAbility.huntMark,
    abilityDescription: '안개 매복대와 약탈 기병을 연속 지휘한다.',
    lore: '검은숲의 모든 샛길에 현상금을 건 약탈 군주.',
    hpBonus: 46,
    damageBonus: 6,
    defenseBonus: 25,
    speedMultiplier: 1.08,
    rareDropId: 'officer_map',
  ),
  EnemyArchetypeSpec(
    id: 'frost_castellan',
    name: '빙성주 에르카',
    faction: EnemyFaction.vargarEmpire,
    rank: EnemyRank.boss,
    role: UnitRole.commander,
    ability: EnemyAbility.commandSiege,
    abilityDescription: '빙벽과 서리 포격으로 요새 진입로를 봉쇄한다.',
    lore: '한겨울에도 성문을 연 적 없는 백야 요새의 성주.',
    hpBonus: 58,
    damageBonus: 6,
    defenseBonus: 36,
    speedMultiplier: .84,
    rareDropId: 'royal_writ',
  ),
  EnemyArchetypeSpec(
    id: 'dusk_general',
    name: '황혼대장 아그론',
    faction: EnemyFaction.cinderCoven,
    rank: EnemyRank.boss,
    role: UnitRole.commander,
    ability: EnemyAbility.bloodNova,
    abilityDescription: '황혼 포격과 혈마법으로 양군의 전열을 태운다.',
    lore: '전쟁이 길어질수록 강해진다는 잿불 교단의 전쟁 영웅.',
    hpBonus: 52,
    damageBonus: 7,
    defenseBonus: 28,
    speedMultiplier: .98,
    rareDropId: 'blood_ember',
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
