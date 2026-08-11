# 기술 아키텍처

## 플랫폼 표시 방향

- Web은 임베드와 반응형 테스트를 위해 브라우저 방향을 강제하지 않는다.
- iOS/Android는 앱 시작 전 `MobileOrientation.apply()`로 Landscape Left/Right만 요청한다.
- Android Manifest는 게임 카테고리와 `sensorLandscape`를 선언한다.
- iOS Info.plist는 iPhone/iPad 모두 두 가로 방향만 선언하고 iPad 전체 화면을 요구한다.
- 런타임 요청과 네이티브 선언을 함께 유지해 Flutter 첫 프레임 전후의 세로 노출과 회전 불일치를 줄인다.

## 1. 목표

- Flutter 메뉴 UI와 Flame 전투의 책임을 명확히 분리한다.
- Web, iOS, Android에서 동일한 게임 규칙을 사용한다.
- 500~1,000 유닛을 위한 데이터 지향 구조를 유지한다.
- 콘텐츠 추가가 화면/전투 코드 수정에 과도하게 의존하지 않게 한다.
- 런 상태와 영구 상태를 분리해 저장과 보상 중복 버그를 방지한다.

## 2. 현재 상태

- `main.dart`: 앱 부팅만 담당하는 9줄 진입점
- `app/game_app.dart`: 앱 구성, 화면 상태와 기능 화면 조합
- `core/theme/game_theme.dart`: 공통 팔레트와 Flutter 테마
- `core/content/game_content_repository.dart`: 콘텐츠 조회 인터페이스와 알파 정적 구현
- `core/content/game_visuals.dart`: 용병/무기의 색상, 아이콘, 이미지 경로
- `core/persistence/save_repository.dart`: versioned 계정 저장 모델과 저장 인터페이스
- `domain/progression.dart`: 용병 레벨·승급, 무기 영구 레벨·단계와 성장 영수증 규칙
- `core/widgets`: 판타지 패널, 버튼, 카드, 상태 표시와 지도 painter
- `features`: 캠프, 계약/출전, 장비, 전투 HUD, 용병, 결과 화면
- `domain/game_data.dart`: Flutter 의존성이 없는 용병과 무기 규칙 데이터
- `domain/battle_models.dart`: BattleConfig, BattleStats, BattleReport와 전투 오버레이 모델
- `domain/run_growth.dart`: 런 성장 상태, 선택 유효성, 가중치 비복원 추출 순수 규칙
- `domain/enemy_catalog.dart`: 8 일반·2 정예·2 보스 원형, 세력·능력·드롭 데이터
- `domain/battlefield_events.dart`: 8종 사건 정의, 선택 명세와 결정론적 가중치 추출 규칙
- `domain/battle_rewards.dart`: 보상 출처별 계산, 결과 보존율, loot table과 MVP 순수 규칙
- `domain/spatial_hash_benchmark.dart`: 전장과 같은 96px 그리드/인접 셀 탐색의 결정론적 CPU 성능 하네스
- `game/survivor_game.dart`: 전투 세션 조합, 이동, 자동 공격, 경험치, 레벨업, 사건
- `game/systems/run_growth_system.dart`: 다중 무기 타이머, 선택 적용과 HUD 빌드 스냅샷
- `game/systems/gate_defense_system.dart`: 성문 목표, 진영 배치, 공성 피해, 승패/결과
- `game/systems/evacuation_system.dart`: 호위 행렬, 탈출 경로, 추격 AI와 철수전 렌더
- `game/systems/unit_ai_system.dart`: 병과별 탐색·공격·대형·지원·후퇴 AI
- `game/systems/damage_system.dart`: 공통 피해·치명타·상태이상·사망 반영
- `game/systems/weapon_system.dart`: 8종 무기 대상 선정과 공격 패턴
- `game/systems/pooled_effects_system.dart`: 투사체·VFX·대미지 숫자 풀과 렌더
- `game/systems/battlefield_event_system.dart`: 사건 시계, 전투 정지, 선택 효과와 증원 생성

앱/도메인/게임 런타임 경계와 기능별 화면 분리가 완료됐다. 화면 파일은 Dart library part로 묶어 현재 비공개 상태 경계를 유지하며, 기능이 커질 때 독립 public widget library로 전환한다.

