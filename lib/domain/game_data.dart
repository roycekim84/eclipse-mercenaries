enum CombatStyle { blades, greatsword, magic }

class MercenarySpec {
  const MercenarySpec({
    required this.id,
    required this.name,
    required this.epithet,
    required this.race,
    required this.job,
    required this.trait,
    required this.traitDescription,
    required this.level,
    required this.power,
    required this.maxHp,
    required this.speed,
    required this.attackInterval,
    required this.baseDamage,
    required this.style,
    required this.signatureWeaponId,
    required this.ultimate,
  });

  final String id;
  final String name;
  final String epithet;
  final String race;
  final String job;
  final String trait;
  final String traitDescription;
  final int level;
  final int power;
  final int maxHp;
  final double speed;
  final double attackInterval;
  final int baseDamage;
  final CombatStyle style;
  final String signatureWeaponId;
  final String ultimate;
}

class WeaponSpec {
  const WeaponSpec({
    required this.id,
    required this.name,
    required this.grade,
    required this.attack,
    required this.crit,
    required this.speed,
    required this.description,
    this.ownerId,
  });

  final String id;
  final String name;
  final String grade;
  final int attack;
  final int crit;
  final int speed;
  final String description;
  final String? ownerId;
}

const alphaMercenaries = <MercenarySpec>[
  MercenarySpec(
    id: 'luna',
    name: '루나 벨하르트',
    epithet: '달빛의 그림자',
    race: '묘족',
    job: '암살자',
    trait: '야행성',
    traitDescription: '어두운 전장에서 공격속도 20%, 치명타 확률 15% 증가',
    level: 45,
    power: 28450,
    maxHp: 1320,
    speed: 160,
    attackInterval: .42,
    baseDamage: 2,
    style: CombatStyle.blades,
    signatureWeaponId: 'moon_blades',
    ultimate: '월식 · 백야난무',
  ),
  MercenarySpec(
    id: 'kael',
    name: '카일 로젠팽',
    epithet: '피 묻은 선봉',
    race: '늑대족',
    job: '검투사',
    trait: '사냥의 고양',
    traitDescription: '연속 처치마다 공격력이 상승하며 체력이 소량 회복',
    level: 42,
    power: 26920,
    maxHp: 1680,
    speed: 135,
    attackInterval: .62,
    baseDamage: 3,
    style: CombatStyle.greatsword,
    signatureWeaponId: 'blood_fang',
    ultimate: '혈월 · 야수해방',
  ),
  MercenarySpec(
    id: 'sera',
    name: '세라 이나리온',
    epithet: '유리불꽃 술사',
    race: '여우족',
    job: '환술사',
    trait: '여우불 장막',
    traitDescription: '상태이상에 걸린 적에게 마법 피해 25% 증가',
    level: 40,
    power: 25840,
    maxHp: 1110,
    speed: 145,
    attackInterval: .55,
    baseDamage: 2,
    style: CombatStyle.magic,
    signatureWeaponId: 'glass_flame',
    ultimate: '천화 · 몽환구미진',
  ),
];

const alphaWeapons = <WeaponSpec>[
  WeaponSpec(
    id: 'moon_blades',
    name: '월광쌍검',
    grade: '전설',
    attack: 1285,
    crit: 18,
    speed: 14,
    description: '치명타 발생 시 40% 확률로 추가 참격',
    ownerId: 'luna',
  ),
  WeaponSpec(
    id: 'blood_fang',
    name: '혈아대검',
    grade: '전설',
    attack: 1510,
    crit: 9,
    speed: -5,
    description: '연속 처치 시 공격 범위와 흡혈량 증가',
    ownerId: 'kael',
  ),
  WeaponSpec(
    id: 'glass_flame',
    name: '유리불꽃 지팡이',
    grade: '전설',
    attack: 1190,
    crit: 13,
    speed: 8,
    description: '투사체가 적 사이를 두 번 도약',
    ownerId: 'sera',
  ),
  WeaponSpec(
    id: 'iron_sword',
    name: '용병단 철검',
    grade: '희귀',
    attack: 720,
    crit: 5,
    speed: 3,
    description: '정직하고 안정적인 전장용 장검',
  ),
  WeaponSpec(
    id: 'war_bow',
    name: '철각 전궁',
    grade: '희귀',
    attack: 650,
    crit: 12,
    speed: 6,
    description: '먼 거리 적을 우선 공격',
  ),
  WeaponSpec(
    id: 'ember_orb',
    name: '잔불 보주',
    grade: '영웅',
    attack: 880,
    crit: 8,
    speed: 10,
    description: '일정 확률로 작은 폭발 발생',
  ),
  WeaponSpec(
    id: 'guard_spear',
    name: '수문장 장창',
    grade: '희귀',
    attack: 790,
    crit: 4,
    speed: 0,
    description: '공격 범위가 크게 증가',
  ),
  WeaponSpec(
    id: 'shadow_knife',
    name: '그림자 투척검',
    grade: '영웅',
    attack: 830,
    crit: 16,
    speed: 12,
    description: '낮은 확률로 관통 투척검 발사',
  ),
];
