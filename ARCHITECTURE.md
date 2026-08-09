# 기술 아키텍처

## 1. 목표

- Flutter 메뉴 UI와 Flame 전투의 책임을 명확히 분리한다.
- Web, iOS, Android에서 동일한 게임 규칙을 사용한다.
- 500~1,000 유닛을 위한 데이터 지향 구조를 유지한다.
- 콘텐츠 추가가 화면/전투 코드 수정에 과도하게 의존하지 않게 한다.
- 런 상태와 영구 상태를 분리해 저장과 보상 중복 버그를 방지한다.

## 2. 현재 상태

- `main.dart`: 앱 부팅만 담당하는 9줄 진입점
- `app/game_app.dart`: 화면 상태, 캠프, 계약, 출전 선택, 장비, 명부, 상세, HUD, 결과
- `core/theme/game_theme.dart`: 공통 팔레트와 Flutter 테마
- `core/content/game_content_repository.dart`: 콘텐츠 조회 인터페이스와 알파 정적 구현
- `core/persistence/save_repository.dart`: versioned 계정 저장 모델과 저장 인터페이스
- `domain/game_data.dart`: 용병과 무기 정의
- `domain/battle_models.dart`: BattleConfig, BattleStats, BattleReport와 전투 오버레이 모델
- `game/survivor_game.dart`: 이동, 유닛, 진영 교전, 자동 공격, 경험치, 레벨업, 사건, 승리

앱/도메인/게임 런타임의 1차 경계는 만들어졌으며, 다음 구조 작업은 `game_app.dart`의 화면과 공통 컴포넌트를 기능 폴더로 분리하는 것이다.

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

같은 프레임에서 순서가 바뀌어 결과가 달라지지 않도록 고정한다. 피해와 사망은 즉시 리스트를 변경하기보다 command buffer를 사용해 프레임 말에 반영한다.

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

원칙:

- save schema version 필수
- 이전 버전 migration 테스트
- 보상 적용과 저장을 하나의 transaction처럼 처리
- 마지막 정상 저장 백업
- Web local storage와 모바일 파일 저장을 repository 뒤에서 교체
- 저장 실패 시 사용자에게 알리고 메모리 상태를 유지한 채 재시도

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
- 시스템 시간을 직접 읽지 않고 GameClock 사용
- 고정 timestep 또는 상한이 있는 dt 처리
- 결과 보고서 snapshot 비교 가능

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