한국어 UI는 네트워크 런타임 폰트 대신 `assets/fonts`의 Noto Sans KR 400/700 서브셋을 사용한다. 영문 대형 제목은 Cinzel을 사용한다. 알파 서브셋은 현재 Dart 소스의 한글 글리프와 기본 Latin/문장부호를 포함하며 `tool/update_font_assets.sh`가 고정된 Google Fonts revision에서 재생성한다. 이 구조로 Web/iOS/Android와 Golden 테스트의 글꼴 메트릭을 일치시킨다.

## 3. 목표 레이어

```text
Presentation (Flutter)
  ↓ user intents / view state
Application
  ↓ use cases / commands
Domain
  ↓ models / rules / repository interfaces
Infrastructure
  ↓ local save / asset loading / platform adapters

Battle Runtime (Flame)
  ← BattleConfig
  → BattleReport
```

### Presentation

화면, 오버레이, 애니메이션, 반응형 레이아웃, semantics를 담당한다. 전투 피해 공식이나 드롭 규칙을 소유하지 않는다.

### Application

계약 수락, 장비 장착, 전투 시작, 결과 반영, 성장 구매 같은 유스케이스를 담당한다. 재화 차감과 보상 반영은 여기서 원자적으로 처리한다.

### Domain

용병, 무기, 계약, 사건, 저장 상태의 불변 모델과 순수 계산을 담당한다. 가능한 한 Flutter/Flame import 없이 테스트 가능해야 한다.

### Infrastructure

로컬 저장, 자산 경로, 플랫폼 기능, 오디오, 분석 도구를 구현한다.

### Battle Runtime

한 번의 전투 세션에 필요한 일시 상태만 가진다. 영구 재화를 직접 수정하지 않고 결과 보고서만 반환한다.

## 4. 목표 폴더 구조

`IMPLEMENTATION_PLAN.md`의 구조를 기준으로 하며 세부 원칙은 다음과 같다.

- 기능 UI는 `features/<feature>/presentation`
- 유스케이스는 `features/<feature>/application`
- 공통 도메인은 `core/domain`
- Flame 시스템은 `game/systems`
- 대량 유닛 데이터와 렌더는 `game/world`, `game/render`
- 콘텐츠 정의는 `assets/data` 또는 컴파일된 repository

## 5. 앱 상태

```text
AccountState
├── currencies
├── ownedMercenaries
├── ownedWeapons
├── progression
├── missions
└── settings

LoadoutState
├── selectedMercenaryId
├── equippedWeaponId
└── consumables

BattleSessionState
├── runLevel / xp
├── playerHp
├── activeUnits
├── objectives
├── events
└── runBuild
```

`BattleSessionState`는 저장 대상 영구 상태에 직접 포함하지 않는다. 앱 종료 복구를 지원할 경우 별도 임시 스냅샷으로 관리한다.

## 6. Flutter와 Flame 통신

### 시작

Flutter Application 계층이 선택 상태와 영구 능력치 스냅샷을 검증해 `BattleConfig`를 생성한다. Flame은 ID 조회가 완료된 불변 설정만 전달받는다.

### 진행

Flame은 HUD용 읽기 전용 `ValueNotifier` 또는 명시적인 상태 스트림을 제공한다. Flutter 오버레이는 사용자 선택을 command로 Flame에 전달한다.

### 종료

Flame은 `BattleReport`를 한 번만 발행한다. Flutter가 결과를 검증하고 보상 적용/저장을 완료한 뒤 결과 화면을 표시한다.

M3.4에서는 `RewardBreakdown`, `LootDrop`, `BattleAward`를 `BattleReport`의 불변 결과로 전달한다. 앱 셸의 `_rewardApplied` guard가 같은 전투 결과의 중복 반영을 막고, 재출전 시에만 새 보상 세션을 연다. M4.1에서 이 경계를 transaction ID와 영구 inventory 저장으로 확장한다.

### 궁극기 시퀀스

- Flame은 `BattleStats.ultimateCharge`와 `ultimateEnabled`를 HUD에 발행한다.
- Flutter는 Ready 입력을 command로 전달하고 `UltimateSequence`를 받아 컷인을 표시한다.
- 컷인 중 Flame 엔진을 완전히 정지하고 UI 애니메이션만 실제 시간으로 재생한다.
- 충격 시점의 피해·사망·경험치는 Flame이 처리하고 Flutter는 연출 상태만 소유한다.
- 저사양 모드는 피해 대상 수를 바꾸지 않고 동시 Slash/VFX 인스턴스만 제한한다.
- `MercenarySpec.ultimatePattern`은 8명 전용 대상 선정, 피해 횟수, 상태이상·회복·목표 보호와 Canvas VFX를 결정한다. 전투 스타일 3종은 일반 공격 렌더에만 사용한다.

