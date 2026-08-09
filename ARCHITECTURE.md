# 아키텍처

## 현재 구조

- Flutter: 캠프, 계약, 명부, 상세, 전투 HUD/오버레이, 결과 화면
- Flame `SurvivorGame`: 전투 시간, 이동, 자동 공격, 경험치, 레벨업, 사건, 승리 판정
- `GameShell`: 알파의 화면 상태와 보상 통합
- `game_data.dart`: 용병·종족·전투 스타일·무기 정적 데이터

## 성능 설계

전투 유닛은 각각 `Component`로 만들지 않는다. `SurvivorGame`이 경량 `BattleUnit` 배열을 보유하고 한 번의 Canvas 패스로 배치 렌더링한다. 96px 공간 그리드로 플레이어 자동 공격뿐 아니라 아군·적군의 상대 진영 탐색 후보도 제한하며 화면 밖 유닛 AI를 줄인다. 참격 이펙트도 수명이 짧은 데이터 배열로 관리한다.

## 다음 분리 목표

`features/camp`, `features/contracts`, `features/mercenaries`, `game/systems`, `data`로 분리하고 저장 계층을 도입한다. 콘텐츠 데이터는 코드에서 JSON/정적 리포지터리로 이동한다.