## 7. Flame 시스템

업데이트 순서:

1. InputSystem
2. EventTriggerSystem
3. ObjectiveSystem
4. AISystem
5. MovementSystem
6. SpatialIndexSystem
7. WeaponSystem
8. ProjectileSystem
9. DamageSystem
10. Death/Loot/ExperienceSystem
11. Animation/VfxSystem
12. BattleEndSystem

M2.1 구현에서는 `gate_defense_system.dart`가 진영별 초기 배치, 공성 목표 이동/공격, 성문 피해, 전선 침투율, 종료 판정과 월드 렌더링을 소유한다. `GateDefenseRules`는 Flame과 분리된 도메인 규칙으로 승패와 보너스를 결정하며 단위 테스트에서 직접 검증한다.

M2.2 구현에서는 `UnitRoleRules`가 7병과의 HP·속도·사거리·피해를 순수 도메인 규칙으로 제공한다. `unit_ai_system.dart`는 공간 그리드의 근접 상대 질의만 사용해 역할 공격, 원거리 거리 확보, 8인 분대 대형, 180px 지휘 오라와 저체력 후퇴를 처리한다. `BattleUnit`은 Component를 만들지 않는 경량 데이터이며 동일 7×2 아틀라스를 `drawImageRect`로 렌더링한다. `BattleStats`와 `BattleReport`에는 지휘관 생존 상태만 전달해 Flutter HUD가 AI 내부 객체를 참조하지 않게 한다.

M2.3 구현에서는 `domain/combat_rules.dart`의 `DamageResolver`가 방어, 치명타, 피해 종류와 상태이상 판정을 순수 계산한다. 플레이어·병사·궁극기·지속 피해는 `damage_system.dart`를 통해 같은 HP/사망 경계를 사용한다. `WeaponPattern` 8종은 `weapon_system.dart`에서 즉시 타격, 직선 관통, 범위 타격 또는 풀링 투사체로 분기한다. 런타임은 투사체 64개, Slash/VFX 96개, 대미지 숫자 36개를 선할당하고 비활성 슬롯을 재사용한다.

M2.4 구현에서는 `RunGrowthRules`가 최대 레벨과 무기 슬롯을 먼저 검증한 뒤 가중치 비복원 추출로 중복 없는 3개 선택을 만든다. 선택 RNG는 `BattleConfig.seed ^ 0x5f3759df`로 생성해 전투 RNG 소비 순서가 레벨업 선택을 바꾸지 않게 한다. 런타임은 최대 4개 `RunWeaponState`에 독립 공격 타이머를 두고, `BattleStats.build`에는 UI가 안전하게 읽을 수 있는 ID·종류·레벨 스냅샷만 발행한다.

M3.1 구현에서는 `BattlefieldType`과 `BattlefieldCondition`을 `BattleConfig`에 포함해 목표와 환경을 세션 시작 전에 고정한다. `EvacuationRules`는 Flame과 무관하게 8명 탈출 승패와 보너스를 판정한다. 호위 대상은 Component가 아닌 12개 경량 데이터 객체로 관리하며, 기존 적 AI의 목표 분기만 확장한다. 프레임 시간은 최근 512개 표본을 고정 배열에 기록하고 `BattleReport`에 최대 활성 유닛과 P95를 전달한다.

계약의 `StageBalanceProfile`은 화면의 권장 전투력과 함께 `BattleConfig`에 복사된다. 전투 시간, 전체/초기/동시 활성 유닛 예산, 증원과 사건 간격, 적 HP·피해·속도 및 정예 밀도를 세션 시작 시 고정하므로 UI 난이도 표기와 Flame 런타임이 분리되지 않는다.

M3.2 구현에서는 `EnemyArchetypeSpec`이 병과 위에 체력·공격·방어·속도 보정과 고유 능력을 합성한다. `BattleUnit`은 원형 참조와 능력 카운터만 추가로 보유하며 별도 Component를 생성하지 않는다. 일반 적은 기존 아틀라스와 세력 tint를 재사용하고 정예/보스만 스케일·링·Canvas 문양을 추가한다. 희귀 드롭 ID는 사망 경계에서 중복 없이 수집해 `BattleReport.rareDropIds`로만 Flutter 결과 화면에 전달한다.

Flutter의 `BattleScreen`은 `WidgetsBindingObserver`로 background/inactive 상태를 Flame 정지 명령으로 변환한다. 사용자 정지와 lifecycle 정지를 별도 플래그로 관리해 앱 복귀가 사용자의 수동 정지를 해제하거나 레벨업 정지를 잘못 재개하지 않게 한다.

같은 프레임에서 시스템 순서가 바뀌어 결과가 달라지지 않도록 고정한다. 현재 수직 슬라이스는 피해와 사망을 공통 경계에서 즉시 반영하며, 다중 투사체 동시 충돌이 확대될 때 command buffer로 전환한다.

## 8. 대량 유닛 구조

개별 유닛마다 무거운 위젯이나 복잡한 Component 트리를 만들지 않는다.

권장 데이터:

- unitId
- archetypeId
- factionId
- position/velocity
- hp/maxHp
- targetId
- state/timers
- animationFrame
- flags

동일 타입 배열 또는 구조체 배열을 사용해 순차 접근을 유지한다. 죽은 유닛 슬롯은 free list로 재사용한다.

## 9. 공간 인덱스

- 기본 cell 크기: 근접/평균 공격 사거리에 맞춰 64~128 논리 픽셀
- 매 프레임 이동 유닛의 셀만 갱신하는 방식 검토
- 질의: 근접 적, 범위 피해, 투사체 충돌, 아군 밀집도
- 후보군을 얻은 뒤 정확 거리 계산
- 유닛 전체 상호 충돌은 수행하지 않는다.

밀집 회피는 완전한 물리 충돌 대신 주변 셀의 제한된 이웃으로 separation 벡터를 계산한다.

## 10. 렌더링

- 전장과 대량 유닛은 Flame Canvas/SpriteBatch 사용
- 동일 atlas 기준으로 정렬해 draw call 감소
- 화면 밖 유닛 렌더 생략
- 먼 유닛 애니메이션 프레임 감소
- VFX, 투사체, 대미지 숫자 풀링
- Flutter는 HUD/모달만 담당하고 대량 월드 요소를 위젯으로 만들지 않음

레이어 순서:

1. 지형
2. 목표 바닥 표시
3. 그림자/바닥 VFX
4. 유닛
5. 투사체
6. 공중 VFX
7. 월드 마커
8. Flutter HUD

## 11. 콘텐츠 데이터

표시 이름, 설명, 수치, 자산 경로를 코드 곳곳에 하드코딩하지 않는다.

Repository:

- MercenaryRepository
- WeaponRepository
- EnemyRepository
- BattlefieldRepository
- ContractRepository
- EventRepository
- LootTableRepository

콘텐츠 로딩 시 ID 중복, 누락 자산, 잘못된 참조, 범위 밖 수치를 검증한다. 릴리스 빌드 전에 콘텐츠 validation 테스트를 실행한다.

## 12. 저장

저장 루트:

```text
SaveGame
├── schemaVersion
├── createdAt / updatedAt
├── account
├── inventory
├── mercenaries
├── weapons
├── missions
└── settings
```

현재 schema v10의 실제 저장 필드는 `gold`, `crystals`, `warSeals`, `honor`, `selectedMercenaryId`, 용병별 장착 무기·방어구·장신구·전술 도구, 세력별 `factionReputation`, `operationProgress`, `mercenaryProgress`, `weaponProgress`, `inventory`, `claimedMissionIds`, `recruitmentCount`, `mercenaryCopies`, `shopPurchaseCounts`, `shopRefreshCount`, `settings`다. `JsonSaveRepository`는 JSON encode/decode와 순차 migration을 담당하고 `SharedPreferencesKeyValueStore`가 Web local storage 및 iOS/Android 플랫폼 저장소를 제공한다.

원칙:

- save schema version 필수
- 이전 버전 migration 테스트
- 보상 적용과 저장을 하나의 transaction처럼 처리
- 마지막 정상 저장 백업
- Web local storage와 모바일 파일 저장을 repository 뒤에서 교체
- 저장 실패 시 사용자에게 알리고 메모리 상태를 유지한 채 재시도

저장 순서는 기존 primary를 backup으로 복사한 뒤 새 primary를 기록한다. load는 primary→backup→initial 순서로 복구하며 backup을 사용한 경우 primary를 즉시 복원한다. UI와 테스트에서는 `MemoryKeyValueStore`를 주입해 플랫폼 plugin 없이 같은 repository 계약을 검증한다.

캠프 메타 동작은 `CampMetaRules`의 순수 조건/비용 계산을 거친 뒤 앱 셸에서 계정 스냅샷을 한 번 교체하고 자동 저장한다. 훈련은 골드·야전 식량을 용병 XP로, 담금질은 골드·전장 고철을 무기 XP로 변환한다. 제작/분해는 재료 수량을 원자적으로 교체하며 임무 수령 ID는 `claimedMissionIds`로 중복 지급을 막는다.

모집 순서와 상점 가격/한도는 `RecruitmentRules`, `ShopRules`에서 결정한다. 모집 결과 적용은 크리스탈/계약서 차감, 보유 사본 증가, 중복 증표 지급을 하나의 계정 스냅샷으로 저장한다. 상점 구매도 재화 차감, inventory 지급, 갱신별 구매 횟수 증가를 동시에 반영한다. 알파 로컬 빌드에는 결제 SDK와 실제 화폐 상품을 포함하지 않는다.

`GameSettings`는 첫 계약 안내 완료, 효과음, 진동, 화면 흔들림, 섬광 감소, 저사양 전투 모드, 큰 글자, 이동 입력 모드와 자동 표적 우선순위를 타입으로 보관한다. 앱 셸은 시스템 글자 배율과 앱 큰 글자 배율을 조합해 1.0~1.3 범위에서 렌더하고, 전투 설정은 세션 시작 시 Flutter 입력 계층과 Flame 표적 탐색에 각각 주입한다. schema v7은 기존 저장에 혼합 입력과 거리 우선 기본값을 추가하고 schema v8은 용병별 방어구·장신구·전술 도구 장착 ID, schema v9는 세력별 평판, schema v10은 작전 진행도를 추가한다. 앱 셸은 장착 ID를 `GearCombatBonus` 불변 스냅샷으로 계산해 `BattleConfig`에 전달하며 전투 결과에 따라 계약 세력 평판과 작전 진행도를 결정론적으로 갱신한다. 튜토리얼은 앱 셸 오버레이로 표시하며 완료 즉시 저장한다.

공통 `GameStatePanel`은 로딩·빈 목록·복구 가능한 오류의 제목, 설명, 행동 구조를 통일한다. 저장 실패는 메모리의 최신 계정 스냅샷을 유지하고 캠프/결과의 `StatusBanner`에서 같은 repository 저장을 다시 시도한다. 재시도 성공 시 오류를 제거하며 실패 시 사용자 행동이 가능한 안내를 유지한다.

## 13. 자산 로딩

- 캠프 진입: 공통 UI와 캠프 필수 자산
- 계약 화면: 지도와 계약 마커
- 출전 선택: 선택 가능한 용병 초상과 무기 아이콘
- 전투 로딩: 선택 전장 atlas, 출전 용병, 등장 가능한 적, VFX, 오디오
- 사용하지 않는 대형 일러스트는 전투 진입 전에 해제 가능성 검토

Web 초기 번들을 줄이기 위해 대형 일러스트와 전장별 자산의 지연 로딩을 우선한다.

## 14. 오디오

AudioService가 BGM, SFX, UI, voice 채널을 관리한다. 동시 재생 상한, 볼륨, mute, lifecycle pause/resume을 제공한다. 전투 시스템은 파일 경로가 아니라 sound event ID를 발생시킨다.

## 15. 결정론과 테스트

- 전투 시작 시 seed 저장
- 사건 선택, 드롭, 치명타가 동일 seed와 입력에서 재현 가능하도록 RNG 주입
- 전리품 RNG는 `seed ^ 0x7f4a7c15`로 분리하고 희귀도 정렬 후 결과 보존율을 적용한다.
- 시스템 시간을 직접 읽지 않고 GameClock 사용
- 고정 timestep 또는 상한이 있는 dt 처리
- 결과 보고서 snapshot 비교 가능
- 런 성장 RNG와 사건 RNG를 각각 `seed ^ 0x5f3759df`, `seed ^ 0x6c8e9cf5`로 분리해 한 시스템의 추출 횟수가 다른 시스템의 결과를 바꾸지 않는다.
- 발생 사건 ID와 선택 결과는 `BattleReport.eventRecords`로 Presentation에 전달하며 런타임이 계정 재화를 직접 수정하지 않는다.
- 캠프, 전쟁 계약, 결과 화면은 1280×720 DPR 1 Golden을 유지한다. Golden 하네스는 Noto Sans KR/Cinzel/Material Icons를 테스트 본문에서 명시적으로 로드하고 캠프 배경을 precache해 폰트·이미지 비동기 로딩 차이를 제거한다.

## 16. 성능 예산

`IMPLEMENTATION_PLAN.md`의 프레임 예산을 따른다.

추가 상한 초안:

- 활성 유닛: 알파 500, 스트레스 1,000
- 활성 투사체: 300
- 파티클: 화면 내 800
- 대미지 숫자: 40
- 동시 SFX voice: 24
- 전투 중 큰 이미지 decode 금지
- 프레임당 신규 객체 allocation 최소화

`ReusableSpatialGrid`는 한 번 생성한 96px 셀 버킷을 프레임 사이에 비우고 재사용한다. 전투와 `tool/performance_benchmark.dart`가 같은 구현을 사용하므로 벤치마크가 실제 런타임의 할당 특성을 반영한다. CPU 하네스는 330/500/750/1,000 유닛의 이동·그리드 재구축·반경 2셀 상대 탐색을 120 프레임 반복한다.

`BattlePerformanceProfiler`는 update 전체, AI/공간 탐색, 전투 풀, 무기, render CPU 구간을 각각 최신 512샘플 고정 배열에 기록한다. 결과 화면에서 P95와 공간 버킷, 투사체/VFX/대미지 숫자 풀 최대 사용량을 확인할 수 있다. render 값은 Flame의 Canvas 제출 코드에 걸린 CPU 시간이며 GPU 시간이나 화면 주사율이 아니다.

`tool/long_run_memory_benchmark.dart`는 1,000유닛을 18,000프레임, 즉 60Hz 5분 상당으로 반복해 워밍업 이후 RSS와 공간 버킷 수를 비교한다. 이는 버킷/샘플의 무제한 증가를 막는 결정론적 VM 회귀 검사다. 실제 Web 브라우저와 모바일의 GPU, GC pause, 발열은 release 빌드의 DevTools trace로 별도 승인한다.

전장 병사는 7병과×2진영 제작 원본을 `tool/update_unit_role_batch.py`로 역할별 표시 비율에 맞춘 런타임 아틀라스로 변환한다. 가시 유닛의 source rect, transform, tint를 재사용 리스트에 모은 뒤 `Canvas.drawAtlas` 한 번으로 제출한다. 그림자와 상태/등급 표식은 전후 레이어로 분리한다.

`BattleRenderPolicy`는 표준/저사양 모드의 지형 밀도, 상세 LOD 반경, 그림자, 참격과 피해 숫자 방출 비율을 순수 규칙으로 관리한다. 저사양 모드에서도 정예·지휘관·보스·상태이상·후퇴 유닛은 중요 대상으로 분류해 전술 표식을 유지한다. `tool/render_budget_benchmark.dart`는 500개 가시 유닛의 스프라이트 제출과 장식/VFX 예산을 비교한다.

## 17. 오류 처리

- 콘텐츠 누락: 개발 빌드 assert + 안전한 fallback
- 저장 오류: 비차단 배너, 재시도, 백업 복구
- 자산 로딩 실패: 로딩 화면에서 재시도/캠프 귀환
- 전투 예외: 보상 중복 없이 세션 종료 가능 상태 확보
- 네트워크 기능 추가 전까지 핵심 루프는 오프라인 동작

## 18. 보안과 공정성

알파 로컬 빌드에서는 서버 권위를 요구하지 않는다. 향후 결제/랭킹을 추가하면 재화, 모집, 보상은 서버 권위로 전환한다. 클라이언트 저장에 실제 결제 검증을 의존하지 않는다.

## 19. 아키텍처 변경 규칙

- 구조 변경 전 영향을 받는 시스템과 migration을 문서화한다.
- 대규모 리팩터링은 기능 추가와 분리해 커밋한다.
- 성능 최적화는 측정 전후 수치를 남긴다.
- 새 dependency는 플랫폼 지원, 번들 크기, 유지보수 상태를 검토한다.
- `PROGRESS.md`, `CHANGELOG.md`, 관련 설계 문서를 함께 갱신한다.
